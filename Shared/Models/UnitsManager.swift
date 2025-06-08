//
//  UnitsManager.swift
//  SwingAnalyzerr
//
//  Units conversion and formatting manager
//

import Foundation

@MainActor
class UnitsManager: ObservableObject {
    @Published var currentUnits: Units = .imperial
    
    enum Units: String, CaseIterable {
        case imperial = "Imperial"
        case metric = "Metric"
        
        var distanceUnit: String {
            switch self {
            case .imperial: return "yards"
            case .metric: return "meters"
            }
        }
        
        var speedUnit: String {
            switch self {
            case .imperial: return "mph"
            case .metric: return "km/h"
            }
        }
    }
    
    init() {
        // Load from UserDefaults
        if let savedUnits = UserDefaults.standard.object(forKey: "units") as? String,
           let units = Units(rawValue: savedUnits) {
            self.currentUnits = units
        }
    }
    
    func setUnits(_ units: Units) {
        currentUnits = units
        UserDefaults.standard.set(units.rawValue, forKey: "units")
        print("✅ Units changed to: \(units.rawValue)")
    }
    
    // MARK: - Distance Conversions
    func formatDistance(_ yards: Double) -> String {
        switch currentUnits {
        case .imperial:
            return "\(Int(yards)) yds"
        case .metric:
            let meters = yardsToMeters(yards)
            return "\(Int(meters)) m"
        }
    }
    
    func formatDistanceValue(_ yards: Double) -> Int {
        switch currentUnits {
        case .imperial:
            return Int(yards)
        case .metric:
            return Int(yardsToMeters(yards))
        }
    }
    
    // MARK: - Speed Conversions
    func formatSpeed(_ mph: Double) -> String {
        switch currentUnits {
        case .imperial:
            return "\(Int(mph)) mph"
        case .metric:
            let kmh = mphToKmh(mph)
            return "\(Int(kmh)) km/h"
        }
    }
    
    func formatSpeedValue(_ mph: Double) -> Int {
        switch currentUnits {
        case .imperial:
            return Int(mph)
        case .metric:
            return Int(mphToKmh(mph))
        }
    }
    
    // MARK: - Conversion Helpers
    private func yardsToMeters(_ yards: Double) -> Double {
        return yards * 0.9144
    }
    
    private func mphToKmh(_ mph: Double) -> Double {
        return mph * 1.60934
    }
}
