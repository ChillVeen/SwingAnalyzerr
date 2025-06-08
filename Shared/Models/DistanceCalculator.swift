//
//  DistanceCalculator.swift
//  SwingAnalyzerr
//
//  Created by Praveen Singh on 07/06/25.
//


//
//  DistanceCalculator.swift
//  SwingAnalyzerr
//
//  Physics-based distance calculation for golf swings
//

import Foundation
import CoreMotion

class DistanceCalculator {
    
    // MARK: - Golf Club Specifications
    enum GolfClub: String, CaseIterable {
        case driver = "Driver"
        case steel7 = "Steel 7"
        case steel9 = "Steel 9"
        
        var loftAngle: Double {
            switch self {
            case .driver: return 10.5 // degrees
            case .steel7: return 34.0 // degrees
            case .steel9: return 42.0 // degrees
            }
        }
        
        var clubLength: Double {
            switch self {
            case .driver: return 1.168 // meters (46 inches)
            case .steel7: return 0.952 // meters (37.5 inches)
            case .steel9: return 0.914 // meters (36 inches)
            }
        }
        
        var clubWeight: Double {
            switch self {
            case .driver: return 0.31 // kg
            case .steel7: return 0.41 // kg
            case .steel9: return 0.43 // kg
            }
        }
        
        var sweetSpotCOR: Double { // Coefficient of Restitution
            switch self {
            case .driver: return 0.83
            case .steel7: return 0.78
            case .steel9: return 0.75
            }
        }
        
        var averageDistance: Double {
            switch self {
            case .driver: return 240.0 // yards
            case .steel7: return 150.0 // yards
            case .steel9: return 130.0 // yards
            }
        }
    }
    
    // MARK: - Physical Constants
    private struct PhysicsConstants {
        static let ballMass: Double = 0.0459 // kg (golf ball mass)
        static let ballDiameter: Double = 0.04267 // meters
        static let airDensity: Double = 1.225 // kg/m³ at sea level
        static let gravity: Double = 9.81 // m/s²
        static let dragCoefficient: Double = 0.25
        static let magnusCoefficient: Double = 0.15
        static let ballArea: Double = 0.00143 // m² (cross-sectional area)
    }
    
    // MARK: - Distance Calculation
    static func calculateDistance(
        from sensorReadings: [MotionDataPoint],
        golfClub: GolfClub,
        swingAnalysis: SwingAnalysisResult
    ) -> DistanceResult {
        
        // Validate input data
        guard !sensorReadings.isEmpty,
              sensorReadings.count >= 50,
              swingAnalysis.confidence > 0.3 else {
            print("❌ Invalid data for distance calculation")
            return DistanceResult(
                estimatedDistance: 0,
                ballSpeed: 0,
                clubHeadSpeed: 0,
                launchAngle: 0,
                spinRate: 0,
                carryDistance: 0,
                totalDistance: 0,
                confidence: 0,
                calculationMethod: .physics
            )
        }
        
        // Calculate swing metrics
        let swingMetrics = calculateSwingMetrics(from: sensorReadings)
        
        // Estimate club head speed from sensor data
        let clubHeadSpeed = estimateClubHeadSpeed(
            metrics: swingMetrics,
            club: golfClub
        )
        
        // Calculate ball speed using smash factor
        let smashFactor = calculateSmashFactor(
            clubHeadSpeed: clubHeadSpeed,
            club: golfClub,
            impactQuality: getImpactQuality(from: swingAnalysis)
        )
        
        let ballSpeed = clubHeadSpeed * smashFactor
        
        // Estimate launch conditions
        let launchAngle = estimateLaunchAngle(
            club: golfClub,
            attackAngle: swingMetrics.attackAngle,
            dynamicLoft: golfClub.loftAngle
        )
        
        let spinRate = estimateSpinRate(
            ballSpeed: ballSpeed,
            club: golfClub,
            launchAngle: launchAngle
        )
        
        // Calculate trajectory and distance
        let trajectory = calculateTrajectory(
            ballSpeed: ballSpeed,
            launchAngle: launchAngle,
            spinRate: spinRate
        )
        
        // Determine confidence based on data quality
        let confidence = calculateConfidence(
            sensorReadings: sensorReadings,
            swingMetrics: swingMetrics,
            analysisResult: swingAnalysis
        )
        
        return DistanceResult(
            estimatedDistance: trajectory.totalDistance,
            ballSpeed: ballSpeed,
            clubHeadSpeed: clubHeadSpeed,
            launchAngle: launchAngle,
            spinRate: spinRate,
            carryDistance: trajectory.carryDistance,
            totalDistance: trajectory.totalDistance,
            confidence: confidence,
            calculationMethod: .physics
        )
    }
    
    // MARK: - Swing Metrics Calculation
    private static func calculateSwingMetrics(from readings: [MotionDataPoint]) -> SwingMetrics {
        
        // Find impact point (maximum acceleration)
        let accelerations = readings.map { $0.totalAcceleration }
        let maxAccelIndex = accelerations.firstIndex(of: accelerations.max() ?? 0) ?? 0
        let impactPoint = readings[maxAccelIndex]
        
        // Calculate swing speed at impact
        let swingSpeed = impactPoint.totalAcceleration
        
        // Estimate attack angle from attitude data around impact
        let impactWindow = max(0, maxAccelIndex - 5)..<min(readings.count, maxAccelIndex + 5)
        let impactReadings = Array(readings[impactWindow])
        
        let attackAngle = calculateAttackAngle(from: impactReadings)
        let swingPath = calculateSwingPath(from: impactReadings)
        let tempo = calculateTempo(from: readings)
        
        return SwingMetrics(
            maxAcceleration: accelerations.max() ?? 0,
            swingSpeed: swingSpeed,
            attackAngle: attackAngle,
            swingPath: swingPath,
            tempo: tempo,
            impactTimestamp: impactPoint.timestamp
        )
    }
    
    // MARK: - Club Head Speed Estimation
    private static func estimateClubHeadSpeed(metrics: SwingMetrics, club: GolfClub) -> Double {
        // Convert acceleration to club head speed using club length and physics
        let angularVelocity = metrics.maxAcceleration / club.clubLength
        let linearSpeed = angularVelocity * club.clubLength
        
        // Apply club-specific calibration factors based on real-world data
        let calibrationFactor: Double
        switch club {
        case .driver: calibrationFactor = 0.85
        case .steel7: calibrationFactor = 0.75
        case .steel9: calibrationFactor = 0.70
        }
        
        let estimatedSpeed = linearSpeed * calibrationFactor
        
        // Apply bounds checking
        let minSpeed = club.averageDistance * 0.4 / 2.5 // Rough conversion factor
        let maxSpeed = club.averageDistance * 1.6 / 2.5
        
        return max(minSpeed, min(maxSpeed, estimatedSpeed))
    }
    
    // MARK: - Smash Factor Calculation
    private static func calculateSmashFactor(clubHeadSpeed: Double, club: GolfClub, impactQuality: Double) -> Double {
        let optimalSmashFactor: Double
        switch club {
        case .driver: optimalSmashFactor = 1.48
        case .steel7: optimalSmashFactor = 1.35
        case .steel9: optimalSmashFactor = 1.28
        }
        
        // Adjust based on impact quality (0.0 - 1.0)
        let qualityAdjustment = 0.15 * (impactQuality - 0.5)
        return optimalSmashFactor + qualityAdjustment
    }
    
    // MARK: - Launch Angle Estimation
    private static func estimateLaunchAngle(club: GolfClub, attackAngle: Double, dynamicLoft: Double) -> Double {
        // Launch angle approximation based on club loft and attack angle
        let baseLaunchAngle = dynamicLoft + (attackAngle * 0.7)
        
        // Apply realistic bounds
        let minAngle: Double
        let maxAngle: Double
        
        switch club {
        case .driver:
            minAngle = 8.0
            maxAngle = 18.0
        case .steel7:
            minAngle = 20.0
            maxAngle = 35.0
        case .steel9:
            minAngle = 28.0
            maxAngle = 45.0
        }
        
        return max(minAngle, min(maxAngle, baseLaunchAngle))
    }
    
    // MARK: - Spin Rate Estimation
    private static func estimateSpinRate(ballSpeed: Double, club: GolfClub, launchAngle: Double) -> Double {
        let baseSpinRate: Double
        switch club {
        case .driver: baseSpinRate = 2500 // RPM
        case .steel7: baseSpinRate = 6000 // RPM
        case .steel9: baseSpinRate = 8000 // RPM
        }
        
        // Adjust spin based on ball speed and launch angle
        let speedFactor = ballSpeed / 100.0 // Normalize around 100 mph
        let angleFactor = launchAngle / 15.0 // Normalize around 15 degrees
        
        return baseSpinRate * speedFactor * (1 + angleFactor * 0.1)
    }
    
    // MARK: - Trajectory Calculation
    private static func calculateTrajectory(ballSpeed: Double, launchAngle: Double, spinRate: Double) -> TrajectoryResult {
        let launchAngleRad = launchAngle * Double.pi / 180.0
        let ballSpeedMS = ballSpeed * 0.44704 // mph to m/s
        
        // Initial velocity components
        let vx0 = ballSpeedMS * cos(launchAngleRad)
        let vy0 = ballSpeedMS * sin(launchAngleRad)
        
        // Simplified trajectory calculation considering drag and magnus effects
        let dragFactor = 0.85 // Simplified drag effect
        let magnusFactor = 1.05 // Simplified magnus effect
        
        // Flight time calculation
        let flightTime = 2 * vy0 / PhysicsConstants.gravity * magnusFactor
        
        // Carry distance
        let carryDistance = vx0 * flightTime * dragFactor
        
        // Roll distance estimation
        let rollFactor: Double = 0.15 // 15% additional roll
        let rollDistance = carryDistance * rollFactor
        
        let totalDistance = carryDistance + rollDistance
        
        // Convert back to yards
        let carryYards = carryDistance * 1.09361
        let totalYards = totalDistance * 1.09361
        
        return TrajectoryResult(
            carryDistance: carryYards,
            totalDistance: totalYards,
            flightTime: flightTime,
            maxHeight: (vy0 * vy0) / (2 * PhysicsConstants.gravity) * 1.09361
        )
    }
    
    // MARK: - Helper Methods
    private static func calculateAttackAngle(from readings: [MotionDataPoint]) -> Double {
        guard readings.count > 2 else { return 0.0 }
        
        let pitchAngles = readings.map { $0.attitude.pitch * 180 / Double.pi }
        let averagePitch = pitchAngles.reduce(0, +) / Double(pitchAngles.count)
        
        return averagePitch
    }
    
    private static func calculateSwingPath(from readings: [MotionDataPoint]) -> Double {
        guard readings.count > 2 else { return 0.0 }
        
        let yawAngles = readings.map { $0.attitude.yaw * 180 / Double.pi }
        let averageYaw = yawAngles.reduce(0, +) / Double(yawAngles.count)
        
        return averageYaw
    }
    
    private static func calculateTempo(from readings: [MotionDataPoint]) -> Double {
        guard readings.count > 2 else { return 0.0 }
        
        let totalTime = readings.last!.timeOffset - readings.first!.timeOffset
        return totalTime > 0 ? 60.0 / totalTime : 0.0 // BPM equivalent
    }
    
    private static func getImpactQuality(from analysis: SwingAnalysisResult?) -> Double {
        guard let analysis = analysis else { return 0.7 }
        
        switch analysis.rating.lowercased() {
        case "excellent": return 0.95
        case "good": return 0.85
        case "average": return 0.70
        default: return 0.60
        }
    }
    
    private static func calculateConfidence(
        sensorReadings: [MotionDataPoint],
        swingMetrics: SwingMetrics,
        analysisResult: SwingAnalysisResult?
    ) -> Double {
        var confidence = 0.5 // Base confidence
        
        // Data quality factors
        if sensorReadings.count > 50 { confidence += 0.2 }
        if swingMetrics.maxAcceleration > 2.0 { confidence += 0.1 }
        if let analysis = analysisResult, analysis.confidence > 0.8 { confidence += 0.2 }
        
        return min(1.0, confidence)
    }
}

// MARK: - Supporting Data Structures

struct SwingMetrics {
    let maxAcceleration: Double
    let swingSpeed: Double
    let attackAngle: Double
    let swingPath: Double
    let tempo: Double
    let impactTimestamp: Date
}

struct TrajectoryResult {
    let carryDistance: Double // yards
    let totalDistance: Double // yards
    let flightTime: Double // seconds
    let maxHeight: Double // yards
}

struct DistanceResult {
    let estimatedDistance: Double // yards
    let ballSpeed: Double // mph
    let clubHeadSpeed: Double // mph
    let launchAngle: Double // degrees
    let spinRate: Double // RPM
    let carryDistance: Double // yards
    let totalDistance: Double // yards
    let confidence: Double // 0.0 - 1.0
    let calculationMethod: CalculationMethod
    
    enum CalculationMethod {
        case physics
        case statistical
        case hybrid
        case error(String)
    }
    
    var distanceRange: ClosedRange<Double> {
        let margin = estimatedDistance * (1.0 - confidence) * 0.2
        return (estimatedDistance - margin)...(estimatedDistance + margin)
    }
    
    var formattedDistance: String {
        return String(format: "%.0f yards", estimatedDistance)
    }
    
    var confidencePercentage: Int {
        return Int(confidence * 100)
    }
}

// MARK: - Extensions
extension DistanceCalculator.GolfClub {
    var displayName: String {
        return rawValue
    }
    
    var emoji: String {
        switch self {
        case .driver: return "🏌️"
        case .steel7: return "⛳"
        case .steel9: return "🎯"
        }
    }
    
    static var allCasesForUI: [DistanceCalculator.GolfClub] {
        return allCases
    }
}
