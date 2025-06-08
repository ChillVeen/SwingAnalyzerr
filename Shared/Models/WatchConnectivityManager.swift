//
//  WatchConnectivityManager.swift
//  SwingAnalyzerr
//
//  Enhanced sync manager for real-time data synchronization
//

import Foundation
import WatchConnectivity
import CoreData
import Combine

@MainActor
class WatchConnectivityManager: NSObject, ObservableObject {
    
    // MARK: - Published Properties
    @Published var isConnected = false
    @Published var isReachable = false
    @Published var lastSyncTime: Date?
    @Published var syncStatus: SyncStatus = .idle
    
    // MARK: - Private Properties
    private var session: WCSession?
    private let persistenceController = PersistenceController.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Sync Status
    enum SyncStatus {
        case idle
        case syncing
        case success
        case failed(String)
    }
    
    // MARK: - Message Types
    enum MessageType: String, CaseIterable {
        case swingData = "swingData"
        case deleteSwing = "deleteSwing"
        case requestSync = "requestSync"
        case syncResponse = "syncResponse"
        case heartbeat = "heartbeat"
    }
    
    override init() {
        super.init()
        setupWatchConnectivity()
        startHeartbeat()
    }
    
    // MARK: - Setup
    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else {
            print("❌ Watch Connectivity not supported")
            return
        }
        
        session = WCSession.default
        session?.delegate = self
        session?.activate()
        
        print("✅ Watch Connectivity Manager initialized")
    }
    
    // MARK: - Heartbeat for Connection Monitoring
    private func startHeartbeat() {
        Timer.publish(every: 30.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.sendHeartbeat()
            }
            .store(in: &cancellables)
    }
    
    private func sendHeartbeat() {
        guard let session = session, session.isReachable else { return }
        
        // Small heartbeat message - use sendMessage
        let message: [String: Any] = [
            "type": "heartbeat",
            "timestamp": Date().timeIntervalSince1970,
            "platform": getCurrentPlatform()
        ]
        
        session.sendMessage(message, replyHandler: nil) { error in
            print("Heartbeat failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Swing Data Sync
    func syncSwingData(_ swingSession: SwingSession) async {
        guard let session = session, session.activationState == .activated else {
            print("❌ Watch session not activated")
            return
        }
        
        // VALIDATE: Don't sync invalid swings
        guard swingSession.calculatedDistance > 0,
              swingSession.swingDuration > 0,
              !(swingSession.rating?.isEmpty ?? true) else {
            print("❌ Invalid swing data - NOT syncing to iPhone")
            print("   Distance: \(swingSession.calculatedDistance)")
            print("   Duration: \(swingSession.swingDuration)")
            print("   Rating: \(swingSession.rating ?? "nil")")
            return
        }
        
        await MainActor.run {
            syncStatus = .syncing
        }
        
        let userInfo: [String: Any] = [
            "type": "swingData",
            "id": swingSession.id?.uuidString ?? UUID().uuidString,
            "timestamp": swingSession.timestamp?.timeIntervalSince1970 ?? Date().timeIntervalSince1970,
            "golfClub": swingSession.golfClub ?? "",
            "rating": swingSession.rating ?? "",
            "distance": swingSession.calculatedDistance, // Ensure this is the correct value
            "duration": swingSession.swingDuration,
            "deviceType": "AppleWatch"
        ]
        
        session.transferUserInfo(userInfo)
        
        await MainActor.run {
            syncStatus = .success
            lastSyncTime = Date()
            print("✅ Valid swing synced to iPhone - Distance: \(swingSession.calculatedDistance) yards")
        }
    }
    
    func syncSwingResults(_ results: SwingResults, club: String, hand: String) async {
        guard let session = session, session.activationState == .activated else {
            print("❌ Watch session not activated")
            return
        }
        
        // VALIDATE: Don't sync invalid swings
        guard results.distanceResult.estimatedDistance > 0,
              results.swingMetrics.swingSpeed > 0,
              !results.mlAnalysis.rating.isEmpty else {
            print("❌ Invalid swing results - NOT syncing to iPhone")
            print("   Distance: \(results.distanceResult.estimatedDistance)")
            print("   Swing Speed: \(results.swingMetrics.swingSpeed)")
            print("   Rating: \(results.mlAnalysis.rating)")
            return
        }
        
        await MainActor.run {
            syncStatus = .syncing
        }
        
        let userInfo: [String: Any] = [
            "type": "swingData",
            "id": UUID().uuidString,
            "timestamp": Date().timeIntervalSince1970,
            "golfClub": club,
            "rating": results.mlAnalysis.rating,
            "distance": results.distanceResult.estimatedDistance,
            "duration": results.swingMetrics.tempo > 0 ? 60.0 / results.swingMetrics.tempo : 0.0,
            "deviceType": "AppleWatch"
        ]
        
        session.transferUserInfo(userInfo)
        
        await MainActor.run {
            syncStatus = .success
            lastSyncTime = Date()
            print("✅ Valid swing synced to iPhone - Distance: \(results.distanceResult.estimatedDistance) yards")
        }
    }
    
    // MARK: - Delete Swing Sync
    func syncSwingDeletion(_ swingID: UUID) async {
        guard let session = session, session.isReachable else {
            print("❌ Watch not reachable for delete sync")
            return
        }
        
        let message: [String: Any] = [
            "type": MessageType.deleteSwing.rawValue,
            "swingID": swingID.uuidString,
            "timestamp": Date().timeIntervalSince1970,
            "platform": getCurrentPlatform()
        ]
        
        session.sendMessage(message, replyHandler: { response in
            print("✅ Delete sync confirmed")
        }) { error in
            print("❌ Delete sync failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Full Data Sync Request
    func requestFullSync() async {
        guard let session = session, session.activationState == .activated else { return }
        
        await MainActor.run {
            syncStatus = .syncing
        }
        
        let allSwings = persistenceController.fetchSwingSessions()
        
        // Use transferUserInfo for large sync data
        let userInfo: [String: Any] = [
            "type": "fullSync",
            "timestamp": Date().timeIntervalSince1970,
            "platform": getCurrentPlatform(),
            "swingCount": allSwings.count,
            "syncRequested": true
        ]
        
        session.transferUserInfo(userInfo)
        
        await MainActor.run {
            syncStatus = .success
            lastSyncTime = Date()
            print("✅ Full sync request queued")
        }
    }
    
    // MARK: - Data Payload Creation (FIXED)
    private func createSwingDataPayload(_ swingSession: SwingSession) -> [String: Any] {
        return [
            "id": swingSession.id?.uuidString ?? UUID().uuidString,
            "timestamp": swingSession.timestamp?.timeIntervalSince1970 ?? Date().timeIntervalSince1970,
            "golfClub": swingSession.golfClub ?? "",
            "watchHand": swingSession.watchHand ?? "",
            "rating": swingSession.rating ?? "",
            "calculatedDistance": swingSession.calculatedDistance,
            "swingDuration": swingSession.swingDuration,
            "deviceType": swingSession.deviceType ?? "AppleWatch",
            "analysis": createAnalysisPayload(swingSession.analysis) ?? [:],
            "sensorData": createSensorDataPayload(swingSession.sensorData?.allObjects as? [SensorReading] ?? [])
        ]
    }
    
    private func createBulkSwingDataPayload(_ swingSessions: [SwingSession]) -> [[String: Any]] {
        return swingSessions.map { swing in
            return createSwingDataPayload(swing)
        }
    }
    
    private func createAnalysisPayload(_ analysis: SwingAnalysis?) -> [String: Any]? {
        guard let analysis = analysis else { return nil }
        
        return [
            "id": analysis.id?.uuidString ?? UUID().uuidString,
            "mlRating": analysis.mlRating ?? "",
            "mlConfidence": analysis.mlConfidence,
            "maxSwingSpeed": analysis.maxSwingSpeed,
            "averageAcceleration": analysis.averageAcceleration,
            "improvementSuggestions": analysis.improvementSuggestions ?? ""
        ]
    }
    
    private func createSensorDataPayload(_ sensorReadings: [SensorReading]) -> [[String: Any]] {
        return sensorReadings.map { reading in
            return [
                "id": reading.id?.uuidString ?? UUID().uuidString,
                "timestamp": reading.timestamp?.timeIntervalSince1970 ?? Date().timeIntervalSince1970,
                "sequenceNumber": reading.sequenceNumber,
                "accelerometerX": reading.accelerometerX,
                "accelerometerY": reading.accelerometerY,
                "accelerometerZ": reading.accelerometerZ,
                "userAccelerationX": reading.userAccelerationX,
                "userAccelerationY": reading.userAccelerationY,
                "userAccelerationZ": reading.userAccelerationZ
            ]
        }
    }
    
    // MARK: - Data Processing from Messages
    // REPLACE with this simple version:
    private func processSwingData(_ data: [String: Any]) async {
        print("✅ Received swing data from companion device")
        // TODO: Implement Core Data sync later
    }

    
    private func processAnalysisData(_ data: [String: Any], for swingSession: SwingSession, context: NSManagedObjectContext) {
        let analysis = SwingAnalysis(context: context)
        analysis.id = UUID(uuidString: data["id"] as? String ?? "") ?? UUID()
        analysis.mlRating = data["mlRating"] as? String
        analysis.mlConfidence = data["mlConfidence"] as? Double ?? 0
        analysis.maxSwingSpeed = data["maxSwingSpeed"] as? Double ?? 0
        analysis.averageAcceleration = data["averageAcceleration"] as? Double ?? 0
        analysis.improvementSuggestions = data["improvementSuggestions"] as? String
        analysis.swingSession = swingSession
    }
    
    private func processSensorData(_ dataArray: [[String: Any]], for swingSession: SwingSession, context: NSManagedObjectContext) {
        for data in dataArray {
            let sensorReading = SensorReading(context: context)
            sensorReading.id = UUID(uuidString: data["id"] as? String ?? "") ?? UUID()
            sensorReading.timestamp = Date(timeIntervalSince1970: data["timestamp"] as? Double ?? Date().timeIntervalSince1970)
            sensorReading.sequenceNumber = Int32(data["sequenceNumber"] as? Int ?? 0)
            sensorReading.accelerometerX = data["accelerometerX"] as? Double ?? 0
            sensorReading.accelerometerY = data["accelerometerY"] as? Double ?? 0
            sensorReading.accelerometerZ = data["accelerometerZ"] as? Double ?? 0
            sensorReading.swingSession = swingSession
        }
    }
    
    // Add this method to save swing data on iPhone
    private func saveSwingDataToiPhone(_ data: [String: Any]) async {
        let container = persistenceController.container
        
        await container.performBackgroundTask { context in
            do {
                // Create new swing session on iPhone
                let swingSession = SwingSession(context: context)
                swingSession.id = UUID(uuidString: data["id"] as? String ?? "") ?? UUID()
                swingSession.timestamp = Date(timeIntervalSince1970: data["timestamp"] as? Double ?? Date().timeIntervalSince1970)
                swingSession.golfClub = data["golfClub"] as? String
                swingSession.rating = data["rating"] as? String
                swingSession.calculatedDistance = data["distance"] as? Double ?? 0
                swingSession.swingDuration = data["duration"] as? Double ?? 0
                swingSession.deviceType = data["deviceType"] as? String ?? "AppleWatch"
                swingSession.watchHand = "Left" // Default for now
                
                // Save to iPhone's Core Data
                try context.save()
                
                print("✅ Swing data saved to iPhone Core Data")
                print("📊 Swing ID: \(swingSession.id?.uuidString ?? "Unknown")")
                print("🏌️ Club: \(swingSession.golfClub ?? "Unknown")")
                print("📏 Distance: \(swingSession.calculatedDistance) yards")
                
            } catch {
                print("❌ Failed to save swing data to iPhone: \(error.localizedDescription)")
            }
        }
    }
    // MARK: - Delete Operations
    private func processSwingDeletion(_ swingID: String) async {
        print("✅ Received delete request for swing: \(swingID)")
        // TODO: Implement deletion sync later
    }

    
    // MARK: - Helper Methods
    private func getCurrentPlatform() -> String {
        #if os(watchOS)
        return "watchOS"
        #else
        return "iOS"
        #endif
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityManager: WCSessionDelegate {
     func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = activationState == .activated
            
            if let error = error {
                print("❌ Watch Connectivity activation error: \(error.localizedDescription)")
            } else {
                print("✅ Watch Connectivity activated successfully")
                
                Task {
                    await self.requestFullSync()
                }
            }
        }
    }
    
     func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            print("📱 Watch reachability changed: \(session.isReachable)")
        }
    }
    
     func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        Task { @MainActor in
            guard let messageType = message["type"] as? String else {
                print("❌ No message type found")
                return
            }
            
            print("📨 Received message type: \(messageType)")
            
            switch messageType {
            case "swingData":
                print("✅ Received swing data from companion device")
                // Simple acknowledgment for now
                
            case "heartbeat":
                print("💓 Heartbeat received")
                
            default:
                print("❌ Unknown message type: \(messageType)")
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        Task { @MainActor in
            guard let messageType = userInfo["type"] as? String else {
                print("❌ No message type in user info")
                return
            }
            
            print("📦 Received user info type: \(messageType)")
            
            switch messageType {
            case "swingData":
                print("✅ Received swing data via user info transfer")
                print("📊 Swing ID: \(userInfo["id"] as? String ?? "Unknown")")
                print("🏌️ Club: \(userInfo["golfClub"] as? String ?? "Unknown")")
                print("📏 Distance: \(userInfo["distance"] as? Double ?? 0) yards")
                print("⭐ Rating: \(userInfo["rating"] as? String ?? "Unknown")")
                
                // SAVE TO CORE DATA ON IPHONE
                await saveSwingDataToiPhone(userInfo)
                
            case "fullSync":
                print("✅ Received full sync request")
                print("📊 Swing count: \(userInfo["swingCount"] as? Int ?? 0)")
                
            default:
                print("❌ Unknown user info type: \(messageType)")
            }
        }
    }
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isConnected = false
        }
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isConnected = false
        }
    }
    #endif
}

// MARK: - Public Methods

// MARK: - Public Methods
extension WatchConnectivityManager {
    func deleteSwing(_ swingSession: SwingSession) async {
        // Delete locally first
        await persistenceController.performBackgroundTask { context in
            do {
                let swingToDelete = context.object(with: swingSession.objectID) as! SwingSession
                context.delete(swingToDelete)
                try context.save()
                print("✅ Deleted swing locally")
            } catch {
                print("❌ Failed to delete swing locally: \(error.localizedDescription)")
            }
        }
        
        // Sync deletion to other device
        if let swingID = swingSession.id {
            await syncSwingDeletion(swingID)
        }
    }
    
    var syncStatusText: String {
        switch syncStatus {
        case .idle:
            return "Ready"
        case .syncing:
            return "Syncing..."
        case .success:
            if let lastSync = lastSyncTime {
                return "Last synced \(lastSync.formatted(.relative(presentation: .named)))"
            }
            return "Synced"
        case .failed(let error):
            return "Sync failed: \(error)"
        }
    }
}

