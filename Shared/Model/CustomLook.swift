import Foundation

/// "Собери своего котика": any cat as the base (shape, ears, tail, pattern)
/// plus your own colours for its parts.
struct CustomLook: Codable, Hashable {
    /// Id of the cat whose drawing is used.
    var baseID: String
    /// Palette role -> 0xRRGGBB. Only roles from `parts` are kept.
    var colors: [String: UInt32]

    /// Parts the editor offers, in display order. `role` is the palette role
    /// the generator uses for that part.
    struct Part: Identifiable, Hashable {
        let role: String
        let title: String
        var id: String { role }
    }

    static let parts: [Part] = [
        Part(role: "B", title: "Шёрстка"),
        Part(role: "D", title: "Узор и полоски"),
        Part(role: "G", title: "Второй цвет пятен"),
        Part(role: "L", title: "Животик и мордочка"),
        Part(role: "E", title: "Глаза"),
        Part(role: "F", title: "Второй глаз"),
        Part(role: "P", title: "Носик и ушки"),
        Part(role: "o", title: "Обводка"),
    ]

    private static let allowedRoles = Set(parts.map(\.role))

    /// Received data is never trusted: unknown base -> nil, unknown parts are
    /// dropped, colours are clamped to 24 bits.
    func sanitized() -> CustomLook? {
        guard PetCatalog.contains(baseID), PetCatalog.isCat(baseID) else { return nil }
        var clean: [String: UInt32] = [:]
        for (role, value) in colors where Self.allowedRoles.contains(role) {
            clean[role] = value & 0xFFFFFF
        }
        return CustomLook(baseID: baseID, colors: clean)
    }
}

/// Colour helpers for derived shades (closed eyes, highlight, shadow).
enum ColorMath {
    static func mix(_ a: UInt32, _ b: UInt32, _ t: Double) -> UInt32 {
        func channel(_ c: UInt32, _ shift: UInt32) -> Double { Double((c >> shift) & 0xFF) }
        func blend(_ shift: UInt32) -> UInt32 {
            let v = channel(a, shift) * (1 - t) + channel(b, shift) * t
            return UInt32(max(0, min(255, v.rounded()))) << shift
        }
        return blend(16) | blend(8) | blend(0)
    }

    static func lighter(_ c: UInt32, _ t: Double = 0.3) -> UInt32 { mix(c, 0xFFFFFF, t) }
    static func darker(_ c: UInt32, _ t: Double = 0.3) -> UInt32 { mix(c, 0x000000, t) }

    /// 0 (black) ... 1 (white), perceived brightness.
    static func luminance(_ c: UInt32) -> Double {
        let r = Double((c >> 16) & 0xFF), g = Double((c >> 8) & 0xFF), b = Double(c & 0xFF)
        return (0.299 * r + 0.587 * g + 0.114 * b) / 255
    }
}
