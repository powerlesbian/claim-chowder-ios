import Foundation

enum FrequencyType: String, Codable, CaseIterable {
    case daily
    case weekly
    case monthly
    case yearly
    case oneOff = "one-off"

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        case .oneOff: return "One-off"
        }
    }

    var monthlyMultiplier: Double {
        switch self {
        case .daily: return 30.0
        case .weekly: return 4.33
        case .monthly: return 1.0
        case .yearly: return 1.0 / 12.0
        case .oneOff: return 0.0
        }
    }
}

enum CurrencyType: String, Codable, CaseIterable {
    case HKD
    case SGD
    case USD

    var symbol: String {
        switch self {
        case .HKD: return "HK$"
        case .SGD: return "S$"
        case .USD: return "US$"
        }
    }
}

struct Subscription: Codable, Identifiable {
    let id: String
    let userId: String
    var name: String
    var amount: Double
    var currency: CurrencyType
    var startDate: String
    var frequency: FrequencyType
    var cancelled: Bool
    var cancelledDate: String?
    var notes: String?
    var screenshot: String?
    var tags: [String]?
    let createdAt: String
    var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case amount
        case currency
        case startDate = "start_date"
        case frequency
        case cancelled
        case cancelledDate = "cancelled_date"
        case notes
        case screenshot
        case tags
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    var monthlyAmount: Double {
        amount * frequency.monthlyMultiplier
    }

    var formattedAmount: String {
        let formatted = String(format: "%.2f", amount)
        return "\(currency.symbol)\(formatted)"
    }

    var nextPaymentDate: Date? {
        guard frequency != .oneOff else { return nil }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let start = formatter.date(from: startDate) ?? ISO8601DateFormatter().date(from: startDate) else {
            return nil
        }

        let today = Calendar.current.startOfDay(for: Date())
        var next = start

        while next < today {
            switch frequency {
            case .daily:
                next = Calendar.current.date(byAdding: .day, value: 1, to: next)!
            case .weekly:
                next = Calendar.current.date(byAdding: .day, value: 7, to: next)!
            case .monthly:
                next = Calendar.current.date(byAdding: .month, value: 1, to: next)!
            case .yearly:
                next = Calendar.current.date(byAdding: .year, value: 1, to: next)!
            case .oneOff:
                return nil
            }
        }

        return next
    }

    var daysUntilNextPayment: Int? {
        guard let next = nextPaymentDate else { return nil }
        let today = Calendar.current.startOfDay(for: Date())
        return Calendar.current.dateComponents([.day], from: today, to: next).day
    }
}

struct SubscriptionInsert: Codable {
    let userId: String
    var name: String
    var amount: Double
    var currency: CurrencyType
    var startDate: String
    var frequency: FrequencyType
    var cancelled: Bool
    var cancelledDate: String?
    var notes: String?
    var tags: [String]

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case name
        case amount
        case currency
        case startDate = "start_date"
        case frequency
        case cancelled
        case cancelledDate = "cancelled_date"
        case notes
        case tags
    }
}

struct SubscriptionUpdate: Codable {
    var name: String?
    var amount: Double?
    var currency: CurrencyType?
    var startDate: String?
    var frequency: FrequencyType?
    var cancelled: Bool?
    var cancelledDate: String?
    var notes: String?
    var tags: [String]?

    enum CodingKeys: String, CodingKey {
        case name
        case amount
        case currency
        case startDate = "start_date"
        case frequency
        case cancelled
        case cancelledDate = "cancelled_date"
        case notes
        case tags
    }
}
