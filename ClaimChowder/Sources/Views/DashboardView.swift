import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: SubscriptionViewModel
    @Binding var displayCurrency: CurrencyType
    @EnvironmentObject var authManager: AuthManager

    private var active: [Subscription] {
        viewModel.activeSubscriptions
    }

    // MARK: - Card metrics

    private var topCategory: (name: String, total: Double)? {
        var totals: [String: Double] = [:]
        for sub in active {
            let tag = sub.tags?.first ?? "Other"
            totals[tag, default: 0] += sub.currency.convert(sub.amount, to: displayCurrency)
        }
        return totals.max(by: { $0.value < $1.value }).map { ($0.key, $0.value) }
    }

    private var topPayee: (name: String, total: Double)? {
        var totals: [String: Double] = [:]
        for sub in active {
            totals[sub.name, default: 0] += sub.currency.convert(sub.amount, to: displayCurrency)
        }
        return totals.max(by: { $0.value < $1.value }).map { ($0.key, $0.value) }
    }

    private var recurringTotal: Double {
        active
            .filter { $0.frequency != .oneOff }
            .reduce(0) { $0 + $1.currency.convert($1.monthlyAmount, to: displayCurrency) }
    }

    private var oneOffThisMonth: Double {
        let now = Date()
        let cal = Calendar.current
        return active
            .filter { sub in
                guard sub.frequency == .oneOff else { return false }
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                guard let date = formatter.date(from: sub.startDate) ?? ISO8601DateFormatter().date(from: sub.startDate) else { return false }
                return cal.isDate(date, equalTo: now, toGranularity: .month)
            }
            .reduce(0) { $0 + $1.currency.convert($1.amount, to: displayCurrency) }
    }

    // MARK: - Greeting

    private var firstName: String {
        authManager.session?.user.email?
            .components(separatedBy: "@").first?
            .components(separatedBy: ".").first?
            .capitalized ?? "there"
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeGreet: String
        switch hour {
        case 0..<12: timeGreet = "Good morning"
        case 12..<17: timeGreet = "Good afternoon"
        default:     timeGreet = "Good evening"
        }
        return "\(timeGreet), \(firstName)"
    }

    // MARK: - Stat pill metrics

    private var currenciesInUse: Int {
        Set(active.map { $0.currency }).count
    }

    private var paymentsThisWeek: Int {
        active.filter { ($0.daysUntilNextPayment ?? Int.max) <= 7 }.count
    }

    private var avgMonthlyPerSub: String {
        let recurring = active.filter { $0.frequency != .oneOff }
        guard !recurring.isEmpty else { return CurrencyType.format(0, currency: displayCurrency) }
        return CurrencyType.format(recurringTotal / Double(recurring.count), currency: displayCurrency)
    }

    // MARK: - Detail drill-down subscriptions

    private var topCategorySubscriptions: [Subscription] {
        guard let name = topCategory?.name else { return [] }
        return active.filter { $0.tags?.contains(name) == true }
    }

    private var topPayeeSubscriptions: [Subscription] {
        guard let name = topPayee?.name else { return [] }
        return active.filter { $0.name == name }
    }

    private var recurringSubscriptions: [Subscription] {
        active.filter { $0.frequency != .oneOff }
    }

    private var oneOffThisMonthSubscriptions: [Subscription] {
        let now = Date()
        let cal = Calendar.current
        return active.filter { sub in
            guard sub.frequency == .oneOff else { return false }
            let fmt = ISO8601DateFormatter()
            fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            guard let date = fmt.date(from: sub.startDate) ?? ISO8601DateFormatter().date(from: sub.startDate) else { return false }
            return cal.isDate(date, equalTo: now, toGranularity: .month)
        }
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header: greeting + currency picker
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(greeting)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Here's your spending overview")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Picker("Currency", selection: $displayCurrency) {
                        ForEach(CurrencyType.allCases, id: \.self) { c in
                            Text("\(c.symbol) \(c.rawValue)").tag(c)
                        }
                    }
                    .pickerStyle(.menu)
                }
                .padding(.horizontal)

                // Cards grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    NavigationLink {
                        SubscriptionDetailListView(
                            title: "Top Category",
                            subscriptions: topCategorySubscriptions,
                            displayCurrency: displayCurrency
                        )
                    } label: {
                        DashboardCard(
                            icon: "tag.fill",
                            iconColor: .purple,
                            label: "Top Category",
                            value: topCategory?.name ?? "N/A",
                            subValue: topCategory.map { CurrencyType.format($0.total, currency: displayCurrency) } ?? ""
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        SubscriptionDetailListView(
                            title: "Biggest Payee",
                            subscriptions: topPayeeSubscriptions,
                            displayCurrency: displayCurrency
                        )
                    } label: {
                        DashboardCard(
                            icon: "arrow.up.right",
                            iconColor: .red,
                            label: "Biggest Payee",
                            value: {
                                guard let name = topPayee?.name else { return "N/A" }
                                return name.count > 12 ? String(name.prefix(12)) + "..." : name
                            }(),
                            subValue: topPayee.map { CurrencyType.format($0.total, currency: displayCurrency) } ?? ""
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        SubscriptionDetailListView(
                            title: "Recurring",
                            subscriptions: recurringSubscriptions,
                            displayCurrency: displayCurrency
                        )
                    } label: {
                        DashboardCard(
                            icon: "repeat",
                            iconColor: .blue,
                            label: "Recurring",
                            value: CurrencyType.format(recurringTotal, currency: displayCurrency),
                            subValue: "per month"
                        )
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        SubscriptionDetailListView(
                            title: "One-off This Month",
                            subscriptions: oneOffThisMonthSubscriptions,
                            displayCurrency: displayCurrency
                        )
                    } label: {
                        DashboardCard(
                            icon: "creditcard.fill",
                            iconColor: .green,
                            label: "One-off",
                            value: CurrencyType.format(oneOffThisMonth, currency: displayCurrency),
                            subValue: "this month"
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)

                // Quick stats
                HStack(spacing: 16) {
                    StatPill(label: "Currencies", value: "\(currenciesInUse)", color: .blue)
                    StatPill(label: "Due This Week", value: "\(paymentsThisWeek)", color: .green)
                    StatPill(label: "Avg/Month", value: avgMonthlyPerSub, color: .orange)
                }
                .padding(.horizontal)
            }
            .padding(.top)
        }
    }
}

struct DashboardCard: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String
    let subValue: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(iconColor)
                    .frame(width: 32, height: 32)
                    .background(iconColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if !subValue.isEmpty {
                Text(subValue)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.quaternary, lineWidth: 1)
        )
    }
}

struct StatPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(.quaternary, lineWidth: 1)
        )
    }
}

private struct SubscriptionDetailListView: View {
    let title: String
    let subscriptions: [Subscription]
    let displayCurrency: CurrencyType

    private var monthlyTotal: Double {
        subscriptions.reduce(0) { $0 + $1.currency.convert($1.monthlyAmount, to: displayCurrency) }
    }

    var body: some View {
        List {
            if !subscriptions.isEmpty {
                Section {
                    HStack {
                        Text("Monthly Total")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(CurrencyType.format(monthlyTotal, currency: displayCurrency))
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                }
            }
            Section("\(subscriptions.count) subscription\(subscriptions.count == 1 ? "" : "s")") {
                if subscriptions.isEmpty {
                    Text("No subscriptions")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(subscriptions) { sub in
                        SubscriptionRow(subscription: sub)
                    }
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
