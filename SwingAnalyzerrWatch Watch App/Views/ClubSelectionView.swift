//
//  ClubSelectionView.swift
//  SwingAnalyzerr Watch App
//
//  Native List-based club selection for Apple Watch
//

import SwiftUI
import WatchKit

struct ClubSelectionView: View {
    @ObservedObject var coordinator: SwingCoordinator
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(DistanceCalculator.GolfClub.allCasesForUI, id: \.self) { club in
                    clubRow(club)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0))
                }
            }
            .listStyle(.plain)
            .background(Color.black)
            .navigationTitle("Select Club")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.orange)
                }
            }
        }
    }
    
    private func clubRow(_ club: DistanceCalculator.GolfClub) -> some View {
        Button(action: {
            coordinator.selectClub(club)
            WKInterfaceDevice.current().play(.success)
            dismiss()
        }) {
            HStack(spacing: 12) {
                // Club emoji - prominent
                Text(club.emoji)
                    .font(.system(size: 26))
                
                // Club details
                VStack(alignment: .leading, spacing: 4) {
                    Text(club.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        Text("\(Int(club.averageDistance)) yards")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                        
                        Text("•")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                        
                        Text("\(String(format: "%.0f", club.loftAngle))°")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }
                }
                
                Spacer()
                
                // Current selection indicator
                if coordinator.selectedClub == club {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                }
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle()) // Makes entire row tappable
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    ClubSelectionView(coordinator: SwingCoordinator())
}

