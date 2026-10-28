import ActivityKit
import Foundation

/// Starts, updates and stops the Live Activity. App target only.
@MainActor
enum IslandController {
    typealias IslandActivity = Activity<PixelIslandAttributes>

    /// iOS lets one activity stay in the island for about 8 hours. Restart a
    /// bit earlier when the app is opened so the pet never disappears mid-day.
    static let refreshAfter: TimeInterval = 6 * 60 * 60

    enum StartError: LocalizedError {
        case disabled

        var errorDescription: String? {
            "Живые активности выключены. Включи их: Настройки → Pixel Island → Живые активности."
        }
    }

    static var current: IslandActivity? {
        IslandActivity.activities.first { activity in
            activity.activityState == .active || activity.activityState == .stale
        }
    }

    static var areActivitiesEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    static func start(_ state: IslandState) async throws {
        guard areActivitiesEnabled else { throw StartError.disabled }
        await endAll()
        _ = try IslandActivity.request(
            attributes: PixelIslandAttributes(),
            content: content(for: state),
            pushType: nil
        )
        IslandStorage.startedAt = .now
        IslandStorage.wantsRunning = true
    }

    static func update(_ state: IslandState) async {
        guard let activity = current else { return }
        await activity.update(content(for: state))
    }

    static func stop() async {
        IslandStorage.wantsRunning = false
        IslandStorage.startedAt = nil
        await endAll()
    }

    /// Called when the app comes to the foreground.
    static func reviveIfNeeded(_ state: IslandState) async {
        guard IslandStorage.wantsRunning, areActivitiesEnabled else { return }
        let age = IslandStorage.startedAt.map { Date.now.timeIntervalSince($0) } ?? .infinity
        if current == nil || age > refreshAfter {
            try? await start(state)
        } else {
            await update(state)
        }
    }

    /// Hearts for four seconds, then back to normal.
    static func flashHearts() async {
        guard let activity = current else { return }
        var state = activity.content.state
        state.showsHearts = true
        await activity.update(content(for: state))
        try? await Task.sleep(for: .seconds(4))
        state.showsHearts = false
        await activity.update(content(for: state))
    }

    private static func endAll() async {
        for activity in IslandActivity.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    /// `staleDate` = end of the focus timer: when it passes, iOS redraws the
    /// activity with `isStale == true` and the island can say "done" on its own.
    private static func content(for state: IslandState) -> ActivityContent<IslandState> {
        ActivityContent(state: state, staleDate: state.focus?.end)
    }
}
