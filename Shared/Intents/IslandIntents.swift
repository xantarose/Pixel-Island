import AppIntents
import Foundation

// Live Activity buttons and Shortcuts actions.
//
// These files are compiled into both targets: the widget extension needs the
// types to draw `Button(intent:)`, but iOS always runs `perform()` inside the
// app process. The extension build defines WIDGET_EXTENSION, so the real work
// (which uses app-only code) is compiled into the app only.

/// "Погладить": hearts float above the pets for a few seconds.
struct PetIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Погладить питомца"
    static let description = IntentDescription("Питомец на островке порадуется сердечками.")
    static let isDiscoverable = false

    func perform() async throws -> some IntentResult {
        #if !WIDGET_EXTENSION
        await IslandController.flashHearts()
        #endif
        return .result()
    }
}

/// Puts the pets to bed or wakes them up.
struct ToggleSleepIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Уложить спать или разбудить"
    static let description = IntentDescription("Питомцы на островке засыпают или просыпаются.")

    func perform() async throws -> some IntentResult {
        #if !WIDGET_EXTENSION
        var state = IslandStorage.load()
        state.isSleeping.toggle()
        IslandStorage.save(state)
        await IslandController.update(state)
        #endif
        return .result()
    }
}

/// Ends the focus timer and lets the pet wake up.
struct StopFocusIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Закончить фокус"
    static let description = IntentDescription("Останавливает таймер фокуса.")
    static let isDiscoverable = false

    func perform() async throws -> some IntentResult {
        #if !WIDGET_EXTENSION
        var state = IslandStorage.load()
        state.focus = nil
        IslandStorage.save(state)
        FocusNotifications.cancel()
        await IslandController.update(state)
        #endif
        return .result()
    }
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
