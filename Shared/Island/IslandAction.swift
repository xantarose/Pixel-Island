import Foundation

/// What the buttons in the expanded island do. Reachable two ways:
/// as App Intents (the normal, silent way) or as `pixelisland://` links that
/// open the app (fallback for builds where iOS doesn't deliver intents).
enum IslandAction: String, CaseIterable {
    case pet
    case next
    case sleep
    case stopFocus

    var title: String {
        switch self {
        case .pet: return "погладить"
        case .next: return "дальше"
        case .sleep: return "спать"
        case .stopFocus: return "стоп"
        }
    }

    var url: URL {
        URL(string: "pixelisland://" + rawValue) ?? URL(fileURLWithPath: "/")
    }

    /// Only our own scheme and the four known actions are accepted; anything
    /// else (a crafted link from another app) is ignored.
    init?(url: URL) {
        guard url.scheme?.lowercased() == "pixelisland",
              let host = url.host(),
              let action = IslandAction(rawValue: host)
        else { return nil }
        self = action
    }

    /// `viaIntent`: called by an App Intent (not a link). Remembered for the
    /// diagnostics line in the app.
    @MainActor
    func perform(viaIntent: Bool = false) async {
        #if !WIDGET_EXTENSION
        if viaIntent {
            IslandStorage.noteButton(rawValue)
        }
        #endif
        switch self {
        case .pet:
            await IslandController.flashHearts()
        case .next:
            await IslandController.modify { state in
                if state.partner != nil {
                    state.activity = state.activity.next
                } else {
                    let all = SoloPose.allCases
                    let index = all.firstIndex(of: state.pose) ?? 0
                    state.pose = all[(index + 1) % all.count]
                }
                state.isSleeping = false
            }
        case .sleep:
            await IslandController.modify { $0.isSleeping.toggle() }
        case .stopFocus:
            await IslandController.modify { $0.focus = nil }
            #if !WIDGET_EXTENSION
            FocusNotifications.cancel()
            #endif
        }
    }
}
