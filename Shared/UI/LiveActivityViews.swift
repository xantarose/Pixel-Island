import AppIntents
import SwiftUI

// Views shown by the Live Activity. They live in Shared so the app can render
// the exact same views as a preview (with `.inApp` playback).

/// Sizes of every place a pet appears. `pixel` = points per art pixel;
/// multiples of 1/3 stay sharp on 3x screens.
enum StageLayout {
    case compact, compactNarrow, minimal, expanded, lockScreen

    static func compact(for state: IslandState) -> StageLayout {
        state.islandWidth == .narrow ? .compactNarrow : .compact
    }

    var width: Int {
        switch self {
        case .compact: return 24
        case .compactNarrow, .minimal: return 16
        case .expanded: return 84
        case .lockScreen: return 110
        }
    }

    var height: Int {
        switch self {
        case .compact, .compactNarrow, .minimal: return 16
        case .expanded, .lockScreen: return 20
        }
    }

    var pixel: CGFloat {
        switch self {
        case .compact, .compactNarrow, .minimal: return 4.0 / 3.0
        case .expanded: return 2
        case .lockScreen: return 7.0 / 3.0
        }
    }
}

private extension IslandState {
    var daysText: String? {
        guard let days = daysTogether() else { return nil }
        let text = "\(days) \(RussianPlural.days(days))"
        return isAnniversary() ? "🎉 " + text : text
    }

    var statusText: String {
        if isSleeping { return "спят" }
        if isFocusing() { return "фокус" }
        if partner != nil { return activity.title.lowercased() }
        return pose.title.lowercased()
    }
}

/// The big scene (lock screen / expanded island).
struct MainStage: View {
    let state: IslandState
    let layout: StageLayout
    let mode: PlaybackMode

    var body: some View {
        StageView(
            script: Scripts.main(for: state, width: layout.width, height: layout.height),
            me: state.me.sprite,
            partner: state.partner?.sprite,
            effect: state.resolvedEffect,
            pixel: layout.pixel,
            mode: mode
        )
    }
}

// MARK: - Compact & minimal

struct CompactLeadingView: View {
    let state: IslandState
    let mode: PlaybackMode

    var body: some View {
        let layout = StageLayout.compact(for: state)
        StageView(
            script: Scripts.compact(for: state, partnerSide: false, width: layout.width, height: layout.height),
            me: state.me.sprite,
            partner: nil,
            effect: state.resolvedEffect,
            pixel: layout.pixel,
            mode: mode,
            effectLength: 12
        )
    }
}

struct CompactTrailingView: View {
    let state: IslandState
    let isStale: Bool
    let mode: PlaybackMode

    var body: some View {
        let layout = StageLayout.compact(for: state)
        if let focus = state.focus, state.isFocusing(isStale: isStale) {
            Text(timerInterval: focus.interval, countsDown: true)
                .font(Theme.pixelFont(12))
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
                .foregroundStyle(Theme.peach)
                .frame(width: 42)
        } else if let partner = state.partner {
            StageView(
                script: Scripts.compact(for: state, partnerSide: true, width: layout.width, height: layout.height),
                me: partner.sprite,
                partner: partner.sprite,
                effect: state.resolvedEffect,
                pixel: layout.pixel,
                mode: mode,
                effectLength: 12
            )
        } else if state.badge != .none || showsIslandEffect {
            ZStack {
                if showsIslandEffect {
                    EffectLayer(
                        effect: state.resolvedEffect,
                        width: layout.width,
                        height: layout.height,
                        pixel: layout.pixel,
                        mode: mode,
                        length: 12
                    )
                }
                BadgeView(badge: state.badge, pixel: 2, mode: mode)
            }
            .frame(width: CGFloat(layout.width) * layout.pixel, height: CGFloat(layout.height) * layout.pixel)
            .clipped()
        }
    }

    /// Particles on the right only when they are on and set to the whole island:
    /// an empty block here would make the island wider for nothing.
    private var showsIslandEffect: Bool {
        state.effectScope == .island && state.resolvedEffect != .none
    }
}

/// Particles behind a whole region when "На весь островок" is on.
struct IslandEffectBackground: View {
    let state: IslandState
    let width: Int
    let height: Int
    let pixel: CGFloat
    let mode: PlaybackMode

    var body: some View {
        if state.effectScope == .island {
            EffectLayer(effect: state.resolvedEffect, width: width, height: height, pixel: pixel, mode: mode)
                .frame(width: CGFloat(width) * pixel, height: CGFloat(height) * pixel)
                .clipped()
        }
    }
}

struct MinimalIslandView: View {
    let state: IslandState
    let mode: PlaybackMode

    var body: some View {
        let pose: SoloPose = state.isSleeping ? .nap : .sit
        StageView(
            script: Scripts.solo(pose, width: StageLayout.minimal.width, height: StageLayout.minimal.height, curled: state.isSleeping),
            me: state.me.sprite,
            partner: nil,
            effect: .none,
            pixel: StageLayout.minimal.pixel,
            mode: mode
        )
    }
}

// MARK: - Expanded

struct ExpandedLeadingView: View {
    let state: IslandState
    var mode: PlaybackMode = .liveActivity

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(state.me.name)
                .font(Theme.pixelFont(13))
                .foregroundStyle(Theme.cream)
                .lineLimit(1)
            Text(state.statusText)
                .font(Theme.roundedFont(11, weight: .medium))
                .foregroundStyle(Theme.muted)
                .lineLimit(1)
        }
        .padding(.leading, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            IslandEffectBackground(state: state, width: 40, height: 22, pixel: 2, mode: mode)
        }
        .clipped()
    }
}

struct ExpandedTrailingView: View {
    let state: IslandState
    var mode: PlaybackMode = .liveActivity

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            if let partner = state.partner {
                Text(partner.name)
                    .font(Theme.pixelFont(13))
                    .foregroundStyle(Theme.cream)
                    .lineLimit(1)
                Text(state.daysText ?? "♥")
                    .font(Theme.roundedFont(11, weight: .medium))
                    .foregroundStyle(Theme.pink)
            } else {
                Text("Pixel")
                    .font(Theme.pixelFont(11))
                    .foregroundStyle(Theme.muted)
                Text("Island")
                    .font(Theme.pixelFont(11))
                    .foregroundStyle(Theme.peach)
            }
        }
        .padding(.trailing, 6)
        .frame(maxWidth: .infinity, alignment: .trailing)
        .background {
            IslandEffectBackground(state: state, width: 40, height: 22, pixel: 2, mode: mode)
        }
        .clipped()
    }
}

struct ExpandedBottomView: View {
    let state: IslandState
    let isStale: Bool
    let mode: PlaybackMode

    var body: some View {
        VStack(spacing: 8) {
            MainStage(state: state, layout: .expanded, mode: mode)
                .frame(maxWidth: .infinity)

            if let focus = state.focus {
                FocusRow(focus: focus, isFocusing: state.isFocusing(isStale: isStale))
            }

            HStack(spacing: 6) {
                IslandButton(action: .pet, intent: PetIntent(), opensApp: state.buttonsOpenApp) {
                    IslandChip(title: "Погладить", systemImage: "heart.fill", tint: Theme.pink)
                }
                if state.focus != nil {
                    IslandButton(action: .stopFocus, intent: StopFocusIntent(), opensApp: state.buttonsOpenApp) {
                        IslandChip(title: "Стоп", systemImage: "stop.fill", tint: Theme.mint)
                    }
                } else {
                    IslandButton(action: .next, intent: NextActivityIntent(), opensApp: state.buttonsOpenApp) {
                        IslandChip(title: "Дальше", systemImage: "sparkles", tint: Theme.mint)
                    }
                }
                IslandButton(action: .sleep, intent: ToggleSleepIntent(), opensApp: state.buttonsOpenApp) {
                    IslandChip(
                        title: state.isSleeping ? "Будить" : "Спать",
                        systemImage: state.isSleeping ? "sun.max.fill" : "moon.fill",
                        tint: Theme.peach
                    )
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 4)
    }
}

/// A button in the expanded island: a silent App Intent, or a link that
/// opens the app when the user switched to that fallback.
struct IslandButton<Intent: LiveActivityIntent, Content: View>: View {
    let action: IslandAction
    let intent: Intent
    let opensApp: Bool
    @ViewBuilder let label: Content

    var body: some View {
        if opensApp {
            Link(destination: action.url) { label }
        } else {
            Button(intent: intent) { label }
        }
    }
}

struct IslandChip: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(Theme.roundedFont(12))
            .lineLimit(1)
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.16), in: Capsule())
    }
}

struct FocusRow: View {
    let focus: FocusSession
    let isFocusing: Bool

    var body: some View {
        if isFocusing {
            HStack(spacing: 10) {
                Image(systemName: "moon.zzz.fill")
                    .foregroundStyle(Theme.peach)
                ProgressView(
                    timerInterval: focus.interval,
                    countsDown: false,
                    label: { EmptyView() },
                    currentValueLabel: { EmptyView() }
                )
                .tint(Theme.peach)
                Text(timerInterval: focus.interval, countsDown: true)
                    .font(Theme.pixelFont(13))
                    .monospacedDigit()
                    .foregroundStyle(Theme.cream)
                    .frame(width: 52, alignment: .trailing)
            }
        } else {
            Text("Фокус окончен, перерыв! ✨")
                .font(Theme.roundedFont(13))
                .foregroundStyle(Theme.mint)
        }
    }
}

// MARK: - Lock screen

struct LockScreenIslandView: View {
    let state: IslandState
    let isStale: Bool
    let mode: PlaybackMode

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                title
                Spacer(minLength: 8)
                if let days = state.daysText {
                    Text(days)
                        .font(Theme.roundedFont(12))
                        .foregroundStyle(Theme.pink)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Theme.pink.opacity(0.15), in: Capsule())
                }
            }

            MainStage(state: state, layout: .lockScreen, mode: mode)
                .frame(maxWidth: .infinity)

            if let focus = state.focus {
                FocusRow(focus: focus, isFocusing: state.isFocusing(isStale: isStale))
            }
        }
        .padding(14)
        .background {
            IslandEffectBackground(state: state, width: 160, height: 46, pixel: 7.0 / 3.0, mode: mode)
        }
        .clipped()
    }

    private var title: some View {
        HStack(spacing: 6) {
            Text(state.me.name)
                .foregroundStyle(Theme.cream)
            if let partner = state.partner {
                PixelHeart(pixel: 1.5)
                Text(partner.name)
                    .foregroundStyle(Theme.cream)
            }
        }
        .font(Theme.pixelFont(14))
        .lineLimit(1)
    }
}
