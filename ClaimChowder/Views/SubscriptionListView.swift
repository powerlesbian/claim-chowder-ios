import SwiftUI

struct SubscriptionListView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = SubscriptionViewModel()
    @State private var showingAddForm = false
    @State private var editingSubscription: Subscription?
    @State private var showingProfile = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading subscriptions...")
                } else if viewModel.subscriptions.isEmpty {
                    emptyState
                } else {
                    subscriptionList
                }
            }
            .navigationTitle("Subscriptions")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingProfile = true
                    } label: {
                        Image(systemName: "person.circle")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddForm) {
                SubscriptionFormView(viewModel: viewModel)
            }
            .sheet(item: $editingSubscription) { subscription in
                SubscriptionFormView(viewModel: viewModel, editing: subscription)
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView()
            }
            .refreshable {
                await viewModel.load()
            }
            .task {
                await viewModel.load()
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Subscriptions", systemImage: "doc.text")
        } description: {
            Text("Add your first subscription to get started")
        } actions: {
            Button("Add Subscription") {
                showingAddForm = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var subscriptionList: some View {
        List {
            // Summary card
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Monthly Total")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(viewModel.formattedMonthlyTotal)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Active")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(viewModel.activeCount)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.blue)
                    }
                }
                .padding(.vertical, 4)
            }

            // Active subscriptions
            if !viewModel.activeSubscriptions.isEmpty {
                Section("Active") {
                    ForEach(viewModel.activeSubscriptions) { subscription in
                        SubscriptionRow(subscription: subscription)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Task { await viewModel.delete(id: subscription.id) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button {
                                    Task { await viewModel.toggleCancelled(id: subscription.id, cancelled: true) }
                                } label: {
                                    Label("Cancel", systemImage: "xmark.circle")
                                }
                                .tint(.orange)
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    editingSubscription = subscription
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(.blue)
                            }
                    }
                }
            }

            // Cancelled subscriptions
            if !viewModel.cancelledSubscriptions.isEmpty {
                Section("Cancelled") {
                    ForEach(viewModel.cancelledSubscriptions) { subscription in
                        SubscriptionRow(subscription: subscription)
                            .opacity(0.6)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Task { await viewModel.delete(id: subscription.id) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    Task { await viewModel.toggleCancelled(id: subscription.id, cancelled: false) }
                                } label: {
                                    Label("Reactivate", systemImage: "checkmark.circle")
                                }
                                .tint(.green)
                            }
                    }
                }
            }
        }
    }
}

struct SubscriptionRow: View {
    let subscription: Subscription

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            Circle()
                .fill(subscription.cancelled ? .gray.opacity(0.2) : .blue.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay {
                    Text(String(subscription.name.prefix(1)).uppercased())
                        .font(.headline)
                        .foregroundStyle(subscription.cancelled ? .gray : .blue)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(subscription.name)
                    .font(.body)
                    .fontWeight(.medium)

                HStack(spacing: 6) {
                    Text(subscription.frequency.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let days = subscription.daysUntilNextPayment, !subscription.cancelled {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(days == 0 ? "Due today" : days == 1 ? "Due tomorrow" : "Due in \(days) days")
                            .font(.caption)
                            .foregroundStyle(days <= 3 ? .orange : .secondary)
                    }
                }

                // Tags
                if let tags = subscription.tags, !tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.blue.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            Spacer()

            Text(subscription.formattedAmount)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(subscription.cancelled ? .secondary : .primary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    SubscriptionListView()
        .environmentObject(AuthManager())
}
