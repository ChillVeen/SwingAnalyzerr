//
//  ImprovementSuggestionEngine.swift
//  SwingAnalyzerr
//
//  Created by Praveen Singh on 07/06/25.
//

//
//  ImprovementSuggestionEngine.swift
//  SwingAnalyzerr
//
//  Engine for generating improvement suggestions based on swing analysis
//

//import Foundation

//struct ImprovementSuggestion: Codable {
//    var speed: Double
//    var increase: Double
//    var decrease: Double
//    var timing: Double
//    var angle: Double
//    var consistency: Double
//    var power: Double
//    var accuracy: Double
//}

//class ImprovementSuggestionEngine {
//    func generateSuggestions(for swing: SwingSession) -> [ImprovementSuggestion] {
//        var suggestions: [ImprovementSuggestion] = []
//        
//        // Example logic for generating suggestions
//        if swing.calculatedDistance < 200 {
//            suggestions.append(ImprovementSuggestion)
//        }
//        
//        // Add more logic based on swing analysis
//        
//        return suggestions
//    }
//    
//    func analyzeSwing(_ swing: SwingSession) {
//        // Perform analysis and generate suggestions
//        let suggestions = generateSuggestions(for: swing)
//        
//        // Process suggestions
//        for suggestion in suggestions {
//            print("Suggestion: \(suggestion)")
//        }
//    }
//}


//
//  ImprovementSuggestionEngine.swift
//  SwingAnalyzerr
//
//  Intelligent swing improvement suggestion system
//

//import Foundation
//
//@MainActor
//class ImprovementSuggestionEngine: ObservableObject {
//    
//    // MARK: - Published Properties
//    @Published var latestSuggestions: [ImprovementSuggestion] = []
//    @Published var isAnalyzing = false
//    
//    // MARK: - Reference Data (Based on your CSV training data)
//    private struct BenchmarkData {
//        static let excellentSwings: [String: ClosedRange<Double>] = [
//            "maxAcceleration": 8.0...15.0,
//            "swingSpeed": 100.0...125.0,
//            "tempo": 45.0...65.0,
//            "consistency": 0.8...1.0
//        ]
//        
//        static let goodSwings: [String: ClosedRange<Double>] = [
//            "maxAcceleration": 6.0...12.0,
//            "swingSpeed": 85.0...115.0,
//            "tempo": 40.0...70.0,
//            "consistency": 0.6...0.9
//        ]
//        
//        static let optimalRanges: [DistanceCalculator.GolfClub: [String: ClosedRange<Double>]] = [
//            .driver: [
//                "ballSpeed": 140.0...170.0,
//                "launchAngle": 10.0...15.0,
//                "spinRate": 2000.0...3000.0,
//                "attackAngle": -2.0...3.0
//            ],
//            .steel7: [
//                "ballSpeed": 110.0...130.0,
//                "launchAngle": 25.0...32.0,
//                "spinRate": 5500.0...7000.0,
//                "attackAngle": -3.0...0.0
//            ],
//            .steel9: [
//                "ballSpeed": 95.0...115.0,
//                "launchAngle": 35.0...42.0,
//                "spinRate": 7500.0...9500.0,
//                "attackAngle": -4.0...0.0
//            ]
//        ]
//    }
//    
//    // MARK: - Suggestion Categories
//    enum SuggestionCategory: String, CaseIterable {
//        case speed = "Speed"
//        case timing = "Timing"
//        case angle = "Angle"
//        case consistency = "Consistency"
//        case tempo = "Tempo"
//        case power = "Power"
//        case accuracy = "Accuracy"
//        
//        var icon: String {
//            switch self {
//            case .speed: return "speedometer"
//            case .timing: return "clock"
//            case .angle: return "angle"
//            case .consistency: return "target"
//            case .tempo: return "metronome"
//            case .power: return "bolt"
//            case .accuracy: return "scope"
//            }
//        }
//        
//        var color: String {
//            switch self {
//            case .speed: return "blue"
//            case .timing: return "orange"
//            case .angle: return "green"
//            case .consistency: return "purple"
//            case .tempo: return "red"
//            case .power: return "yellow"
//            case .accuracy: return "teal"
//            }
//        }
//    }
//    
//    // MARK: - Generate Suggestions
//    func generateSuggestions(
//        swingAnalysis: SwingAnalysisResult,
//        distanceResult: DistanceResult,
//        swingMetrics: SwingMetrics,
//        golfClub: DistanceCalculator.GolfClub,
//        previousSwings: [SwingSession] = []
//    ) async -> [ImprovementSuggestion] {
//        
//        isAnalyzing = true
//        
//        var suggestions: [ImprovementSuggestion] = []
//        
//        // Analyze different aspects of the swing
//        suggestions.append(contentsOf: analyzeSwingSpeed(distanceResult, swingMetrics, golfClub))
//        suggestions.append(contentsOf: analyzeSwingTiming(swingMetrics, swingAnalysis))
//        suggestions.append(contentsOf: analyzeSwingAngle(distanceResult, golfClub))
//        suggestions.append(contentsOf: analyzeConsistency(previousSwings, swingAnalysis))
//        suggestions.append(contentsOf: analyzeTempo(swingMetrics))
//        suggestions.append(contentsOf: analyzePower(distanceResult, golfClub))
//        suggestions.append(contentsOf: analyzeAccuracy(swingAnalysis, distanceResult))
//        
//        // Sort by priority and limit to top suggestions
//        let prioritizedSuggestions = suggestions
//            .sorted { $0.priority > $1.priority }
//            .prefix(5)
//        
//        let finalSuggestions = Array(prioritizedSuggestions)
//        
//        await MainActor.run {
//            latestSuggestions = finalSuggestions
//            isAnalyzing = false
//        }
//        
//        return finalSuggestions
//    }
//    
//    // MARK: - Speed Analysis
//    private func analyzeSwingSpeed(_ distance: DistanceResult, _ metrics: SwingMetrics, _ club: DistanceCalculator.GolfClub) -> [ImprovementSuggestion] {
//        guard let optimalRange = BenchmarkData.optimalRanges[club]?["ballSpeed"] else { return [] }
//        
//        var suggestions: [ImprovementSuggestion] = []
//        
//        if distance.clubHeadSpeed < optimalRange.lowerBound {
//            suggestions.append(ImprovementSuggestion(
//                category: .speed,
//                title: "Increase Swing Speed",
//                description: "Your club head speed is below optimal range. Focus on generating more speed through your core rotation.",
//                actionableSteps: [
//                    "Practice with lighter clubs to increase swing speed",
//                    "Focus on full shoulder turn in backswing",
//                    "Use ground force by pushing off back foot in downswing",
//                    "Practice tempo drills with metronome"
//                ],
//                priority: 4,
//                currentValue: distance.clubHeadSpeed,
//                targetValue: optimalRange.lowerBound,
//                measurementUnit: "mph",
//                improvementType: .increase
//            ))
//        } else if distance.clubHeadSpeed > optimalRange.upperBound {
//            suggestions.append(ImprovementSuggestion(
//                category: .speed,
//                title: "Control Your Speed",
//                description: "You're swinging too fast, which may be affecting accuracy. Focus on controlled power.",
//                actionableSteps: [
//                    "Practice 80% speed swings for better control",
//                    "Focus on smooth tempo rather than max power",
//                    "Work on balance throughout the swing",
//                    "Practice with rhythm drills"
//                ],
//                priority: 3,
//                currentValue: distance.clubHeadSpeed,
//                targetValue: optimalRange.upperBound,
//                measurementUnit: "mph",
//                improvementType: .decrease
//            ))
//        }
//        
//        return suggestions
//    }
//    
//    // MARK: - Timing Analysis
//    private func analyzeSwingTiming(_ metrics: SwingMetrics, _ analysis: SwingAnalysisResult) -> [ImprovementSuggestion] {
//        var suggestions: [ImprovementSuggestion] = []
//        
//        let optimalTempo = BenchmarkData.excellentSwings["tempo"]!
//        
//        if !optimalTempo.contains(metrics.tempo) {
//            let isToeFast = metrics.tempo > optimalTempo.upperBound
//            
//            suggestions.append(ImprovementSuggestion(
//                category: .timing,
//                title: isToeFast ? "Slow Down Your Tempo" : "Increase Your Tempo",
//                description: isToeFast ? "Your swing tempo is too fast. Focus on smooth, controlled movements." : "Your swing tempo is too slow. Work on creating more rhythm and flow.",
//                actionableSteps: isToeFast ? [
//                    "Count '1-2' in your head during swing",
//                    "Practice with smooth, deliberate movements",
//                    "Focus on pause at top of backswing",
//                    "Use lighter clubs for tempo practice"
//                ] : [
//                    "Practice with a metronome for consistent rhythm",
//                    "Focus on smooth transition from backswing to downswing",
//                    "Work on maintaining flow throughout swing",
//                    "Practice one-piece takeaway drills"
//                ],
//                priority: 4,
//                currentValue: metrics.tempo,
//                targetValue: optimalTempo.lowerBound + (optimalTempo.upperBound - optimalTempo.lowerBound) / 2,
//                measurementUnit: "BPM",
//                improvementType: isToeFast ? .decrease : .increase
//            ))
//        }
//        
//        return suggestions
//    }
//    
//    // MARK: - Angle Analysis
//    private func analyzeSwingAngle(_ distance: DistanceResult, _ club: DistanceCalculator.GolfClub) -> [ImprovementSuggestion] {
//        guard let optimalLaunch = BenchmarkData.optimalRanges[club]?["launchAngle"] else { return [] }
//        
//        var suggestions: [ImprovementSuggestion] = []
//        
//        if distance.launchAngle < optimalLaunch.lowerBound {
//            suggestions.append(ImprovementSuggestion(
//                category: .angle,
//                title: "Increase Launch Angle",
//                description: "Your ball launches too low. Adjust your setup and swing to achieve better trajectory.",
//                actionableSteps: [
//                    "Position ball slightly forward in stance",
//                    "Tee the ball higher (for driver)",
//                    "Focus on hitting up on the ball",
//                    "Keep your head behind the ball at impact"
//                ],
//                priority: 3,
//                currentValue: distance.launchAngle,
//                targetValue: optimalLaunch.lowerBound,
//                measurementUnit: "degrees",
//                improvementType: .increase
//            ))
//        } else if distance.launchAngle > optimalLaunch.upperBound {
//            suggestions.append(ImprovementSuggestion(
//                category: .angle,
//                title: "Lower Launch Angle",
//                description: "Your ball launches too high, reducing distance. Adjust for optimal trajectory.",
//                actionableSteps: [
//                    "Position ball slightly back in stance",
//                    "Tee the ball lower (for driver)",
//                    "Focus on hitting down on the ball",
//                    "Maintain forward shaft lean at impact"
//                ],
//                priority: 3,
//                currentValue: distance.launchAngle,
//                targetValue: optimalLaunch.upperBound,
//                measurementUnit: "degrees",
//                improvementType: .decrease
//            ))
//        }
//        
//        return suggestions
//    }
//    
//    // MARK: - Consistency Analysis
//    private func analyzeConsistency(_ previousSwings: [SwingSession], _ currentAnalysis: SwingAnalysisResult) -> [ImprovementSuggestion] {
//        guard previousSwings.count >= 3 else { return [] }
//        
//        var suggestions: [ImprovementSuggestion] = []
//        
//        // Analyze rating consistency
//        let recentRatings = previousSwings.prefix(5).compactMap { $0.rating }
//        let excellentCount = recentRatings.filter { $0 == "Excellent" }.count
//        let goodCount = recentRatings.filter { $0 == "Good" }.count
//        let consistencyScore = Double(excellentCount + goodCount) / Double(recentRatings.count)
//        
//        if consistencyScore < 0.6 {
//            suggestions.append(ImprovementSuggestion(
//                category: .consistency,
//                title: "Improve Consistency",
//                description: "Your swing ratings vary significantly. Focus on developing a repeatable swing.",
//                actionableSteps: [
//                    "Practice the same pre-shot routine every time",
//                    "Focus on fundamentals: grip, stance, posture",
//                    "Practice shorter swings first, then build up",
//                    "Use alignment sticks during practice",
//                    "Record your swing to identify patterns"
//                ],
//                priority: 5,
//                currentValue: consistencyScore * 100,
//                targetValue: 80.0,
//                measurementUnit: "%",
//                improvementType: .increase
//            ))
//        }
//        
//        return suggestions
//    }
//    
//    // MARK: - Tempo Analysis
//    private func analyzeTempo(_ metrics: SwingMetrics) -> [ImprovementSuggestion] {
//        var suggestions: [ImprovementSuggestion] = []
//        
//        if metrics.maxAcceleration > 12.0 {
//            suggestions.append(ImprovementSuggestion(
//                category: .tempo,
//                title: "Smooth Your Transition",
//                description: "High peak acceleration suggests rushed transition. Focus on smooth tempo changes.",
//                actionableSteps: [
//                    "Practice pause drill at top of backswing",
//                    "Focus on gradual acceleration in downswing",
//                    "Practice with 'whoosh' sound drill",
//                    "Count rhythm during practice swings"
//                ],
//                priority: 3,
//                currentValue: metrics.maxAcceleration,
//                targetValue: 10.0,
//                measurementUnit: "G-force",
//                improvementType: .decrease
//            ))
//        }
//        
//        return suggestions
//    }
//    
//    // MARK: - Power Analysis
//    private func analyzePower(_ distance: DistanceResult, _ club: DistanceCalculator.GolfClub) -> [ImprovementSuggestion] {
//        var suggestions: [ImprovementSuggestion] = []
//        
//        let averageDistance = club.averageDistance
//        let distanceEfficiency = distance.estimatedDistance / averageDistance
//        
//        if distanceEfficiency < 0.85 {
//            suggestions.append(ImprovementSuggestion(
//                category: .power,
//                title: "Increase Power Transfer",
//                description: "You're not maximizing distance potential. Focus on efficient power transfer.",
//                actionableSteps: [
//                    "Work on solid contact - hit ball first, then turf",
//                    "Improve weight shift from back foot to front foot",
//                    "Practice hip rotation leading the downswing",
//                    "Focus on extending through impact",
//                    "Check equipment - ensure proper club fitting"
//                ],
//                priority: 4,
//                currentValue: distance.estimatedDistance,
//                targetValue: averageDistance,
//                measurementUnit: "yards",
//                improvementType: .increase
//            ))
//        }
//        
//        return suggestions
//    }
//    
//    // MARK: - Accuracy Analysis
//    private func analyzeAccuracy(_ analysis: SwingAnalysisResult, _ distance: DistanceResult) -> [ImprovementSuggestion] {
//        var suggestions: [ImprovementSuggestion] = []
//        
//        if analysis.confidence < 0.7 {
//            suggestions.append(ImprovementSuggestion(
//                category: .accuracy,
//                title: "Improve Swing Reliability",
//                description: "Inconsistent swing patterns detected. Focus on building a more reliable swing.",
//                actionableSteps: [
//                    "Practice with shorter clubs first",
//                    "Focus on maintaining spine angle throughout swing",
//                    "Work on consistent ball position",
//                    "Practice impact position drills",
//                    "Use training aids for swing plane consistency"
//                ],
//                priority: 4,
//                currentValue: analysis.confidence * 100,
//                targetValue: 85.0,
//                measurementUnit: "%",
//                improvementType: .increase
//            ))
//        }
//        
//        return suggestions
//    }
//}
//
//// MARK: - Improvement Suggestion Data Model
//struct ImprovementSuggestion: Identifiable, Codable {
//    let id = UUID()
//    let category: ImprovementSuggestionEngine.SuggestionCategory
//    let title: String
//    let description: String
//    let actionableSteps: [String]
//    let priority: Int // 1-5, 5 being highest priority
//    let currentValue: Double
//    let targetValue: Double
//    let measurementUnit: String
//    let improvementType: ImprovementType
//    let timestamp: Date
//    
//    enum ImprovementType: String, Codable {
//        case increase = "increase"
//        case decrease = "decrease"
//        case maintain = "maintain"
//        
//        var arrow: String {
//            switch self {
//            case .increase: return "↗️"
//            case .decrease: return "↘️"
//            case .maintain: return "→"
//            }
//        }
//    }
//    
//    init(category: ImprovementSuggestionEngine.SuggestionCategory, title: String, description: String, actionableSteps: [String], priority: Int, currentValue: Double, targetValue: Double, measurementUnit: String, improvementType: ImprovementType) {
//        self.category = category
//        self.title = title
//        self.description = description
//        self.actionableSteps = actionableSteps
//        self.priority = priority
//        self.currentValue = currentValue
//        self.targetValue = targetValue
//        self.measurementUnit = measurementUnit
//        self.improvementType = improvementType
//        self.timestamp = Date()
//    }
//    
//    var improvementGap: Double {
//        return abs(targetValue - currentValue)
//    }
//    
//    var progressDirection: String {
//        return improvementType.arrow
//    }
//    
//    var formattedCurrentValue: String {
//        return String(format: "%.1f %@", currentValue, measurementUnit)
//    }
//    
//    var formattedTargetValue: String {
//        return String(format: "%.1f %@", targetValue, measurementUnit)
//    }
//}
//
//// MARK: - Extensions
//extension Array where Element == ImprovementSuggestion {
//    var topPrioritySuggestion: ImprovementSuggestion? {
//        return self.sorted { $0.priority > $1.priority }.first
//    }
//    
//    func suggestions(for category: ImprovementSuggestionEngine.SuggestionCategory) -> [ImprovementSuggestion] {
//        return self.filter { $0.category == category }
//    }
//    
//    var categorizedSuggestions: [ImprovementSuggestionEngine.SuggestionCategory: [ImprovementSuggestion]] {
//        return Dictionary(grouping: self) { $0.category }
//    }
//}
