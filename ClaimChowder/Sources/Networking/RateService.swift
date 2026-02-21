import Foundation

/// Fetches and caches USD-based exchange rates from open.er-api.com (free, no API key).
/// All conversions go via USD as the base: amount * (toRate / fromRate).
@MainActor
final class RateService {
    static let shared = RateService()

    // Cache TTL: refresh rates every 4 hours
    private let cacheTTL: TimeInterval = 4 * 60 * 60
    private let cacheKey = "cached_exchange_rates"
    private let cacheTimeKey = "cached_exchange_rates_time"

    // Fallback rates (1 USD = X units of currency)
    static let fallbackRates: [String: Double] = [
        "USD": 1.0,
        "HKD": 7.80,
        "SGD": 1.35,
        "MYR": 4.48,
        "GBP": 0.79,
        "CNY": 7.28,
        "EUR": 0.93
    ]

    private(set) var rates: [String: Double] = RateService.fallbackRates

    private init() {
        if let cached = UserDefaults.standard.dictionary(forKey: cacheKey) as? [String: Double],
           !cached.isEmpty {
            rates = cached
        }
    }

    func fetch() async {
        let lastFetch = UserDefaults.standard.double(forKey: cacheTimeKey)
        let now = Date().timeIntervalSince1970
        guard now - lastFetch > cacheTTL else { return }

        guard let url = URL(string: "https://open.er-api.com/v6/latest/USD") else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(ExchangeRateResponse.self, from: data)
            guard response.result == "success" else { return }
            rates = response.rates
            UserDefaults.standard.set(response.rates, forKey: cacheKey)
            UserDefaults.standard.set(now, forKey: cacheTimeKey)
        } catch {
            // Silently keep cached or fallback rates
        }
    }

    func convert(_ amount: Double, from: String, to: String) -> Double {
        guard from != to else { return amount }
        let fromRate = rates[from] ?? 1.0
        let toRate = rates[to] ?? 1.0
        return amount * (toRate / fromRate)
    }
}

private struct ExchangeRateResponse: Codable {
    let result: String
    let rates: [String: Double]
}
