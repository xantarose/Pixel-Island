import AppIntents
import Foundation

// Live Activity buttons and Shortcuts actions.
//
// Compiled into both targets. iOS is supposed to run `perform()` in the app,
// but a re-signed build may run it in the widget extension. Every button
// therefore changes the activity through `IslandController.modify`, which
// works in both processes. Only "start" needs the app (WIDGET_EXTENSION is
// defined in the extension build).

/// "Погладить": hearts float above the pets for a few seconds.
struct PetIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Погладить питомца"
    static let description = IntentDescription("Питомец на островке порадуется сердечками.")
    static let isDiscoverable = false

    func perform() async throws -> some IntentResult {
        await IslandAction.pet.perform(viaIntent: true)
        return .result()
    }
}

/// Puts the pets to bed or wakes them up.
struct ToggleSleepIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Уложить спать или разбудить"
    static let description = IntentDescription("Питомцы на островке засыпают или просыпаются.")

    func perform() async throws -> some IntentResult {
        await IslandAction.sleep.perform(viaIntent: true)
        return .result()
    }
}

/// Next couple activity (or next pose when there is no partner).
struct NextActivityIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Следующая активность"
    static let description = IntentDescription("Питомцы на островке переключаются на другое занятие.")

    func perform() async throws -> some IntentResult {
        await IslandAction.next.perform(viaIntent: true)
        return .result()
    }
}

/// Ends the focus timer and lets the pet wake up.
struct StopFocusIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Закончить фокус"
    static let description = IntentDescription("Останавливает таймер фокуса.")
    static let isDiscoverable = false

    func perform() async throws -> some IntentResult {
        await IslandAction.stopFocus.perform(viaIntent: true)
        return .result()
    }
}

/// Referenced from the app so the optimizer can never strip the intent types
/// out of the app binary (iOS then can't find them and buttons do nothing).
enum IslandIntents {
    static let all: [any AppIntent.Type] = [
        PetIntent.self, ToggleSleepIntent.self, NextActivityIntent.self,
        StopFocusIntent.self, StartIslandIntent.self,
    ]
}

/// Starts (or restarts) the pet on the island. Handy in a Shortcuts
/// automation, e.g. every morning, because iOS ends Live Activities after 8 h.
struct StartIslandIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Запустить Pixel Island"
    static let description = IntentDescription("Выпускает питомца на Dynamic Island.")

    func perform() async throws -> some IntentResult {
        #if !WIDGET_EXTENSION
        try await IslandController.start(IslandStorage.load())
        #endif
        return .result()
    }
}
