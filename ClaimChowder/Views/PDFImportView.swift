import SwiftUI
import UniformTypeIdentifiers

struct PDFImportView: View {
    @ObservedObject var viewModel: SubscriptionViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingPicker = false
    @State private var transactions: [ParsedTransaction] = []
    @State private var selectedIds: Set<String> = []
    @State private var isLoading = false
    @State private var isImporting = false
    @State private var errorMessage: String?
    @State private var bankDetected: String?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Parsing statement...")
                            .foregroundStyle(.secondary)
                    }
                } else if transactions.isEmpty {
                    pickFileView
                } else {
                    transactionList
                }
            }
            .navigationTitle("Import Statement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                if !transactions.isEmpty {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Import (\(selectedIds.count))") {
                            Task { await importSelected() }
                        }
                        .disabled(selectedIds.isEmpty || isImporting)
                        .fontWeight(.semibold)
                    }
                }
            }
            .fileImporter(
                isPresented: $showingPicker,
                allowedContentTypes: [UTType.pdf],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        Task { await parsePDF(url: url) }
                    }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private var pickFileView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 56))
                .foregroundStyle(.blue)

            Text("Import Bank Statement")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Select a PDF bank statement to extract transactions.\nSupports AMEX and Hang Seng.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 32)
            }

            Button {
                showingPicker = true
            } label: {
                Label("Select PDF", systemImage: "folder")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 48)

            Spacer()
            Spacer()
        }
    }

    private var transactionList: some View {
        List {
            Section {
                HStack {
                    if let bank = bankDetected {
                        Label(bank, systemImage: "building.columns")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(transactions.count) transactions found")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Button {
                    if selectedIds.count == transactions.count {
                        selectedIds.removeAll()
                    } else {
                        selectedIds = Set(transactions.map(\.id))
                    }
                } label: {
                    HStack {
                        Image(systemName: selectedIds.count == transactions.count ? "checkmark.square.fill" : "square")
                        Text(selectedIds.count == transactions.count ? "Deselect All" : "Select All")
                    }
                    .font(.subheadline)
                }
            }

            Section("Transactions") {
                ForEach(transactions) { tx in
                    Button {
                        if selectedIds.contains(tx.id) {
                            selectedIds.remove(tx.id)
                        } else {
                            selectedIds.insert(tx.id)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: selectedIds.contains(tx.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selectedIds.contains(tx.id) ? .blue : .secondary)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(tx.description)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)
                                Text(tx.date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text(CurrencyType.format(tx.amount, currency: .HKD))
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
        }
    }

    private func parsePDF(url: URL) async {
        isLoading = true
        errorMessage = nil

        guard url.startAccessingSecurityScopedResource() else {
            errorMessage = "Unable to access file"
            isLoading = false
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let result = try PDFParser.parse(url: url)
            transactions = result.transactions
            bankDetected = result.bankName
            selectedIds = Set(transactions.map(\.id))
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func importSelected() async {
        isImporting = true

        let selected = transactions.filter { selectedIds.contains($0.id) }
        let subscriptionData: [SubscriptionInsert] = await {
            guard let userId = try? await supabase.auth.session.user.id.uuidString else { return [] }
            return selected.map { tx in
                SubscriptionInsert(
                    userId: userId,
                    name: tx.description,
                    amount: tx.amount,
                    currency: .HKD,
                    startDate: tx.date + "T00:00:00.000Z",
                    frequency: .oneOff,
                    cancelled: false,
                    cancelledDate: nil,
                    notes: nil,
                    tags: ["Personal"]
                )
            }
        }()

        for insert in subscriptionData {
            do {
                let newSub = try await SubscriptionService.shared.addSubscription(insert)
                await MainActor.run {
                    viewModel.subscriptions.insert(newSub, at: 0)
                }
            } catch {
                // Continue importing rest even if one fails
            }
        }

        isImporting = false
        dismiss()
    }
}
