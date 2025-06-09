//
//  SwingResultsView.swift
//  SwingAnalyzerr Watch App
//
//  Minimal, elegant swing results optimized for Apple Watch
//

import SwiftUI
import WatchKit

struct SwingResultsView: View {
    let results: SwingResults
    let coordinator: SwingCoordinator
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hero Result - The only thing that matters
                heroSection
                
                // Essential Metrics - Minimal data
                essentialMetrics
                
                // Simple action
                actionButton
            }
            .padding(16)
        }
        .background(.black)
        .navigationBarHidden(true)
        .onAppear {
            WKInterfaceDevice.current().play(.success)
        }
    }
    
    // MARK: - Hero Section (Inspired by Default Guidelines)
    private var heroSection: some View {
        VStack(spacing: 12) {
            // Big headline with strong visual hierarchy (48px+ guideline)
            Text("\(Int(results.distanceResult.estimatedDistance))")
                .font(.system(size: 52, weight: .bold))
                .foregroundColor(.white)
            
            // Subtext clearly explaining the value (neutral gray)
            Text("YARDS")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(red: 0.42, green: 0.45, blue: 0.5)) // #6b7280 equivalent
                .tracking(1)
            
            // Rating badge - clean with subtle rounded corners (0.75rem guideline)
            Text(results.mlAnalysis.rating.uppercased())
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6) // 0.375rem for watch scale
                        .fill(ratingColor(results.mlAnalysis.rating))
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16) // Breathing room
    }
    
    // MARK: - Essential Metrics (Clean cards with minimal borders)
    private var essentialMetrics: some View {
        VStack(spacing: 8) {
            // Only the 3 most important metrics
            metricCard("Club Speed", value: "\(Int(results.distanceResult.clubHeadSpeed))", unit: "mph")
            metricCard("Launch Angle", value: "\(Int(results.distanceResult.launchAngle))", unit: "degrees")
            metricCard("Confidence", value: "\(results.mlAnalysis.confidencePercentage)", unit: "percent")
        }
    }
    
    // MARK: - Metric Card (Light shadows, clean design)
    private func metricCard(_ label: String, value: String, unit: String) -> some View {
        HStack {
            // Body text - neutral gray, readable
            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(red: 0.42, green: 0.45, blue: 0.5)) // #6b7280
            
            Spacer()
            
            // Value with bold typography
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Text(unit == "mph" ? "mph" : (unit == "degrees" ? "°" : "%"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color(red: 0.42, green: 0.45, blue: 0.5))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8) // Subtle rounded corners
                .fill(.white.opacity(0.03)) // Light, minimal background
        )
    }
    
    // MARK: - Action Button (Large, well-spaced, visually distinct)
    private var actionButton: some View {
        Button(action: {
            dismiss()
        }) {
            Text("Done")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black) // Black text
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.white) // White background (inverted from guidelines for watch)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.top, 8) // Extra spacing
    }
    
    // MARK: - Helper
    private func ratingColor(_ rating: String) -> Color {
        switch rating.lowercased() {
        case "excellent": return .green
        case "good": return .blue
        case "average": return .orange
        default: return Color(red: 0.42, green: 0.45, blue: 0.5)
        }
    }
}

// MARK: - Alternative Even More Minimal Version
struct SwingResultsViewUltraMinimal: View {
    let results: SwingResults
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Just the essential result - elegant and clear
            VStack(spacing: 16) {
                // Distance - hero typography
                Text("\(Int(results.distanceResult.estimatedDistance))")
                    .font(.system(size: 60, weight: .bold)) // Even bigger for impact
                    .foregroundColor(.white)
                
                Text("YARDS")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.gray)
                    .tracking(2)
                
                // Rating with lots of breathing room
                Text(results.mlAnalysis.rating)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(ratingColor(results.mlAnalysis.rating))
                    )
            }
            
            Spacer()
            
            // Single action - clean and minimal
            Button("Continue") {
                dismiss()
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(.white)
            )
            .buttonStyle(PlainButtonStyle())
            
            Spacer().frame(height: 20)
        }
        .padding(20)
        .background(.black)
        .navigationBarHidden(true)
        .onAppear {
            WKInterfaceDevice.current().play(.success)
        }
    }
    
    private func ratingColor(_ rating: String) -> Color {
        switch rating.lowercased() {
        case "excellent": return .green
        case "good": return .blue
        case "average": return .orange
        default: return .gray
        }
    }
}

// MARK: - Preview
#Preview("Minimal") {
    let sampleResults = SwingResults(
        mlAnalysis: SwingAnalysisResult(rating: "Excellent", confidence: 0.92, aggregatedMetrics: nil, error: nil),
        distanceResult: DistanceResult(estimatedDistance: 267, ballSpeed: 158, clubHeadSpeed: 108, launchAngle: 13, spinRate: 2580, carryDistance: 252, totalDistance: 267, confidence: 0.92, calculationMethod: .physics),
        swingMetrics: SwingMetrics(maxAcceleration: 9.2, swingSpeed: 108, attackAngle: -1.8, swingPath: 0.8, tempo: 58, impactTimestamp: Date()),
        suggestions: [],
        sensorReadings: []
    )
    
    SwingResultsView(results: sampleResults, coordinator: SwingCoordinator())
}

#Preview("Ultra Minimal") {
    let sampleResults = SwingResults(
        mlAnalysis: SwingAnalysisResult(rating: "Excellent", confidence: 0.92, aggregatedMetrics: nil, error: nil),
        distanceResult: DistanceResult(estimatedDistance: 267, ballSpeed: 158, clubHeadSpeed: 108, launchAngle: 13, spinRate: 2580, carryDistance: 252, totalDistance: 267, confidence: 0.92, calculationMethod: .physics),
        swingMetrics: SwingMetrics(maxAcceleration: 9.2, swingSpeed: 108, attackAngle: -1.8, swingPath: 0.8, tempo: 58, impactTimestamp: Date()),
        suggestions: [],
        sensorReadings: []
    )
    
    SwingResultsViewUltraMinimal(results: sampleResults)
}




// MARK: - Preview
#Preview {
    let sampleResults = SwingResults(
        mlAnalysis: SwingAnalysisResult(
            rating: "Good",
            confidence: 0.87,
            aggregatedMetrics: nil,
            error: nil
        ),
        distanceResult: DistanceResult(
            estimatedDistance: 245,
            ballSpeed: 152,
            clubHeadSpeed: 103,
            launchAngle: 12.5,
            spinRate: 2650,
            carryDistance: 230,
            totalDistance: 245,
            confidence: 0.85,
            calculationMethod: .physics
        ),
        swingMetrics: SwingMetrics(
            maxAcceleration: 8.5,
            swingSpeed: 103,
            attackAngle: -2.1,
            swingPath: 1.2,
            tempo: 55,
            impactTimestamp: Date()
        ),
        suggestions: [],
        sensorReadings: []
    )
    
    SwingResultsView(results: sampleResults, coordinator: SwingCoordinator())
}

