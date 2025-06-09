//
//  SwingHistoryView.swift
//  SwingAnalyzerr
//
//  Comprehensive swing history with filtering and detailed records
//

import SwiftUI

struct SwingHistoryView: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SwingSession.timestamp, ascending: false)]
    ) private var allSwings: FetchedResults<SwingSession>
    
    @StateObject private var syncManager = WatchConnectivityManager()
    @State private var swingToDelete: SwingSession?
    @State private var showingDeleteAlert = false
    @State private var searchText = ""
    @State private var selectedClubFilter: ClubFilter = .all
    @State private var selectedRatingFilter: RatingFilter = .all
    @State private var selectedDateRange: DateRangeFilter = .all
    @State private var showingFilters = false
    @State private var selectedSwing: SwingSession?
    @State private var showingSwingDetail = false
    
    enum ClubFilter: String, CaseIterable {
        case all = "All Clubs"
        case driver = "Driver"
        case steel7 = "Steel 7"
        case steel9 = "Steel 9"
        
        var systemImage: String {
            switch self {
            case .all: return "golf.club"
            case .driver: return "figure.golf"
            case .steel7: return "target"
            case .steel9: return "scope"
            }
        }
    }
    
    enum RatingFilter: String, CaseIterable {
        case all = "All Ratings"
        case excellent = "Excellent"
        case good = "Good"
        case average = "Average"
        
        var color: Color {
            switch self {
            case .all: return .secondary
            case .excellent: return .green
            case .good: return .blue
            case .average: return .orange
            }
        }
    }
    
    enum DateRangeFilter: String, CaseIterable {
        case all = "All Time"
        case today = "Today"
        case week = "This Week"
        case month = "This Month"
        case threeMonths = "3 Months"
        
        var days: Int? {
            switch self {
            case .all: return nil
            case .today: return 1
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            }
        }
    }
    
    var filteredSwings: [SwingSession] {
        var swings = Array(allSwings)
        
        // Apply search filter
        if !searchText.isEmpty {
            swings = swings.filter { swing in
                swing.golfClub?.lowercased().contains(searchText.lowercased()) == true ||
                swing.rating?.lowercased().contains(searchText.lowercased()) == true
            }
        }
        
        // Apply club filter
        if selectedClubFilter != .all {
            swings = swings.filter { swing in
                swing.golfClub == selectedClubFilter.rawValue.replacingOccurrences(of: "Steel ", with: "Steel ")
            }
        }
        
        // Apply rating filter
        if selectedRatingFilter != .all {
            swings = swings.filter { swing in
                swing.rating == selectedRatingFilter.rawValue
            }
        }
        
        // Apply date range filter
        if let days = selectedDateRange.days {
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            swings = swings.filter { swing in
                swing.timestamp ?? Date.distantPast >= cutoffDate
            }
        }
        
        return swings
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with search, filters, and sync status
                headerSection
                
                // NEW: Sync Status Bar
                syncStatusBar
                
                // Content
                if filteredSwings.isEmpty {
                    emptyStateView
                } else {
                    swingsList
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Swing History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        // NEW: Manual sync button
                        Button(action: {
                            Task {
                                await syncManager.requestFullSync()
                            }
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.primary)
                        }
                        
                        Button("Filters") {
                            showingFilters = true
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .alert("Delete Swing", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let swing = swingToDelete {
                    Task {
                        await syncManager.deleteSwing(swing)
                    }
                }
            }
        } message: {
            Text("This will permanently delete this swing from all devices.")
        }
        .sheet(isPresented: $showingFilters) {
            FiltersView(
                clubFilter: $selectedClubFilter,
                ratingFilter: $selectedRatingFilter,
                dateRangeFilter: $selectedDateRange
            )
        }
        .sheet(isPresented: $showingSwingDetail) {
            if let swing = selectedSwing {
                SwingDetailView(swing: swing)
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 16))
                
                TextField("Search swings...", text: $searchText)
                    .font(.system(size: 16))
                    .textFieldStyle(.plain)
                
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
            )
            
            // Quick Filter Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    filterChip(
                        title: selectedClubFilter.rawValue,
                        icon: selectedClubFilter.systemImage,
                        isActive: selectedClubFilter != .all
                    ) {
                        cycleClubFilter()
                    }
                    
                    filterChip(
                        title: selectedRatingFilter.rawValue,
                        icon: "star",
                        isActive: selectedRatingFilter != .all,
                        activeColor: selectedRatingFilter.color
                    ) {
                        cycleRatingFilter()
                    }
                    
                    filterChip(
                        title: selectedDateRange.rawValue,
                        icon: "calendar",
                        isActive: selectedDateRange != .all
                    ) {
                        cycleDateRangeFilter()
                    }
                    
                    // Results count
                    if !filteredSwings.isEmpty {
                        Text("\(filteredSwings.count) swings")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.systemGray6))
                            )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 16)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: searchText.isEmpty ? "clock" : "magnifyingglass")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(.secondary)
                
                VStack(spacing: 8) {
                    Text(searchText.isEmpty ? "No Swings Yet" : "No Results Found")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(searchText.isEmpty ? 
                         "Start recording swings with your Apple Watch to build your swing history." :
                         "Try adjusting your search or filters to find what you're looking for."
                    )
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                }
            }
            
            if !searchText.isEmpty || selectedClubFilter != .all || selectedRatingFilter != .all || selectedDateRange != .all {
                Button("Clear Filters") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        searchText = ""
                        selectedClubFilter = .all
                        selectedRatingFilter = .all
                        selectedDateRange = .all
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.black)
                )
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Swings List
    private var swingsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(groupedSwings, id: \.date) { group in
                    swingGroupSection(group)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    // MARK: - NEW: Sync Status Bar (Following Default Guidelines)
    private var syncStatusBar: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(syncManager.isReachable ? .green : .gray)
                .frame(width: 8, height: 8)
            
            Text(syncManager.syncStatusText)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "#6b7280")) // Neutral gray from guidelines
            
            Spacer()
            
            if syncManager.isReachable {
                HStack(spacing: 4) {
                    Image(systemName: "applewatch")
                        .font(.system(size: 12))
                        .foregroundColor(.green)
                    
                    Text("Connected")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8) // Subtle rounded corners from guidelines
                .fill(.white)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2) // Light shadow
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
    
    // MARK: - Swing Group Section
    private func swingGroupSection(_ group: SwingGroup) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date Header
            HStack {
                Text(group.date, style: .date)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(group.swings.count) swing\(group.swings.count == 1 ? "" : "s")")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)
            
            // Swings for this date
            VStack(spacing: 8) {
                ForEach(group.swings, id: \.id) { swing in
                    swingCard(swing)
                }
            }
        }
    }
    
    // MARK: - Swing Card
    private func swingCard(_ swing: SwingSession) -> some View {
        Button(action: {
            selectedSwing = swing
            showingSwingDetail = true
        }) {
            HStack(spacing: 16) {
                // Club Icon and Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: clubIcon(swing.golfClub ?? ""))
                            .foregroundColor(.secondary)
                            .font(.system(size: 16))
                        
                        Text(swing.golfClub ?? "Unknown Club")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.primary)
                        
                    }
                    
                    if let timestamp = swing.timestamp {
                        Text(timestamp, style: .time)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                }
                
                Spacer()
                
                // Metrics
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(swing.calculatedDistance)) yds")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                    
                    if let rating = swing.rating {
                        ratingBadge(rating)
                    }
                }
                
                // Arrow
                Image(systemName: "chevron.right")
                    .foregroundColor(Color(UIColor.tertiaryLabel))
                    .font(.system(size: 12, weight: .medium))
                
                
                // NEW: Delete button
                Button(action: {
                    swingToDelete = swing
                    showingDeleteAlert = true
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.red.opacity(0.1))
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12) // Following guidelines
                    .fill(.white)
                    .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Supporting Views
    private func filterChip(title: String, icon: String, isActive: Bool, activeColor: Color = .black, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundColor(isActive ? .white : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isActive ? activeColor : Color(.systemGray6))
            )
            .animation(.easeInOut(duration: 0.2), value: isActive)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func ratingBadge(_ rating: String) -> some View {
        Text(rating)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
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
        default: return .secondary
        }
    }
    
    private func cycleClubFilter() {
        let allCases = ClubFilter.allCases
        if let currentIndex = allCases.firstIndex(of: selectedClubFilter) {
            let nextIndex = (currentIndex + 1) % allCases.count
            selectedClubFilter = allCases[nextIndex]
        }
    }
    
    private func cycleRatingFilter() {
        let allCases = RatingFilter.allCases
        if let currentIndex = allCases.firstIndex(of: selectedRatingFilter) {
            let nextIndex = (currentIndex + 1) % allCases.count
            selectedRatingFilter = allCases[nextIndex]
        }
    }
    
    private func cycleDateRangeFilter() {
        let allCases = DateRangeFilter.allCases
        if let currentIndex = allCases.firstIndex(of: selectedDateRange) {
            let nextIndex = (currentIndex + 1) % allCases.count
            selectedDateRange = allCases[nextIndex]
        }
    }
    
    // MARK: - Data Grouping
    private var groupedSwings: [SwingGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredSwings) { swing in
            calendar.startOfDay(for: swing.timestamp ?? Date())
        }
        
        return grouped.map { date, swings in
            SwingGroup(date: date, swings: swings.sorted { ($0.timestamp ?? Date()) > ($1.timestamp ?? Date()) })
        }.sorted { $0.date > $1.date }
    }
}

// MARK: - Data Models
struct SwingGroup {
    let date: Date
    let swings: [SwingSession]
}

// MARK: - Filters View
struct FiltersView: View {
    @Binding var clubFilter: SwingHistoryView.ClubFilter
    @Binding var ratingFilter: SwingHistoryView.RatingFilter
    @Binding var dateRangeFilter: SwingHistoryView.DateRangeFilter
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Golf Club")) {
                    Picker("Club", selection: $clubFilter) {
                        ForEach(SwingHistoryView.ClubFilter.allCases, id: \.self) { club in
                            Label(club.rawValue, systemImage: club.systemImage)
                                .tag(club)
                        }
                    }
                    .pickerStyle(.wheel)
                }
                
                Section(header: Text("Rating")) {
                    Picker("Rating", selection: $ratingFilter) {
                        ForEach(SwingHistoryView.RatingFilter.allCases, id: \.self) { rating in
                            HStack {
                                Text(rating.rawValue)
                                Spacer()
                                if rating != .all {
                                    Circle()
                                        .fill(rating.color)
                                        .frame(width: 12, height: 12)
                                }
                            }
                            .tag(rating)
                        }
                    }
                    .pickerStyle(.wheel)
                }
                
                Section(header: Text("Date Range")) {
                    Picker("Date Range", selection: $dateRangeFilter) {
                        ForEach(SwingHistoryView.DateRangeFilter.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.wheel)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Reset") {
                        clubFilter = .all
                        ratingFilter = .all
                        dateRangeFilter = .all
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Swing Detail View
struct SwingDetailView: View {
    let swing: SwingSession
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Stats
                    headerStats
                    
                    // Analysis Results
                    if let analysis = swing.analysis {
                        analysisSection(analysis)
                    }
                    
                    // Improvement Suggestions
                    if let analysis = swing.analysis, let suggestions = analysis.improvementSuggestions, !suggestions.isEmpty {
                        improvementSection(suggestions)
                    }
                    
                    // Technical Details
                    technicalDetailsSection
                    
                    // Actions
                    actionsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Swing Details")
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
    
    // MARK: - Header Stats
    private var headerStats: some View {
        VStack(spacing: 20) {
            // Club and Rating
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(swing.golfClub ?? "Unknown Club")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)
                    
                    if let timestamp = swing.timestamp {
                        Text(timestamp, format: .dateTime)
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if let rating = swing.rating {
                    VStack(alignment: .trailing, spacing: 4) {
                        ratingBadge(rating, large: true)
                        
                        if let analysis = swing.analysis {
                            Text("\(Int(analysis.mlConfidence * 100))% confidence")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Key Metrics
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                metricCard("Distance", value: "\(Int(swing.calculatedDistance))", unit: "yds")
                metricCard("Duration", value: String(format: "%.1f", swing.swingDuration), unit: "sec")
                metricCard("Hand", value: swing.watchHand ?? "Unknown", unit: "")
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.03), radius: 12, x: 0, y: 4)
        )
    }
    
    // MARK: - Analysis Section
    private func analysisSection(_ analysis: SwingAnalysis) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Analysis Results")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                analysisRow("Max Swing Speed", value: String(format: "%.1f mph", analysis.maxSwingSpeed))
                analysisRow("Average Acceleration", value: String(format: "%.1f G", analysis.averageAcceleration))
                analysisRow("Impact Acceleration", value: String(format: "%.1f G", analysis.impactAcceleration))
                analysisRow("Backswing Time", value: String(format: "%.2f sec", analysis.backswingTime))
                analysisRow("Downswing Time", value: String(format: "%.2f sec", analysis.downswingTime))
                analysisRow("Follow Through", value: String(format: "%.2f sec", analysis.followThroughTime))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 2)
            )
        }
    }
    
    // MARK: - Improvement Section
    private func improvementSection(_ suggestions: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Improvement Suggestions")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "lightbulb")
                        .foregroundColor(.orange)
                        .font(.system(size: 20))
                        .padding(.top, 2)
                    
                    Text(suggestions)
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                        .lineSpacing(4)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                    )
            )
        }
    }
    
    // MARK: - Technical Details Section
    private var technicalDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Technical Details")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                technicalRow("Device Type", value: swing.deviceType ?? "Apple Watch")
                technicalRow("Session ID", value: String(swing.id?.uuidString.prefix(8) ?? "Unknown"))
                
                if let analysis = swing.analysis {
                    technicalRow("Sensor Readings", value: "\(swing.sensorData?.count ?? 0) data points")
                    technicalRow("Analysis Timestamp", value: formatTimestamp(analysis.timestamp))
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
    
    // MARK: - Actions Section
    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                // Export swing data
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Export Swing Data")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black)
                )
            }
            
            Button(action: {
                deleteSwing()
            }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Swing")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    // MARK: - Supporting Views
    private func metricCard(_ title: String, value: String, unit: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            
            if !unit.isEmpty {
                Text(unit)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
    
    private func ratingBadge(_ rating: String, large: Bool = false) -> some View {
        Text(rating)
            .font(.system(size: large ? 16 : 12, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, large ? 12 : 8)
            .padding(.vertical, large ? 8 : 4)
            .background(
                RoundedRectangle(cornerRadius: large ? 8 : 6)
                    .fill(ratingColor(rating))
            )
    }
    
    private func analysisRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.secondary)
        }
    }
    
    private func technicalRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
        }
    }
    
    // MARK: - Helper Methods
    private func ratingColor(_ rating: String) -> Color {
        switch rating.lowercased() {
        case "excellent": return .green
        case "good": return .blue
        case "average": return .orange
        default: return .secondary
        }
    }
    
    private func formatTimestamp(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func deleteSwing() {
        viewContext.delete(swing)
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Failed to delete swing: \(error)")
        }
    }
}

// MARK: - Preview
#Preview {
    SwingHistoryView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
