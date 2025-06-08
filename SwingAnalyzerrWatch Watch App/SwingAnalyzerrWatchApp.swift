//
//  SwingAnalyzerrApp.swift
//  SwingAnalyzerr Watch App
//
//  Main entry point for the watchOS app
//

import SwiftUI

@main
struct SwingAnalyzerr_Watch_AppApp: App {
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

