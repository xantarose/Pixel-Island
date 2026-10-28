import SwiftUI

/// Pixel particles: sakura petals, snow, hearts, fireflies, leaves, stars.
///
/// Each effect is a loop of `length` frames built from a fixed random seed,
/// so the same effect always looks the same and loops without a jump:
/// every particle travels exactly a whole number of laps per loop.
enum Effects {
    static let length = 24

    struct Particle {
        var x: Int
        var y: Int
        /// Vertical laps per loop (negative = rising).
        var laps: Int
        var sway: Int
        var phase: Double
        var role: Character
        var shape: [(Int, Int)]
    }

    static func palette(_ effect: AtmosphereEffect) -> [Character: Color] {
        switch effect {
        case .sakura:
            return ["P": Color(hex: 0xFFB3CB), "L": Color(hex: 0xFFE1EC), "D": Color(hex: 0xF58CB0)]
        case .snow:
            return ["W": Color(hex: 0xFFFFFF), "L": Color(hex: 0xCFE2FF)]
        case .rain:
            return ["L": Color(hex: 0x8FB8FF), "W": Color(hex: 0xCFE2FF)]
        case .hearts:
            return ["P": Color(hex: 0xFF6F9F), "L": Color(hex: 0xFFB3CB)]
        case .confetti:
            return [
                "P": Color(hex: 0xFF6F9F), "G": Color(hex: 0xFFE27A), "L": Color(hex: 0x8FE3B0),
                "D": Color(hex: 0x8FB8FF), "W": Color(hex: 0xC9A7FF),
            ]
        case .fireflies:
            return ["G": Color(hex: 0xFFE27A), "L": Color(hex: 0xFFF6C8)]
        case .leaves:
            return ["G": Color(hex: 0xE8873A), "D": Color(hex: 0xC2502E), "Y": Color(hex: 0xF2C14E)]
        case .stars:
            return ["W": Color(hex: 0xFFFFFF), "S": Color(hex: 0xFFF3A0), "L": Color(hex: 0x9FB4FF)]
        case .auto, .none:
            return [:]
        }
    }

    /// `length` = frames per loop. Small places (compact island) use fewer:
    /// every frame is one more view the system keeps animating.
    static func frames(_ effect: AtmosphereEffect, width: Int, height: Int, length: Int = Effects.length) -> [PixelFrame] {
        guard effect != .none, effect != .auto, width > 0, height > 0, length > 0 else { return [] }
        var rng = SplitMix(seed: UInt64(width * 131 + height * 7) &+ UInt64(effect.hashSeed))
        let area = width * height
        let margin = 4
        let travel = height + margin

        func pick<T>(_ options: [T]) -> T { options[Int(rng.next() % UInt64(options.count))] }
        func int(_ range: Range<Int>) -> Int { range.lowerBound + Int(rng.next() % UInt64(max(range.count, 1))) }
        func unit() -> Double { Double(rng.next() % 10_000) / 10_000 }

        var particles: [Particle] = []

        switch effect {
        case .sakura:
            for _ in 0..<max(area / 70, 2) {
                particles.append(Particle(
                    x: int(0..<width), y: int(0..<travel), laps: pick([1, 1, 2]), sway: pick([1, 2]),
                    phase: unit(), role: pick(["P", "P", "L", "D"]),
                    shape: pick([[(0, 0), (1, 0)], [(0, 0)], [(0, 0), (1, 1)]])
                ))
            }
        case .snow:
            for _ in 0..<max(area / 60, 2) {
                particles.append(Particle(
                    x: int(0..<width), y: int(0..<travel), laps: pick([1, 1, 2]), sway: 1,
                    phase: unit(), role: pick(["W", "W", "L"]), shape: [(0, 0)]
                ))
            }
        case .rain:
            for _ in 0..<max(area / 50, 2) {
                particles.append(Particle(
                    x: int(0..<width), y: int(0..<travel), laps: pick([3, 4]), sway: 0,
                    phase: unit(), role: pick(["L", "L", "W"]), shape: [(0, 0), (0, 1)]
                ))
            }
        case .confetti:
            for _ in 0..<max(area / 55, 2) {
                particles.append(Particle(
                    x: int(0..<width), y: int(0..<travel), laps: pick([1, 2]), sway: pick([1, 2]),
                    phase: unit(), role: pick(["P", "G", "L", "D", "W"]),
                    shape: pick([[(0, 0)], [(0, 0), (1, 0)], [(0, 0), (0, 1)]])
                ))
            }
        case .hearts:
            for _ in 0..<max(area / 160, 2) {
                particles.append(Particle(
                    x: int(0..<width), y: int(0..<travel), laps: -1, sway: 1,
                    phase: unit(), role: pick(["P", "L"]),
                    shape: [(0, 0), (2, 0), (0, 1), (1, 1), (2, 1), (1, 2)]
                ))
            }
        case .leaves:
            for _ in 0..<max(area / 110, 2) {
                particles.append(Particle(
                    x: int(0..<width), y: int(0..<travel), laps: pick([1, 2]), sway: pick([2, 3]),
                    phase: unit(), role: pick(["G", "D", "Y"]),
                    shape: pick([[(0, 0), (1, 0)], [(0, 0), (0, 1)]])
                ))
            }
        case .fireflies:
            for _ in 0..<max(area / 120, 2) {
                particles.append(Particle(
                    x: int(0..<width), y: int(0..<max(height - 3, 1)), laps: 0, sway: 2,
                    phase: unit(), role: pick(["G", "L"]), shape: [(0, 0)]
                ))
            }
        case .stars:
            for _ in 0..<max(area / 90, 2) {
                particles.append(Particle(
                    x: int(0..<width), y: int(0..<max(height - 8, 2)), laps: 0, sway: 0,
                    phase: unit(), role: pick(["W", "S", "L"]),
                    shape: pick([[(0, 0)], [(0, 0)], [(1, 0), (0, 1), (1, 1), (2, 1), (1, 2)]])
                ))
            }
        case .auto, .none:
            break
        }

        return (0..<length).map { t in
            let progress = Double(t) / Double(length)
            var pixels: [(x: Int, y: Int, role: Character)] = []
            for p in particles {
                let angle = 2 * Double.pi * (progress + p.phase)
                var px = p.x
                var py = p.y
                switch effect {
                case .fireflies:
                    // Slow little circles, blinking on and off.
                    guard sin(angle * 2) > -0.35 else { continue }
                    px += Int((Double(p.sway) * cos(angle)).rounded())
                    py += Int((sin(angle) * 1.5).rounded())
                case .stars:
                    // Twinkle: hidden for a short part of the loop.
                    guard sin(angle * 3) > -0.6 else { continue }
                default:
                    let fall = Int((Double(p.laps * travel) * progress).rounded(.down))
                    py = mod(p.y + fall, travel) - margin / 2
                    px += Int((Double(p.sway) * sin(angle)).rounded())
                }
                for (dx, dy) in p.shape {
                    pixels.append((x: mod(px + dx, width), y: py + dy, role: p.role))
                }
            }
            if effect == .stars {
                pixels += shootingStar(at: t, width: width)
            }
            return PixelFrame(width: width, height: height, pixels: pixels)
        }
    }

    /// One shooting star at the start of every loop.
    private static func shootingStar(at t: Int, width: Int) -> [(x: Int, y: Int, role: Character)] {
        guard t < 10 else { return [] }
        let headX = width - 4 - t * 3
        let headY = t
        return [
            (x: headX, y: headY, role: "W"),
            (x: headX + 1, y: headY, role: "S"),
            (x: headX + 2, y: headY - 1, role: "S"),
            (x: headX + 3, y: headY - 1, role: "L"),
        ]
    }

    private static func mod(_ a: Int, _ n: Int) -> Int {
        n == 0 ? 0 : ((a % n) + n) % n
    }
}

private extension AtmosphereEffect {
    var hashSeed: Int {
        AtmosphereEffect.allCases.firstIndex(of: self) ?? 0
    }
}

/// Tiny deterministic random generator (SplitMix64). Not for security, only
/// for "random but always the same" particle layouts.
struct SplitMix {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}
