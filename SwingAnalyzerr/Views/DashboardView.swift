//
//  DashboardView.swift
//  SwingAnalyzerr
//
//  Elegant dashboard following minimal design guidelines
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var unitsManager: UnitsManager
    @EnvironmentObject var watchConnectivity: WatchConnectivityManager
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SwingSession.timestamp, ascending: false)]
    ) private var recentSwings: FetchedResults<SwingSession>
    
    @State private var stats = SwingStatistics()
    @State private var showingAllHistory = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Hero Section
                    heroSection
                        .padding(.top, 32)
                        .padding(.bottom, 80)
                    
                    // Key Metrics
                    metricsSection
                        .padding(.bottom, 80)
                    
                    // Recent Activity
                    recentActivitySection
                        .padding(.bottom, 80)
                    
                    // Quick Actions
                    quickActionsSection
                        .padding(.bottom, 80)
                    
                    // Watch Status
                    watchStatusSection
                        .padding(.bottom, 48)
                    // NEW: Sync Status Section (Following Default Guidelines)
                    syncStatusSection
                        .padding(.bottom, 80)
                }
                .frame(maxWidth: 1200) // Centered max-width container
                .padding(.horizontal, 20)
            }
            .background(Color(hex: "#ffffff")) // Light background
            .refreshable {
                await refreshData()
            }
            .navigationBarHidden(true) // Clean minimal nav
        }
        .navigationViewStyle(.stack)
        .onAppear {
            loadStats()
        }
        .sheet(isPresented: $showingAllHistory) {
            SwingHistoryView()
        }
    }
    
    // MARK: - Hero Section
    private var heroSection: some View {
        VStack(spacing: 32) {
            // Big headline with strong visual hierarchy
            VStack(spacing: 24) {
                Text("Build Better Golf Swings")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                
                // Subtext clearly explaining value
                Text("Advanced swing analysis using Apple Watch sensors and machine learning to improve your game with precision insights.")
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "#6b7280"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 40)
            }
            
            // Large, well-spaced CTA button
            Button(action: {
                // Navigate to Apple Watch app or show instructions
            }) {
                HStack(spacing: 16) {
                    Image(systemName: "applewatch")
                        .font(.system(size: 20, weight: .semibold))
                    
                    Text("Start Recording on Apple Watch")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: 400) // Constrained width
                .padding(.vertical, 20)
                .padding(.horizontal, 32)
                .background(
                    RoundedRectangle(cornerRadius: 12) // Subtle rounded corners
                        .fill(.black) // Black with white text
                )
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(1.0)
            .animation(.easeInOut(duration: 0.2), value: true)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Metrics Section
    private var metricsSection: some View {
        VStack(spacing: 48) {
            // Section Header
            VStack(spacing: 16) {
                Text("Your Progress")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                
                Text("Track your improvement with detailed performance metrics")
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "#6b7280"))
                    .multilineTextAlignment(.center)
            }
            
            // Grid layout for features and content blocks
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 24),
                GridItem(.flexible(), spacing: 24)
            ], spacing: 24) {
                metricCard(
                    title: "Total Swings",
                    value: "\(stats.totalSwings)",
                    subtitle: "All time",
                    icon: "figure.golf"
                )
                
                metricCard(
                    title: "Best Distance",
                    value: stats.maxDistance > 0 ? "\(Int(stats.maxDistance))" : "0",
                    subtitle: "Yards",
                    icon: "target"
                )
                
                metricCard(
                    title: "Success Rate",
                    value: "\(Int(stats.successRate))",
                    subtitle: "Percentage",
                    icon: "checkmark.circle"
                )
                
                metricCard(
                    title: "This Week",
                    value: "\(getThisWeekCount())",
                    subtitle: "Swings",
                    icon: "calendar"
                )
            }
        }
    }

    // MARK: - NEW: Sync Status Section (Following Default Guidelines)
    private var syncStatusSection: some View {
        VStack(spacing: 48) {
            VStack(spacing: 16) {
                Text("Device Sync")
                    .font(.system(size: 48, weight: .bold)) // Bold typography from guidelines
                    .foregroundColor(.black)
                
                Text("Real-time synchronization with your Apple Watch")
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "#6b7280")) // Neutral gray from guidelines
                    .multilineTextAlignment(.center)
            }
            
            // Clean card with minimal borders (following guidelines)
            VStack(spacing: 24) {
                HStack(spacing: 16) {
                    Image(systemName: "applewatch")
                        .font(.system(size: 32))
                        .foregroundColor(watchConnectivity.isReachable ? .green : Color(hex: "#6b7280"))
                        .frame(width: 64, height: 64)
                        .background(
                            Circle()
                                .fill((watchConnectivity.isReachable ? Color.green : Color(hex: "#6b7280")).opacity(0.1))
                        )
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(watchConnectivity.isReachable ? "Apple Watch Connected" : "Apple Watch Disconnected")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.black)
                        
                        Text(watchConnectivity.syncStatusText)
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "#6b7280"))
                    }
                    Spacer()
                }
                
                if watchConnectivity.isReachable {
                    Button(action: {
                        Task {
                            await watchConnectivity.requestFullSync()
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 16, weight: .semibold))
                            
                            Text("Sync Now")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12) // Subtle rounded corners
                                .fill(.black) // Black with white text from guidelines
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(32) // Generous padding from guidelines
            .background(
                RoundedRectangle(cornerRadius: 12) // Subtle rounded corners
                    .fill(.white)
                    .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4) // Light shadow
            )
        }
    }
    // MARK: - Recent Activity Section
    private var recentActivitySection: some View {
        VStack(spacing: 48) {
            // Section Header
            HStack {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Recent Activity")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text("Your latest swing sessions and performance")
                        .font(.system(size: 18))
                        .foregroundColor(Color(hex: "#6b7280"))
                }
                
                Spacer()
                
                if !recentSwings.isEmpty {
                    Button("View All") {
                        showingAllHistory = true
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.05))
                    )
                }
            }
            
            // Content
            if recentSwings.isEmpty {
                emptyActivityCard
            } else {
                VStack(spacing: 16) {
                    ForEach(Array(recentSwings.prefix(3)), id: \.id) { swing in
                        recentSwingCard(swing)
                    }
                }
            }
        }
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        VStack(spacing: 48) {
            VStack(spacing: 16) {
                Text("Quick Actions")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.black)
                
                Text("Access your most used features")
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "#6b7280"))
            }
            
            VStack(spacing: 16) {
                quickActionCard(
                    title: "View Analytics",
                    subtitle: "Detailed performance insights and trends",
                    icon: "chart.line.uptrend.xyaxis",
                    action: {}
                )
                
                quickActionCard(
                    title: "Export Data",
                    subtitle: "Share your swing history and analysis",
                    icon: "square.and.arrow.up",
                    action: {}
                )
            }
        }
    }
    
    // MARK: - Watch Status Section
    private var watchStatusSection: some View {
        VStack(spacing: 48) {
            VStack(spacing: 16) {
                Text("Apple Watch")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.black)
                
                Text("Connect your Apple Watch for real-time swing analysis")
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "#6b7280"))
                    .multilineTextAlignment(.center)
            }
            
            watchConnectionCard
        }
    }
    
    // MARK: - Supporting Views (Clean cards with minimal borders)
    // Update the metricCard method:
    private func metricCard(title: String, value: String, subtitle: String, icon: String) -> some View {
        VStack(spacing: 24) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(Color(red: 0.42, green: 0.45, blue: 0.5))
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                // Handle distance values with proper units
                if title.contains("Distance") {
                    Text("\(unitsManager.formatDistanceValue(Double(value) ?? 0))")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Text(unitsManager.currentUnits.distanceUnit)
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0.42, green: 0.45, blue: 0.5))
                } else {
                    Text(value)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Text(subtitle)
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0.42, green: 0.45, blue: 0.5))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(32)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
        }
    }

    
    private var emptyActivityCard: some View {
        VStack(spacing: 32) {
            Image(systemName: "figure.golf")
                .font(.system(size: 64))
                .foregroundColor(Color(hex: "#6b7280"))
            
            VStack(spacing: 16) {
                Text("No Swings Yet")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
                
                Text("Start recording swings with your Apple Watch to see your activity here.")
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "#6b7280"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 64)
        .padding(.horizontal, 48)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
        )
    }
    
    private func recentSwingCard(_ swing: SwingSession) -> some View {
        HStack(spacing: 24) {
            Image(systemName: clubIcon(swing.golfClub ?? ""))
                .font(.system(size: 24))
                .foregroundColor(.black)
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.05))
                )
            
            VStack(alignment: .leading, spacing: 8) {
                Text(swing.golfClub ?? "Unknown Club")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.black)
                
                if let timestamp = swing.timestamp {
                    Text(timestamp, style: .relative)
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#6b7280"))
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 8) {
                Text(unitsManager.formatDistance(swing.calculatedDistance))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
                
                if let rating = swing.rating {
                    ratingBadge(rating)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
        )
    }
    
    private func quickActionCard(title: String, subtitle: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 24) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(.black)
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(Color.black.opacity(0.05))
                    )
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.black)
                    
                    Text(subtitle)
                        .font(.system(size: 16))
                        .foregroundColor(Color(hex: "#6b7280"))
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(hex: "#6b7280"))
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        // Gentle hover/active transitions
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.15), value: true)
    }
    
    private var watchConnectionCard: some View {
        HStack(spacing: 24) {
            Image(systemName: "applewatch")
                .font(.system(size: 36))
                .foregroundColor(watchConnectivity.isConnected ? .green : Color(hex: "#6b7280"))
                .frame(width: 64, height: 64)
                .background(
                    Circle()
                        .fill((watchConnectivity.isConnected ? Color.green : Color(hex: "#6b7280")).opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 8) {
                Text(watchConnectivity.isConnected ? "Connected" : "Disconnected")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.black)
                
                Text(watchConnectivity.isConnected ? "Ready to track swings" : "Check Apple Watch connection")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#6b7280"))
            }
            
            Spacer()
            
            Circle()
                .fill(watchConnectivity.isConnected ? .green : Color(hex: "#6b7280"))
                .frame(width: 16, height: 16)
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
        )
    }
    
    private func ratingBadge(_ rating: String) -> some View {
        Text(rating)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(ratingColor(rating))
            )
    }
    
    // MARK: - Helper Methods
    private func clubIcon(_ clubName: String) -> String {
        switch clubName.lowercased() {
        case "driver": return "figure.golf"
        case "steel 7": return "target"
        case "steel 9": return "scope"
        default: return "golf.club"
        }
    }
    
    private func ratingColor(_ rating: String) -> Color {
        switch rating.lowercased() {
        case "excellent": return .green
        case "good": return .blue
        case "average": return .orange
        default: return Color(hex: "#6b7280")
        }
    }
    
    private func getThisWeekCount() -> Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return recentSwings.filter { swing in
            swing.timestamp ?? Date.distantPast >= weekAgo
        }.count
    }
    
    private func loadStats() {
        stats = PersistenceController.shared.fetchSwingStatistics()
    }
    
    private func refreshData() async {
        await MainActor.run {
            loadStats()
        }
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview
#Preview {
    DashboardView()
        .environmentObject(WatchConnectivityManager())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

