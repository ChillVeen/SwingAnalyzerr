//
//  SettingsView.swift
//  SwingAnalyzerr Watch App
//
//  Minimal settings for Apple Watch
//

import SwiftUI
import WatchKit

struct SettingsView: View {
    @EnvironmentObject var unitsManager: UnitsManager

    @ObservedObject var coordinator: SwingCoordinator
    
    @AppStorage("hapticFeedback") private var hapticFeedback = true
    @AppStorage("autoAnalysis") private var autoAnalysis = true
    @AppStorage("units") private var units = "Imperial"
    
    @State private var showingDataManagement = false
    @State private var showingAbout = false
    
    var body: some View {
        NavigationStack {
            List {
                // Golf Settings Section
                Section {
                    handSelectionRow
                    unitsRow
                } header: {
                    Text("Golf")
                        .foregroundColor(.white)
                }
                
                // App Settings Section
                Section {
                    hapticRow
                    autoAnalysisRow
                } header: {
                    Text("App")
                        .foregroundColor(.white)
                }
                
                // Data & Info Section
                Section {
                    dataManagementRow
                    aboutRow
                } header: {
                    Text("Data")
                        .foregroundColor(.white)
                }
            }
            .listStyle(.plain)
            .background(.black)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showingDataManagement) {
            DataManagementView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }
    
    // MARK: - Setting Rows
    private var handSelectionRow: some View {
        HStack {
            Image(systemName: "hand.raised")
                .foregroundColor(.green)
                .frame(width: 20)
            
            Text("Watch Hand")
                .font(.system(size: 14))
                .foregroundColor(.white)
            
            Spacer()
            
            Picker("Hand", selection: .constant(coordinator.selectedHand)) {
                ForEach(SwingCoordinator.WatchHand.allCases, id: \.self) { hand in
                    Text(hand.displayName).tag(hand)
                }
            }
            .pickerStyle(.automatic)
            .onChange(of: coordinator.selectedHand) { _, newHand in
                coordinator.selectHand(newHand)
                WKInterfaceDevice.current().play(.click)
            }
        }
        .listRowBackground(Color.clear)
    }
    
    private var unitsRow: some View {
        HStack {
            Image(systemName: "ruler")
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text("Units")
                .font(.system(size: 14))
                .foregroundColor(.white)
            
            Spacer()
            
            Picker("Units", selection: $unitsManager.currentUnits) {
                ForEach(UnitsManager.Units.allCases, id: \.self) { unit in
                    Text(unit.rawValue).tag(unit)
                }
            }
            .pickerStyle(.automatic)
            .onChange(of: unitsManager.currentUnits) { _, newUnits in
                unitsManager.setUnits(newUnits)
                WKInterfaceDevice.current().play(.click)
            }
        }
        .listRowBackground(Color.clear)
    }
    
    private var hapticRow: some View {
        HStack {
            Image(systemName: "hand.tap")
                .foregroundColor(.orange)
                .frame(width: 20)
            
            Text("Haptic Feedback")
                .font(.system(size: 14))
                .foregroundColor(.white)
            
            Spacer()
            
            Toggle("", isOn: $hapticFeedback)
                .labelsHidden()
                .onChange(of: hapticFeedback) { _, newValue in
                    if newValue {
                        WKInterfaceDevice.current().play(.success)
                    }
                }
        }
        .listRowBackground(Color.clear)
    }
    
    private var autoAnalysisRow: some View {
        HStack {
            Image(systemName: "brain")
                .foregroundColor(.purple)
                .frame(width: 20)
            
            Text("Auto Analysis")
                .font(.system(size: 14))
                .foregroundColor(.white)
            
            Spacer()
            
            Toggle("", isOn: $autoAnalysis)
                .labelsHidden()
                .onChange(of: autoAnalysis) { _, _ in
                    WKInterfaceDevice.current().play(.click)
                }
        }
        .listRowBackground(Color.clear)
    }
    
    private var dataManagementRow: some View {
        Button(action: {
            showingDataManagement = true
        }) {
            HStack {
                Image(systemName: "externaldrive")
                    .foregroundColor(.red)
                    .frame(width: 20)
                
                Text("Data Management")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 10))
            }
        }
        .buttonStyle(PlainButtonStyle())
        .listRowBackground(Color.clear)
    }
    
    private var aboutRow: some View {
        Button(action: {
            showingAbout = true
        }) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                Text("About")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
                    .font(.system(size: 10))
            }
        }
        .buttonStyle(PlainButtonStyle())
        .listRowBackground(Color.clear)
    }
}

// MARK: - Data Management View (Minimal for Watch)
struct DataManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Total Swings: 12")
                        .foregroundColor(.white)
                    
                    Text("Storage Used: 2.4 MB")
                        .foregroundColor(.gray)
                } header: {
                    Text("Usage")
                        .foregroundColor(.white)
                }
                
                Section {
                    Button("Delete All Data") {
                        showingDeleteAlert = true
                    }
                    .foregroundColor(.red)
                } header: {
                    Text("Actions")
                        .foregroundColor(.white)
                }
            }
            .listStyle(.plain)
            .background(.black)
            .navigationTitle("Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.orange)
                }
            }
        }
        .alert("Delete All Data", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                PersistenceController.shared.deleteAllData()
                dismiss()
            }
        } message: {
            Text("This will permanently delete all swing data.")
        }
    }
}

// MARK: - About View (Minimal for Watch)
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Image(systemName: "figure.golf")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                        .padding(.top, 20)
                    
                    VStack(spacing: 8) {
                        Text("SwingAnalyzer")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Version 1.0.0")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    
                    Text("Advanced golf swing analysis using Apple Watch sensors and machine learning.")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        featureRow("Real-time analysis", icon: "brain")
                        featureRow("Distance calculation", icon: "target")
                        featureRow("Performance tracking", icon: "chart.line.uptrend.xyaxis")
                    }
                    .padding(.top, 16)
                }
                .padding(16)
            }
            .background(.black)
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.orange)
                }
            }
        }
    }
    
    private func featureRow(_ text: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .font(.system(size: 12))
                .frame(width: 16)
            
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.white)
            
            Spacer()
        }
    }
}

// MARK: - Preview
#Preview("Settings") {
    SettingsView(coordinator: SwingCoordinator())
}

#Preview("Data Management") {
    DataManagementView()
}

#Preview("About") {
    AboutView()
}

