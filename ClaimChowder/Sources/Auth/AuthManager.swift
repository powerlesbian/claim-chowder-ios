import Foundation
import Supabase
import Auth

@MainActor
class AuthManager: ObservableObject {
    @Published var session: Session?
    @Published var isLoading = true

    var isAuthenticated: Bool {
        session != nil
    }

    var userId: String? {
        session?.user.id.uuidString
    }

    init() {
        Task {
            await loadSession()
            listenForAuthChanges()
        }
    }

    private func loadSession() async {
        do {
            session = try await supabase.auth.session
        } catch {
            session = nil
        }
        isLoading = false
    }

    private func listenForAuthChanges() {
        Task {
            for await (event, session) in supabase.auth.authStateChanges {
                switch event {
                case .signedIn, .tokenRefreshed:
                    self.session = session
                case .signedOut:
                    self.session = nil
                default:
                    break
                }
            }
        }
    }

    func signIn(email: String, password: String) async throws {
        let session = try await supabase.auth.signIn(
            email: email,
            password: password
        )
        self.session = session
    }

    func signUp(email: String, password: String) async throws {
        let response = try await supabase.auth.signUp(
            email: email,
            password: password
        )
        self.session = response.session
    }

    func signOut() async throws {
        try await supabase.auth.signOut()
        session = nil
    }
}
