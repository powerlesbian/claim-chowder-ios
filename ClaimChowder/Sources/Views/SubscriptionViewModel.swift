import Foundation

@MainActor
class SubscriptionViewModel: ObservableObject {
    @Published var subscriptions: [Subscription] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service = SubscriptionService.shared

    var activeSubscriptions: [Subscription] {
        subscriptions.filter { !$0.cancelled }
    }

    var cancelledSubscriptions: [Subscription] {
        subscriptions.filter { $0.cancelled }
    }

    var activeCount: Int {
        activeSubscriptions.count
    }

    var monthlyTotal: Double {
        activeSubscriptions.reduce(0) { $0 + $1.monthlyAmount }
    }

    var formattedMonthlyTotal: String {
        // Use HKD as default display currency
        let formatted = String(format: "%.2f", monthlyTotal)
        return "HK$\(formatted)"
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            subscriptions = try await service.loadSubscriptions()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func add(
        name: String,
        amount: Double,
        currency: CurrencyType,
        startDate: Date,
        frequency: FrequencyType,
        notes: String?,
        tags: [String]
    ) async {
        guard let userId = try? await supabase.auth.session.user.id.uuidString else { return }

        let insert = SubscriptionInsert(
            userId: userId,
            name: name,
            amount: amount,
            currency: currency,
            startDate: ISO8601DateFormatter().string(from: startDate),
            frequency: frequency,
            cancelled: false,
            cancelledDate: nil,
            notes: notes?.isEmpty == true ? nil : notes,
            tags: tags.isEmpty ? ["Personal"] : tags
        )

        do {
            let newSubscription = try await service.addSubscription(insert)
            subscriptions.insert(newSubscription, at: 0)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func update(id: String, name: String, amount: Double, currency: CurrencyType, startDate: Date, frequency: FrequencyType, notes: String?, tags: [String]) async {
        let updates = SubscriptionUpdate(
            name: name,
            amount: amount,
            currency: currency,
            startDate: ISO8601DateFormatter().string(from: startDate),
            frequency: frequency,
            notes: notes?.isEmpty == true ? nil : notes,
            tags: tags.isEmpty ? ["Personal"] : tags
        )

        do {
            try await service.updateSubscription(id: id, updates: updates)
            if let index = subscriptions.firstIndex(where: { $0.id == id }) {
                subscriptions[index].name = name
                subscriptions[index].amount = amount
                subscriptions[index].currency = currency
                subscriptions[index].startDate = ISO8601DateFormatter().string(from: startDate)
                subscriptions[index].frequency = frequency
                subscriptions[index].notes = notes
                subscriptions[index].tags = tags
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(id: String) async {
        do {
            try await service.deleteSubscription(id: id)
            subscriptions.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteMany(ids: Set<String>) async {
        do {
            try await service.deleteManySubscriptions(ids: Array(ids))
            subscriptions.removeAll { ids.contains($0.id) }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleCancelled(id: String, cancelled: Bool) async {
        do {
            try await service.toggleCancelled(id: id, cancelled: cancelled)
            if let index = subscriptions.firstIndex(where: { $0.id == id }) {
                subscriptions[index].cancelled = cancelled
                subscriptions[index].cancelledDate = cancelled ? ISO8601DateFormatter().string(from: Date()) : nil
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
