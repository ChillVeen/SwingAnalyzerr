//
//  AnalyticsView.swift
//  SwingAnalyzerr
//
//  Elegant analytics dashboard following minimal design guidelines
//

import SwiftUI
import Charts

struct AnalyticsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SwingSession.timestamp, ascending: false)]
    ) private var recentSwings: FetchedResults<SwingSession>
    
    @State private var selectedTimeframe: TimeFrame = .week
    @State private var selectedMetric: AnalyticsMetric = .distance
    @State private var showingFilters = false
    @State private var animateCharts = false
    
    enum TimeFrame: String, CaseIterable {
        case week = "7D"
        case month = "30D"
        case threeMonths = "90D"
        case year = "1Y"
        
        var displayName: String {
            switch self {
            case .week: return "This Week"
            case .month: return "This Month"
            case .threeMonths: return "3 Months"
            case .year: return "This Year"
            }
        }
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .threeMonths: return 90
            case .year: return 365
            }
        }
    }
    
    enum AnalyticsMetric: String, CaseIterable {
        case distance = "Distance"
        case consistency = "Consistency"
        case clubPerformance = "Club Performance"
        case improvement = "Improvement"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 48) {
                    // Header with time controls
                    headerSection
                    
                    // Key Metrics Overview
                    keyMetricsSection
                    
                    // Main Chart
                    mainChartSection
                    
                    // Performance Insights
                    performanceInsightsSection
                    
                    // Club Comparison
                    clubComparisonSection
                    
                    // Weekly Summary
                    weeklySummarySection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .background(Color.white) // Following design guidelines
            .navigationTitle("Analytics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Filters") {
                        showingFilters = true
                    }
                    .foregroundColor(.black)
                }
            }
        }
        .navigationViewStyle(.stack)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0)) {
                animateCharts = true
            }
        }
        .sheet(isPresented: $showingFilters) {
            AnalyticsFiltersView(selectedTimeframe: $selectedTimeframe, selectedMetric: $selectedMetric)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 24) {
            // Hero Title
            VStack(spacing: 16) {
                Text("Performance Analytics")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                
                Text("Track your golf swing progress with precision insights and detailed performance metrics.")
                    .font(.system(size: 18))
                    .foregroundColor(Color(red: 0.42, green: 0.45, blue: 0.5))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 20)
            }
            
            // Time Frame Selector
            HStack(spacing: 0) {
                ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedTimeframe = timeFrame
                        }
                    }) {
                        Text(timeFrame.rawValue)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(selectedTimeframe == timeFrame ? .white : Color(hex: "#6b7280"))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedTimeframe == timeFrame ? Color.black : Color.clear)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
            )
        }
    }
    
    // MARK: - Key Metrics Section
    private var keyMetricsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Overview")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.black)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                metricCard(
                    title: "Average Distance",
                    value: formatDistance(getAverageDistance()),
                    change: "+12 yds",
                    changePositive: true,
                    icon: "target"
                )
                
                metricCard(
                    title: "Consistency Score",
                    value: "\(getConsistencyScore())%",
                    change: "+8%",
                    changePositive: true,
                    icon: "chart.line.uptrend.xyaxis"
                )
                
                metricCard(
                    title: "Total Swings",
                    value: "\(getTotalSwings())",
                    change: "+5",
                    changePositive: true,
                    icon: "figure.golf"
                )
                
                metricCard(
                    title: "Best Performance",
                    value: formatDistance(getBestDistance()),
                    change: "Personal Best",
                    changePositive: true,
                    icon: "star"
                )
            }
        }
    }
    
    // MARK: - Main Chart Section
    private var mainChartSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("Performance Trend")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
                
                Spacer()
                
                // Metric Selector
                Menu(selectedMetric.rawValue) {
                    ForEach(AnalyticsMetric.allCases, id: \.self) { metric in
                        Button(metric.rawValue) {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedMetric = metric
                            }
                        }
                    }
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(red: 0.42, green: 0.45, blue: 0.5))
            }
            
            // Chart Container
            VStack(spacing: 16) {
                chartView
                
                // Chart Legend
                chartLegend
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
            )
        }
    }
    
    // MARK: - Chart View
    private var chartView: some View {
        Chart {
            ForEach(getChartData(), id: \.date) { dataPoint in
                LineMark(
                    x: .value("Date", dataPoint.date),
                    y: .value(selectedMetric.rawValue, dataPoint.value)
                )
                .foregroundStyle(Color.black)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                
                AreaMark(
                    x: .value("Date", dataPoint.date),
                    yStart: .value("Min", 0),
                    yEnd: .value(selectedMetric.rawValue, dataPoint.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.black.opacity(0.1), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .frame(height: 200)
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: max(1, selectedTimeframe.days / 7))) { _ in
                AxisGridLine()
                    .foregroundStyle(Color(.systemGray5))
                AxisValueLabel(format: .dateTime.month().day())
                    .foregroundStyle(Color(.systemGray))
            }
        }
        .chartYAxis {
            AxisMarks { _ in
                AxisGridLine()
                    .foregroundStyle(Color(.systemGray5))
                AxisValueLabel()
                    .foregroundStyle(Color(.systemGray))
            }
        }
        .opacity(animateCharts ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 1.0).delay(0.3), value: animateCharts)
    }
    
    // MARK: - Chart Legend
    private var chartLegend: some View {
        HStack(spacing: 24) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.black)
                    .frame(width: 8, height: 8)
                
                Text(selectedMetric.rawValue)
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.42, green: 0.45, blue: 0.5))
            }
            
            Spacer()
            
            Text("Updated \(Date.now, style: .relative) ago")
                .font(.system(size: 12))
                .foregroundColor(Color(red: 0.42, green: 0.45, blue: 0.5))

        }
    }
    
    // MARK: - Performance Insights Section
    private var performanceInsightsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Performance Insights")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.black)
            
            VStack(spacing: 12) {
                insightCard(
                    icon: "arrow.up",
                    iconColor: .green,
                    title: "Improving Consistency",
                    description: "Your swing consistency has improved by 15% over the past month. Great progress!",
                    action: "View Details"
                )
                
                insightCard(
                    icon: "target",
                    iconColor: .blue,
                    title: "Driver Performance",
                    description: "Your driver distance is 8% above average. Focus on maintaining this consistency.",
                    action: "Analyze Driver"
                )
                
                insightCard(
                    icon: "lightbulb",
                    iconColor: .orange,
                    title: "Improvement Opportunity",
                    description: "Your short iron accuracy could benefit from tempo adjustments.",
                    action: "Get Tips"
                )
            }
        }
    }
    
    // MARK: - Club Comparison Section
    private var clubComparisonSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Club Performance")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.black)
            
            VStack(spacing: 16) {
                ForEach(getClubPerformanceData(), id: \.club) { clubData in
                    clubPerformanceRow(clubData)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
            )
        }
    }
    
    // MARK: - Weekly Summary Section
    private var weeklySummarySection: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Weekly Summary")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.black)
            
            VStack(spacing: 16) {
                weeklyStatRow("Total Swings", value: "\(getThisWeekCount())", icon: "figure.golf")
                weeklyStatRow("Average Rating", value: getAverageRating(), icon: "star")
                weeklyStatRow("Best Distance", value: formatDistance(getBestDistance()), icon: "target")
                weeklyStatRow("Practice Sessions", value: "3", icon: "clock")
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
            )
        }
    }
    
    // MARK: - Supporting Views
    private func metricCard(title: String, value: String, change: String, changePositive: Bool, icon: String) -> some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Color(red: 0.42, green: 0.45, blue: 0.5))
                
                Spacer()
                
                Image(systemName: changePositive ? "arrow.up.right" : "arrow.down.right")
                    .foregroundColor(changePositive ? .green : .red)
                    .font(.system(size: 12, weight: .semibold))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(value)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)
                
                Text(change)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(changePositive ? .green : .red)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background{
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
        }
    }
    
    private func insightCard(icon: String, iconColor: Color, title: String, description: String, action: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(iconColor)
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(iconColor.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                
                Text(description)
                    .font(.system(size: 16))
                    .foregroundColor(Color(red: 0.42, green: 0.45, blue: 0.5))
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button(action: {}) {
                Text(action)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black)
            }
        }
        .padding(20)
        .background{
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 12, x: 0, y: 4)
        }
    }
    
    private func clubPerformanceRow(_ clubData: ClubPerformanceData) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(clubData.club)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                
                Text("\(clubData.swings) swings")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.42, green: 0.45, blue: 0.5))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(clubData.averageDistance)) yds")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                
                Text(clubData.rating)
                    .font(.system(size: 14))
                    .foregroundColor(ratingColor(clubData.rating))
            }
        }
        .padding(.vertical, 8)
    }
    
    private func weeklyStatRow(_ title: String, value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color(red: 0.42, green: 0.45, blue: 0.5))
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.black)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.black)
        }
    }
    
    // MARK: - Data Helpers
    private func getAverageDistance() -> Double {
        let limitedSwings = Array(recentSwings.prefix(50))
        let distances = limitedSwings.compactMap { swing in
            swing.calculatedDistance > 0 ? swing.calculatedDistance : nil
        }
        guard !distances.isEmpty else { return 0 }
        return distances.reduce(0, +) / Double(distances.count)
    }
    
    private func getConsistencyScore() -> Int {
        let limitedSwings = Array(recentSwings.prefix(50))
        let goodSwings = limitedSwings.filter { swing in
            swing.rating == "Good" || swing.rating == "Excellent"
        }.count
        guard limitedSwings.count > 0 else { return 0 }
        return Int((Double(goodSwings) / Double(limitedSwings.count)) * 100)
    }
    
    private func getTotalSwings() -> Int {
        return recentSwings.count
    }
    
    private func getBestDistance() -> Double {
        return recentSwings.compactMap { $0.calculatedDistance }.max() ?? 0
    }
    
    private func getThisWeekCount() -> Int {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return recentSwings.filter { swing in
            swing.timestamp ?? Date.distantPast >= weekAgo
        }.count
    }
    
    private func getAverageRating() -> String {
        let limitedSwings = Array(recentSwings.prefix(20))
        guard !limitedSwings.isEmpty else { return "N/A" }
        
        let ratings = limitedSwings.compactMap { $0.rating }
        let excellentCount = ratings.filter { $0 == "Excellent" }.count
        let goodCount = ratings.filter { $0 == "Good" }.count
        
        if excellentCount > goodCount {
            return "Excellent"
        } else if goodCount > 0 {
            return "Good"
        } else {
            return "Average"
        }
    }
    
    private func formatDistance(_ distance: Double) -> String {
        return distance > 0 ? "\(Int(distance)) yds" : "N/A"
    }
    
    private func ratingColor(_ rating: String) -> Color {
        switch rating.lowercased() {
        case "excellent": return .green
        case "good": return .blue
        case "average": return .orange
        default: return Color(.white)
        }
    }
    
    private func getChartData() -> [ChartDataPoint] {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -selectedTimeframe.days, to: endDate) ?? endDate
        
        let filteredSwings = recentSwings.filter { swing in
            guard let timestamp = swing.timestamp else { return false }
            return timestamp >= startDate && timestamp <= endDate
        }
        
        // Group swings by day and calculate average for selected metric
        var dailyData: [Date: [Double]] = [:]
        
        for swing in filteredSwings {
            guard let timestamp = swing.timestamp else { continue }
            let dayStart = calendar.startOfDay(for: timestamp)
            
            let value: Double
            switch selectedMetric {
            case .distance:
                value = swing.calculatedDistance
            case .consistency:
                let rating = swing.rating?.lowercased() ?? ""
                value = rating == "excellent" ? 100 : (rating == "good" ? 80 : 60)
            case .clubPerformance:
                value = swing.calculatedDistance
            case .improvement:
                value = swing.calculatedDistance
            }
            
            if dailyData[dayStart] == nil {
                dailyData[dayStart] = []
            }
            dailyData[dayStart]?.append(value)
        }
        
        // Convert to chart data points
        return dailyData.map { date, values in
            let averageValue = values.reduce(0, +) / Double(values.count)
            return ChartDataPoint(date: date, value: averageValue)
        }.sorted { $0.date < $1.date }
    }
    
    private func getClubPerformanceData() -> [ClubPerformanceData] {
        let clubs = ["Driver", "Steel 7", "Steel 9"]
        
        return clubs.map { club in
            let clubSwings = recentSwings.filter { $0.golfClub == club }
            let averageDistance = clubSwings.compactMap { swing in
                swing.calculatedDistance > 0 ? swing.calculatedDistance : nil
            }.reduce(0, +) / Double(max(1, clubSwings.count))
            
            let goodSwings = clubSwings.filter { $0.rating == "Good" || $0.rating == "Excellent" }.count
            let rating = clubSwings.count > 0 ? (goodSwings >= clubSwings.count / 2 ? "Good" : "Average") : "N/A"
            
            return ClubPerformanceData(
                club: club,
                swings: clubSwings.count,
                averageDistance: averageDistance,
                rating: rating
            )
        }
    }
}

// MARK: - Data Models
struct ChartDataPoint {
    let date: Date
    let value: Double
}

struct ClubPerformanceData {
    let club: String
    let swings: Int
    let averageDistance: Double
    let rating: String
}

// MARK: - Analytics Filters View
struct AnalyticsFiltersView: View {
    @Binding var selectedTimeframe: AnalyticsView.TimeFrame
    @Binding var selectedMetric: AnalyticsView.AnalyticsMetric
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Time Range") {
                    Picker("Timeframe", selection: $selectedTimeframe) {
                        ForEach(AnalyticsView.TimeFrame.allCases, id: \.self) { timeFrame in
                            Text(timeFrame.displayName).tag(timeFrame)
                        }
                    }
                    .pickerStyle(.wheel)
                }
                
                Section("Metric") {
                    Picker("Metric", selection: $selectedMetric) {
                        ForEach(AnalyticsView.AnalyticsMetric.allCases, id: \.self) { metric in
                            Text(metric.rawValue).tag(metric)
                        }
                    }
                    .pickerStyle(.wheel)
                }
            }
            .navigationTitle("Filters")
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
}

extension Color {
    static func hex(_ hex: String) -> Color {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        return Color(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }
}


// MARK: - Preview
#Preview {
    AnalyticsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

