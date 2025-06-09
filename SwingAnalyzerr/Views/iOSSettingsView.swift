//
//  iOSSettingsView.swift
//  SwingAnalyzerr
//
//  Elegant settings interface for iOS companion app
//

import SwiftUI

struct iOSSettingsView: View {
    
    @AppStorage("units") private var units = "Imperial"
    @AppStorage("notifications") private var notificationsEnabled = true
    @AppStorage("autoSync") private var autoSyncEnabled = true
    @AppStorage("confidenceThreshold") private var confidenceThreshold = 0.7
    @AppStorage("dataRetention") private var dataRetentionDays = 365
    @AppStorage("theme") private var selectedTheme = "System"
    
    @State private var showingDataManagement = false
    @State private var showingAbout = false
    @State private var showingExportSheet = false
    @State private var watchConnectionStatus = "Connected"
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header Section
                    headerSection
                    
                    // Watch Connection
                    watchConnectionSection
                    
                    // Preferences
                    preferencesSection
                    
                    // Analysis Settings
                    analysisSettingsSection
                    
                    // Data & Privacy
                    dataPrivacySection
                    
                    // Support & Info
                    supportSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .navigationViewStyle(.stack)
        .sheet(isPresented: $showingDataManagement) {
            DataManagementView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutAppView()
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportDataView()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // App Icon and Title
            VStack(spacing: 12) {
                Image(systemName: "figure.golf")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.green)
                    .frame(width: 80, height: 80)
                    .background(
                        Circle()
                            .fill(Color.green.opacity(0.1))
                    )
                
                VStack(spacing: 4) {
                    Text("SwingAnalyzer")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Version 1.0.0")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.03), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Watch Connection Section
    private var watchConnectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Apple Watch")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                // Connection Status
                HStack(spacing: 16) {
                    Image(systemName: "applewatch")
                        .font(.system(size: 32))
                        .foregroundColor(.green)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Apple Watch Series 9")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 8) {
                            Circle()
                                .fill(.green)
                                .frame(width: 8, height: 8)
                            
                            Text(watchConnectionStatus)
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button("Sync Now") {
                        // Trigger manual sync
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black)
                    )
                }
                
                // Auto Sync Toggle
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Auto Sync")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Text("Automatically sync data from Apple Watch")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $autoSyncEnabled)
                        .labelsHidden()
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
            )
        }
    }
    
    // MARK: - Preferences Section
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Preferences")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                // Units
                settingRow(
                    icon: "ruler",
                    iconColor: .blue,
                    title: "Units",
                    subtitle: "Distance and measurement units"
                ) {
                    Picker("Units", selection: $units) {
                        Text("Imperial").tag("Imperial")
                        Text("Metric").tag("Metric")
                    }
                    .pickerStyle(.menu)
                }
                
                Divider()
                    .padding(.horizontal, 16)
                
                // Theme
                settingRow(
                    icon: "paintbrush",
                    iconColor: .purple,
                    title: "Theme",
                    subtitle: "App appearance"
                ) {
                    Picker("Theme", selection: $selectedTheme) {
                        Text("System").tag("System")
                        Text("Light").tag("Light")
                        Text("Dark").tag("Dark")
                    }
                    .pickerStyle(.menu)
                }
                
                Divider()
                    .padding(.horizontal, 16)
                
                // Notifications
                settingRow(
                    icon: "bell",
                    iconColor: .orange,
                    title: "Notifications",
                    subtitle: "Swing analysis alerts and reminders"
                ) {
                    Toggle("", isOn: $notificationsEnabled)
                        .labelsHidden()
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
            )
        }
    }
    
    // MARK: - Analysis Settings Section
    private var analysisSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Analysis Settings")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            
            VStack(spacing: 20) {
                // Confidence Threshold
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(.green)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Confidence Threshold")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Text("Minimum confidence for swing analysis")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text("\(Int(confidenceThreshold * 100))%")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(width: 50)
                    }
                    
                    Slider(value: $confidenceThreshold, in: 0.5...0.95, step: 0.05)
                        .accentColor(.black)
                }
                
                Divider()
                
                // Data Retention
                settingRow(
                    icon: "clock",
                    iconColor: .red,
                    title: "Data Retention",
                    subtitle: "Keep swing data for \(dataRetentionDays) days"
                ) {
                    Picker("Retention", selection: $dataRetentionDays) {
                        Text("30 Days").tag(30)
                        Text("90 Days").tag(90)
                        Text("1 Year").tag(365)
                        Text("Forever").tag(0)
                    }
                    .pickerStyle(.menu)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
            )
        }
    }
    
    // MARK: - Data & Privacy Section
    private var dataPrivacySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Data & Privacy")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                // Data Management
                navigationRow(
                    icon: "externaldrive",
                    iconColor: .blue,
                    title: "Data Management",
                    subtitle: "Manage stored swing data"
                ) {
                    showingDataManagement = true
                }
                
                Divider()
                    .padding(.horizontal, 16)
                
                // Export Data
                navigationRow(
                    icon: "square.and.arrow.up",
                    iconColor: .green,
                    title: "Export Data",
                    subtitle: "Export your swing history"
                ) {
                    showingExportSheet = true
                }
                
                Divider()
                    .padding(.horizontal, 16)
                
                // Privacy Policy
                navigationRow(
                    icon: "hand.raised",
                    iconColor: .purple,
                    title: "Privacy Policy",
                    subtitle: "How we protect your data"
                ) {
                    // Open privacy policy
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
            )
        }
    }
    
    // MARK: - Support Section
    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Support & Information")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                // About
                navigationRow(
                    icon: "info.circle",
                    iconColor: .blue,
                    title: "About SwingAnalyzer",
                    subtitle: "App information and credits"
                ) {
                    showingAbout = true
                }
                
                Divider()
                    .padding(.horizontal, 16)
                
                // Help & Support
                navigationRow(
                    icon: "questionmark.circle",
                    iconColor: .orange,
                    title: "Help & Support",
                    subtitle: "Get help using the app"
                ) {
                    // Open help
                }
                
                Divider()
                    .padding(.horizontal, 16)
                
                // Send Feedback
                navigationRow(
                    icon: "envelope",
                    iconColor: .green,
                    title: "Send Feedback",
                    subtitle: "Help us improve the app"
                ) {
                    // Open feedback
                }
                
                Divider()
                    .padding(.horizontal, 16)
                
                // Rate on App Store
                navigationRow(
                    icon: "star",
                    iconColor: .yellow,
                    title: "Rate on App Store",
                    subtitle: "Share your experience"
                ) {
                    // Open App Store rating
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
            )
        }
    }
    
    // MARK: - Supporting Views
    private func settingRow<Content: View>(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            content()
        }
    }
    
    private func navigationRow(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(UIColor.tertiaryLabel))
                    .font(.system(size: 12, weight: .medium))
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Data Management View
struct DataManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var swingCount = 0
    @State private var storageUsed = "0 MB"
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Storage Overview
                    storageOverviewSection
                    
                    // Data Categories
                    dataCategoriesSection
                    
                    // Actions
                    actionsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Data Management")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadDataStats()
        }
        .alert("Delete All Data", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete All", role: .destructive) {
                deleteAllData()
            }
        } message: {
            Text("This will permanently delete all your swing data. This action cannot be undone.")
        }
    }
    
    // MARK: - Storage Overview Section
    private var storageOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Storage Overview")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Storage Used")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Text("Across all swing data")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(storageUsed)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.green)
                }
                
                // Storage breakdown bar
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Storage Breakdown")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text("\(swingCount) total swings")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    // Progress bar showing data distribution
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.green)
                                .frame(width: geometry.size.width * 0.6)
                            
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: geometry.size.width * 0.3)
                            
                            Rectangle()
                                .fill(Color.orange)
                                .frame(width: geometry.size.width * 0.1)
                        }
                        .frame(height: 8)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                    .frame(height: 8)
                    
                    // Legend
                    HStack(spacing: 16) {
                        legendItem("Sensor Data", color: .green)
                        legendItem("Analysis", color: .blue)
                        legendItem("Other", color: .orange)
                    }
                    .font(.system(size: 12))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
            )
        }
    }
    
    // MARK: - Data Categories Section
    private var dataCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Data Categories")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                dataCategoryRow("Swing Sessions", count: swingCount, size: "2.4 MB", icon: "figure.golf", color: .green)
                dataCategoryRow("Sensor Readings", count: swingCount * 150, size: "12.8 MB", icon: "dot.radiowaves.left.and.right", color: .blue)
                dataCategoryRow("Analysis Results", count: swingCount, size: "1.2 MB", icon: "brain", color: .purple)
                dataCategoryRow("Improvement Data", count: swingCount * 3, size: "0.8 MB", icon: "lightbulb", color: .orange)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
            )
        }
    }
    
    // MARK: - Actions Section
    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Actions")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                // Clean up old data
                actionButton(
                    title: "Clean Up Old Data",
                    subtitle: "Remove data older than 1 year",
                    icon: "trash",
                    color: .orange,
                    action: {
                        // Implement cleanup
                    }
                )
                
                // Optimize storage
                actionButton(
                    title: "Optimize Storage",
                    subtitle: "Compress and optimize data files",
                    icon: "arrow.down.circle",
                    color: .blue,
                    action: {
                        // Implement optimization
                    }
                )
                
                // Delete all data
                actionButton(
                    title: "Delete All Data",
                    subtitle: "Permanently remove all swing data",
                    icon: "trash.fill",
                    color: .red,
                    action: {
                        showingDeleteAlert = true
                    }
                )
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
            )
        }
    }
    
    // MARK: - Supporting Views
    private func legendItem(_ title: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(title)
                .foregroundColor(.secondary)
        }
    }
    
    private func dataCategoryRow(_ title: String, count: Int, size: String, icon: String, color: Color) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Text("\(count.formatted()) items")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(size)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }
    
    private func actionButton(title: String, subtitle: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(UIColor.tertiaryLabel))
                    .font(.system(size: 12, weight: .medium))
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Methods
    private func loadDataStats() {
        let swingSessions = PersistenceController.shared.fetchSwingSessions()
        swingCount = swingSessions.count
        
        // Calculate approximate storage (simplified)
        let estimatedSize = Double(swingCount) * 0.1 // MB per swing
        storageUsed = String(format: "%.1f MB", estimatedSize)
    }
    
    private func deleteAllData() {
        PersistenceController.shared.deleteAllData()
        loadDataStats()
        dismiss()
    }
}

// MARK: - Export Data View
struct ExportDataView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFormat = "JSON"
    @State private var includePersonalData = true
    @State private var dateRange = "All Time"
    @State private var isExporting = false
    
    let formats = ["JSON", "CSV", "PDF Report"]
    let dateRanges = ["Last 7 Days", "Last 30 Days", "Last 3 Months", "All Time"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Export Format")) {
                    Picker("Format", selection: $selectedFormat) {
                        ForEach(formats, id: \.self) { format in
                            Text(format).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Data Range")) {
                    Picker("Date Range", selection: $dateRange) {
                        ForEach(dateRanges, id: \.self) { range in
                            Text(range).tag(range)
                        }
                    }
                }
                
                Section(header: Text("Options")) {
                    Toggle("Include Personal Data", isOn: $includePersonalData)
                }
                
                Section {
                    Button(action: {
                        exportData()
                    }) {
                        HStack {
                            if isExporting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "square.and.arrow.up")
                            }
                            
                            Text(isExporting ? "Exporting..." : "Export Data")
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(isExporting ? .secondary : .white)
                    }
                    .disabled(isExporting)
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isExporting ? Color(.systemGray4) : Color.black)
                    )
                }
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func exportData() {
        isExporting = true
        
        // Simulate export process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isExporting = false
            dismiss()
        }
    }
}

// MARK: - About App View
struct AboutAppView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // App Header
                    VStack(spacing: 16) {
                        Image(systemName: "figure.golf")
                            .font(.system(size: 64, weight: .bold))
                            .foregroundColor(.green)
                        
                        VStack(spacing: 8) {
                            Text("SwingAnalyzer")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Text("Version 1.0.0 (Build 1)")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 16) {
                        Text("About")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("SwingAnalyzer uses advanced machine learning and Apple Watch sensors to provide detailed golf swing analysis. Get real-time feedback, track your progress, and receive personalized improvement suggestions to enhance your golf game.")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Features")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 12) {
                            featureRow("Real-time swing analysis", icon: "brain")
                            featureRow("Distance calculation", icon: "target")
                            featureRow("Improvement suggestions", icon: "lightbulb")
                            featureRow("Historical tracking", icon: "chart.line.uptrend.xyaxis")
                            featureRow("Multi-club support", icon: "golf.club")
                            featureRow("Apple Watch integration", icon: "applewatch")
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Credits
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Credits")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Developed with ❤️ using:")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("• SwiftUI & Core ML")
                                Text("• Apple Watch & Core Motion")
                                Text("• Core Data & Charts")
                                Text("• Machine Learning Models")
                            }
                            .font(.system(size: 14))
                            .foregroundColor(Color(UIColor.tertiaryLabel))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func featureRow(_ text: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 24, height: 24)
            
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

// MARK: - Preview
#Preview("Settings") {
    iOSSettingsView()
}

#Preview("Data Management") {
    DataManagementView()
}

#Preview("About") {
    AboutAppView()
}
