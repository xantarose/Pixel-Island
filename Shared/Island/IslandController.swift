import ActivityKit
import Foundation

/// Starts, updates and stops the Live Activity.
///
/// Compiled into both targets. Island buttons are App Intents that iOS should
/// run in the app, but with a re-signed build iOS 26 may run them in the
/// widget extension instead. So the button actions only touch the activity's
/// own state (works in either process); starting a new activity and the
/// local storage are app-only.
@MainActor
enum IslandController {
    typealias IslandActivity = Activity<PixelIslandAttributes>

    static var current: IslandActivity? {
        IslandActivity.activities.first { activity in
            activity.activityState == .active || activity.activityState == .stale
        }
    }

    static func update(_ state: IslandState) async {
        guard let activity = current else { return }
        await activity.update(content(for: state))
    }

    /// Change the running activity's state in place (island buttons).
    static func modify(_ change: (inout IslandState) -> Void) async {
        guard let activity = current else { return }
        var state = activity.content.state
        change(&state)
        await activity.update(content(for: state))
        #if !WIDGET_EXTENSION
        var stored = IslandStorage.load()
        change(&stored)
        stored.showsHearts = false
        IslandStorage.save(stored)
        #endif
    }

    /// Hearts for four seconds, then back to normal.
    static func flashHearts() async {
        await modify { $0.showsHearts = true }
        try? await Task.sleep(for: .seconds(4))
        await modify { $0.showsHearts = false }
    }

    /// `staleDate` = end of the focus timer: when it passes, iOS redraws the
    /// activity with `isStale == true` and the island can say "done" on its own.
    static func content(for state: IslandState) -> ActivityContent<IslandState> {
        ActivityContent(state: state, staleDate: state.focus?.end)
    }

    #if !WIDGET_EXTENSION
    /// iOS lets one activity stay in the island for about 8 hours. Restart a
    /// bit earlier when the app is opened so the pet never disappears mid-day.
    static let refreshAfter: TimeInterval = 6 * 60 * 60

    enum StartError: LocalizedError {
        case disabled

        var errorDescription: String? {
            "Живые активности выключены. Включи их: Настройки → Pixel Island → Живые активности."
        }
    }

    static var areActivitiesEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    static func start(_ state: IslandState) async throws {
        guard areActivitiesEnabled else { throw StartError.disabled }
        await endAll()
        var clean = state
        clean.showsHearts = false
        _ = try IslandActivity.request(
            attributes: PixelIslandAttributes(),
            content: content(for: clean),
            pushType: nil
        )
        IslandStorage.startedAt = .now
        IslandStorage.wantsRunning = true
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

    private static func endAll() async {
        for activity in IslandActivity.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
    #endif
}
