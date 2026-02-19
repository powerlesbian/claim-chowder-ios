import Foundation
import PDFKit

struct ParsedTransaction: Identifiable {
    let id: String
    let date: String
    let description: String
    let amount: Double
    let currency: String
    let rawText: String
}

struct PDFParseResult {
    let transactions: [ParsedTransaction]
    let bankName: String?
}

enum PDFParserError: LocalizedError {
    case cannotLoadPDF
    case noTransactionsFound

    var errorDescription: String? {
        switch self {
        case .cannotLoadPDF: return "Unable to read PDF file"
        case .noTransactionsFound: return "No transactions found in this statement"
        }
    }
}

enum BankType {
    case amex
    case hangSeng
    case unknown
}

struct PDFParser {

    // MARK: - Public

    static func parse(url: URL) throws -> PDFParseResult {
        guard let document = PDFDocument(url: url) else {
            throw PDFParserError.cannotLoadPDF
        }

        let fullText = extractFullText(from: document)
        let bank = detectBank(text: fullText)
        let lines = extractLines(from: document)

        let transactions: [ParsedTransaction]
        let bankName: String?

        switch bank {
        case .amex:
            bankName = "American Express"
            transactions = parseAmex(lines: lines, fullText: fullText)
        case .hangSeng:
            bankName = "Hang Seng Bank"
            transactions = parseHangSeng(lines: lines)
        case .unknown:
            bankName = nil
            let amex = parseAmex(lines: lines, fullText: fullText)
            let hs = parseHangSeng(lines: lines)
            transactions = amex.count >= hs.count ? amex : hs
        }

        if transactions.isEmpty {
            throw PDFParserError.noTransactionsFound
        }

        return PDFParseResult(transactions: transactions, bankName: bankName)
    }

    // MARK: - Text extraction

    private static func extractFullText(from document: PDFDocument) -> String {
        (0..<document.pageCount).compactMap { document.page(at: $0)?.string }.joined(separator: "\n")
    }

    private static func extractLines(from document: PDFDocument) -> [String] {
        var lines: [String] = []
        for i in 0..<document.pageCount {
            guard let page = document.page(at: i), let text = page.string else { continue }
            lines.append(contentsOf: text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty })
        }
        return lines
    }

    // MARK: - Bank detection

    private static func detectBank(text: String) -> BankType {
        let upper = text.uppercased()
        if upper.contains("HANG SENG BANK") || upper.contains("恒生銀行") || upper.contains("HKJC") {
            return .hangSeng
        }
        if upper.contains("AMERICAN EXPRESS") || upper.contains("AMEX") {
            return .amex
        }
        // Check for AMEX-style full month names
        let months = ["JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE", "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"]
        if months.contains(where: { upper.contains($0) }) {
            return .amex
        }
        return .unknown
    }

    // MARK: - Statement year detection

    private static func detectStatementYear(lines: [String]) -> Int {
        for line in lines.prefix(20) {
            if let match = line.range(of: #"\b(202\d)\b"#, options: .regularExpression) {
                return Int(line[match])!
            }
        }
        return Calendar.current.component(.year, from: Date())
    }

    // MARK: - AMEX parser

    private static let monthsFull: [String: Int] = [
        "january": 1, "february": 2, "march": 3, "april": 4,
        "may": 5, "june": 6, "july": 7, "august": 8,
        "september": 9, "october": 10, "november": 11, "december": 12,
    ]

    private static let skipPatternsAmex = [
        "payment received", "direct debit", "autopay", "總額", "賬項", "會員", "截數", "月結單",
    ]

    private static func parseAmex(lines: [String], fullText: String) -> [ParsedTransaction] {
        let year = detectStatementYear(lines: lines)
        var transactions: [ParsedTransaction] = []
        // Pattern: "Month Day Description Amount"
        let datePattern = #"^(January|February|March|April|May|June|July|August|September|October|November|December)\s+(\d{1,2})\s+"#

        for line in lines {
            let lower = line.lowercased()
            if skipPatternsAmex.contains(where: { lower.contains($0.lowercased()) }) { continue }

            guard let dateMatch = line.range(of: datePattern, options: .regularExpression, range: line.startIndex..<line.endIndex) else { continue }

            let datePart = String(line[dateMatch]).trimmingCharacters(in: .whitespaces)
            let rest = String(line[dateMatch.upperBound...]).trimmingCharacters(in: .whitespaces)

            // Parse date
            guard let parsed = parseAmexDate(datePart, year: year) else { continue }

            // Find amount at end: digits with optional comma and decimal
            guard let amountMatch = rest.range(of: #"[\d,]+\.\d{2}$"#, options: .regularExpression) else { continue }
            let amountStr = rest[amountMatch].replacingOccurrences(of: ",", with: "")
            guard let amount = Double(amountStr), amount > 0 else { continue }

            // Description is everything between date and amount
            var description = String(rest[rest.startIndex..<amountMatch.lowerBound])
                .trimmingCharacters(in: .whitespaces)
                .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)

            if description.count < 2 { continue }
            if description.lowercased().hasPrefix("payment") || description.lowercased().hasPrefix("credit") { continue }

            // Clean up
            description = cleanDescription(description)

            transactions.append(ParsedTransaction(
                id: UUID().uuidString,
                date: parsed,
                description: description,
                amount: amount,
                currency: "HKD",
                rawText: line
            ))
        }

        return transactions
    }

    private static func parseAmexDate(_ dateStr: String, year: Int) -> String? {
        let parts = dateStr.lowercased().trimmingCharacters(in: .whitespaces).split(separator: " ")
        guard parts.count == 2,
              let month = monthsFull[String(parts[0])],
              let day = Int(parts[1]) else { return nil }

        var actualYear = year
        if month >= 10 { actualYear = year - 1 }

        return String(format: "%04d-%02d-%02d", actualYear, month, day)
    }

    // MARK: - Hang Seng parser

    private static let monthsAbbr: [String: Int] = [
        "JAN": 1, "FEB": 2, "MAR": 3, "APR": 4, "MAY": 5, "JUN": 6,
        "JUL": 7, "AUG": 8, "SEP": 9, "OCT": 10, "NOV": 11, "DEC": 12,
    ]

    private static let skipPatternsHangSeng = [
        "opening balance", "autopay pymt", "card total", "fee-overseas",
        "total hkjc", "hkjc facility", "trans date", "post date",
        "new activity", "member no", "account no", "closing date",
        "payment due", "minimum payment", "credit limit", "previous balance",
        "new balance", "finance charge", "will be deducted", "please note",
        "apple pay-others", "foreign currency", "exchange rate",
    ]

    private static func parseHangSeng(lines: [String]) -> [ParsedTransaction] {
        var transactions: [ParsedTransaction] = []
        // Pattern: "DD MMM YYYY DD MMM YYYY Description Amount"
        let datePattern = #"^(\d{1,2})\s+(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC)\s+(\d{4})"#

        for line in lines {
            let lower = line.lowercased()
            if skipPatternsHangSeng.contains(where: { lower.contains($0) }) { continue }

            guard let firstDateMatch = line.range(of: datePattern, options: .regularExpression) else { continue }

            let dateStr = String(line[firstDateMatch])
            guard let parsedDate = parseHangSengDate(dateStr) else { continue }

            // Skip past second date if present
            let afterFirstDate = String(line[firstDateMatch.upperBound...]).trimmingCharacters(in: .whitespaces)
            var rest = afterFirstDate
            if let secondDateMatch = afterFirstDate.range(of: datePattern, options: .regularExpression) {
                rest = String(afterFirstDate[secondDateMatch.upperBound...]).trimmingCharacters(in: .whitespaces)
            }

            // Find amount at end (may have trailing - for credits)
            guard let amountMatch = rest.range(of: #"[\d,]+\.\d{2}-?$"#, options: .regularExpression) else { continue }
            let amountStr = String(rest[amountMatch])

            // Skip credits (amount ends with -)
            if amountStr.hasSuffix("-") { continue }

            let cleanAmount = amountStr.replacingOccurrences(of: ",", with: "")
            guard let amount = Double(cleanAmount), amount > 0 else { continue }

            var description = String(rest[rest.startIndex..<amountMatch.lowerBound])
                .trimmingCharacters(in: .whitespaces)
                .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)

            // Clean up country codes and location info
            description = description
                .replacingOccurrences(of: #"\s+(HK|IE|AU|MY|US|SG|GB|JP|CN)$"#, with: "", options: .regularExpression)
                .replacingOccurrences(of: #"\s+(Hong Kong|HONG KONG|HongKong|KUALA LUMPUR|SAGGART).*$"#, with: "", options: [.regularExpression, .caseInsensitive])
                .replacingOccurrences(of: #"\s+\d{10,}$"#, with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespaces)

            if description.count < 2 { continue }

            description = cleanDescription(description)

            transactions.append(ParsedTransaction(
                id: UUID().uuidString,
                date: parsedDate,
                description: description,
                amount: amount,
                currency: "HKD",
                rawText: line
            ))
        }

        return transactions
    }

    private static func parseHangSengDate(_ dateStr: String) -> String? {
        let parts = dateStr.split(separator: " ")
        guard parts.count == 3,
              let day = Int(parts[0]),
              let month = monthsAbbr[String(parts[1]).uppercased()],
              let year = Int(parts[2]) else { return nil }

        return String(format: "%04d-%02d-%02d", year, month, day)
    }

    // MARK: - Helpers

    private static func cleanDescription(_ desc: String) -> String {
        var name = desc
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\d{5,}"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s*-\s*[A-Z]{3}-\d+"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s+\d+\s*$"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: "*", with: " ")
            .trimmingCharacters(in: .whitespaces)

        // Capitalize words, take first 3
        let words = name.split(separator: " ")
            .filter { $0.count > 1 }
            .prefix(4)
            .map { word -> String in
                let lower = word.lowercased()
                return lower.prefix(1).uppercased() + lower.dropFirst()
            }

        name = words.joined(separator: " ")
        return name.isEmpty ? desc.prefix(30).description : name
    }
}
