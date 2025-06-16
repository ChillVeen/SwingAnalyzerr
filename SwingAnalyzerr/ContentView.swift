//
//  ContentView.swift
//  SwingAnalyzerr
//
//  Main navigation hub for iOS companion app
//

import SwiftUI

struct ContentView: View {
    @StateObject private var watchConnectivity = WatchConnectivityManager()
    @State private var selectedTab = 0
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            } else {
                mainTabView
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.6), value: hasCompletedOnboarding)
        .environmentObject(watchConnectivity)
        .onAppear {
            print("📱 iPhone app started")
            print("📱 Watch connected: \(watchConnectivity.isConnected)")
            print("📱 Watch reachable: \(watchConnectivity.isReachable)")
        }
    }
    
    // MARK: - Main Tab View
    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text("Dashboard")
                }
                .tag(0)
            
            AnalyticsView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "chart.line.uptrend.xyaxis" : "chart.xyaxis.line")
                    Text("Analytics")
                }
                .tag(1)
            
            SwingHistoryView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "clock.fill" : "clock")
                    Text("History")
                }
                .tag(2)
            
            iOSSettingsView()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "gear.circle.fill" : "gear")
                    Text("Settings")
                }
                .tag(3)
        }
        .accentColor(.black)
        .onAppear {
            configureTabBarStyling()
        }
    }
    
    // MARK: - Helper Methods
    private func configureTabBarStyling() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor.white
        
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor.black
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.black,
            .font: UIFont.systemFont(ofSize: 12, weight: .medium)
        ]
        
        tabBarAppearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
        tabBarAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.systemGray,
            .font: UIFont.systemFont(ofSize: 12, weight: .regular)
        ]
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}

// MARK: - Onboarding View
struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var currentPage = 0
    
    private let pages = [
        OnboardingPage(
            title: "Welcome to iSwing",
            subtitle: "Advanced golf swing analysis using Apple Watch",
            imageName: "figure.golf",
            description: "Get real-time feedback and track your progress."
        ),
        OnboardingPage(
            title: "Apple Watch Integration",
            subtitle: "Seamless data collection from your wrist",
            imageName: "applewatch",
            description: "Record swings with precision using motion sensors."
        ),
        OnboardingPage(
            title: "Intelligent Analysis",
            subtitle: "Machine learning powered insights",
            imageName: "brain",
            description: "Get detailed analysis and coaching tips."
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    onboardingPageView(pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            
            bottomActionView
        }
        .background(Color.white)
    }
    
    private func onboardingPageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 48) {
            Spacer()
            
            Image(systemName: page.imageName)
                .font(.system(size: 80, weight: .bold))
                .foregroundColor(.black)
            
            VStack(spacing: 24) {
                Text(page.title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                Text(page.subtitle)
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Text(page.description)
                    .font(.system(size: 16))
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
        }
    }
    
    private var bottomActionView: some View {
        VStack(spacing: 24) {
            HStack(spacing: 8) {
                ForEach(0..<pages.count, id: \.self) { index in
                    Circle()
                        .fill(currentPage == index ? Color.black : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
            
            if currentPage == pages.count - 1 {
                Button("Get Started") {
                    hasCompletedOnboarding = true
                }
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black)
                )
                .padding(.horizontal, 32)
            } else {
                Button("Continue") {
                    withAnimation {
                        currentPage += 1
                    }
                }
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black)
                )
                .padding(.horizontal, 32)
            }
        }
        .padding(.bottom, 48)
    }
}

// MARK: - Supporting Models
struct OnboardingPage {
    let title: String
    let subtitle: String
    let imageName: String
    let description: String
}

// MARK: - Preview
#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}



