import SwiftUI
import UIKit

enum SortOption: String, CaseIterable {
    case nameAZ = "Name (A–Z)"
    case amountHigh = "Amount (High–Low)"
    case dueSoon = "Due Soon"
    case dateAdded = "Date Added (Newest)"
}

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
    @State private var sortOrder: SortOption = .nameAZ
    @State private var isSelecting = false
    @State private var selectedIDs = Set<String>()
    @State private var showingDeleteConfirm = false
    private var csvExportURL: URL? { buildCSV() }

    private var availableTags: [String] {
        let used = viewModel.subscriptions.compactMap { $0.tags }.flatMap { $0 }
        let sorted = Array(Set(used)).sorted()
        return ["All"] + sorted
    }

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

        // Sort
        result.sort { a, b in
            switch sortOrder {
            case .nameAZ:
                return a.name.localizedCompare(b.name) == .orderedAscending
            case .amountHigh:
                return a.currency.convert(a.amount, to: .HKD) > b.currency.convert(b.amount, to: .HKD)
            case .dueSoon:
                switch (a.daysUntilNextPayment, b.daysUntilNextPayment) {
                case (let x?, let y?): return x < y
                case (nil, _?):        return false
                case (_?, nil):        return true
                case (nil, nil):       return false
                }
            case .dateAdded:
                return a.createdAt > b.createdAt
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

    private var selectionTotal: Double {
        filteredSubscriptions
            .filter { selectedIDs.contains($0.id) }
            .reduce(0) { $0 + $1.currency.convert($1.amount, to: .HKD) }
    }

    private func buildCSV() -> URL? {
        var lines = ["Name,Amount,Currency,Frequency,Start Date,Status,Tags,Notes,Created At"]
        for sub in viewModel.subscriptions {
            let fields = [
                csvEscape(sub.name),
                String(format: "%.2f", sub.amount),
                sub.currency.rawValue,
                sub.frequency.rawValue,
                String(sub.startDate.prefix(10)),
                sub.cancelled ? "Cancelled" : "Active",
                csvEscape(sub.tags?.joined(separator: ";") ?? ""),
                csvEscape(sub.notes ?? ""),
                String(sub.createdAt.prefix(10))
            ]
            lines.append(fields.joined(separator: ","))
        }
        let csv = lines.joined(separator: "\n")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("claim_chowder_export.csv")
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            return nil
        }
    }

    private func csvEscape(_ value: String) -> String {
        guard value.contains(",") || value.contains("\"") || value.contains("\n") else {
            return value
        }
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
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
                if isSelecting {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(selectedIDs.count == filteredSubscriptions.count ? "Deselect All" : "Select All") {
                            if selectedIDs.count == filteredSubscriptions.count {
                                selectedIDs.removeAll()
                            } else {
                                selectedIDs = Set(filteredSubscriptions.map { $0.id })
                            }
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            isSelecting = false
                            selectedIDs.removeAll()
                        }
                    }
                } else {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showingProfile = true
                        } label: {
                            Image(systemName: "person.circle")
                        }
                    }
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button("Select") {
                            isSelecting = true
                        }
                        Menu {
                            Picker("Sort by", selection: $sortOrder) {
                                ForEach(SortOption.allCases, id: \.self) { option in
                                    Text(option.rawValue).tag(option)
                                }
                            }
                        } label: {
                            Image(systemName: "arrow.up.arrow.down")
                        }
                        Menu {
                            Button {
                                showingImport = true
                            } label: {
                                Label("Import PDF", systemImage: "doc.text")
                            }
                            if let url = csvExportURL {
                                ShareLink(item: url, preview: SharePreview("claim_chowder_export.csv", image: Image(systemName: "tablecells"))) {
                                    Label("Export CSV", systemImage: "square.and.arrow.up")
                                }
                            }
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
            .confirmationDialog(
                "Delete \(selectedIDs.count) subscription\(selectedIDs.count == 1 ? "" : "s")?",
                isPresented: $showingDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                    Task {
                        await viewModel.deleteMany(ids: selectedIDs)
                        isSelecting = false
                        selectedIDs.removeAll()
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No expenses yet", systemImage: "doc.text")
        } description: {
            Text("Add your first expense manually, or import a bank statement PDF to get started quickly.")
        } actions: {
            Button("Add Expense") {
                showingAddForm = true
            }
            .buttonStyle(.borderedProminent)
            Button("Import PDF") {
                showingImport = true
            }
            .buttonStyle(.bordered)
        }
    }

    private var subscriptionList: some View {
        List(selection: $selectedIDs) {
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
                        Button {
                            guard !isSelecting else { return }
                            editingSubscription = subscription
                        } label: {
                            SubscriptionRow(subscription: subscription)
                        }
                        .buttonStyle(.plain)
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
        .environment(\.editMode, .constant(isSelecting ? .active : .inactive))
        .safeAreaInset(edge: .bottom) {
            if isSelecting && !selectedIDs.isEmpty {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(selectedIDs.count) selected")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("HK$\(String(format: "%.2f", selectionTotal))")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    Spacer()
                    Button(role: .destructive) {
                        showingDeleteConfirm = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(.regularMaterial)
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

