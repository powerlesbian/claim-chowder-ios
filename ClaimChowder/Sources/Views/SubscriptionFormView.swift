import SwiftUI

struct SubscriptionFormView: View {
    @ObservedObject var viewModel: SubscriptionViewModel
    @Environment(\.dismiss) private var dismiss

    let editing: Subscription?

    @State private var name: String
    @State private var amount: String
    @State private var currency: CurrencyType
    @State private var startDate: Date
    @State private var frequency: FrequencyType
    @State private var notes: String
    @State private var selectedTags: Set<String>
    @State private var isSaving = false

    private let availableTags = ["Personal", "Business"]

    init(viewModel: SubscriptionViewModel, editing: Subscription? = nil) {
        self.viewModel = viewModel
        self.editing = editing

        _name = State(initialValue: editing?.name ?? "")
        _amount = State(initialValue: editing.map { String(format: "%.2f", $0.amount) } ?? "")
        _currency = State(initialValue: editing?.currency ?? .HKD)
        _frequency = State(initialValue: editing?.frequency ?? .monthly)
        _notes = State(initialValue: editing?.notes ?? "")
        _selectedTags = State(initialValue: Set(editing?.tags ?? ["Personal"]))

        if let editing, let date = ISO8601DateFormatter().date(from: editing.startDate) {
            _startDate = State(initialValue: date)
        } else {
            _startDate = State(initialValue: Date())
        }
    }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && Double(amount) != nil && Double(amount)! > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Name", text: $name)
                        .textInputAutocapitalization(.words)

                    HStack {
                        Picker("Currency", selection: $currency) {
                            ForEach(CurrencyType.allCases, id: \.self) { curr in
                                Text(curr.symbol).tag(curr)
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)

                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                    }

                    Picker("Frequency", selection: $frequency) {
                        ForEach(FrequencyType.allCases, id: \.self) { freq in
                            Text(freq.displayName).tag(freq)
                        }
                    }

                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                }

                Section("Tags") {
                    ForEach(availableTags, id: \.self) { tag in
                        Button {
                            if selectedTags.contains(tag) {
                                selectedTags.remove(tag)
                            } else {
                                selectedTags.insert(tag)
                            }
                        } label: {
                            HStack {
                                Text(tag)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedTags.contains(tag) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(editing != nil ? "Edit Subscription" : "Add Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(editing != nil ? "Save" : "Add") {
                        Task { await save() }
                    }
                    .disabled(!isValid || isSaving)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func save() async {
        guard let amountValue = Double(amount) else { return }
        isSaving = true

        if let editing {
            await viewModel.update(
                id: editing.id,
                name: name.trimmingCharacters(in: .whitespaces),
                amount: amountValue,
                currency: currency,
                startDate: startDate,
                frequency: frequency,
                notes: notes.isEmpty ? nil : notes,
                tags: Array(selectedTags)
            )
        } else {
            await viewModel.add(
                name: name.trimmingCharacters(in: .whitespaces),
                amount: amountValue,
                currency: currency,
                startDate: startDate,
                frequency: frequency,
                notes: notes.isEmpty ? nil : notes,
                tags: Array(selectedTags)
            )
        }

        UINotificationFeedbackGenerator().notificationOccurred(.success)
        isSaving = false
        dismiss()
    }
}
