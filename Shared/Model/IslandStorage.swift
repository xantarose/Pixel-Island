import Foundation

/// Saves the island setup on the device (UserDefaults, app sandbox only).
/// Nothing leaves the phone: there is no server and no analytics.
enum IslandStorage {
    private static let stateKey = "pixelisland.state.v1"
    private static let wantsRunningKey = "pixelisland.wantsRunning"
    private static let startedAtKey = "pixelisland.startedAt"
    private static let lastButtonKey = "pixelisland.lastButton"
    private static let lastButtonDateKey = "pixelisland.lastButtonDate"

    static func load(from defaults: UserDefaults = .standard) -> IslandState {
        guard
            let data = defaults.data(forKey: stateKey),
            let state = try? JSONDecoder().decode(IslandState.self, from: data)
        else {
            return .initial
        }
        var clean = state.sanitized()
        clean.showsHearts = false
        return clean
    }

    static func save(_ state: IslandState, to defaults: UserDefaults = .standard) {
        var copy = state
        copy.showsHearts = false
        if let data = try? JSONEncoder().encode(copy) {
            defaults.set(data, forKey: stateKey)
        }
    }

    /// The user pressed "start" and did not press "stop": bring the pet back
    /// automatically after iOS ends the Live Activity (8 hour limit).
    static var wantsRunning: Bool {
        get { UserDefaults.standard.bool(forKey: wantsRunningKey) }
        set { UserDefaults.standard.set(newValue, forKey: wantsRunningKey) }
    }

    /// Diagnostics: the last island button that reached the app process.
    static func noteButton(_ name: String) {
        UserDefaults.standard.set(name, forKey: lastButtonKey)
        UserDefaults.standard.set(Date.now, forKey: lastButtonDateKey)
    }

    static var lastButton: (name: String, date: Date)? {
        guard
            let name = UserDefaults.standard.string(forKey: lastButtonKey),
            let date = UserDefaults.standard.object(forKey: lastButtonDateKey) as? Date
        else { return nil }
        return (name, date)
    }

    static var startedAt: Date? {
        get { UserDefaults.standard.object(forKey: startedAtKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: startedAtKey) }
    }
}
