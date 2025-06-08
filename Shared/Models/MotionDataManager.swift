//
//  MotionDataManager.swift
//  SwingAnalyzerr
//
//  Created by Praveen Singh on 07/06/25.
//


//
//  MotionDataManager.swift
//  SwingAnalyzerr
//
//  Created for Core Motion integration and swing detection
//

import Foundation
import CoreMotion
import CoreData
import WatchConnectivity

@MainActor
class MotionDataManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isRecording = false
    @Published var swingProgress: Double = 0.0
    @Published var currentMotionData: MotionDataPoint?
    @Published var detectedSwingPhase: SwingPhase = .idle
    @Published var recordingStatus: RecordingStatus = .idle
    
    // MARK: - Motion Manager
    private let motionManager = CMMotionManager()
    private let deviceMotion = CMMotionManager()
    
    // MARK: - Data Collection
    var sensorReadings: [MotionDataPoint] = []
    private var recordingStartTime: Date?
    private var swingStartTime: Date?
    private var lastMotionUpdate: Date = Date()
    
    // MARK: - Swing Detection
    private var accelerationHistory: [Double] = []
    private var rotationHistory: [Double] = []
    private let historySize = 20
    private let swingThreshold: Double = 2.0  // G-force threshold
    private let rotationThreshold: Double = 3.0  // rad/s threshold
    private var consecutiveHighMotion = 0
    private var swingDetectionTimer: Timer?
    
    // MARK: - Configuration
    private let updateInterval: TimeInterval = 0.02  // 50Hz sampling
    private let maxRecordingDuration: TimeInterval = 10.0  // Maximum recording time
    
    // MARK: - Recording Status
    enum RecordingStatus {
        case idle
        case waiting  // Waiting for swing to start
        case recording  // Actively recording swing
        case processing  // Processing recorded data
        case completed
        case error(String)
    }
    
    // MARK: - Swing Phases
    enum SwingPhase {
        case idle
        case address  // Setup position
        case backswing
        case transition  // Top of backswing
        case downswing
        case impact
        case followThrough
        case finish
    }
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupMotionManager()
    }
    
    // MARK: - Motion Manager Setup
    func testMotionSensors() {
        let manager = CMMotionManager()
        
        print("🔍 Motion Manager Tests:")
        print("  - Device Motion: \(manager.isDeviceMotionAvailable)")
        print("  - Accelerometer: \(manager.isAccelerometerAvailable)")
        print("  - Gyroscope: \(manager.isGyroAvailable)")
        print("  - Magnetometer: \(manager.isMagnetometerAvailable)")
    }

    private func checkMotionAvailability() -> Bool {
        return motionManager.isDeviceMotionAvailable &&
               motionManager.isAccelerometerAvailable &&
               motionManager.isGyroAvailable
    }
    
    private func setupMotionManager() {
        // Configure motion manager
        motionManager.deviceMotionUpdateInterval = updateInterval
        motionManager.accelerometerUpdateInterval = updateInterval
        motionManager.gyroUpdateInterval = updateInterval
        
        // Check availability
        guard motionManager.isDeviceMotionAvailable,
              motionManager.isAccelerometerAvailable,
              motionManager.isGyroAvailable else {
            print("❌ Motion sensors not available")
            return
        }
        
        print("✅ Motion sensors initialized successfully")
    }
    
    func getSensorReadings() -> [MotionDataPoint] {
        return sensorReadings
    }
    // MARK: - Start Recording
    func startRecording() async {
        print("🔍 Debug: Starting motion recording...")
            print("🔍 Device Motion Available: \(motionManager.isDeviceMotionAvailable)")
            print("🔍 Accelerometer Available: \(motionManager.isAccelerometerAvailable)")
            print("🔍 Gyro Available: \(motionManager.isGyroAvailable)")
        
        guard !isRecording else { return }
        
        // Reset state
        sensorReadings.removeAll()
        accelerationHistory.removeAll()
        rotationHistory.removeAll()
        consecutiveHighMotion = 0
        recordingStartTime = Date()
        swingStartTime = nil
        detectedSwingPhase = .idle
        recordingStatus = .waiting
        
        isRecording = true
        
        // Start motion updates
        startMotionUpdates()
        
        // Start swing detection timer
        startSwingDetectionTimer()
        
        print("🎯 Started motion recording - waiting for swing...")
    }
    
    // MARK: - Stop Recording
    func stopRecording() {
        guard isRecording else { return }
        
        isRecording = false
        recordingStatus = .processing
        
        // Stop motion updates
        motionManager.stopDeviceMotionUpdates()
        swingDetectionTimer?.invalidate()
        
        print("⏹️ Stopped motion recording. Collected \(sensorReadings.count) data points")
        
        // Process the collected data
        Task {
            await processCollectedData()
        }
    }
    
    // MARK: - Start Motion Updates
    private func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            recordingStatus = .error("Device motion not available")
            return
        }
        
        motionManager.startDeviceMotionUpdates(
            using: .xMagneticNorthZVertical,
            to: .main
        ) { [weak self] motionData, error in
            guard let self = self,
                  let motion = motionData else {
                if let error = error {
                    self?.recordingStatus = .error(error.localizedDescription)
                }
                return
            }
            
            Task { @MainActor in
                self.processMotionUpdate(motion)
            }
        }
    }
    
    // MARK: - Process Motion Update
    private func processMotionUpdate(_ motion: CMDeviceMotion) {
        let now = Date()
        let timeOffset = recordingStartTime?.timeIntervalSince(now) ?? 0
        
        // Create motion data point
        let dataPoint = MotionDataPoint(
            timestamp: now,
            timeOffset: abs(timeOffset),
            userAcceleration: motion.userAcceleration,
            gravity: motion.gravity,
            rotationRate: motion.rotationRate,
            attitude: motion.attitude
        )
        
        // Store data point
        sensorReadings.append(dataPoint)
        currentMotionData = dataPoint
        lastMotionUpdate = now
        
        // Detect swing phases
        detectSwingPhase(dataPoint)
        
        // Check for swing completion
        if detectedSwingPhase == .finish {
            // Wait a bit more to capture full follow-through
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.stopRecording()
            }
        }
    }
    private func handleSwingDetection() {
        // Only update recording status - don't create any Core Data objects
        recordingStatus = .recording
        print("🏌️ Swing detected - started recording!")
    }
    private func handleImpactDetection() {
        // Only update status - don't save anything yet
        print("💥 Impact detected!")
    }
    private func completeRecording() {
        // Validate data before marking as complete
        guard validateSwingData() else {
            recordingStatus = .error("Invalid swing data")
            return
        }
        
        recordingStatus = .completed
        print("🎯 Swing completed with valid data!")
    }
    
    // Find your swing completion logic and add validation
    private func validateSwingData() -> Bool {
        let readings = getSensorReadings()
        
        guard readings.count >= 50 else {
            print("❌ Insufficient data points: \(readings.count)")
            return false
        }
        
        let maxAcceleration = readings.map { $0.totalAcceleration }.max() ?? 0
        guard maxAcceleration > 2.0 else {
            print("❌ Insufficient acceleration: \(maxAcceleration)")
            return false
        }
        
        return true
    }
    
    // MARK: - Swing Detection
    private func detectSwingPhase(_ dataPoint: MotionDataPoint) {
        let totalAcceleration = sqrt(
            pow(dataPoint.userAcceleration.x, 2) +
            pow(dataPoint.userAcceleration.y, 2) +
            pow(dataPoint.userAcceleration.z, 2)
        )
        
        let totalRotation = sqrt(
            pow(dataPoint.rotationRate.x, 2) +
            pow(dataPoint.rotationRate.y, 2) +
            pow(dataPoint.rotationRate.z, 2)
        )
        
        // Update history
        accelerationHistory.append(totalAcceleration)
        rotationHistory.append(totalRotation)
        
        if accelerationHistory.count > historySize {
            accelerationHistory.removeFirst()
            rotationHistory.removeFirst()
        }
        
        // Detect swing phases based on motion patterns
        switch detectedSwingPhase {
        case .idle, .address:
            // Look for start of backswing
            if totalAcceleration > swingThreshold * 0.5 || totalRotation > rotationThreshold * 0.3 {
                if swingStartTime == nil {
                    swingStartTime = dataPoint.timestamp
                    recordingStatus = .recording
                    print("🏌️ Swing detected - started recording!")
                }
                detectedSwingPhase = .backswing
            }
            
        case .backswing:
            // Look for transition to downswing (acceleration peak)
            if totalAcceleration > swingThreshold {
                detectedSwingPhase = .transition
            }
            
        case .transition:
            // Look for downswing (high acceleration)
            if totalAcceleration > swingThreshold * 1.5 {
                detectedSwingPhase = .downswing
            }
            
        case .downswing:
            // Look for impact (maximum acceleration)
            if totalAcceleration > swingThreshold * 2.0 {
                detectedSwingPhase = .impact
                print("💥 Impact detected!")
            }
            
        case .impact:
            // Look for follow-through (decreasing acceleration)
            if totalAcceleration < swingThreshold {
                detectedSwingPhase = .followThrough
            }
            
        case .followThrough:
            // Look for finish (low acceleration and rotation)
            if totalAcceleration < swingThreshold * 0.3 && totalRotation < rotationThreshold * 0.3 {
                detectedSwingPhase = .finish
                print("🎯 Swing completed!")
            }
            
        case .finish:
            break
        }
        
        // Update progress based on swing phase
        updateSwingProgress()
    }
    
    private func completeSwingRecording() {
        guard validateSwingData() else {
            print("❌ Invalid swing - discarding data")
            recordingStatus = .error("Invalid swing data")
            return
        }
        
        recordingStatus = .completed
        print("✅ Valid swing completed")
    }
    // MARK: - Update Swing Progress
    private func updateSwingProgress() {
        switch detectedSwingPhase {
        case .idle: swingProgress = 0.0
        case .address: swingProgress = 0.1
        case .backswing: swingProgress = 0.3
        case .transition: swingProgress = 0.5
        case .downswing: swingProgress = 0.7
        case .impact: swingProgress = 0.8
        case .followThrough: swingProgress = 0.9
        case .finish: swingProgress = 1.0
        }
    }
    
    // MARK: - Swing Detection Timer
    private func startSwingDetectionTimer() {
        swingDetectionTimer = Timer.scheduledTimer(withTimeInterval: maxRecordingDuration, repeats: false) { _ in
            if self.isRecording && self.detectedSwingPhase == .idle {
                print("⏱️ Recording timeout - no swing detected")
                self.stopRecording()
            }
        }
    }
    
    // MARK: - Process Collected Data
    private func processCollectedData() async {
        guard !sensorReadings.isEmpty else {
            await MainActor.run {
                recordingStatus = .error("No data collected")
            }
            return
        }
        
        print("📊 Processing \(sensorReadings.count) sensor readings...")
        
        // Save to Core Data
        do {
            let swingSession = try await saveSwingSession()
            
            await MainActor.run {
                recordingStatus = .completed
                print("✅ Swing data saved successfully with ID: \(String(describing: swingSession.id))")
            }
        } catch {
            await MainActor.run {
                recordingStatus = .error("Failed to save data: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Save Swing Session
    private func saveSwingSession() async throws -> SwingSession {
        let context = PersistenceController.shared.container.viewContext
        
        return try await context.perform {
            // Create SwingSession
            let swingSession = SwingSession(context: context)
            swingSession.id = UUID()
            swingSession.timestamp = self.recordingStartTime ?? Date()
            swingSession.golfClub = "Driver" // Will be set by UI selection
            swingSession.watchHand = "Left" // Will be detected or set by UI
            swingSession.deviceType = "AppleWatch"
            swingSession.swingDuration = self.sensorReadings.last?.timeOffset ?? 0.0
            
            // Create SensorReading entities
            for (index, dataPoint) in self.sensorReadings.enumerated() {
                let sensorReading = SensorReading(context: context)
                sensorReading.id = UUID()
                sensorReading.timestamp = dataPoint.timestamp
                sensorReading.sequenceNumber = Int32(index)
                
                // Accelerometer
                sensorReading.accelerometerX = dataPoint.userAcceleration.x + dataPoint.gravity.x
                sensorReading.accelerometerY = dataPoint.userAcceleration.y + dataPoint.gravity.y
                sensorReading.accelerometerZ = dataPoint.userAcceleration.z + dataPoint.gravity.z
                
                // User Acceleration
                sensorReading.userAccelerationX = dataPoint.userAcceleration.x
                sensorReading.userAccelerationY = dataPoint.userAcceleration.y
                sensorReading.userAccelerationZ = dataPoint.userAcceleration.z
                
                // Gravity
                sensorReading.gravityX = dataPoint.gravity.x
                sensorReading.gravityY = dataPoint.gravity.y
                sensorReading.gravityZ = dataPoint.gravity.z
                
                // Rotation Rate
                sensorReading.rotationRateX = dataPoint.rotationRate.x
                sensorReading.rotationRateY = dataPoint.rotationRate.y
                sensorReading.rotationRateZ = dataPoint.rotationRate.z
                
                // Attitude
                sensorReading.attitudeRoll = dataPoint.attitude.roll
                sensorReading.attitudePitch = dataPoint.attitude.pitch
                sensorReading.attitudeYaw = dataPoint.attitude.yaw
                
                // Link to swing session
                sensorReading.swingSession = swingSession
            }
            
            // Save context
            try context.save()
            
            return swingSession
        }
    }
}

// MARK: - Motion Data Point
struct MotionDataPoint {
    let timestamp: Date
    let timeOffset: TimeInterval
    let userAcceleration: CMAcceleration
    let gravity: CMAcceleration
    let rotationRate: CMRotationRate
    let attitude: CMAttitude
    
    // Computed properties for analysis
    var totalAcceleration: Double {
        sqrt(pow(userAcceleration.x, 2) + pow(userAcceleration.y, 2) + pow(userAcceleration.z, 2))
    }
    
    var totalRotation: Double {
        sqrt(pow(rotationRate.x, 2) + pow(rotationRate.y, 2) + pow(rotationRate.z, 2))
    }
}

// MARK: - Extensions
extension MotionDataManager {
    var hasValidData: Bool {
        !sensorReadings.isEmpty && sensorReadings.count > 10
    }
    
    var swingDuration: TimeInterval {
        guard let start = swingStartTime,
              let end = sensorReadings.last?.timestamp else {
            return 0
        }
        return end.timeIntervalSince(start)
    }
    
    func getMaxAcceleration() -> Double {
        sensorReadings.map { $0.totalAcceleration }.max() ?? 0.0
    }
    
    func getMaxRotationRate() -> Double {
        sensorReadings.map { $0.totalRotation }.max() ?? 0.0
    }
}

