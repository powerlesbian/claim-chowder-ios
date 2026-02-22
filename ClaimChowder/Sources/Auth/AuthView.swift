import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isLoading = false
    @State private var showPassword = false
    @State private var errorMessage: String?
    @State private var showingResetConfirmation = false

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

                Text("Track expenses & subscriptions across currencies")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 48)
            .padding(.horizontal, 32)

            // Form
            VStack(spacing: 16) {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)

                // Password field with eye toggle
                ZStack(alignment: .trailing) {
                    Group {
                        if showPassword {
                            TextField("Password", text: $password)
                        } else {
                            SecureField("Password", text: $password)
                        }
                    }
                    .textFieldStyle(.roundedBorder)
                    .textContentType(isSignUp ? .newPassword : .password)
                    .padding(.trailing, 32)

                    Button {
                        showPassword.toggle()
                    } label: {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundStyle(.secondary)
                    }
                    .padding(.trailing, 8)
                }

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

                // Privacy reassurance (sign-up only)
                if isSignUp {
                    Text("🔒 Your data is stored securely and privately. It is only accessible to a dedicated support person if you explicitly request assistance — otherwise we never see it, and we never share it with anyone.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Forgot password (sign-in only)
                if !isSignUp {
                    Button("Forgot password?") {
                        Task { await resetPassword() }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal, 32)

            // Toggle sign in / sign up
            Button {
                isSignUp.toggle()
                errorMessage = nil
                showPassword = false
            } label: {
                Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                    .font(.subheadline)
            }
            .padding(.top, 20)

            Spacer()
            Spacer()
        }
        .alert("Check your email", isPresented: $showingResetConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("We've sent a password reset link to \(email). Check your inbox and follow the link to set a new password.")
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
            errorMessage = humaniseError(error)
        }

        isLoading = false
    }

    private func resetPassword() async {
        guard !email.isEmpty else {
            errorMessage = "Enter your email address above, then tap Forgot password."
            return
        }
        do {
            try await supabase.auth.resetPasswordForEmail(email)
            showingResetConfirmation = true
        } catch {
            errorMessage = humaniseError(error)
        }
    }

    private func humaniseError(_ error: Error) -> String {
        let message = error.localizedDescription
        if message.contains("Invalid login credentials") {
            return "Wrong email or password. Please try again."
        } else if message.contains("User already registered") {
            return "An account with that email already exists. Try signing in instead."
        } else if message.contains("invalid email") || message.contains("unable to validate email") {
            return "Please enter a valid email address."
        } else if message.contains("network") || message.contains("connection") || message.contains("offline") {
            return "Connection error. Please check your internet and try again."
        }
        return message
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthManager())
}
