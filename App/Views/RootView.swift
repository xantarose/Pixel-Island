import SwiftUI

/// Four tabs, one topic each: the island, your cat, the couple, focus & sleep.
struct RootView: View {
    @Environment(IslandModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase

    @State private var tab: Tab = .island

    enum Tab: Hashable {
        case island, cat, couple, focus
    }

    var body: some View {
        TabView(selection: $tab) {
            IslandTab()
                .tabItem { Label("Островок", systemImage: "sparkles") }
                .tag(Tab.island)
            CatTab()
                .tabItem { Label("Котик", systemImage: "pawprint.fill") }
                .tag(Tab.cat)
            CoupleTab()
                .tabItem { Label("Пара", systemImage: "heart.fill") }
                .tag(Tab.couple)
            FocusTab()
                .tabItem { Label("Фокус", systemImage: "moon.zzz.fill") }
                .tag(Tab.focus)
        }
        .overlay(alignment: .bottom) { toast }
        .task {
            // onChange below doesn't fire for the initial phase of a cold launch.
            await model.appBecameActive()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await model.appBecameActive() }
            } else if phase == .background {
                model.flushSync()
            }
        }
    }

    @ViewBuilder
    private var toast: some View {
        if let message = model.message {
            Text(message)
                .font(Theme.roundedFont(14))
                .foregroundStyle(Theme.cream)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Theme.cardBorder, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.horizontal, 16)
                .padding(.bottom, 70)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .task(id: message) {
                    try? await Task.sleep(for: .seconds(4))
                    model.message = nil
                }
                .onTapGesture { model.message = nil }
        }
    }
}

/// Scrollable page with a big title, shared by all tabs.
struct TabPage<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(Theme.pixelFont(28, weight: .heavy))
                        .foregroundStyle(Theme.cream)
                    Text(subtitle)
                        .font(Theme.roundedFont(14, weight: .regular))
                        .foregroundStyle(Theme.muted)
                }
                .padding(.top, 8)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isHeader)
                content
            }
            .padding(16)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.background.ignoresSafeArea())
    }
}

/// A small grey hint under a section.
struct Hint: View {
    let text: String

    var body: some View {
        Text(text)
            .font(Theme.roundedFont(13, weight: .regular))
            .foregroundStyle(Theme.muted)
            .fixedSize(horizontal: false, vertical: true)
    }
}
