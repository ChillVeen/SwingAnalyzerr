//
//  ContentView.swift
//  SwingAnalyzerr Watch App
//
//  Main navigation with settings access
//

import SwiftUI

struct ContentView: View {
    @StateObject private var coordinator = SwingCoordinator()
    @State private var selectedTab = 0
    @State private var showingSettings = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Main Swing Recording View
            SwingRecordingView()
                .tag(0)
            
            // Recent Swings View
            RecentSwingsView()
                .tag(1)
            
            // Settings View (NEW)
            SettingsView(coordinator: coordinator)
                .tag(2)
        }
        .tabViewStyle(.page)
    }
}

struct RecentSwingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SwingSession.timestamp, ascending: false)]
    ) private var recentSwings: FetchedResults<SwingSession>
    
    // Add this property:
    @EnvironmentObject var unitsManager: UnitsManager
    
    @StateObject private var coordinator = SwingCoordinator()
    @State private var swingToDelete: SwingSession?
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationStack {
            Group {
                if recentSwings.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(Array(recentSwings.prefix(10)), id: \.id) { swing in
                            swingRow(swing)
                                .listRowBackground(Color.clear)
                                .contextMenu {
                                    Button("Delete", role: .destructive) {
                                        swingToDelete = swing
                                        showingDeleteAlert = true
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(.black)
            .navigationTitle("Recent")
            .navigationBarTitleDisplayMode(.inline)
        }
        .alert("Delete Swing", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let swing = swingToDelete {
                    Task {
                        await coordinator.deleteSwing(swing)
                    }
                }
            }
        } message: {
            Text("This will permanently delete this swing from all devices.")
        }
    }
    
    // Update the swing row:
    private func swingRow(_ swing: SwingSession) -> some View {
        HStack(spacing: 12) {
            // Club icon
            Image(systemName: clubIcon(swing.golfClub ?? ""))
                .font(.system(size: 16))
                .foregroundColor(.green)
                .frame(width: 24, height: 24)
            
            // Swing info
            VStack(alignment: .leading, spacing: 4) {
                Text(swing.golfClub ?? "Unknown")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                if let timestamp = swing.timestamp {
                    Text(timestamp, style: .relative)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Distance and rating with proper units
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Text("\(unitsManager.formatDistanceValue(swing.calculatedDistance))")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(unitsManager.currentUnits.distanceUnit)
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
                
                if let rating = swing.rating {
                    ratingBadge(rating)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // ... rest of existing methods remain the same

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "figure.golf")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("No Swings Yet")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Start recording to see your swings here")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(20)
    }
    
    
    private func ratingBadge(_ rating: String) -> some View {
        Text(rating)
            .font(.system(size: 8, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(ratingColor(rating))
            )
    }
    
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
        default: return .gray
        }
    }
}


// MARK: - Preview
#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}


