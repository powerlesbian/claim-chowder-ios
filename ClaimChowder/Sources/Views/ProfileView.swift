import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingSignOutConfirmation = false
    @State private var showingDeleteConfirmation = false
    @State private var deleteError: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if let email = authManager.session?.user.email {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title)
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading) {
                                Text(email)
                                    .font(.body)
                                Text("Signed in")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showingSignOutConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Sign Out")
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Account")
                        }
                    }

                    if let error = deleteError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                } footer: {
                    Text("Permanently deletes your account and all subscription data.")
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog("Sign Out", isPresented: $showingSignOutConfirmation) {
                Button("Sign Out", role: .destructive) {
                    Task {
                        try? await authManager.signOut()
                        dismiss()
                    }
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .confirmationDialog("Delete Account", isPresented: $showingDeleteConfirmation) {
                Button("Delete Account", role: .destructive) {
                    Task {
                        do {
                            try await authManager.deleteAccount()
                            dismiss()
                        } catch {
                            deleteError = "Failed to delete account. Please try again."
                        }
                    }
                }
            } message: {
                Text("This will permanently delete your account and all your subscription data. This cannot be undone.")
            }
        }
    }
}
