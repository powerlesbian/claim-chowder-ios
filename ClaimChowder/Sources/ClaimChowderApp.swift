import SwiftUI

@main
struct ClaimChowderApp: App {
    @StateObject private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .task { await RateService.shared.fetch() }
        }
    }
}
