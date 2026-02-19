import SwiftUI
import UIKit

struct SubscriptionListView: View {
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject var viewModel: SubscriptionViewModel
    @State private var showingAddForm = false
    @State private var editingSubscription: Subscription?
    @State private var showingProfile = false
    @State private var searchText = ""
    @State private var selectedTag: String? = nil
    @State private var showingImport = false
    @State private var showingError = false

    private let availableTags = ["All", "Personal", "Business"]

    private var filteredSubscriptions: [Subscription] {
        var result = viewModel.subscriptions

        // Filter by tag
        if let tag = selectedTag, tag != "All" {
            result = result.filter { $0.tags?.contains(tag) == true }
        }

        // Filter by search
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.name.lowercased().contains(query) ||
                $0.notes?.lowercased().contains(query) == true ||
                $0.currency.rawValue.lowercased().contains(query) ||
                $0.frequency.displayName.lowercased().contains(query)
            }
        }

        return result
    }

    private var activeFiltered: [Subscription] {
        filteredSubscriptions.filter { !$0.cancelled }
    }

    private var cancelledFiltered: [Subscription] {
        filteredSubscriptions.filter { $0.cancelled }
    }

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
            .searchable(text: $searchText, prompt: "Search subscriptions")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingProfile = true
                    } label: {
                        Image(systemName: "person.circle")
                    }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showingImport = true
                    } label: {
                        Image(systemName: "doc.text")
                    }
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
            .sheet(isPresented: $showingImport) {
                PDFImportView(viewModel: viewModel)
            }
            .refreshable {
                await viewModel.load()
            }
            .task {
                await viewModel.load()
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "Something went wrong")
            }
            .onChange(of: viewModel.errorMessage) { _, newValue in
                showingError = newValue != nil
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
            // Tag filter
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(availableTags, id: \.self) { tag in
                            Button {
                                selectedTag = tag == "All" ? nil : tag
                            } label: {
                                Text(tag)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(
                                        (selectedTag == nil && tag == "All") || selectedTag == tag
                                            ? Color.blue
                                            : Color.blue.opacity(0.1)
                                    )
                                    .foregroundStyle(
                                        (selectedTag == nil && tag == "All") || selectedTag == tag
                                            ? .white
                                            : .blue
                                    )
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

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
            if !activeFiltered.isEmpty {
                Section("Active (\(activeFiltered.count))") {
                    ForEach(activeFiltered) { subscription in
                        SubscriptionRow(subscription: subscription)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                                    Task { await viewModel.delete(id: subscription.id) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                Button {
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
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
            if !cancelledFiltered.isEmpty {
                Section("Cancelled (\(cancelledFiltered.count))") {
                    ForEach(cancelledFiltered) { subscription in
                        SubscriptionRow(subscription: subscription)
                            .opacity(0.6)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                                    Task { await viewModel.delete(id: subscription.id) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    UINotificationFeedbackGenerator().notificationOccurred(.success)
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
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text(days == 0 ? "Due today" : days == 1 ? "Due tomorrow" : "Due in \(days) days")
                            .font(.caption)
                            .foregroundStyle(days <= 3 ? .orange : .secondary)
                    }
                }

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
