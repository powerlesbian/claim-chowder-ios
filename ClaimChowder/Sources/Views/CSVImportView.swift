import SwiftUI
import UniformTypeIdentifiers

// MARK: - Data Model

private struct ImportRow: Identifiable {
    let id = UUID().uuidString
    let name: String
    let amount: Double
    let currency: CurrencyType
    let frequency: FrequencyType
    let startDate: String   // YYYY-MM-DD
    let cancelled: Bool
    let tags: [String]
    let notes: String?
    let error: String?      // nil = valid row

    var isValid: Bool { error == nil }
}

// MARK: - View

struct CSVImportView: View {
    @ObservedObject var viewModel: SubscriptionViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showingPicker = false
    @State private var rows: [ImportRow] = []
    @State private var selectedIds: Set<String> = []
    @State private var isImporting = false
    @State private var errorMessage: String?
    @State private var fileName: String?

    private var validRows: [ImportRow]    { rows.filter {  $0.isValid } }
    private var invalidRows: [ImportRow]  { rows.filter { !$0.isValid } }

    var body: some View {
        NavigationStack {
            Group {
                if rows.isEmpty {
                    pickFileView
                } else {
                    rowList
                }
            }
            .navigationTitle("Import CSV")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                if !validRows.isEmpty {
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
                allowedContentTypes: [UTType.commaSeparatedText, UTType.plainText],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first { loadCSV(url: url) }
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    // MARK: - Pick file screen

    private var pickFileView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 8)

                Image(systemName: "tablecells")
                    .font(.system(size: 56))
                    .foregroundStyle(.blue)

                Text("Import CSV")
                    .font(.title3)
                    .fontWeight(.semibold)

                // Required columns
                VStack(alignment: .leading, spacing: 12) {
                    Text("Required columns")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    ForEach(requiredColumns, id: \.name) { col in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .frame(width: 18)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(col.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(col.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Divider().padding(.vertical, 4)

                    Text("Optional columns")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    ForEach(optionalColumns, id: \.name) { col in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "circle.dashed")
                                .foregroundStyle(.secondary)
                                .frame(width: 18)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(col.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(col.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    Divider().padding(.vertical, 4)

                    Label("Tip: Export your existing data first to see the exact format expected.", systemImage: "lightbulb")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 24)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Button {
                    showingPicker = true
                } label: {
                    Label("Select CSV File", systemImage: "folder")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 48)

                Spacer().frame(height: 24)
            }
        }
    }

    private struct ColumnInfo { let name: String; let detail: String }

    private let requiredColumns: [ColumnInfo] = [
        ColumnInfo(name: "Name",       detail: "Subscription or expense name. Any text."),
        ColumnInfo(name: "Amount",     detail: "Positive number, e.g. 12.99"),
        ColumnInfo(name: "Currency",   detail: "HKD, SGD, USD, MYR, GBP, CNY or EUR"),
        ColumnInfo(name: "Frequency",  detail: "monthly, yearly, weekly, daily or one-off"),
        ColumnInfo(name: "Start Date", detail: "Date in YYYY-MM-DD format, e.g. 2024-01-15"),
    ]

    private let optionalColumns: [ColumnInfo] = [
        ColumnInfo(name: "Status", detail: "Active or Cancelled. Defaults to Active."),
        ColumnInfo(name: "Tags",   detail: "Semicolon-separated, e.g. Personal;Work"),
        ColumnInfo(name: "Notes",  detail: "Any free text. Created At is ignored."),
    ]

    // MARK: - Row list screen

    private var rowList: some View {
        List {
            Section {
                HStack {
                    if let name = fileName {
                        Label(name, systemImage: "doc.text")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    Text("\(validRows.count) valid · \(invalidRows.count) skipped")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Button {
                    if selectedIds.count == validRows.count {
                        selectedIds.removeAll()
                    } else {
                        selectedIds = Set(validRows.map(\.id))
                    }
                } label: {
                    HStack {
                        Image(systemName: selectedIds.count == validRows.count ? "checkmark.square.fill" : "square")
                        Text(selectedIds.count == validRows.count ? "Deselect All" : "Select All")
                    }
                    .font(.subheadline)
                }
            }

            if !validRows.isEmpty {
                Section("Ready to import (\(validRows.count))") {
                    ForEach(validRows) { row in
                        Button {
                            if selectedIds.contains(row.id) {
                                selectedIds.remove(row.id)
                            } else {
                                selectedIds.insert(row.id)
                            }
                        } label: {
                            ImportRowView(row: row, isSelected: selectedIds.contains(row.id))
                        }
                    }
                }
            }

            if !invalidRows.isEmpty {
                Section("Skipped — fix and re-import (\(invalidRows.count))") {
                    ForEach(invalidRows) { row in
                        ImportRowView(row: row, isSelected: false)
                    }
                }
            }
        }
    }

    // MARK: - Load & parse

    private func loadCSV(url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            errorMessage = "Unable to access the file. Try moving it to Files first."
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            fileName = url.lastPathComponent
            let parsed = parseCSV(content)
            rows = parsed
            selectedIds = Set(parsed.filter { $0.isValid }.map(\.id))
            if parsed.isEmpty {
                errorMessage = "No rows found. Make sure the file has a header row and at least one data row."
            }
        } catch {
            errorMessage = "Could not read file: \(error.localizedDescription)"
        }
    }

    private func parseCSV(_ content: String) -> [ImportRow] {
        let normalized = content
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        let lines = normalized
            .components(separatedBy: "\n")
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        guard lines.count > 1 else { return [] }

        let header = parseCSVLine(lines[0])
            .map { $0.lowercased().trimmingCharacters(in: .whitespaces) }

        return lines.dropFirst().compactMap { line in
            var dict: [String: String] = [:]
            let fields = parseCSVLine(line)
            for (i, col) in header.enumerated() {
                dict[col] = i < fields.count ? fields[i].trimmingCharacters(in: .whitespaces) : ""
            }
            return makeRow(from: dict)
        }
    }

    private func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false

        for char in line {
            switch (char, inQuotes) {
            case ("\"", _):
                inQuotes.toggle()
            case (",", false):
                fields.append(current)
                current = ""
            default:
                current.append(char)
            }
        }
        fields.append(current)
        return fields
    }

    private func makeRow(from dict: [String: String]) -> ImportRow {
        // Name
        let name = dict["name"] ?? ""
        guard !name.isEmpty else {
            return .invalid(name: "—", error: "Missing name")
        }

        // Amount
        let amountStr = dict["amount"] ?? ""
        guard let amount = Double(amountStr), amount > 0 else {
            return .invalid(name: name, error: "Invalid amount: \"\(amountStr)\"")
        }

        // Currency
        let currencyStr = (dict["currency"] ?? "").uppercased()
        guard let currency = CurrencyType(rawValue: currencyStr) else {
            return .invalid(name: name, error: "Invalid currency: \"\(currencyStr)\". Use HKD, SGD, USD, MYR, GBP, CNY or EUR.")
        }

        // Frequency
        let freqStr = (dict["frequency"] ?? "").lowercased()
        guard let frequency = FrequencyType(rawValue: freqStr) else {
            return .invalid(name: name, error: "Invalid frequency: \"\(freqStr)\". Use monthly, yearly, weekly, daily or one-off.")
        }

        // Start Date
        let startDate = dict["start date"] ?? dict["start_date"] ?? dict["startdate"] ?? ""
        guard !startDate.isEmpty, isValidDate(startDate) else {
            return .invalid(name: name, error: "Invalid start date: \"\(startDate)\". Use YYYY-MM-DD.")
        }

        // Optional: Status
        let statusStr = (dict["status"] ?? "active").lowercased()
        let cancelled = statusStr == "cancelled" || statusStr == "canceled"

        // Optional: Tags
        let tagsRaw = dict["tags"] ?? ""
        let tags = tagsRaw.isEmpty ? [] : tagsRaw
            .components(separatedBy: ";")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        // Optional: Notes
        let notes: String? = {
            let n = dict["notes"] ?? ""
            return n.isEmpty ? nil : n
        }()

        return ImportRow(
            name: name,
            amount: amount,
            currency: currency,
            frequency: frequency,
            startDate: startDate,
            cancelled: cancelled,
            tags: tags,
            notes: notes,
            error: nil
        )
    }

    private func isValidDate(_ str: String) -> Bool {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        return fmt.date(from: str) != nil
    }

    // MARK: - Import

    private func importSelected() async {
        isImporting = true
        let toImport = validRows.filter { selectedIds.contains($0.id) }

        guard let userId = try? await supabase.auth.session.user.id.uuidString else {
            isImporting = false
            return
        }

        for row in toImport {
            let insert = SubscriptionInsert(
                userId: userId,
                name: row.name,
                amount: row.amount,
                currency: row.currency,
                startDate: row.startDate + "T00:00:00.000Z",
                frequency: row.frequency,
                cancelled: row.cancelled,
                cancelledDate: nil,
                notes: row.notes,
                tags: row.tags.isEmpty ? ["Personal"] : row.tags
            )
            do {
                let newSub = try await SubscriptionService.shared.addSubscription(insert)
                await MainActor.run {
                    viewModel.subscriptions.insert(newSub, at: 0)
                }
            } catch {
                // Continue with remaining rows
            }
        }

        isImporting = false
        dismiss()
    }
}

// MARK: - Row view

private struct ImportRowView: View {
    let row: ImportRow
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            if row.isValid {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? .blue : .secondary)
            } else {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.red)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(row.name)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if let error = row.error {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                } else {
                    HStack(spacing: 6) {
                        Text(row.frequency.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if !row.tags.isEmpty {
                            Text("·")
                                .foregroundStyle(.tertiary)
                            Text(row.tags.joined(separator: ", "))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }

            Spacer()

            if row.isValid {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(CurrencyType.format(row.amount, currency: row.currency))
                        .font(.body)
                        .fontWeight(.medium)
                    Text(row.startDate)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .opacity(row.isValid ? 1.0 : 0.5)
    }
}

// MARK: - ImportRow helpers

private extension ImportRow {
    static func invalid(name: String, error: String) -> ImportRow {
        ImportRow(name: name, amount: 0, currency: .HKD, frequency: .monthly,
                  startDate: "", cancelled: false, tags: [], notes: nil, error: error)
    }
}
