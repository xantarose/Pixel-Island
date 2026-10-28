import Foundation

// A "stage" is a small pixel canvas (width x height art pixels) where pets and
// glyphs act out a looping script. Time is counted in slots: one slot is one
// animation step (1/6 s). Every track of a script has the same number of
// slots, so all of them stay in sync while looping.

/// Where a pet is and what it does during one slot.
struct ActorFrame: Hashable {
    var pose: PetPose
    var frame: Int
    var x: Int
    var y: Int
    var flipped: Bool
}

/// A glyph (heart, Z, yarn ball) during one slot; `nil` glyph = nothing.
struct GlyphFrame: Hashable {
    var glyph: StageGlyph?
    var x: Int
    var y: Int

    static let hidden = GlyphFrame(glyph: nil, x: 0, y: 0)
}

/// Slots of one actor, with equal neighbours merged into weighted segments:
/// fewer views to draw, same timing.
struct Track<Frame: Hashable> {
    struct Segment {
        let frame: Frame
        let weight: Double
    }

    let segments: [Segment]
    let length: Int

    init(_ slots: [Frame]) {
        var merged: [Segment] = []
        for slot in slots {
            if let last = merged.last, last.frame == slot {
                merged[merged.count - 1] = Segment(frame: slot, weight: last.weight + 1)
            } else {
                merged.append(Segment(frame: slot, weight: 1))
            }
        }
        segments = merged
        length = slots.count
    }

    var weights: [Double] { segments.map(\.weight) }
}

enum StageRole {
    case me
    case partner
}

struct StageScript {
    let width: Int
    let height: Int
    let actors: [(role: StageRole, track: Track<ActorFrame>)]
    let glyphs: [Track<GlyphFrame>]

    /// Pads every track to the longest one so all loops have the same period.
    init(width: Int, height: Int, actors: [(StageRole, [ActorFrame])], glyphs: [[GlyphFrame]] = []) {
        let longest = max(
            actors.map { $0.1.count }.max() ?? 1,
            glyphs.map { $0.count }.max() ?? 1,
            1
        )
        self.width = width
        self.height = height
        self.actors = actors.map { entry in
            var padded = entry.1
            if let last = padded.last, padded.count < longest {
                padded += Array(repeating: last, count: longest - padded.count)
            }
            return (role: entry.0, track: Track(padded))
        }
        self.glyphs = glyphs.map { slots in
            Track(slots + Array(repeating: .hidden, count: max(0, longest - slots.count)))
        }
    }
}

// MARK: - Building scripts

/// A tiny "director" for one pet: walk here, sit there, blink.
struct Actor {
    private(set) var slots: [ActorFrame] = []
    private(set) var x: Int
    let y: Int
    private(set) var flipped: Bool

    init(x: Int, y: Int, facingRight: Bool = true) {
        self.x = x
        self.y = y
        self.flipped = !facingRight
    }

    mutating func face(right: Bool) {
        flipped = !right
    }

    /// `stride` art pixels per slot, cycling the four walk frames. Every slot
    /// at a new position is a separate view in the Live Activity, so wide
    /// stages walk with stride 2 to keep the view count down.
    mutating func walk(to target: Int, stride: Int = 1) {
        guard target != x else { return }
        let direction = target > x ? 1 : -1
        let step = max(stride, 1) * direction
        flipped = direction < 0
        var frame = 0
        while x != target {
            x = direction > 0 ? min(x + step, target) : max(x + step, target)
            slots.append(ActorFrame(pose: .walk, frame: frame % 4, x: x, y: y, flipped: flipped))
            frame += 1
        }
    }

    /// Run right on a looping strip: leaving at `width` brings the pet back in
    /// from the left edge. `width + 16` must be divisible by `stride`.
    mutating func runWrapping(width: Int, stride: Int) {
        flipped = false
        let lap = width + 16
        let steps = lap / max(stride, 1)
        for i in 0..<steps {
            x += stride
            if x >= width { x -= lap }
            slots.append(ActorFrame(pose: .walk, frame: i % 4, x: x, y: y, flipped: false))
        }
    }

    /// Play `pattern` = [(frame, how many slots)] in place.
    mutating func hold(_ pose: PetPose, _ pattern: [(Int, Int)]) {
        for (frame, count) in pattern {
            for _ in 0..<max(count, 0) {
                slots.append(ActorFrame(pose: pose, frame: frame, x: x, y: y, flipped: flipped))
            }
        }
    }
}

/// Builder for glyph tracks.
struct GlyphTrackBuilder {
    private(set) var slots: [GlyphFrame] = []

    mutating func hide(_ count: Int) {
        slots += Array(repeating: .hidden, count: max(count, 0))
    }

    mutating func show(_ glyph: StageGlyph, x: Int, y: Int, _ count: Int) {
        slots += Array(repeating: GlyphFrame(glyph: glyph, x: x, y: y), count: max(count, 0))
    }

    mutating func append(_ frame: GlyphFrame) {
        slots.append(frame)
    }
}
