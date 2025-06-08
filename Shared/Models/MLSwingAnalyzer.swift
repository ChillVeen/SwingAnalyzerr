//
//  MLSwingAnalyzer.swift
//  SwingAnalyzerr
//
//  Created by Praveen Singh on 07/06/25.
//


//
//  MLSwingAnalyzer.swift
//  SwingAnalyzerr
//
//  Core ML integration for swing analysis and rating prediction
//

import CoreML
import Foundation

@MainActor
class MLSwingAnalyzer: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isAnalyzing = false
    @Published var lastAnalysisResult: SwingAnalysisResult?
    @Published var analysisError: String?
    
    // MARK: - ML Model
    private var model: MLModel?
    private let modelName = "golftrain" // Replace with your actual .mlmodel name
    
    // MARK: - Initialization
    init() {
        loadModel()
    }
    
    // MARK: - Load ML Model
    private func loadModel() {
        do {
            // Load your trained Core ML model
            // Make sure to replace "YourSwingClassifierModel" with your actual model name
            guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "mlmodelc") else {
                print("❌ Could not find \(modelName).mlmodelc in bundle")
                analysisError = "ML model not found in app bundle"
                return
            }
            
            model = try MLModel(contentsOf: modelURL)
            print("✅ ML model loaded successfully: \(modelName)")
            
        } catch {
            print("❌ Failed to load ML model: \(error.localizedDescription)")
            analysisError = "Failed to load ML model: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Analyze Swing Data
    func analyzeSwing(sensorReadings: [MotionDataPoint], golfClub: String, watchHand: String) async -> SwingAnalysisResult {
        guard let model = model else {
            let errorResult = SwingAnalysisResult(
                rating: "Unknown",
                confidence: 0.0,
                aggregatedMetrics: nil,
                error: "ML model not available"
            )
            
            await MainActor.run {
                lastAnalysisResult = errorResult
                analysisError = "ML model not available"
            }
            
            return errorResult
        }
        
        await MainActor.run {
            isAnalyzing = true
            analysisError = nil
        }
        
        do {
            // Calculate aggregated statistics from sensor readings
            let aggregatedMetrics = calculateAggregatedMetrics(from: sensorReadings)
            
            // Create ML input features
            let features = try createMLFeatures(
                aggregatedMetrics: aggregatedMetrics,
                golfClub: golfClub,
                watchHand: watchHand
            )
            
            // Make prediction
            let prediction = try await model.prediction(from: features)
            
            // Extract results
            let result = extractPredictionResults(prediction, aggregatedMetrics: aggregatedMetrics)
            
            await MainActor.run {
                lastAnalysisResult = result
                isAnalyzing = false
            }
            
            return result
            
        } catch {
            let errorResult = SwingAnalysisResult(
                rating: "Error",
                confidence: 0.0,
                aggregatedMetrics: nil,
                error: error.localizedDescription
            )
            
            await MainActor.run {
                lastAnalysisResult = errorResult
                analysisError = error.localizedDescription
                isAnalyzing = false
            }
            
            return errorResult
        }
    }
    
    // MARK: - Calculate Aggregated Metrics
    private func calculateAggregatedMetrics(from sensorReadings: [MotionDataPoint]) -> AggregatedMetrics {
        guard !sensorReadings.isEmpty else {
            return AggregatedMetrics()
        }
        
        // Extract arrays for calculations
        let accelerometerX = sensorReadings.map { $0.userAcceleration.x + $0.gravity.x }
        let accelerometerY = sensorReadings.map { $0.userAcceleration.y + $0.gravity.y }
        let accelerometerZ = sensorReadings.map { $0.userAcceleration.z + $0.gravity.z }
        
        let userAccelX = sensorReadings.map { $0.userAcceleration.x }
        let userAccelY = sensorReadings.map { $0.userAcceleration.y }
        let userAccelZ = sensorReadings.map { $0.userAcceleration.z }
        
        let gravityX = sensorReadings.map { $0.gravity.x }
        let gravityY = sensorReadings.map { $0.gravity.y }
        let gravityZ = sensorReadings.map { $0.gravity.z }
        
        let rotationX = sensorReadings.map { $0.rotationRate.x }
        let rotationY = sensorReadings.map { $0.rotationRate.y }
        let rotationZ = sensorReadings.map { $0.rotationRate.z }
        
        let attitudeRoll = sensorReadings.map { $0.attitude.roll }
        let attitudePitch = sensorReadings.map { $0.attitude.pitch }
        let attitudeYaw = sensorReadings.map { $0.attitude.yaw }
        
        return AggregatedMetrics(
            // Accelerometer aggregates
            accelerometerXMean: calculateMean(accelerometerX),
            accelerometerXMax: accelerometerX.max() ?? 0,
            accelerometerXMin: accelerometerX.min() ?? 0,
            accelerometerXStd: calculateStandardDeviation(accelerometerX),
            
            accelerometerYMean: calculateMean(accelerometerY),
            accelerometerYMax: accelerometerY.max() ?? 0,
            accelerometerYMin: accelerometerY.min() ?? 0,
            accelerometerYStd: calculateStandardDeviation(accelerometerY),
            
            accelerometerZMean: calculateMean(accelerometerZ),
            accelerometerZMax: accelerometerZ.max() ?? 0,
            accelerometerZMin: accelerometerZ.min() ?? 0,
            accelerometerZStd: calculateStandardDeviation(accelerometerZ),
            
            // User acceleration aggregates
            userAccelerationXMean: calculateMean(userAccelX),
            userAccelerationXMax: userAccelX.max() ?? 0,
            userAccelerationXMin: userAccelX.min() ?? 0,
            userAccelerationXStd: calculateStandardDeviation(userAccelX),
            
            userAccelerationYMean: calculateMean(userAccelY),
            userAccelerationYMax: userAccelY.max() ?? 0,
            userAccelerationYMin: userAccelY.min() ?? 0,
            userAccelerationYStd: calculateStandardDeviation(userAccelY),
            
            userAccelerationZMean: calculateMean(userAccelZ),
            userAccelerationZMax: userAccelZ.max() ?? 0,
            userAccelerationZMin: userAccelZ.min() ?? 0,
            userAccelerationZStd: calculateStandardDeviation(userAccelZ),
            
            // Gravity aggregates
            gravityXMean: calculateMean(gravityX),
            gravityXMax: gravityX.max() ?? 0,
            gravityXMin: gravityX.min() ?? 0,
            gravityXStd: calculateStandardDeviation(gravityX),
            
            gravityYMean: calculateMean(gravityY),
            gravityYMax: gravityY.max() ?? 0,
            gravityYMin: gravityY.min() ?? 0,
            gravityYStd: calculateStandardDeviation(gravityY),
            
            gravityZMean: calculateMean(gravityZ),
            gravityZMax: gravityZ.max() ?? 0,
            gravityZMin: gravityZ.min() ?? 0,
            gravityZStd: calculateStandardDeviation(gravityZ),
            
            // Rotation rate aggregates
            rotationRateXMean: calculateMean(rotationX),
            rotationRateXMax: rotationX.max() ?? 0,
            rotationRateXMin: rotationX.min() ?? 0,
            rotationRateXStd: calculateStandardDeviation(rotationX),
            
            rotationRateYMean: calculateMean(rotationY),
            rotationRateYMax: rotationY.max() ?? 0,
            rotationRateYMin: rotationY.min() ?? 0,
            rotationRateYStd: calculateStandardDeviation(rotationY),
            
            rotationRateZMean: calculateMean(rotationZ),
            rotationRateZMax: rotationZ.max() ?? 0,
            rotationRateZMin: rotationZ.min() ?? 0,
            rotationRateZStd: calculateStandardDeviation(rotationZ),
            
            // Attitude aggregates
            attitudeRollMean: calculateMean(attitudeRoll),
            attitudeRollMax: attitudeRoll.max() ?? 0,
            attitudeRollMin: attitudeRoll.min() ?? 0,
            attitudeRollStd: calculateStandardDeviation(attitudeRoll),
            
            attitudePitchMean: calculateMean(attitudePitch),
            attitudePitchMax: attitudePitch.max() ?? 0,
            attitudePitchMin: attitudePitch.min() ?? 0,
            attitudePitchStd: calculateStandardDeviation(attitudePitch),
            
            attitudeYawMean: calculateMean(attitudeYaw),
            attitudeYawMax: attitudeYaw.max() ?? 0,
            attitudeYawMin: attitudeYaw.min() ?? 0,
            attitudeYawStd: calculateStandardDeviation(attitudeYaw)
        )
    }
    
    // MARK: - Create ML Features
    private func createMLFeatures(aggregatedMetrics: AggregatedMetrics, golfClub: String, watchHand: String) throws -> MLFeatureProvider {
        
        // Create feature dictionary that matches your trained model's input
        let features: [String: Any] = [
            // Golf club and watch hand
            "GolfClub": golfClub,
            "WatchHand": watchHand,
            
            // Accelerometer features
            "AccelerometerXmean": aggregatedMetrics.accelerometerXMean,
            "AccelerometerXmax": aggregatedMetrics.accelerometerXMax,
            "AccelerometerXmin": aggregatedMetrics.accelerometerXMin,
            "AccelerometerX_std": aggregatedMetrics.accelerometerXStd,
            
            "AccelerometerYmean": aggregatedMetrics.accelerometerYMean,
            "AccelerometerYmax": aggregatedMetrics.accelerometerYMax,
            "AccelerometerYmin": aggregatedMetrics.accelerometerYMin,
            "AccelerometerY_std": aggregatedMetrics.accelerometerYStd,
            
            "AccelerometerZmean": aggregatedMetrics.accelerometerZMean,
            "AccelerometerZmax": aggregatedMetrics.accelerometerZMax,
            "AccelerometerZmin": aggregatedMetrics.accelerometerZMin,
            "AccelerometerZ_std": aggregatedMetrics.accelerometerZStd,
            
            // User acceleration features
            "UserAccelerationXmean": aggregatedMetrics.userAccelerationXMean,
            "UserAccelerationXmax": aggregatedMetrics.userAccelerationXMax,
            "UserAccelerationXmin": aggregatedMetrics.userAccelerationXMin,
            "UserAccelerationX_std": aggregatedMetrics.userAccelerationXStd,
            
            "UserAccelerationYmean": aggregatedMetrics.userAccelerationYMean,
            "UserAccelerationYmax": aggregatedMetrics.userAccelerationYMax,
            "UserAccelerationYmin": aggregatedMetrics.userAccelerationYMin,
            "UserAccelerationY_std": aggregatedMetrics.userAccelerationYStd,
            
            "UserAccelerationZmean": aggregatedMetrics.userAccelerationZMean,
            "UserAccelerationZmax": aggregatedMetrics.userAccelerationZMax,
            "UserAccelerationZmin": aggregatedMetrics.userAccelerationZMin,
            "UserAccelerationZ_std": aggregatedMetrics.userAccelerationZStd,
            
            // Gravity features
            "GravityXmean": aggregatedMetrics.gravityXMean,
            "GravityXmax": aggregatedMetrics.gravityXMax,
            "GravityXmin": aggregatedMetrics.gravityXMin,
            "GravityX_std": aggregatedMetrics.gravityXStd,
            
            "GravityYmean": aggregatedMetrics.gravityYMean,
            "GravityYmax": aggregatedMetrics.gravityYMax,
            "GravityYmin": aggregatedMetrics.gravityYMin,
            "GravityY_std": aggregatedMetrics.gravityYStd,
            
            "GravityZmean": aggregatedMetrics.gravityZMean,
            "GravityZmax": aggregatedMetrics.gravityZMax,
            "GravityZmin": aggregatedMetrics.gravityZMin,
            "GravityZ_std": aggregatedMetrics.gravityZStd,
            
            // Rotation rate features
            "RotationRateXmean": aggregatedMetrics.rotationRateXMean,
            "RotationRateXmax": aggregatedMetrics.rotationRateXMax,
            "RotationRateXmin": aggregatedMetrics.rotationRateXMin,
            "RotationRateX_std": aggregatedMetrics.rotationRateXStd,
            
            "RotationRateYmean": aggregatedMetrics.rotationRateYMean,
            "RotationRateYmax": aggregatedMetrics.rotationRateYMax,
            "RotationRateYmin": aggregatedMetrics.rotationRateYMin,
            "RotationRateY_std": aggregatedMetrics.rotationRateYStd,
            
            "RotationRateZmean": aggregatedMetrics.rotationRateZMean,
            "RotationRateZmax": aggregatedMetrics.rotationRateZMax,
            "RotationRateZmin": aggregatedMetrics.rotationRateZMin,
            "RotationRateZ_std": aggregatedMetrics.rotationRateZStd,
            
            // Attitude features
            "AttitudeRollmean": aggregatedMetrics.attitudeRollMean,
            "AttitudeRollmax": aggregatedMetrics.attitudeRollMax,
            "AttitudeRollmin": aggregatedMetrics.attitudeRollMin,
            "AttitudeRoll_std": aggregatedMetrics.attitudeRollStd,
            
            "AttitudePitchmean": aggregatedMetrics.attitudePitchMean,
            "AttitudePitchmax": aggregatedMetrics.attitudePitchMax,
            "AttitudePitchmin": aggregatedMetrics.attitudePitchMin,
            "AttitudePitch_std": aggregatedMetrics.attitudePitchStd,
            
            "AttitudeYawmean": aggregatedMetrics.attitudeYawMean,
            "AttitudeYawmax": aggregatedMetrics.attitudeYawMax,
            "AttitudeYawmin": aggregatedMetrics.attitudeYawMin,
            "AttitudeYaw_std": aggregatedMetrics.attitudeYawStd
        ]
        
        return try MLDictionaryFeatureProvider(dictionary: features)
    }
    
    // MARK: - Extract Prediction Results
    private func extractPredictionResults(_ prediction: MLFeatureProvider, aggregatedMetrics: AggregatedMetrics) -> SwingAnalysisResult {
        
        // Extract rating prediction (adjust based on your model's output)
        let rating: String
        let confidence: Double
        
        if let ratingValue = prediction.featureValue(for: "Rating")?.stringValue {
            rating = ratingValue
        } else if let ratingValue = prediction.featureValue(for: "target")?.stringValue {
            rating = ratingValue
        } else {
            rating = "Unknown"
        }
        
        // Extract confidence (adjust based on your model's output)
        if let confidenceDict = prediction.featureValue(for: "Rating_confidence")?.dictionaryValue {
            confidence = confidenceDict.values.compactMap { $0.doubleValue }.max() ?? 0.0
        } else if let confidenceDict = prediction.featureValue(for: "targetProbability")?.dictionaryValue {
            confidence = confidenceDict.values.compactMap { $0.doubleValue }.max() ?? 0.0
        } else {
            confidence = 0.8 // Default confidence if not available
        }
        
        return SwingAnalysisResult(
            rating: rating,
            confidence: confidence,
            aggregatedMetrics: aggregatedMetrics,
            error: nil
        )
    }
    
    // MARK: - Statistical Calculations
    private func calculateMean(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0.0 }
        return values.reduce(0, +) / Double(values.count)
    }
    
    private func calculateStandardDeviation(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0.0 }
        
        let mean = calculateMean(values)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count - 1)
        return sqrt(variance)
    }
}

// MARK: - Data Models

struct SwingAnalysisResult {
    let rating: String
    let confidence: Double
    let aggregatedMetrics: AggregatedMetrics?
    let error: String?
    
    var isValid: Bool {
        return error == nil && !rating.isEmpty && rating != "Unknown"
    }
    
    var confidencePercentage: Int {
        return Int(confidence * 100)
    }
}

struct AggregatedMetrics {
    // Accelerometer
    let accelerometerXMean: Double
    let accelerometerXMax: Double
    let accelerometerXMin: Double
    let accelerometerXStd: Double
    let accelerometerYMean: Double
    let accelerometerYMax: Double
    let accelerometerYMin: Double
    let accelerometerYStd: Double
    let accelerometerZMean: Double
    let accelerometerZMax: Double
    let accelerometerZMin: Double
    let accelerometerZStd: Double
    
    // User Acceleration
    let userAccelerationXMean: Double
    let userAccelerationXMax: Double
    let userAccelerationXMin: Double
    let userAccelerationXStd: Double
    let userAccelerationYMean: Double
    let userAccelerationYMax: Double
    let userAccelerationYMin: Double
    let userAccelerationYStd: Double
    let userAccelerationZMean: Double
    let userAccelerationZMax: Double
    let userAccelerationZMin: Double
    let userAccelerationZStd: Double
    
    // Gravity
    let gravityXMean: Double
    let gravityXMax: Double
    let gravityXMin: Double
    let gravityXStd: Double
    let gravityYMean: Double
    let gravityYMax: Double
    let gravityYMin: Double
    let gravityYStd: Double
    let gravityZMean: Double
    let gravityZMax: Double
    let gravityZMin: Double
    let gravityZStd: Double
    
    // Rotation Rate
    let rotationRateXMean: Double
    let rotationRateXMax: Double
    let rotationRateXMin: Double
    let rotationRateXStd: Double
    let rotationRateYMean: Double
    let rotationRateYMax: Double
    let rotationRateYMin: Double
    let rotationRateYStd: Double
    let rotationRateZMean: Double
    let rotationRateZMax: Double
    let rotationRateZMin: Double
    let rotationRateZStd: Double
    
    // Attitude
    let attitudeRollMean: Double
    let attitudeRollMax: Double
    let attitudeRollMin: Double
    let attitudeRollStd: Double
    let attitudePitchMean: Double
    let attitudePitchMax: Double
    let attitudePitchMin: Double
    let attitudePitchStd: Double
    let attitudeYawMean: Double
    let attitudeYawMax: Double
    let attitudeYawMin: Double
    let attitudeYawStd: Double
    
    init(accelerometerXMean: Double = 0, accelerometerXMax: Double = 0, accelerometerXMin: Double = 0, accelerometerXStd: Double = 0, accelerometerYMean: Double = 0, accelerometerYMax: Double = 0, accelerometerYMin: Double = 0, accelerometerYStd: Double = 0, accelerometerZMean: Double = 0, accelerometerZMax: Double = 0, accelerometerZMin: Double = 0, accelerometerZStd: Double = 0, userAccelerationXMean: Double = 0, userAccelerationXMax: Double = 0, userAccelerationXMin: Double = 0, userAccelerationXStd: Double = 0, userAccelerationYMean: Double = 0, userAccelerationYMax: Double = 0, userAccelerationYMin: Double = 0, userAccelerationYStd: Double = 0, userAccelerationZMean: Double = 0, userAccelerationZMax: Double = 0, userAccelerationZMin: Double = 0, userAccelerationZStd: Double = 0, gravityXMean: Double = 0, gravityXMax: Double = 0, gravityXMin: Double = 0, gravityXStd: Double = 0, gravityYMean: Double = 0, gravityYMax: Double = 0, gravityYMin: Double = 0, gravityYStd: Double = 0, gravityZMean: Double = 0, gravityZMax: Double = 0, gravityZMin: Double = 0, gravityZStd: Double = 0, rotationRateXMean: Double = 0, rotationRateXMax: Double = 0, rotationRateXMin: Double = 0, rotationRateXStd: Double = 0, rotationRateYMean: Double = 0, rotationRateYMax: Double = 0, rotationRateYMin: Double = 0, rotationRateYStd: Double = 0, rotationRateZMean: Double = 0, rotationRateZMax: Double = 0, rotationRateZMin: Double = 0, rotationRateZStd: Double = 0, attitudeRollMean: Double = 0, attitudeRollMax: Double = 0, attitudeRollMin: Double = 0, attitudeRollStd: Double = 0, attitudePitchMean: Double = 0, attitudePitchMax: Double = 0, attitudePitchMin: Double = 0, attitudePitchStd: Double = 0, attitudeYawMean: Double = 0, attitudeYawMax: Double = 0, attitudeYawMin: Double = 0, attitudeYawStd: Double = 0) {
        self.accelerometerXMean = accelerometerXMean
        self.accelerometerXMax = accelerometerXMax
        self.accelerometerXMin = accelerometerXMin
        self.accelerometerXStd = accelerometerXStd
        self.accelerometerYMean = accelerometerYMean
        self.accelerometerYMax = accelerometerYMax
        self.accelerometerYMin = accelerometerYMin
        self.accelerometerYStd = accelerometerYStd
        self.accelerometerZMean = accelerometerZMean
        self.accelerometerZMax = accelerometerZMax
        self.accelerometerZMin = accelerometerZMin
        self.accelerometerZStd = accelerometerZStd
        self.userAccelerationXMean = userAccelerationXMean
        self.userAccelerationXMax = userAccelerationXMax
        self.userAccelerationXMin = userAccelerationXMin
        self.userAccelerationXStd = userAccelerationXStd
        self.userAccelerationYMean = userAccelerationYMean
        self.userAccelerationYMax = userAccelerationYMax
        self.userAccelerationYMin = userAccelerationYMin
        self.userAccelerationYStd = userAccelerationYStd
        self.userAccelerationZMean = userAccelerationZMean
        self.userAccelerationZMax = userAccelerationZMax
        self.userAccelerationZMin = userAccelerationZMin
        self.userAccelerationZStd = userAccelerationZStd
        self.gravityXMean = gravityXMean
        self.gravityXMax = gravityXMax
        self.gravityXMin = gravityXMin
        self.gravityXStd = gravityXStd
        self.gravityYMean = gravityYMean
        self.gravityYMax = gravityYMax
        self.gravityYMin = gravityYMin
        self.gravityYStd = gravityYStd
        self.gravityZMean = gravityZMean
        self.gravityZMax = gravityZMax
        self.gravityZMin = gravityZMin
        self.gravityZStd = gravityZStd
        self.rotationRateXMean = rotationRateXMean
        self.rotationRateXMax = rotationRateXMax
        self.rotationRateXMin = rotationRateXMin
        self.rotationRateXStd = rotationRateXStd
        self.rotationRateYMean = rotationRateYMean
        self.rotationRateYMax = rotationRateYMax
        self.rotationRateYMin = rotationRateYMin
        self.rotationRateYStd = rotationRateYStd
        self.rotationRateZMean = rotationRateZMean
        self.rotationRateZMax = rotationRateZMax
        self.rotationRateZMin = rotationRateZMin
        self.rotationRateZStd = rotationRateZStd
        self.attitudeRollMean = attitudeRollMean
        self.attitudeRollMax = attitudeRollMax
        self.attitudeRollMin = attitudeRollMin
        self.attitudeRollStd = attitudeRollStd
        self.attitudePitchMean = attitudePitchMean
        self.attitudePitchMax = attitudePitchMax
        self.attitudePitchMin = attitudePitchMin
        self.attitudePitchStd = attitudePitchStd
        self.attitudeYawMean = attitudeYawMean
        self.attitudeYawMax = attitudeYawMax
        self.attitudeYawMin = attitudeYawMin
        self.attitudeYawStd = attitudeYawStd
    }
}
