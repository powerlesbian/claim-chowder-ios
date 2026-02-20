import Foundation
import Supabase

final class SubscriptionService: Sendable {
    static let shared = SubscriptionService()
    private init() {}

    func loadSubscriptions() async throws -> [Subscription] {
        let response: [Subscription] = try await supabase
            .from("subscriptions")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
        return response
    }

    func addSubscription(_ insert: SubscriptionInsert) async throws -> Subscription {
        let response: Subscription = try await supabase
            .from("subscriptions")
            .insert(insert)
            .select()
            .single()
            .execute()
            .value
        return response
    }

    func updateSubscription(id: String, updates: SubscriptionUpdate) async throws {
        try await supabase
            .from("subscriptions")
            .update(updates)
            .eq("id", value: id)
            .execute()
    }

    func deleteSubscription(id: String) async throws {
        try await supabase
            .from("subscriptions")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    func deleteManySubscriptions(ids: [String]) async throws {
        try await supabase
            .from("subscriptions")
            .delete()
            .in("id", value: ids)
            .execute()
    }

    func toggleCancelled(id: String, cancelled: Bool) async throws {
        let updates = SubscriptionUpdate(
            cancelled: cancelled,
            cancelledDate: cancelled ? ISO8601DateFormatter().string(from: Date()) : nil
        )
        try await updateSubscription(id: id, updates: updates)
    }
}
