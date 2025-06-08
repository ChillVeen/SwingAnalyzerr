//
//  PersistenceController.swift
//  SwingAnalyzerr
//
//  Created by Praveen Singh on 07/06/25.
//



//
//  PersistenceController.swift
//  SwingAnalyzerr
//
//  Core Data persistence controller for managing swing data
//

import CoreData
import Foundation

class PersistenceController {
    
    // MARK: - Singleton
    static let shared = PersistenceController()
    
    // MARK: - Preview Context (for SwiftUI previews)
    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext
        
        // Create sample data for previews
        createSampleData(in: context)
        
        return controller
    }()
    
    // MARK: - Core Data Container
    let container: NSPersistentContainer
    
    // MARK: - Initialization
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "SwingAnalyzerr")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Configure for App Groups (for sharing data between iOS and watchOS)
            if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.yourcompany.swinganalyzer") {
                let storeURL = url.appendingPathComponent("SwingAnalyzer.sqlite")
                container.persistentStoreDescriptions.first?.url = storeURL
            }
        }
        
        // Configure persistent store
        container.persistentStoreDescriptions.first?.setOption(true as NSNumber, 
                                                              forKey: NSPersistentHistoryTrackingKey)
        container.persistentStoreDescriptions.first?.setOption(true as NSNumber, 
                                                              forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        // Load persistent stores
        container.loadPersistentStores { description, error in
            if let error = error {
                print("❌ Core Data failed to load: \(error.localizedDescription)")
                fatalError("Core Data failed to load: \(error)")
            } else {
                print("✅ Core Data loaded successfully from: \(description.url?.lastPathComponent ?? "unknown")")
            }
        }
        
        // Configure view context
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}

// MARK: - Data Operations
extension PersistenceController {
    
    // MARK: - Save Context
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
                print("✅ Core Data context saved successfully")
            } catch {
                print("❌ Failed to save Core Data context: \(error)")
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    // MARK: - Background Context Operations
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) -> T) async -> T {
        return await withCheckedContinuation { continuation in
            container.performBackgroundTask { context in
                let result = block(context)
                
                if context.hasChanges {
                    do {
                        try context.save()
                    } catch {
                        print("❌ Failed to save background context: \(error)")
                    }
                }
                
                continuation.resume(returning: result)
            }
        }
    }
    
    // MARK: - Fetch Swing Sessions
    func fetchSwingSessions() -> [SwingSession] {
        let request: NSFetchRequest<SwingSession> = SwingSession.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SwingSession.timestamp, ascending: false)]
        
        do {
            return try container.viewContext.fetch(request)
        } catch {
            print("❌ Failed to fetch swing sessions: \(error.localizedDescription)")
            return []
        }
    }
    
    // MARK: - Fetch Recent Swings
    func fetchRecentSwings(days: Int = 7) -> [SwingSession] {
        let request: NSFetchRequest<SwingSession> = SwingSession.fetchRequest()
        
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        
        request.predicate = NSPredicate(format: "timestamp >= %@", startDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \SwingSession.timestamp, ascending: false)]
        
        do {
            return try container.viewContext.fetch(request)
        } catch {
            print("❌ Failed to fetch recent swings: \(error)")
            return []
        }
    }
    
    // MARK: - Fetch Swing Statistics
    func fetchSwingStatistics() -> SwingStatistics {
        let request: NSFetchRequest<SwingSession> = SwingSession.fetchRequest()
        
        do {
            let sessions = try container.viewContext.fetch(request)
            
            let totalSwings = sessions.count
            let excellentCount = sessions.filter { $0.rating == "Excellent" }.count
            let goodCount = sessions.filter { $0.rating == "Good" }.count
            let averageCount = sessions.filter { $0.rating == "Average" }.count
            
            let averageDistance = sessions.compactMap { $0.calculatedDistance > 0 ? $0.calculatedDistance : nil }.reduce(0, +) / Double(max(1, sessions.filter { $0.calculatedDistance > 0 }.count))
            
            let maxDistance = sessions.compactMap { $0.calculatedDistance > 0 ? $0.calculatedDistance : nil }.max() ?? 0
            
            return SwingStatistics(
                totalSwings: totalSwings,
                excellentCount: excellentCount,
                goodCount: goodCount,
                averageCount: averageCount,
                averageDistance: averageDistance,
                maxDistance: maxDistance,
                lastSwingDate: sessions.first?.timestamp
            )
        } catch {
            print("❌ Failed to fetch swing statistics: \(error)")
            return SwingStatistics()
        }
    }
    
    // MARK: - Delete Swing Session
    func deleteSwingSession(_ session: SwingSession) {
        let context = container.viewContext
        context.delete(session)
        save()
    }
    
    // MARK: - Delete All Data
    func deleteAllData() {
        let entities = ["SwingSession", "SensorReading", "SwingAnalysis", "ImprovementSuggestion"]
        
        for entityName in entities {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            
            do {
                try container.viewContext.execute(deleteRequest)
                print("✅ Deleted all \(entityName) entities")
            } catch {
                print("❌ Failed to delete \(entityName): \(error)")
            }
        }
        
        save()
    }
}

// MARK: - Sample Data Creation
extension PersistenceController {
    
    static func createSampleData(in context: NSManagedObjectContext) {
        // Create sample swing session
        let sampleSwing = SwingSession(context: context)
        sampleSwing.id = UUID()
        sampleSwing.timestamp = Date().addingTimeInterval(-3600) // 1 hour ago
        sampleSwing.golfClub = "Driver"
        sampleSwing.watchHand = "Left"
        sampleSwing.rating = "Good"
        sampleSwing.calculatedDistance = 245.5
        sampleSwing.swingDuration = 2.3
        sampleSwing.deviceType = "AppleWatch"
        
        // Create sample analysis
        let sampleAnalysis = SwingAnalysis(context: context)
        sampleAnalysis.id = UUID()
        sampleAnalysis.timestamp = sampleSwing.timestamp
        sampleAnalysis.mlRating = "Good"
        sampleAnalysis.mlConfidence = 0.87
        sampleAnalysis.maxSwingSpeed = 112.5
        sampleAnalysis.averageAcceleration = 3.2
        sampleAnalysis.swingPlaneDeviation = 2.1
        sampleAnalysis.backswingTime = 0.8
        sampleAnalysis.downswingTime = 0.3
        sampleAnalysis.impactAcceleration = 8.5
        sampleAnalysis.followThroughTime = 1.2
        sampleAnalysis.improvementSuggestions = "Try to maintain a more consistent swing plane. Consider slowing down your backswing for better control."
        
        // Link analysis to swing
        sampleAnalysis.swingSession = sampleSwing
        sampleSwing.analysis = sampleAnalysis
        
        // Create a few more sample swings
        createAdditionalSampleSwings(in: context)
        
        do {
            try context.save()
            print("✅ Sample data created successfully")
        } catch {
            print("❌ Failed to create sample data: \(error)")
        }
    }
    
    private static func createAdditionalSampleSwings(in context: NSManagedObjectContext) {
        let clubs = ["Driver", "Steel 7", "Steel 9"]
        let ratings = ["Excellent", "Good", "Average"]
        let distances = [280.0, 245.0, 220.0, 160.0, 145.0, 130.0] // Driver, Steel 7, Steel 9 distances
        
        for i in 0..<5 {
            let swing = SwingSession(context: context)
            swing.id = UUID()
            swing.timestamp = Date().addingTimeInterval(-Double(i * 3600)) // Hours ago
            swing.golfClub = clubs[i % clubs.count]
            swing.watchHand = "Left"
            swing.rating = ratings[i % ratings.count]
            swing.calculatedDistance = distances[i % distances.count] + Double.random(in: -20...20)
            swing.swingDuration = Double.random(in: 1.5...3.0)
            swing.deviceType = "AppleWatch"
        }
    }
}

// MARK: - Swing Statistics Model
struct SwingStatistics {
    let totalSwings: Int
    let excellentCount: Int
    let goodCount: Int
    let averageCount: Int
    let averageDistance: Double
    let maxDistance: Double
    let lastSwingDate: Date?
    
    init(totalSwings: Int = 0, excellentCount: Int = 0, goodCount: Int = 0, averageCount: Int = 0, averageDistance: Double = 0.0, maxDistance: Double = 0.0, lastSwingDate: Date? = nil) {
        self.totalSwings = totalSwings
        self.excellentCount = excellentCount
        self.goodCount = goodCount
        self.averageCount = averageCount
        self.averageDistance = averageDistance
        self.maxDistance = maxDistance
        self.lastSwingDate = lastSwingDate
    }
    
    var successRate: Double {
        guard totalSwings > 0 else { return 0.0 }
        return Double(excellentCount + goodCount) / Double(totalSwings) * 100.0
    }
}

// MARK: - Core Data Extensions
extension SwingSession {
    static var example: SwingSession {
        let session = SwingSession()
        session.id = UUID()
        session.timestamp = Date()
        session.golfClub = "Driver"
        session.watchHand = "Left"
        session.rating = "Good"
        session.calculatedDistance = 245.5
        session.swingDuration = 2.3
        session.deviceType = "AppleWatch"
        return session
    }
}

extension SwingAnalysis {
    static var example: SwingAnalysis {
        let analysis = SwingAnalysis()
        analysis.id = UUID()
        analysis.timestamp = Date()
        analysis.mlRating = "Good"
        analysis.mlConfidence = 0.87
        analysis.maxSwingSpeed = 112.5
        analysis.averageAcceleration = 3.2
        analysis.improvementSuggestions = "Great swing! Try to maintain consistent tempo."
        return analysis
    }
}

