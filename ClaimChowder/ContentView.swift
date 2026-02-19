import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        Group {
            if authManager.isLoading {
                ProgressView("Loading...")
            } else if authManager.isAuthenticated {
                MainTabView()
            } else {
                AuthView()
            }
        }
        .animation(.easeInOut, value: authManager.isAuthenticated)
    }
}

struct MainTabView: View {
    @StateObject private var viewModel = SubscriptionViewModel()
    @State private var displayCurrency: CurrencyType = .HKD

    var body: some View {
        TabView {
            Tab("Dashboard", systemImage: "chart.bar.fill") {
                NavigationStack {
                    DashboardView(viewModel: viewModel, displayCurrency: $displayCurrency)
                        .navigationTitle("Dashboard")
                        .task { await viewModel.load() }
                }
            }

            Tab("Subscriptions", systemImage: "list.bullet") {
                SubscriptionListView(viewModel: viewModel)
            }

            Tab("Upcoming", systemImage: "calendar") {
                NavigationStack {
                    UpcomingPaymentsView(viewModel: viewModel)
                        .navigationTitle("Upcoming Payments")
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
}
