import AppIntents
import SwiftUI

@main
struct PixelIslandApp: App {
    @State private var model = IslandModel()

    init() {
        // Keep every island button's intent type alive in the app binary.
        _ = IslandIntents.all
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .onOpenURL { model.handle($0) }
                .preferredColorScheme(.dark)
                .tint(Theme.peach)
        }
    }
}

/// Shows "Запустить Pixel Island" in the Shortcuts app, so the pet can be
/// brought back automatically (e.g. a "Every day at 8:00" automation).
struct PixelIslandShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartIslandIntent(),
            phrases: ["Start \(.applicationName)"],
            shortTitle: "Запустить остров",
            systemImageName: "pawprint.fill"
        )
    }
}
