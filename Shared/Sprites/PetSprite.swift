import SwiftUI

/// Which shelf of the picker a pet lives on.
enum PetGroup: String, Codable, CaseIterable {
    case cats
    case friends

    var title: String {
        switch self {
        case .cats: return "Котики"
        case .friends: return "Друзья"
        }
    }
}

/// What a pet is doing in a given frame.
enum PetAction: Hashable {
    case walk
    case idle
    case sleep
}

/// Raw sprite description written by `tools/sprites/generate.py`.
struct PetSpriteData {
    let id: String
    let name: String
    let group: PetGroup
    let palette: [Character: UInt32]
    let walk: [[String]]
    let idle: [[String]]
    let sleep: [[String]]
}

/// A horizontal strip of same-coloured pixels. Merging pixels into strips
/// keeps the number of rectangles per frame small.
struct PixelRun: Hashable {
    let x: Int
    let y: Int
    let length: Int
}

/// All strips of one palette role inside a frame.
struct PixelLayer: Identifiable {
    let role: Character
    let runs: [PixelRun]
    var id: Character { role }
}

/// One parsed frame: a grid of `width` x `height` art pixels split by colour.
struct PixelFrame {
    let width: Int
    let height: Int
    let layers: [PixelLayer]

    init(rows: [String]) {
        var byRole: [Character: [PixelRun]] = [:]
        var order: [Character] = []
        var width = 0
        for (y, row) in rows.enumerated() {
            let chars = Array(row)
            width = max(width, chars.count)
            var x = 0
            while x < chars.count {
                let c = chars[x]
                guard c != "." else {
                    x += 1
                    continue
                }
                var end = x + 1
                while end < chars.count && chars[end] == c {
                    end += 1
                }
                if byRole[c] == nil {
                    order.append(c)
                }
                byRole[c, default: []].append(PixelRun(x: x, y: y, length: end - x))
                x = end
            }
        }
        self.width = width
        self.height = rows.count
        self.layers = order.map { PixelLayer(role: $0, runs: byRole[$0] ?? []) }
    }
}

/// A ready-to-draw pet: parsed frames plus SwiftUI colours.
struct PetSprite: Identifiable {
    let id: String
    let name: String
    let group: PetGroup
    let palette: [Character: Color]
    let walk: [PixelFrame]
    let idle: [PixelFrame]
    let sleep: [PixelFrame]

    init(_ data: PetSpriteData) {
        id = data.id
        name = data.name
        group = data.group
        palette = data.palette.mapValues { Color(hex: $0) }
        walk = data.walk.map(PixelFrame.init(rows:))
        idle = data.idle.map(PixelFrame.init(rows:))
        sleep = data.sleep.map(PixelFrame.init(rows:))
    }

    /// Frame lookup that never crashes: the index wraps around.
    func frame(_ action: PetAction, _ index: Int) -> PixelFrame {
        let list: [PixelFrame]
        switch action {
        case .walk: list = walk
        case .idle: list = idle
        case .sleep: list = sleep
        }
        return list[((index % list.count) + list.count) % list.count]
    }
}

enum PetCatalog {
    static let all: [PetSprite] = SpriteCatalog.pets.map(PetSprite.init)

    private static let byID: [String: PetSprite] = Dictionary(
        all.map { ($0.id, $0) },
        uniquingKeysWith: { first, _ in first }
    )

    static let defaultID = "cat.ginger"

    /// Unknown ids (old versions, tampered pair codes) fall back to the ginger cat.
    static func pet(_ id: String) -> PetSprite {
        byID[id] ?? byID[defaultID] ?? all[0]
    }

    static func contains(_ id: String) -> Bool {
        byID[id] != nil
    }

    static func pets(in group: PetGroup) -> [PetSprite] {
        all.filter { $0.group == group }
    }
}

/// Small sprites that are not pets.
enum Glyphs {
    static let heart = PixelFrame(rows: [
        ".oo.oo.",
        "oPPoPPo",
        "oPWPPPo",
        "oPPPPPo",
        ".oPPPo.",
        "..oPo..",
        "...o...",
    ])

    static let heartPalette: [Character: Color] = [
        "o": Color(hex: 0x5A1F36),
        "P": Color(hex: 0xFF6F9F),
        "W": Color(hex: 0xFFE3EE),
    ]
}

extension Color {
    /// `Color(hex: 0xFF8800)`: 24-bit RGB, fully opaque.
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}
