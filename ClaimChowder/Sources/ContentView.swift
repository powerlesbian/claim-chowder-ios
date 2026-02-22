import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        Group {
            if !hasSeenOnboarding {
                OnboardingView(hasSeenOnboarding: $hasSeenOnboarding)
            } else if authManager.isLoading {
                ProgressView("Loading...")
            } else if authManager.isAuthenticated {
                MainTabView()
            } else {
                AuthView()
            }
        }
        .animation(.easeInOut, value: hasSeenOnboarding)
        .animation(.easeInOut, value: authManager.isAuthenticated)
    }
}

struct MainTabView: View {
    @StateObject private var viewModel = SubscriptionViewModel()
    @State private var displayCurrency: CurrencyType = .HKD

    var body: some View {
        TabView {
            NavigationStack {
                DashboardView(viewModel: viewModel, displayCurrency: $displayCurrency)
                    .navigationTitle("Dashboard")
                    .navigationBarTitleDisplayMode(.inline)
                    .task { await viewModel.load() }
            }
            .tabItem {
                Label("Dashboard", systemImage: "chart.bar.fill")
            }

            SubscriptionListView(viewModel: viewModel)
                .tabItem {
                    Label("Subscriptions", systemImage: "list.bullet")
                }

            NavigationStack {
                UpcomingPaymentsView(viewModel: viewModel)
                    .navigationTitle("Upcoming Payments")
            }
            .tabItem {
                Label("Upcoming", systemImage: "calendar")
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
}
