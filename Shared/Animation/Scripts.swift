import Foundation

/// All the little plays the pets act out. Coordinates are art pixels on the
/// stage; sprites are 16x16 and face right unless flipped.
enum Scripts {
    static let sprite = 16

    // MARK: - Entry points

    /// The big stage: lock screen and expanded island.
    static func main(for state: IslandState, width: Int, height: Int) -> StageScript {
        if state.partner != nil {
            if state.isSleeping { return couple(.nap, width: width, height: height) }
            if state.isFocusing() { return coupleFocus(width: width, height: height) }
            return couple(state.activity, width: width, height: height, stride: state.motion.walkStride)
        }
        if state.isSleeping { return solo(.nap, width: width, height: height, curled: true) }
        if state.isFocusing() { return solo(.nap, width: width, height: height) }
        return solo(state.pose, width: width, height: height, stride: state.motion.walkStride)
    }

    /// The tiny compact island: one pet per side.
    static func compact(for state: IslandState, partnerSide: Bool, width: Int, height: Int) -> StageScript {
        if state.isSleeping {
            return solo(.nap, width: width, height: height, curled: true, mirrored: partnerSide)
        }
        if !partnerSide && state.isFocusing() {
            return solo(.nap, width: width, height: height)
        }
        let pose = state.partner == nil ? state.pose : state.activity.compactPose
        return solo(pose, width: width, height: height, mirrored: partnerSide)
    }

    // MARK: - Solo

    static func solo(
        _ pose: SoloPose,
        width: Int,
        height: Int,
        curled: Bool = false,
        mirrored: Bool = false,
        stride strideOverride: Int? = nil
    ) -> StageScript {
        let range = max(width - sprite, 0)
        let y = height - sprite
        let center = range / 2
        // Long walks cost a view per step: keep the stroll short on wide stages.
        let strollEnd = min(range, 32)
        let stride = strideOverride ?? (width > 40 ? 2 : 1)
        var a = Actor(x: center, y: y)
        var zTracks: [[GlyphFrame]] = []

        switch pose {
        case .auto:
            let start = (range - strollEnd) / 2
            a = Actor(x: start, y: y)
            if strollEnd == 0 {
                a.hold(.walk, [(0, 2), (1, 2), (2, 2), (3, 2)])
            }
            a.walk(to: start + strollEnd, stride: stride)
            a.hold(.sit, [(0, 8), (1, 1), (0, 4)])
            a.hold(.groom, [(0, 3), (1, 3), (0, 3), (1, 3)])
            a.hold(.sit, [(0, 3), (2, 3), (0, 3)])
            a.walk(to: start + strollEnd / 2, stride: stride)
            a.hold(.loaf, [(0, 6), (1, 4), (0, 6), (1, 4), (2, 1), (0, 4)])
            a.hold(.stretch, [(0, 4), (1, 4)])
            a.hold(.play, [(0, 4), (1, 2), (0, 3), (1, 2)])
            a.walk(to: start, stride: stride)
            a.hold(.sit, [(0, 6), (1, 1), (0, 3)])
        case .walk where strollEnd == 0:
            // No room (narrow island): walk on the spot.
            a.hold(.walk, [(0, 2), (1, 2), (2, 2), (3, 2), (0, 2), (1, 2), (2, 2), (3, 2)])
            a.hold(.sit, [(0, 6), (1, 1), (0, 3)])
        case .walk:
            let start = (range - strollEnd) / 2
            a = Actor(x: start, y: y)
            a.walk(to: start + strollEnd, stride: stride)
            a.hold(.sit, [(0, 8), (1, 1), (0, 3)])
            a.walk(to: start, stride: stride)
            a.hold(.sit, [(0, 8), (1, 1), (0, 3)])
        case .sit:
            a.hold(.sit, [(0, 14), (1, 1), (0, 6), (2, 3), (0, 4)])
        case .loaf:
            a.hold(.loaf, [(0, 6), (1, 4), (0, 6), (1, 4), (2, 1), (0, 3)])
        case .groom:
            a.hold(.groom, [(0, 3), (1, 3), (0, 3), (1, 3), (0, 3), (1, 3)])
            a.hold(.sit, [(0, 6), (1, 1), (0, 3)])
        case .play:
            a.hold(.play, [(0, 8), (1, 2), (0, 4), (1, 2), (0, 2), (1, 2)])
        case .nap:
            let sleepPose: PetPose = curled ? .curl : .sleep
            a.hold(sleepPose, [(0, 9), (1, 9)])
            zTracks = zzz(overX: center, y: y, flipped: false, stageWidth: width)
        }

        var script = StageScript(width: width, height: height, actors: [(.me, a.slots)], glyphs: zTracks)
        if mirrored {
            script = mirror(script, role: .partner)
        }
        return script
    }

    // MARK: - Couple

    static func couple(_ activity: CoupleActivity, width: Int, height: Int, stride strideOverride: Int? = nil) -> StageScript {
        let y = height - sprite
        let rightStart = max(width - sprite, 0)
        // Facing each other, noses touching: the right pet stands 14 px further.
        let meetLeft = max((width - 30) / 2, 0)
        let meetRight = meetLeft + 14
        let heartX = meetLeft + 13
        let stride = strideOverride ?? (width > 40 ? 2 : 1)
        // Pets enter from a bit inside the edges: shorter walks, fewer views.
        let leftStart = max(meetLeft - 24, 0)
        let rightEnd = min(meetRight + 24, rightStart)
        let walkSlots = (meetLeft - leftStart + stride - 1) / stride

        var left = Actor(x: leftStart, y: y)
        var right = Actor(x: rightEnd, y: y, facingRight: false)
        var glyphs: [[GlyphFrame]] = []

        switch activity {
        case .walk:
            left.walk(to: meetLeft, stride: stride)
            right.walk(to: meetRight, stride: stride)
            left.hold(.sit, [(0, 10), (1, 1), (0, 5)])
            right.hold(.sit, [(0, 4), (1, 1), (0, 11)])
            left.walk(to: leftStart, stride: stride)
            right.walk(to: rightEnd, stride: stride)
            left.hold(.sit, [(0, 6), (1, 1), (0, 1)])
            right.hold(.sit, [(0, 2), (1, 1), (0, 5)])
            var heart = GlyphTrackBuilder()
            heart.hide(walkSlots)
            heart.show(.smallHeart, x: heartX, y: y - 3, 16)
            glyphs.append(heart.slots)

        case .cuddle:
            left = Actor(x: meetLeft, y: y)
            right = Actor(x: meetRight, y: y, facingRight: false)
            left.hold(.loaf, [(0, 6), (1, 4), (0, 6), (1, 4), (2, 1), (0, 3)])
            right.hold(.loaf, [(1, 4), (0, 6), (2, 1), (0, 3), (1, 4), (0, 6)])
            var heart = GlyphTrackBuilder()
            for _ in 0..<4 {
                heart.show(.smallHeart, x: heartX, y: y, 4)
                heart.hide(2)
            }
            glyphs.append(heart.slots)

        case .boop:
            left.walk(to: meetLeft, stride: stride)
            right.walk(to: meetRight, stride: stride)
            left.hold(.play, [(0, 3), (1, 3), (0, 2)])
            right.hold(.sit, [(0, 4), (1, 1), (0, 3)])
            left.hold(.sit, [(0, 4), (1, 1), (0, 3)])
            right.hold(.play, [(0, 3), (1, 3), (0, 2)])
            left.walk(to: leftStart, stride: stride)
            right.walk(to: rightEnd, stride: stride)
            left.hold(.sit, [(0, 6)])
            right.hold(.sit, [(0, 6)])
            var heart = GlyphTrackBuilder()
            heart.hide(walkSlots + 3)
            heart.show(.heart, x: heartX - 1, y: y - 4, 13)
            glyphs.append(heart.slots)

        case .nap:
            left = Actor(x: meetLeft, y: y)
            right = Actor(x: meetRight, y: y, facingRight: false)
            left.hold(.curl, [(0, 9), (1, 9)])
            right.hold(.curl, [(1, 9), (0, 9)])
            glyphs += zzz(overX: meetLeft, y: y, flipped: false, stageWidth: width)
            glyphs += zzz(overX: meetRight, y: y, flipped: true, stageWidth: width, phase: 9)

        case .sakura:
            left = Actor(x: meetLeft - 1, y: y)
            right = Actor(x: meetRight + 1, y: y, facingRight: false)
            left.hold(.sit, [(0, 10), (2, 3), (0, 6), (1, 1), (0, 4)])
            right.hold(.sit, [(0, 5), (1, 1), (0, 8), (2, 3), (0, 7)])
            // A blossoming tree behind the pair (left of them), petals falling.
            var tree = GlyphTrackBuilder()
            let treeX = max(meetLeft - 1 - sprite, 0)
            for i in 0..<8 {
                tree.show(StageGlyph.sakuraTree[i % 4], x: treeX, y: height - sprite, 3)
            }
            glyphs.append(tree.slots)

        case .chase:
            // A run: 3 px per slot. The strip is padded so the lap divides evenly.
            let run = 3
            let lapWidth = width + (run - (width + sprite) % run) % run
            left = Actor(x: -sprite, y: y)
            right = Actor(x: -sprite + 21, y: y)
            left.runWrapping(width: lapWidth, stride: run)
            right.runWrapping(width: lapWidth, stride: run)

        case .yarn:
            let leftX = 1
            let rightX = rightStart - 1
            left = Actor(x: leftX, y: y)
            right = Actor(x: rightX, y: y, facingRight: false)
            let from = leftX + 14
            let to = rightX - 3
            let steps = max((to - from) / 4, 1)
            left.hold(.play, [(1, 2), (0, steps), (0, 2), (0, steps)])
            right.hold(.play, [(0, 2), (0, steps), (1, 2), (0, steps)])
            var ball = GlyphTrackBuilder()
            let ballY = height - 5
            ball.show(.yarn, x: from, y: ballY, 2)
            for i in 1...steps { ball.show(.yarn, x: from + (to - from) * i / steps, y: ballY, 1) }
            ball.show(.yarn, x: to, y: ballY, 2)
            for i in 1...steps { ball.show(.yarn, x: to - (to - from) * i / steps, y: ballY, 1) }
            glyphs.append(ball.slots)

        case .stars:
            left = Actor(x: meetLeft - 2, y: y)
            right = Actor(x: meetLeft + 12, y: y)
            left.hold(.sit, [(0, 12), (1, 1), (0, 7), (2, 3), (0, 1)])
            right.hold(.sit, [(0, 5), (2, 3), (0, 9), (1, 1), (0, 6)])
        }

        return StageScript(
            width: width,
            height: height,
            actors: [(.me, left.slots), (.partner, right.slots)],
            glyphs: glyphs
        )
    }

    /// Focus with a partner: your pet naps, theirs keeps watch.
    static func coupleFocus(width: Int, height: Int) -> StageScript {
        let y = height - sprite
        let meetLeft = max((width - 30) / 2, 0)
        var left = Actor(x: meetLeft, y: y)
        var right = Actor(x: meetLeft + 15, y: y, facingRight: false)
        left.hold(.sleep, [(0, 9), (1, 9)])
        right.hold(.sit, [(0, 10), (1, 1), (0, 7)])
        return StageScript(
            width: width,
            height: height,
            actors: [(.me, left.slots), (.partner, right.slots)],
            glyphs: zzz(overX: meetLeft, y: y, flipped: false, stageWidth: width)
        )
    }

    // MARK: - Helpers

    /// Slots in one sleep loop: breathing in and out, 💤 appearing.
    static let sleepLoop = 18

    /// 💤 above a sleeping pet's head: nothing, small "z", then "z Z".
    /// Returned as a list of glyph tracks so callers can just `+=` them.
    static func zzz(overX x: Int, y: Int, flipped: Bool, stageWidth: Int, phase: Int = 0) -> [[GlyphFrame]] {
        // Head of a sleeping/curled cat spans columns 9...14, ears on row 8:
        // the 9x9 glyph sits between and above the ears. On a stage too
        // narrow for that (narrow island) it floats above the back instead.
        let glyphWidth = StageGlyph.zzzTwo.frame.width
        let fitsAboveHead = x + 10 + glyphWidth <= stageWidth
        let offset = fitsAboveHead ? 10 : 1
        let gx = flipped ? x + sprite - offset - glyphWidth : x + offset
        var frames: [GlyphFrame] = Array(repeating: .hidden, count: 4)
        frames += Array(repeating: GlyphFrame(glyph: .zzzOne, x: gx, y: y), count: 5)
        frames += Array(repeating: GlyphFrame(glyph: .zzzTwo, x: gx, y: y), count: sleepLoop - 9)
        let shift = ((phase % sleepLoop) + sleepLoop) % sleepLoop
        return [Array(frames[shift...] + frames[..<shift])]
    }

    /// Mirror a script left-right (used for the partner's side of the island).
    static func mirror(_ script: StageScript, role: StageRole) -> StageScript {
        let w = script.width
        let actors: [(StageRole, [ActorFrame])] = script.actors.map { entry in
            let slots = expand(entry.track).map { f in
                ActorFrame(pose: f.pose, frame: f.frame, x: w - sprite - f.x, y: f.y, flipped: !f.flipped)
            }
            return (role, slots)
        }
        let glyphs: [[GlyphFrame]] = script.glyphs.map { track in
            expand(track).map { g in
                guard let glyph = g.glyph else { return g }
                return GlyphFrame(glyph: glyph, x: w - glyph.frame.width - g.x, y: g.y)
            }
        }
        return StageScript(width: w, height: script.height, actors: actors, glyphs: glyphs)
    }

    private static func expand<F>(_ track: Track<F>) -> [F] {
        track.segments.flatMap { Array(repeating: $0.frame, count: Int($0.weight)) }
    }
}
