//
//  SwingRecordingView.swift
//  SwingAnalyzerr Watch App
//
//  Optimized main swing recording interface for Apple Watch
//

import SwiftUI
import WatchKit

struct SwingRecordingView: View {
    @StateObject private var coordinator = SwingCoordinator()
    @State private var showingClubSelection = false
    @State private var showingResults = false
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 12) {
                    // Status indicator at top
                    statusIndicator
                        .padding(.top, 8)
                    
                    // Main content based on state
                    mainContent
                        .frame(minHeight: geometry.size.height * 0.6)
                    
                    // Action button
                    actionButton
                        .padding(.bottom, 8)
                }
                .padding(.horizontal, 16)
            }
            .background(Color.black) // Apple Watch standard dark background
            .ignoresSafeArea(edges: .bottom)
        }
        .navigationBarHidden(true)
        .onAppear {
            coordinator.reset()
        }
        .sheet(isPresented: $showingResults) {
            if let results = coordinator.latestResults {
                SwingResultsView(results: results, coordinator: coordinator)
            }
        }
        .sheet(isPresented: $showingClubSelection) {
            ClubSelectionView(coordinator: coordinator)
        }
        .onChange(of: coordinator.currentState) { _, newState in
            handleStateChange(newState)
        }
    }
    
    // MARK: - Status Indicator
    private var statusIndicator: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            
            Text(coordinator.currentState.displayText)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        VStack(spacing: 16) {
            // Progress Circle - Central focus
            progressCircle
            
            // Selected club info
            clubInfoCard
            
            // Quick results (if available)
            if let results = coordinator.latestResults {
                quickResults(results)
            }
        }
    }
    
    // MARK: - Progress Circle
    private var progressCircle: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                .frame(width: 100, height: 100)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: coordinator.progressPercentage)
                .stroke(
                    Color.green,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 100, height: 100)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: coordinator.progressPercentage)
            
            // Center icon/content
            VStack(spacing: 4) {
                Image(systemName: stateIcon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.green)
                
                if coordinator.isAnalyzing {
                    Text("Analyzing...")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white)
                } else {
                    Text("\(Int(coordinator.progressPercentage * 100))%")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    // MARK: - Club Info Card
    private var clubInfoCard: some View {
        Button(action: {
            showingClubSelection = true
        }) {
            HStack(spacing: 8) {
                Image(systemName: "golf.club")
                    .font(.system(size: 16))
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(coordinator.selectedClub.displayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(coordinator.selectedHand.displayName)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.15))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Quick Results
    private func quickResults(_ results: SwingResults) -> some View {
        Button(action: {
            showingResults = true
        }) {
            VStack(spacing: 6) {
                HStack {
                    ratingBadge(results.mlAnalysis.rating)
                    
                    Spacer()
                    
                    Text("\(Int(results.distanceResult.estimatedDistance)) yds")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }
                
                HStack {
                    Text("Tap for details")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text("\(results.mlAnalysis.confidencePercentage)%")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.green.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Action Button
    private var actionButton: some View {
        Button(action: {
            Task {
                await handleMainAction()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: actionButtonIcon)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(actionButtonText)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(actionButtonForeground)
            .frame(maxWidth: .infinity)
            .frame(height: 44) // Standard watchOS button height
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(actionButtonBackground)
            )
        }
        .disabled(!coordinator.canStartSwing && coordinator.currentState != .completed)
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Supporting Views
    private func ratingBadge(_ rating: String) -> some View {
        Text(rating)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(ratingColor(rating))
            )
    }
    
    // MARK: - Computed Properties
    private var statusColor: Color {
        switch coordinator.currentState {
        case .idle: return .gray
        case .preparing, .waitingForSwing: return .orange
        case .recording: return .red
        case .analyzing: return .blue
        case .completed: return .green
        case .error: return .red
        }
    }
    
    private var stateIcon: String {
        switch coordinator.currentState {
        case .idle: return "figure.golf"
        case .preparing: return "clock"
        case .waitingForSwing: return "hand.raised"
        case .recording: return "record.circle"
        case .analyzing: return "brain"
        case .completed: return "checkmark.circle"
        case .error: return "exclamationmark.triangle"
        }
    }
    
    private var actionButtonText: String {
        switch coordinator.currentState {
        case .idle: return "Start"
        case .preparing, .waitingForSwing, .recording, .analyzing: return "Stop"
        case .completed: return "New Swing"
        case .error: return "Retry"
        }
    }
    
    private var actionButtonIcon: String {
        switch coordinator.currentState {
        case .idle: return "play.fill"
        case .preparing, .waitingForSwing, .recording, .analyzing: return "stop.fill"
        case .completed: return "arrow.clockwise"
        case .error: return "arrow.clockwise"
        }
    }
    
    private var actionButtonBackground: Color {
        switch coordinator.currentState {
        case .idle, .completed: return .green
        case .preparing, .waitingForSwing, .recording, .analyzing: return .orange
        case .error: return .red
        }
    }
    
    private var actionButtonForeground: Color {
        return .black
    }
    
    // MARK: - Helper Methods
    private func ratingColor(_ rating: String) -> Color {
        switch rating.lowercased() {
        case "excellent": return .green
        case "good": return .blue
        case "average": return .orange
        default: return .gray
        }
    }
    
    private func handleMainAction() async {
        switch coordinator.currentState {
        case .idle:
            WKInterfaceDevice.current().play(.start)
            do {
                try await coordinator.startSwingAnalysis()
            } catch {
                print("Error starting swing analysis: \(error)")
            }
        case .completed:
            coordinator.reset()
            WKInterfaceDevice.current().play(.click)
        case .error:
            coordinator.reset()
            WKInterfaceDevice.current().play(.retry)
        default:
            coordinator.reset()
            WKInterfaceDevice.current().play(.stop)
        }
    }
    
    private func handleStateChange(_ newState: SwingCoordinator.SwingState) {
        switch newState {
        case .recording:
            WKInterfaceDevice.current().play(.start)
        case .completed:
            WKInterfaceDevice.current().play(.success)
            showingResults = true
        case .error:
            WKInterfaceDevice.current().play(.failure)
        default:
            break
        }
    }
}

// MARK: - Preview
#Preview {
    SwingRecordingView()
}

