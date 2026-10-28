import Foundation

/// One moment of an animation: which frame, where, facing which way.
struct SceneSlot: Hashable {
    var action: PetAction
    var frame: Int
    /// Horizontal offset inside the scene canvas, in art pixels.
    var x: Int
    /// Sprites are drawn facing right; `true` mirrors them to face left.
    var flipped: Bool
}

/// A looping animation. Consecutive identical slots are merged into one
/// segment with a bigger weight: fewer views to draw, same timing.
struct PetScene {
    struct Segment {
        let slot: SceneSlot
        let weight: Double
    }

    static let fps: Double = 6

    let segments: [Segment]
    /// How far the pet travels, in art pixels. Canvas width = 16 + range.
    let range: Int

    var weights: [Double] { segments.map(\.weight) }
    var slotCount: Double { weights.reduce(0, +) }

    init(slots: [SceneSlot], range: Int) {
        var merged: [Segment] = []
        for slot in slots {
            if let last = merged.last, last.slot == slot {
                merged[merged.count - 1] = Segment(slot: slot, weight: last.weight + 1)
            } else {
                merged.append(Segment(slot: slot, weight: 1))
            }
        }
        self.segments = merged
        self.range = range
    }
}

// MARK: - Building blocks

extension PetScene {
    /// Walk from `from` to `to`, one art pixel per slot, cycling 4 walk frames.
    static func walk(from: Int, to: Int) -> [SceneSlot] {
        guard from != to else { return [] }
        let step = to > from ? 1 : -1
        var slots: [SceneSlot] = []
        var x = from
        var frame = 0
        while x != to {
            x += step
            slots.append(SceneSlot(action: .walk, frame: frame, x: x, flipped: step < 0))
            frame += 1
        }
        return slots
    }

    /// Stand still for `length` slots and blink once near the end.
    static func idle(at x: Int, flipped: Bool, length: Int) -> [SceneSlot] {
        (0..<length).map { i in
            SceneSlot(action: .idle, frame: i == length - 2 ? 1 : 0, x: x, flipped: flipped)
        }
    }

    /// Walk across the canvas and back, resting at both ends.
    static func patrol(range: Int, startsFacingLeft: Bool = false) -> PetScene {
        let rest = 10
        let slots: [SceneSlot]
        if startsFacingLeft {
            slots = walk(from: range, to: 0)
                + idle(at: 0, flipped: true, length: rest)
                + walk(from: 0, to: range)
                + idle(at: range, flipped: false, length: rest)
        } else {
            slots = walk(from: 0, to: range)
                + idle(at: range, flipped: false, length: rest)
                + walk(from: range, to: 0)
                + idle(at: 0, flipped: true, length: rest)
        }
        return PetScene(slots: slots, range: range)
    }

    /// Stay in place, idle with a blink. Used where there is no room to walk.
    static func standing(flipped: Bool = false) -> PetScene {
        PetScene(slots: idle(at: 0, flipped: flipped, length: 14), range: 0)
    }

    /// Curled up asleep, breathing slowly.
    static func sleeping(flipped: Bool = false) -> PetScene {
        let slots = Array(repeating: SceneSlot(action: .sleep, frame: 0, x: 0, flipped: flipped), count: 6)
            + Array(repeating: SceneSlot(action: .sleep, frame: 1, x: 0, flipped: flipped), count: 6)
        return PetScene(slots: slots, range: 0)
    }

    // MARK: Couple scene

    /// Number of slots the pair stands together; the heart shows during it.
    static let meetPause = 14
    static let meetRest = 6

    /// Two pets walk towards each other, pause (heart pops up), walk back.
    /// The left pet faces right first, the right pet is its mirror image.
    /// Both scenes have exactly the same length so they stay in sync.
    static func meet(range: Int, isLeft: Bool) -> PetScene {
        let slots: [SceneSlot]
        if isLeft {
            slots = walk(from: 0, to: range)
                + idle(at: range, flipped: false, length: meetPause)
                + walk(from: range, to: 0)
                + idle(at: 0, flipped: true, length: meetRest)
        } else {
            slots = walk(from: range, to: 0)
                + idle(at: 0, flipped: true, length: meetPause)
                + walk(from: 0, to: range)
                + idle(at: range, flipped: false, length: meetRest)
        }
        return PetScene(slots: slots, range: range)
    }

    /// Weights for the heart between the pets: hidden, visible, hidden.
    /// Must add up to the same total as `meet(range:isLeft:)`.
    static func meetHeartWeights(range: Int) -> [Double] {
        [Double(range), Double(meetPause), Double(range + meetRest)]
    }
}
