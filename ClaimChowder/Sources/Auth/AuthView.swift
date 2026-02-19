import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo and title
            VStack(spacing: 12) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 56))
                    .foregroundStyle(.blue)

                Text("Claim Chowder")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Track subscriptions & fix the leaks")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 48)

            // Form
            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)

                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(isSignUp ? .newPassword : .password)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task { await authenticate() }
                } label: {
                    if isLoading {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(isSignUp ? "Create Account" : "Sign In")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(.blue)
                .foregroundStyle(.white)
                .fontWeight(.semibold)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .disabled(isLoading || email.isEmpty || password.isEmpty)
                .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1.0)
            }
            .padding(.horizontal, 32)

            // Toggle sign in / sign up
            Button {
                isSignUp.toggle()
                errorMessage = nil
            } label: {
                Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                    .font(.subheadline)
            }
            .padding(.top, 20)

            Spacer()
            Spacer()
        }
    }

    private func authenticate() async {
        isLoading = true
        errorMessage = nil

        do {
            if isSignUp {
                try await authManager.signUp(email: email, password: password)
            } else {
                try await authManager.signIn(email: email, password: password)
            }
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthManager())
}
