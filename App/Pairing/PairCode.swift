import Foundation

/// Pairing without a server.
///
/// Your pet (kind + name) is packed into a short text code like
/// `PI1.eyJrIjoiY2F0LmdpbmdlciIsIm4iOiLQoNGL0LbQuNC6In0`. You send it to your
/// partner in any messenger, they paste it, and your pet appears next to theirs.
///
/// The code is plain data, not a password: it only says which sprite to draw
/// and what to call it. Parsing treats it as hostile input anyway:
/// length limits, strict alphabet, strict JSON, catalogue check, name cleanup.
enum PairCode {
    static let prefix = "PI1."
    /// Longest text we are willing to scan (a pasted message, not a novel).
    static let maxInputLength = 4_000
    /// Longest base64 body a valid code can have (with room to spare).
    static let maxBodyLength = 1_200

    private struct Payload: Codable {
        let k: String
        let n: String
    }

    enum ParseError: LocalizedError {
        case tooLong
        case notFound
        case damaged
        case unknownPet

        var errorDescription: String? {
            switch self {
            case .tooLong: return "Слишком длинный текст. Вставь только сообщение с кодом."
            case .notFound: return "Не нашёл код. Он начинается с PI1."
            case .damaged: return "Код повреждён. Попроси прислать его ещё раз."
            case .unknownPet: return "Такого питомца нет в этой версии приложения. Обновитесь оба."
            }
        }
    }

    static func make(for pet: PetProfile) -> String {
        let clean = pet.sanitized()
        let payload = Payload(k: clean.kindID, n: clean.name)
        guard let data = try? JSONEncoder().encode(payload) else { return prefix }
        return prefix + base64URLEncode(data)
    }

    static func shareText(for pet: PetProfile) -> String {
        """
        🐾 Забери моего питомца в Pixel Island!
        Открой приложение → «Пара» → «Вставить код».

        \(make(for: pet))
        """
    }

    /// Finds a code anywhere inside `text` (a whole pasted message is fine).
    static func parse(_ text: String) throws -> PetProfile {
        guard text.utf8.count <= maxInputLength else { throw ParseError.tooLong }
        guard let body = extractBody(from: text) else { throw ParseError.notFound }
        guard
            let data = base64URLDecode(body),
            let payload = try? JSONDecoder().decode(Payload.self, from: data)
        else {
            throw ParseError.damaged
        }
        guard PetCatalog.contains(payload.k) else { throw ParseError.unknownPet }
        return PetProfile(kindID: payload.k, name: payload.n).sanitized()
    }

    // MARK: - Internals

    private static let alphabet = Set("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_")

    private static func extractBody(from text: String) -> String? {
        guard let range = text.range(of: prefix) else { return nil }
        let body = text[range.upperBound...].prefix { alphabet.contains($0) }
        guard (4...maxBodyLength).contains(body.count) else { return nil }
        return String(body)
    }

    private static func base64URLEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private static func base64URLDecode(_ string: String) -> Data? {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = base64.count % 4
        if remainder == 1 { return nil }
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }
        return Data(base64Encoded: base64)
    }
}
