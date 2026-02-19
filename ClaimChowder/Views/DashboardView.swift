import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: SubscriptionViewModel
    @Binding var displayCurrency: CurrencyType

    private var active: [Subscription] {
        viewModel.activeSubscriptions
    }

    // Top category by total spend
    private var topCategory: (name: String, total: Double)? {
        var totals: [String: Double] = [:]
        for sub in active {
            let tag = sub.tags?.first ?? "Other"
            totals[tag, default: 0] += sub.currency.convert(sub.amount, to: displayCurrency)
        }
        return totals.max(by: { $0.value < $1.value }).map { ($0.key, $0.value) }
    }

    // Biggest payee by total spend
    private var topPayee: (name: String, total: Double)? {
        var totals: [String: Double] = [:]
        for sub in active {
            totals[sub.name, default: 0] += sub.currency.convert(sub.amount, to: displayCurrency)
        }
        return totals.max(by: { $0.value < $1.value }).map { ($0.key, $0.value) }
    }

    // Recurring monthly total
    private var recurringTotal: Double {
        active
            .filter { $0.frequency != .oneOff }
            .reduce(0) { $0 + $1.currency.convert($1.monthlyAmount, to: displayCurrency) }
    }

    // One-off spend this month
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

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Currency picker
                HStack {
                    Text("Dashboard")
                        .font(.title2)
                        .fontWeight(.bold)
                    Spacer()
                    Picker("Currency", selection: $displayCurrency) {
                        ForEach(CurrencyType.allCases, id: \.self) { c in
                            Text(c.rawValue).tag(c)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                }
                .padding(.horizontal)

                // Cards grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    DashboardCard(
                        icon: "tag.fill",
                        iconColor: .purple,
                        label: "Top Category",
                        value: topCategory?.name ?? "N/A",
                        subValue: topCategory.map { CurrencyType.format($0.total, currency: displayCurrency) } ?? ""
                    )
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
                    DashboardCard(
                        icon: "repeat",
                        iconColor: .blue,
                        label: "Recurring",
                        value: CurrencyType.format(recurringTotal, currency: displayCurrency),
                        subValue: "per month"
                    )
                    DashboardCard(
                        icon: "creditcard.fill",
                        iconColor: .green,
                        label: "One-off",
                        value: CurrencyType.format(oneOffThisMonth, currency: displayCurrency),
                        subValue: "this month"
                    )
                }
                .padding(.horizontal)

                // Quick stats
                HStack(spacing: 16) {
                    StatPill(label: "Active", value: "\(viewModel.activeCount)", color: .blue)
                    StatPill(label: "Cancelled", value: "\(viewModel.cancelledSubscriptions.count)", color: .orange)
                    StatPill(label: "Total", value: "\(viewModel.subscriptions.count)", color: .secondary)
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
