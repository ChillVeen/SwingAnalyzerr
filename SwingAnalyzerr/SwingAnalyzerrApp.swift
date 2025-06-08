//
//  SwingAnalyzerrApp.swift
//  SwingAnalyzerr
//
//  Main entry point for the iOS app
//

//import SwiftUI
//
//@main
//struct SwingAnalyzerrrApp: App {
//    let persistenceController = PersistenceController.shared
//    
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//                .environment(\.managedObjectContext, persistenceController.container.viewContext)
//        }
//    }
//}

import SwiftUI
@main
struct SwingAnalyzerrApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var unitsManager = UnitsManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(unitsManager)
        }
    }
}

