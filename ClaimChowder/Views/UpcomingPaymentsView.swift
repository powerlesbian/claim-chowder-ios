import SwiftUI

struct UpcomingPayment: Identifiable {
    var id: String { subscription.id }
    let subscription: Subscription
    let nextPaymentDate: Date
    let daysUntil: Int
}

struct UpcomingPaymentsView: View {
    @ObservedObject var viewModel: SubscriptionViewModel

    private var payments: [UpcomingPayment] {
        viewModel.activeSubscriptions
            .compactMap { sub -> UpcomingPayment? in
                guard let next = sub.nextPaymentDate,
                      let days = sub.daysUntilNextPayment else { return nil }
                return UpcomingPayment(subscription: sub, nextPaymentDate: next, daysUntil: days)
            }
            .sorted { $0.daysUntil < $1.daysUntil }
    }

    private var dueToday: [UpcomingPayment] { payments.filter { $0.daysUntil == 0 } }
    private var thisWeek: [UpcomingPayment] { payments.filter { $0.daysUntil > 0 && $0.daysUntil <= 7 } }
    private var later: [UpcomingPayment] { payments.filter { $0.daysUntil > 7 } }

    var body: some View {
        ScrollView {
            if payments.isEmpty {
                ContentUnavailableView {
                    Label("No Upcoming Payments", systemImage: "calendar")
                } description: {
                    Text("Add active recurring subscriptions to see payment reminders")
                }
                .padding(.top, 60)
            } else {
                VStack(spacing: 16) {
                    if !dueToday.isEmpty {
                        PaymentSection(
                            title: "Due Today",
                            icon: "bell.fill",
                            payments: dueToday,
                            backgroundColor: .red.opacity(0.08),
                            borderColor: .red.opacity(0.2),
                            accentColor: .red
                        )
                    }

                    if !thisWeek.isEmpty {
                        PaymentSection(
                            title: "This Week",
                            icon: "calendar",
                            payments: thisWeek,
                            backgroundColor: .orange.opacity(0.08),
                            borderColor: .orange.opacity(0.2),
                            accentColor: .orange
                        )
                    }

                    if !later.isEmpty {
                        PaymentSection(
                            title: "Later",
                            icon: "calendar.badge.clock",
                            payments: Array(later.prefix(10)),
                            backgroundColor: Color(.systemBackground),
                            borderColor: .secondary.opacity(0.2),
                            accentColor: .secondary
                        )
                    }
                }
                .padding()
            }
        }
    }
}

struct PaymentSection: View {
    let title: String
    let icon: String
    let payments: [UpcomingPayment]
    let backgroundColor: Color
    let borderColor: Color
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundStyle(accentColor)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(accentColor == .secondary ? .primary : accentColor)
            }
            .padding(.bottom, 2)

            ForEach(payments) { payment in
                PaymentRow(payment: payment)
                if payment.id != payments.last?.id {
                    Divider()
                }
            }
        }
        .padding()
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: 1)
        )
    }
}

struct PaymentRow: View {
    let payment: UpcomingPayment

    private var daysText: String {
        switch payment.daysUntil {
        case 0: return "Today"
        case 1: return "Tomorrow"
        default: return "In \(payment.daysUntil) days"
        }
    }

    private var dateText: String {
        payment.nextPaymentDate.formatted(.dateTime.month(.abbreviated).day())
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(payment.subscription.name)
                    .font(.body)
                    .fontWeight(.medium)
                Text(dateText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(payment.subscription.formattedAmount)
                    .font(.body)
                    .fontWeight(.semibold)
                Text(daysText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
