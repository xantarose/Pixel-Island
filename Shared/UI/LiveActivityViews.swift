import AppIntents
import SwiftUI

// Views shown by the Live Activity. They live in Shared so the app can render
// the exact same views as a preview (with `.inApp` playback).

/// Points per art pixel in the compact island. 16 px * 2 pt = 32 pt tall.
private let compactPixel: CGFloat = 2
/// How far the pet strolls inside the compact island, in art pixels.
private let compactRange = 6

private extension IslandState {
    func isFocusing(isStale: Bool, now: Date = .now) -> Bool {
        guard let focus else { return false }
        return !isStale && !focus.isFinished(at: now)
    }

    var daysText: String? {
        guard let days = daysTogether() else { return nil }
        return "\(days) \(RussianPlural.days(days))"
    }

    var statusText: String {
        if isSleeping { return "спит" }
        if focus != nil { return "фокус" }
        return partner == nil ? "гуляет" : "гуляют"
    }
}

// MARK: - Compact & minimal

struct CompactLeadingView: View {
    let state: IslandState
    let isStale: Bool
    let mode: PlaybackMode

    var body: some View {
        let scene: PetScene = state.isSleeping || state.isFocusing(isStale: isStale)
            ? .sleeping()
            : .patrol(range: compactRange)
        PetSceneView(pet: state.me.sprite, scene: scene, pixel: compactPixel, mode: mode)
    }
}

struct CompactTrailingView: View {
    let state: IslandState
    let isStale: Bool
    let mode: PlaybackMode

    var body: some View {
        if let focus = state.focus, state.isFocusing(isStale: isStale) {
            Text(timerInterval: focus.interval, countsDown: true)
                .font(Theme.pixelFont(13))
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
                .foregroundStyle(Theme.peach)
                .frame(width: 46)
        } else if state.showsHearts {
            PixelHeart(pixel: 3)
        } else if let partner = state.partner {
            let scene: PetScene = state.isSleeping
                ? .sleeping(flipped: true)
                : .patrol(range: compactRange, startsFacingLeft: true)
            PetSceneView(pet: partner.sprite, scene: scene, pixel: compactPixel, mode: mode)
        } else {
            PixelHeart(pixel: 2.5)
        }
    }
}

struct MinimalIslandView: View {
    let state: IslandState
    let mode: PlaybackMode

    var body: some View {
        let scene: PetScene = state.isSleeping ? .sleeping() : .standing()
        PetSceneView(pet: state.me.sprite, scene: scene, pixel: compactPixel, mode: mode)
    }
}

// MARK: - Expanded

struct ExpandedLeadingView: View {
    let state: IslandState

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(state.me.name)
                .font(Theme.pixelFont(14))
                .foregroundStyle(Theme.cream)
                .lineLimit(1)
            Text(state.statusText)
                .font(Theme.roundedFont(11, weight: .medium))
                .foregroundStyle(Theme.muted)
        }
        .padding(.leading, 6)
    }
}

struct ExpandedTrailingView: View {
    let state: IslandState

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            if let partner = state.partner {
                Text(partner.name)
                    .font(Theme.pixelFont(14))
                    .foregroundStyle(Theme.cream)
                    .lineLimit(1)
                Text(state.daysText ?? "♥")
                    .font(Theme.roundedFont(11, weight: .medium))
                    .foregroundStyle(Theme.pink)
            } else {
                Text("Pixel")
                    .font(Theme.pixelFont(12))
                    .foregroundStyle(Theme.muted)
                Text("Island")
                    .font(Theme.pixelFont(12))
                    .foregroundStyle(Theme.peach)
            }
        }
        .padding(.trailing, 6)
    }
}

struct ExpandedBottomView: View {
    let state: IslandState
    let isStale: Bool
    let mode: PlaybackMode

    var body: some View {
        VStack(spacing: 10) {
            IslandStage(state: state, pixel: 7.0 / 3.0, range: 10, mode: mode)
                .frame(maxWidth: .infinity)

            if let focus = state.focus {
                FocusRow(focus: focus, isFocusing: state.isFocusing(isStale: isStale))
            }

            HStack(spacing: 8) {
                Button(intent: PetIntent()) {
                    IslandChip(title: "Погладить", systemImage: "heart.fill", tint: Theme.pink)
                }
                Button(intent: ToggleSleepIntent()) {
                    IslandChip(
                        title: state.isSleeping ? "Разбудить" : "Спать",
                        systemImage: state.isSleeping ? "sun.max.fill" : "moon.fill",
                        tint: Theme.peach
                    )
                }
                if state.focus != nil {
                    Button(intent: StopFocusIntent()) {
                        IslandChip(title: "Стоп", systemImage: "stop.fill", tint: Theme.mint)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 4)
    }
}

struct IslandChip: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(Theme.roundedFont(13))
            .foregroundStyle(tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
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
        VStack(alignment: .leading, spacing: 10) {
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

            IslandStage(state: state, pixel: 3, range: 14, mode: mode)
                .frame(maxWidth: .infinity)

            if let focus = state.focus {
                FocusRow(focus: focus, isFocusing: state.isFocusing(isStale: isStale))
            }
        }
        .padding(16)
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
