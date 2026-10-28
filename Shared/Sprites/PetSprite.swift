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

/// A body pose. Every cat has all of them; simple critters (frog, ghost…)
/// only have walk/sit/sleep and borrow the closest one.
enum PetPose: String, CaseIterable, Hashable {
    case walk, sit, loaf, sleep, curl, groom, stretch, play

    var fallback: PetPose? {
        switch self {
        case .walk: return nil
        case .sit: return .walk
        case .loaf, .groom, .stretch, .play: return .sit
        case .sleep: return .curl
        case .curl: return .sit
        }
    }
}

/// Raw sprite description written by `tools/sprites/generate.py`.
/// Every frame is one 256-character string (16 rows of 16).
struct PetSpriteData {
    let id: String
    let name: String
    let group: PetGroup
    let palette: [Character: UInt32]
    let poses: [String: [String]]
}

/// A horizontal strip of same-coloured pixels. Merging pixels into strips
/// keeps the number of rectangles per frame small.
struct PixelRun: Hashable {
    let x: Int
    let y: Int
    let length: Int
}

/// All strips of one palette role inside a frame.
struct PixelLayer: Identifiable, Hashable {
    let role: Character
    let runs: [PixelRun]
    var id: Character { role }
}

/// One parsed frame: a grid of `width` x `height` art pixels split by colour.
struct PixelFrame: Hashable {
    let width: Int
    let height: Int
    let layers: [PixelLayer]

    /// Rows of equal length, '.' = transparent.
    init(rows: [String]) {
        self.init(chars: rows.flatMap { Array($0) }, width: rows.first?.count ?? 0)
    }

    /// One flat string, `width` characters per row.
    init(flat: String, width: Int) {
        self.init(chars: Array(flat), width: width)
    }

    /// Already-known pixels, e.g. particles of an effect.
    init(width: Int, height: Int, pixels: [(x: Int, y: Int, role: Character)]) {
        var grid = [Character](repeating: ".", count: max(width * height, 0))
        for p in pixels where p.x >= 0 && p.x < width && p.y >= 0 && p.y < height {
            grid[p.y * width + p.x] = p.role
        }
        self.init(chars: grid, width: width)
    }

    private init(chars: [Character], width: Int) {
        let width = max(width, 1)
        var byRole: [Character: [PixelRun]] = [:]
        var order: [Character] = []
        let height = chars.count / width
        for y in 0..<height {
            var x = 0
            while x < width {
                let c = chars[y * width + x]
                guard c != "." else {
                    x += 1
                    continue
                }
                var end = x + 1
                while end < width && chars[y * width + end] == c {
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
        self.height = height
        self.layers = order.map { PixelLayer(role: $0, runs: byRole[$0] ?? []) }
    }
}

/// A ready-to-draw pet: parsed frames plus SwiftUI colours.
struct PetSprite: Identifiable {
    let id: String
    let name: String
    let group: PetGroup
    let palette: [Character: Color]
    private let poses: [PetPose: [PixelFrame]]

    /// `colors` recolours parts (see `CustomLook`); derived shades follow:
    /// highlight/shadow from the fur, closed eyes from the outline.
    init(_ data: PetSpriteData, colors: [String: UInt32] = [:]) {
        id = data.id
        name = data.name
        group = data.group
        var raw = data.palette
        for (role, value) in colors {
            guard let key = role.first, role.count == 1 else { continue }
            raw[key] = value & 0xFFFFFF
        }
        if let fur = colors["B"], data.palette["H"] != nil {
            raw["H"] = ColorMath.lighter(fur, 0.25)
            raw["Q"] = ColorMath.darker(fur, 0.3)
        }
        if colors["E"] != nil && colors["F"] == nil {
            raw["F"] = raw["E"]
        }
        if let outline = colors["o"], data.palette["K"] == data.palette["o"] {
            raw["K"] = outline
        }
        // Closed eyes must stay visible on very dark fur.
        if let fur = raw["B"], let closed = raw["K"],
           ColorMath.luminance(fur) < 0.3, ColorMath.luminance(closed) < 0.3 {
            raw["K"] = ColorMath.lighter(fur, 0.45)
        }
        palette = raw.mapValues { Color(hex: $0) }
        var parsed: [PetPose: [PixelFrame]] = [:]
        for (key, frames) in data.poses {
            guard let pose = PetPose(rawValue: key), !frames.isEmpty else { continue }
            parsed[pose] = frames.map { PixelFrame(flat: $0, width: 16) }
        }
        poses = parsed
    }

    /// Frames for a pose, borrowing a similar pose if this pet lacks it.
    func frames(_ pose: PetPose) -> [PixelFrame] {
        var current: PetPose? = pose
        while let p = current {
            if let frames = poses[p] { return frames }
            current = p.fallback
        }
        return poses.values.first ?? []
    }

    /// Frame lookup that never crashes: the index wraps around.
    func frame(_ pose: PetPose, _ index: Int) -> PixelFrame {
        let list = frames(pose)
        guard !list.isEmpty else { return PixelFrame(rows: []) }
        return list[((index % list.count) + list.count) % list.count]
    }
}

enum PetCatalog {
    /// Raw data only; a sprite is parsed when it is actually needed, so the
    /// Live Activity never parses all 50+ pets just to draw two of them.
    private static let byID: [String: PetSpriteData] = Dictionary(
        SpriteCatalog.pets.map { ($0.id, $0) },
        uniquingKeysWith: { first, _ in first }
    )

    static let defaultID = "cat.ginger"

    static var count: Int { SpriteCatalog.pets.count }

    /// Unknown ids (old versions, tampered pair codes) fall back to the ginger cat.
    static func pet(_ id: String, colors: [String: UInt32] = [:]) -> PetSprite {
        PetSprite(byID[id] ?? byID[defaultID] ?? SpriteCatalog.pets[0], colors: colors)
    }

    static func contains(_ id: String) -> Bool {
        byID[id] != nil
    }

    static func isCat(_ id: String) -> Bool {
        byID[id]?.group == .cats
    }

    /// Raw palette of a pet, for the editor's "current colour" swatches.
    static func palette(_ id: String) -> [Character: UInt32] {
        (byID[id] ?? byID[defaultID])?.palette ?? [:]
    }

    struct Entry: Identifiable, Hashable {
        let id: String
        let name: String
    }

    static func entries(in group: PetGroup) -> [Entry] {
        SpriteCatalog.pets.filter { $0.group == group }.map { Entry(id: $0.id, name: $0.name) }
    }
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
