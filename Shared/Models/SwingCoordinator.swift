//
//  SwingCoordinator.swift
//  SwingAnalyzerr
//
//  Enhanced with sync capabilities
//

import Foundation
import CoreData
import WatchConnectivity
import Combine

@MainActor
class SwingCoordinator: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentState: SwingState = .idle
    @Published var selectedClub: DistanceCalculator.GolfClub = .driver
    @Published var selectedHand: WatchHand = .left
    @Published var isAnalyzing = false
    @Published var currentSwingSession: SwingSession?
    @Published var latestResults: SwingResults?
    @Published var error: String?
    
    // MARK: - Managers
    private let motionManager = MotionDataManager()
    private let mlAnalyzer = MLSwingAnalyzer()
    private let persistenceController = PersistenceController.shared
    
    // MARK: - Sync Manager
    private let syncManager = WatchConnectivityManager()
    
    // MARK: - State Management
    enum SwingState: Equatable {
        case idle
        case preparing
        case waitingForSwing
        case recording
        case analyzing
        case completed
        case error(String)
        
        var displayText: String {
            switch self {
            case .idle: return "Ready to Swing"
            case .preparing: return "Preparing..."
            case .waitingForSwing: return "Make Your Swing"
            case .recording: return "Recording Swing..."
            case .analyzing: return "Analyzing..."
            case .completed: return "Analysis Complete"
            case .error(let message): return "Error: \(message)"
            }
        }
        
        var isRecording: Bool {
            switch self {
            case .recording: return true
            default: return false
            }
        }
        
        static func == (lhs: SwingState, rhs: SwingState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.preparing, .preparing), (.waitingForSwing, .waitingForSwing),
                 (.recording, .recording), (.analyzing, .analyzing), (.completed, .completed):
                return true
            case (.error(let lhsMessage), .error(let rhsMessage)):
                return lhsMessage == rhsMessage
            default:
                return false
            }
        }
    }
    
    enum WatchHand: String, CaseIterable {
        case left = "Left"
        case right = "Right"
        
        var displayName: String { rawValue }
    }
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupMotionManagerObservation()
    }
    
    // MARK: - Setup Methods
    private func setupMotionManagerObservation() {
        motionManager.$recordingStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.handleMotionManagerStatusChange(status)
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Main Swing Analysis Flow
    func startSwingAnalysis() async throws {
        guard currentState == .idle else { return }
        
        do {
            currentState = .preparing
            error = nil
            latestResults = nil
            // DON'T create any swing session here
            
            currentState = .waitingForSwing
            await motionManager.startRecording()
            
            await waitForSwingCompletion()
            
            // Only proceed if we have valid motion data
            guard motionManager.hasValidData else {
                throw SwingAnalysisError.insufficientData
            }
            
            currentState = .analyzing
            isAnalyzing = true
            
            let results = try await performFullAnalysis()
            
            // ONLY save after successful analysis with valid results
            try await saveAndPresentResults(results)
            
            currentState = .completed
            isAnalyzing = false
            
        } catch {
            currentState = .error(error.localizedDescription)
            self.error = error.localizedDescription
            isAnalyzing = false
            // DON'T save anything on error
            throw error
        }
    }

    
    // MARK: - Wait for Swing Completion (Fixed)
    private func waitForSwingCompletion() async {
        while true {
            switch motionManager.recordingStatus {
            case .recording:
                currentState = .recording
            case .completed:
                return
            case .error(let message):
                currentState = .error(message)
                return
            default:
                break
            }
            
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
    }
    
    // MARK: - Perform Full Analysis
    private func performFullAnalysis() async throws -> SwingResults {
        guard motionManager.hasValidData else {
            throw SwingAnalysisError.insufficientData
        }
        
        let sensorReadings = motionManager.getSensorReadings()
        
        // Validate we have enough data
        guard sensorReadings.count >= 50 else {
            print("❌ Insufficient sensor readings: \(sensorReadings.count)")
            throw SwingAnalysisError.insufficientData
        }
        
        let mlAnalysis = await mlAnalyzer.analyzeSwing(
            sensorReadings: sensorReadings,
            golfClub: selectedClub.rawValue,
            watchHand: selectedHand.rawValue
        )
        
        // Validate ML analysis
        guard !mlAnalysis.rating.isEmpty, mlAnalysis.confidence > 0.3 else {
            print("❌ Invalid ML analysis - Rating: \(mlAnalysis.rating), Confidence: \(mlAnalysis.confidence)")
            throw SwingAnalysisError.mlModelUnavailable
        }
        
        let swingMetrics = calculateSwingMetrics(from: sensorReadings)
        
        let distanceResult = DistanceCalculator.calculateDistance(
            from: sensorReadings,
            golfClub: selectedClub,
            swingAnalysis: mlAnalysis
        )
        
        // Validate distance calculation
        guard distanceResult.estimatedDistance > 0 else {
            print("❌ Invalid distance calculation: \(distanceResult.estimatedDistance)")
            throw SwingAnalysisError.insufficientData
        }
        
        print("✅ Valid analysis completed - Distance: \(distanceResult.estimatedDistance) yards")
        
        return SwingResults(
            mlAnalysis: mlAnalysis,
            distanceResult: distanceResult,
            swingMetrics: swingMetrics,
            suggestions: [],
            sensorReadings: sensorReadings
        )
    }

    
    // MARK: - Calculate Swing Metrics
    private func calculateSwingMetrics(from readings: [MotionDataPoint]) -> SwingMetrics {
        guard !readings.isEmpty else {
            return SwingMetrics(
                maxAcceleration: 0,
                swingSpeed: 0,
                attackAngle: 0,
                swingPath: 0,
                tempo: 0,
                impactTimestamp: Date()
            )
        }
        
        let accelerations = readings.map { $0.totalAcceleration }
        let maxAccelIndex = accelerations.firstIndex(of: accelerations.max() ?? 0) ?? 0
        let impactPoint = readings[maxAccelIndex]
        
        let maxAcceleration = accelerations.max() ?? 0
        let swingSpeed = calculateSwingSpeed(from: readings)
        let attackAngle = calculateAttackAngle(from: readings, impactIndex: maxAccelIndex)
        let swingPath = calculateSwingPath(from: readings, impactIndex: maxAccelIndex)
        let tempo = calculateTempo(from: readings)
        
        return SwingMetrics(
            maxAcceleration: maxAcceleration,
            swingSpeed: swingSpeed,
            attackAngle: attackAngle,
            swingPath: swingPath,
            tempo: tempo,
            impactTimestamp: impactPoint.timestamp
        )
    }
    
    private func calculateSwingSpeed(from readings: [MotionDataPoint]) -> Double {
        let speeds = readings.map { $0.totalAcceleration }
        return speeds.max() ?? 0.0
    }
    
    private func calculateAttackAngle(from readings: [MotionDataPoint], impactIndex: Int) -> Double {
        let windowStart = max(0, impactIndex - 5)
        let windowEnd = min(readings.count, impactIndex + 5)
        let impactWindow = Array(readings[windowStart..<windowEnd])
        
        let pitchAngles = impactWindow.map { $0.attitude.pitch * 180 / Double.pi }
        return pitchAngles.reduce(0, +) / Double(max(1, pitchAngles.count))
    }
    
    private func calculateSwingPath(from readings: [MotionDataPoint], impactIndex: Int) -> Double {
        let windowStart = max(0, impactIndex - 3)
        let windowEnd = min(readings.count, impactIndex + 3)
        let impactWindow = Array(readings[windowStart..<windowEnd])
        
        let yawAngles = impactWindow.map { $0.attitude.yaw * 180 / Double.pi }
        return yawAngles.reduce(0, +) / Double(max(1, yawAngles.count))
    }
    
    private func calculateTempo(from readings: [MotionDataPoint]) -> Double {
        guard readings.count > 1 else { return 0.0 }
        
        let totalTime = readings.last!.timeOffset - readings.first!.timeOffset
        return totalTime > 0 ? 60.0 / totalTime : 0.0
    }
    
    // MARK: - Save and Present Results (FIXED - Single Declaration)
    private func saveAndPresentResults(_ results: SwingResults) async throws {
        // VALIDATE before saving
        guard results.distanceResult.estimatedDistance > 0,
              !results.sensorReadings.isEmpty,
              results.swingMetrics.maxAcceleration > 1.0,
              !results.mlAnalysis.rating.isEmpty else {
            print("❌ Invalid swing results - not saving or syncing")
            throw SwingAnalysisError.insufficientData
        }
        
        let swingSession = try await saveSwingSession(results)
        
        await MainActor.run {
            self.currentSwingSession = swingSession
            self.latestResults = results
        }
        
        // Sync using results directly instead of saved session
        await syncManager.syncSwingResults(results, club: selectedClub.rawValue, hand: selectedHand.rawValue)
    }
    
    // MARK: - Save Swing Session
    private func saveSwingSession(_ results: SwingResults) async throws -> SwingSession {
        return try await withCheckedThrowingContinuation { continuation in
            persistenceController.container.performBackgroundTask { context in
                do {
                    let swingSession = SwingSession(context: context)
                    swingSession.id = UUID()
                    swingSession.timestamp = Date()
                    swingSession.golfClub = self.selectedClub.rawValue
                    swingSession.watchHand = self.selectedHand.rawValue
                    swingSession.rating = results.mlAnalysis.rating
                    swingSession.calculatedDistance = results.distanceResult.estimatedDistance
                    swingSession.swingDuration = results.swingMetrics.tempo > 0 ? 60.0 / results.swingMetrics.tempo : 0.0
                    swingSession.deviceType = "AppleWatch"
                    
                    // DEBUG: Log what we're saving
                    print("🔍 Saving swing session:")
                    print("   Distance: \(swingSession.calculatedDistance)")
                    print("   Duration: \(swingSession.swingDuration)")
                    print("   Rating: \(swingSession.rating ?? "nil")")
                    print("   Club: \(swingSession.golfClub ?? "nil")")
                    
                    let analysis = SwingAnalysis(context: context)
                    analysis.id = UUID()
                    analysis.timestamp = Date()
                    analysis.mlRating = results.mlAnalysis.rating
                    analysis.mlConfidence = results.mlAnalysis.confidence
                    analysis.maxSwingSpeed = results.swingMetrics.swingSpeed
                    analysis.averageAcceleration = results.swingMetrics.maxAcceleration
                    analysis.improvementSuggestions = ""
                    analysis.swingSession = swingSession
                    swingSession.analysis = analysis
                    
                    for (index, reading) in results.sensorReadings.enumerated() {
                        let sensorReading = SensorReading(context: context)
                        sensorReading.id = UUID()
                        sensorReading.timestamp = reading.timestamp
                        sensorReading.sequenceNumber = Int32(index)
                        sensorReading.accelerometerX = reading.userAcceleration.x + reading.gravity.x
                        sensorReading.accelerometerY = reading.userAcceleration.y + reading.gravity.y
                        sensorReading.accelerometerZ = reading.userAcceleration.z + reading.gravity.z
                        sensorReading.swingSession = swingSession
                    }
                    
                    try context.save()
                    continuation.resume(returning: swingSession)
                    
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Motion Manager Status Handler
    private func handleMotionManagerStatusChange(_ status: MotionDataManager.RecordingStatus) {
        switch status {
        case .idle:
            if currentState == .recording || currentState == .waitingForSwing {
                currentState = .idle
            }
        case .waiting:
            currentState = .waitingForSwing
        case .recording:
            currentState = .recording
        case .processing:
            currentState = .analyzing
        case .completed:
            break
        case .error(let message):
            currentState = .error(message)
            self.error = message
        }
    }
    
    // MARK: - Public Methods
    func reset() {
        currentState = .idle
        error = nil
        latestResults = nil
        currentSwingSession = nil
        isAnalyzing = false
        Task {
            await motionManager.stopRecording()
        }
    }
    
    func selectClub(_ club: DistanceCalculator.GolfClub) {
        selectedClub = club
    }
    
    func selectHand(_ hand: WatchHand) {
        selectedHand = hand
    }
    
    // MARK: - Sync Methods
    func deleteSwing(_ swingSession: SwingSession) async {
        await syncManager.deleteSwing(swingSession)
    }
    
    func requestManualSync() async {
        await syncManager.requestFullSync()
    }
    
    var syncStatus: String {
        return syncManager.syncStatusText
    }
    
    var isConnectedToCompanion: Bool {
        return syncManager.isReachable
    }
}

// MARK: - Extensions
extension SwingCoordinator {
    var canStartSwing: Bool {
        return currentState == .idle && !isAnalyzing
    }
    
    var progressPercentage: Double {
        switch currentState {
        case .idle: return 0.0
        case .preparing: return 0.2
        case .waitingForSwing: return 0.3
        case .recording: return 0.6
        case .analyzing: return 0.8
        case .completed: return 1.0
        case .error: return 0.0
        }
    }
}

// MARK: - Error Handling
enum SwingAnalysisError: LocalizedError {
    case insufficientData
    case analysisTimeout
    case mlModelUnavailable
    case saveFailed
    
    var errorDescription: String? {
        switch self {
        case .insufficientData:
            return "Not enough swing data collected"
        case .analysisTimeout:
            return "Analysis timed out"
        case .mlModelUnavailable:
            return "Machine learning model not available"
        case .saveFailed:
            return "Failed to save swing data"
        }
    }
}


// MARK: - Data Models
struct SwingResults {
    let mlAnalysis: SwingAnalysisResult
    let distanceResult: DistanceResult
    let swingMetrics: SwingMetrics
    let suggestions: [ImprovementSuggestionModel]
    let sensorReadings: [MotionDataPoint]
    
    var isValid: Bool {
        return mlAnalysis.isValid && distanceResult.confidence > 0.5
    }
    
    var summaryText: String {
        return "\(mlAnalysis.rating) swing - \(distanceResult.formattedDistance)"
    }
}

// MARK: - Improvement Suggestion Model (to avoid conflicts)
struct ImprovementSuggestionModel: Identifiable, Codable {
    let id = UUID()
    let title: String
    let description: String
    let category: String
    let priority: Int
    let actionableSteps: [String]
    
    init(title: String, description: String, category: String, priority: Int, actionableSteps: [String]) {
        self.title = title
        self.description = description
        self.category = category
        self.priority = priority
        self.actionableSteps = actionableSteps
    }
}




