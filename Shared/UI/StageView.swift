import SwiftUI

/// Plays a `StageScript`: pets, glyphs and particles on one pixel canvas.
struct StageView: View {
    let script: StageScript
    let me: PetSprite
    let partner: PetSprite?
    let effect: AtmosphereEffect
    /// Points per art pixel. Multiples of 1/3 stay sharp on 3x screens.
    let pixel: CGFloat
    let mode: PlaybackMode
    /// Frames per particle loop; fewer in the compact island.
    var effectLength: Int = Effects.length

    private var size: CGSize {
        CGSize(width: CGFloat(script.width) * pixel, height: CGFloat(script.height) * pixel)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(script.actors.indices, id: \.self) { index in
                let actor = script.actors[index]
                ActorTrackView(
                    track: actor.track,
                    sprite: actor.role == .me ? me : (partner ?? me),
                    pixel: pixel,
                    size: size,
                    mode: mode
                )
            }
            ForEach(script.glyphs.indices, id: \.self) { index in
                GlyphTrackView(track: script.glyphs[index], pixel: pixel, size: size, mode: mode)
            }
            EffectLayer(effect: effect, width: script.width, height: script.height, pixel: pixel, mode: mode, length: effectLength)
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .clipped()
    }
}

private struct ActorTrackView: View {
    let track: Track<ActorFrame>
    let sprite: PetSprite
    let pixel: CGFloat
    let size: CGSize
    let mode: PlaybackMode

    var body: some View {
        SegmentPlayer(weights: track.weights, size: size, mode: mode) { index in
            let f = track.segments[index].frame
            PixelFrameView(frame: sprite.frame(f.pose, f.frame), palette: sprite.palette, pixel: pixel, flipped: f.flipped)
                .offset(x: CGFloat(f.x) * pixel, y: CGFloat(f.y) * pixel)
                .frame(width: size.width, height: size.height, alignment: .topLeading)
        }
    }
}

private struct GlyphTrackView: View {
    let track: Track<GlyphFrame>
    let pixel: CGFloat
    let size: CGSize
    let mode: PlaybackMode

    var body: some View {
        SegmentPlayer(weights: track.weights, size: size, mode: mode) { index in
            let g = track.segments[index].frame
            if let glyph = g.glyph {
                PixelFrameView(frame: glyph.frame, palette: StageGlyph.palette, pixel: pixel)
                    .offset(x: CGFloat(g.x) * pixel, y: CGFloat(g.y) * pixel)
                    .frame(width: size.width, height: size.height, alignment: .topLeading)
            } else {
                Color.clear
            }
        }
    }
}

/// Particles on top of the pets. Nothing is drawn for `.none`.
struct EffectLayer: View {
    let effect: AtmosphereEffect
    let width: Int
    let height: Int
    let pixel: CGFloat
    let mode: PlaybackMode
    var length: Int = Effects.length

    var body: some View {
        let frames = Effects.frames(effect, width: width, height: height, length: length)
        if !frames.isEmpty {
            let palette = Effects.palette(effect)
            let track = Track(frames)
            let size = CGSize(width: CGFloat(width) * pixel, height: CGFloat(height) * pixel)
            SegmentPlayer(weights: track.weights, size: size, mode: mode) { index in
                PixelFrameView(frame: track.segments[index].frame, palette: palette, pixel: pixel)
            }
            .allowsHitTesting(false)
        }
    }
}
