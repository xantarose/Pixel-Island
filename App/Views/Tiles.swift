import SwiftUI

// Option tiles that show the real pixel picture of what you pick, instead of
// an emoji: the cat in that pose, the pair doing that activity, the particles
// of that effect. Only the selected tile animates (battery).

/// A selectable tile: preview on top, title below.
struct OptionTile<Preview: View>: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @ViewBuilder let preview: Preview

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                preview
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                Text(title)
                    .font(Theme.roundedFont(12, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .foregroundStyle(isSelected ? Theme.peach : Theme.cream)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity)
            .background(Color.black, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isSelected ? Theme.peach : Theme.cardBorder, lineWidth: isSelected ? 2.5 : 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

/// Grid for tiles.
struct TileGrid<Content: View>: View {
    var minWidth: CGFloat = 92
    @ViewBuilder let content: Content

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: minWidth), spacing: 8)], spacing: 8) {
            content
        }
    }
}

// MARK: - Previews

/// Your cat in a pose.
struct PosePreview: View {
    let pet: PetSprite
    let pose: SoloPose
    let animated: Bool

    var body: some View {
        StageView(
            script: Scripts.solo(pose, width: 16, height: 16, curled: pose == .nap),
            me: pet,
            partner: nil,
            effect: .none,
            pixel: 2.5,
            mode: animated ? .inApp : .still
        )
    }
}

/// The two pets doing an activity.
struct ActivityPreview: View {
    let me: PetSprite
    let partner: PetSprite
    let activity: CoupleActivity
    let animated: Bool

    var body: some View {
        StageView(
            script: Scripts.couple(activity, width: 64, height: 20),
            me: me,
            partner: partner,
            effect: activity.defaultEffect,
            pixel: 2,
            mode: animated ? .inApp : .still
        )
    }
}

/// Particles of an effect around a sitting cat.
struct EffectPreview: View {
    let pet: PetSprite
    let effect: AtmosphereEffect
    let animated: Bool

    var body: some View {
        StageView(
            script: Scripts.solo(.sit, width: 32, height: 18),
            me: pet,
            partner: nil,
            effect: effect == .auto ? .none : effect,
            pixel: 2.5,
            mode: animated ? .inApp : .still
        )
        .overlay(alignment: .topTrailing) {
            if effect == .auto {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Theme.peach)
                    .padding(4)
            }
        }
    }
}

/// A tiny Dynamic Island: black pill with the camera in the middle.
struct MiniIsland<Leading: View, Trailing: View>: View {
    var camera: CGFloat = 26
    @ViewBuilder let leading: Leading
    @ViewBuilder let trailing: Trailing

    var body: some View {
        HStack(spacing: 4) {
            leading
            Circle()
                .fill(Color(hex: 0x15151A))
                .frame(width: 7, height: 7)
                .frame(width: camera)
            trailing
        }
        .padding(.horizontal, 8)
        .frame(height: 24)
        .background(Color(hex: 0x000000), in: Capsule())
        .overlay { Capsule().strokeBorder(Theme.cardBorder, lineWidth: 1) }
    }
}

/// Narrow vs wide island.
struct WidthPreview: View {
    let pet: PetSprite
    let width: IslandWidth

    var body: some View {
        MiniIsland {
            PixelFrameView(frame: pet.frame(.sit, 0), palette: pet.palette, pixel: 1.1)
            if width == .wide {
                Spacer().frame(width: 10)
            }
        } trailing: {
            if width == .wide {
                Spacer().frame(width: 10)
            }
            PixelHeart(pixel: 1.6)
        }
    }
}

/// Particles only by the cat, or on the whole island.
struct ScopePreview: View {
    let pet: PetSprite
    let scope: EffectScope
    let animated: Bool

    var body: some View {
        MiniIsland {
            ZStack {
                PixelFrameView(frame: pet.frame(.sit, 0), palette: pet.palette, pixel: 1.1)
                EffectLayer(effect: .sakura, width: 14, height: 14, pixel: 1.4, mode: animated ? .inApp : .still)
            }
            .frame(width: 19, height: 19)
        } trailing: {
            ZStack {
                if scope == .island {
                    EffectLayer(effect: .sakura, width: 14, height: 14, pixel: 1.4, mode: animated ? .inApp : .still)
                }
                PixelHeart(pixel: 1.6)
            }
            .frame(width: 19, height: 19)
        }
    }
}

/// A walking cat with the chosen amount of frames.
struct MotionPreview: View {
    let pet: PetSprite
    let motion: MotionDetail
    let animated: Bool

    var body: some View {
        StageView(
            script: Scripts.solo(.walk, width: 40, height: 16, stride: motion.walkStride),
            me: pet,
            partner: nil,
            effect: motion == .still ? .none : .sakura,
            pixel: 2,
            mode: animated && motion != .still ? .inApp : .still,
            effectLength: motion.effectFrames(compact: false)
        )
    }
}
