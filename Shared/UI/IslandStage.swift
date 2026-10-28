import SwiftUI

/// One pet playing one scene.
struct PetSceneView: View {
    let pet: PetSprite
    let scene: PetScene
    let pixel: CGFloat
    let mode: PlaybackMode

    var size: CGSize {
        CGSize(width: CGFloat(16 + scene.range) * pixel, height: 16 * pixel)
    }

    var body: some View {
        SegmentPlayer(weights: scene.weights, size: size, mode: mode) { index in
            let slot = scene.segments[index].slot
            PixelFrameView(
                frame: pet.frame(slot.action, slot.frame),
                palette: pet.palette,
                pixel: pixel,
                flipped: slot.flipped
            )
            .offset(x: CGFloat(slot.x) * pixel)
            .frame(width: size.width, height: size.height, alignment: .leading)
        }
        .frame(width: size.width, height: size.height)
    }
}

/// The "stage": your pet, your partner's pet and the heart between them.
/// Used on the lock screen, in the expanded island and in the app preview.
struct IslandStage: View {
    let state: IslandState
    /// Points per art pixel. Multiples of 1/3 stay sharp on 3x screens.
    let pixel: CGFloat
    /// How far each pet walks, in art pixels.
    let range: Int
    let mode: PlaybackMode
    var now: Date = .now

    private var isFocusing: Bool {
        guard let focus = state.focus else { return false }
        return !focus.isFinished(at: now)
    }

    var body: some View {
        content
            .overlay(alignment: .top) {
                if state.showsHearts {
                    HeartsBurst(pixel: pixel * 0.6)
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        let me = state.me.sprite
        if let partner = state.partner?.sprite {
            if state.isSleeping {
                HStack(spacing: pixel * 2) {
                    PetSceneView(pet: me, scene: .sleeping(), pixel: pixel, mode: mode)
                    PetSceneView(pet: partner, scene: .sleeping(flipped: true), pixel: pixel, mode: mode)
                }
            } else if isFocusing {
                HStack(spacing: pixel * 2) {
                    PetSceneView(pet: me, scene: .sleeping(), pixel: pixel, mode: mode)
                    PetSceneView(pet: partner, scene: .patrol(range: range, startsFacingLeft: true), pixel: pixel, mode: mode)
                }
            } else {
                HStack(alignment: .top, spacing: 0) {
                    PetSceneView(pet: me, scene: .meet(range: range, isLeft: true), pixel: pixel, mode: mode)
                    meetHeart
                    PetSceneView(pet: partner, scene: .meet(range: range, isLeft: false), pixel: pixel, mode: mode)
                }
            }
        } else if state.isSleeping || isFocusing {
            PetSceneView(pet: me, scene: .sleeping(), pixel: pixel, mode: mode)
        } else {
            PetSceneView(pet: me, scene: .patrol(range: range * 2 + 7), pixel: pixel, mode: mode)
        }
    }

    /// Pops up exactly while the two pets stand nose to nose.
    private var meetHeart: some View {
        let size = CGSize(width: 7 * pixel, height: 16 * pixel)
        return SegmentPlayer(weights: PetScene.meetHeartWeights(range: range), size: size, mode: mode) { index in
            if index == 1 {
                PixelHeart(pixel: pixel)
                    .padding(.top, 2 * pixel)
                    .frame(width: size.width, height: size.height, alignment: .top)
            } else {
                Color.clear
            }
        }
    }
}

/// A few hearts floating above the pets after "Погладить".
struct HeartsBurst: View {
    let pixel: CGFloat

    var body: some View {
        HStack(alignment: .top, spacing: pixel * 6) {
            PixelHeart(pixel: pixel)
                .offset(y: pixel * 3)
            PixelHeart(pixel: pixel * 1.3)
            PixelHeart(pixel: pixel)
                .offset(y: pixel * 2)
        }
        .allowsHitTesting(false)
    }
}
