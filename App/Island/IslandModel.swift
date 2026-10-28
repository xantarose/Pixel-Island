import Foundation
import Observation
import SwiftUI

/// The app's single source of truth. Every change goes through `mutate`,
/// which saves to disk and (debounced) pushes the new state to the island.
@Observable
@MainActor
final class IslandModel {
    private(set) var state: IslandState
    private(set) var isRunning = false
    var message: String?

    @ObservationIgnored private var syncTask: Task<Void, Never>?
    @ObservationIgnored private var watchTask: Task<Void, Never>?

    init() {
        state = IslandStorage.load()
        isRunning = IslandController.current != nil
        watchActivity()
    }

    // MARK: - Editing

    func mutate(_ change: (inout IslandState) -> Void) {
        var copy = state
        change(&copy)
        copy = copy.sanitizedKeepingTyping()
        guard copy != state else { return }
        state = copy
        IslandStorage.save(copy)
        scheduleSync()
    }

    /// Binding for text fields: raw while typing, cleaned when saved.
    func nameBinding(forPartner: Bool) -> Binding<String> {
        Binding(
            get: { forPartner ? (self.state.partner?.name ?? "") : self.state.me.name },
            set: { newValue in
                self.mutate { state in
                    if forPartner {
                        state.partner?.name = newValue
                    } else {
                        state.me.name = newValue
                    }
                }
            }
        )
    }

    /// Typing shouldn't be fought: only trim length and strip invisible
    /// characters here. Empty names get a default when the field loses focus.
    func finishEditingNames() {
        mutate { state in
            state = state.sanitized()
        }
    }

    // MARK: - Island

    func start() async {
        do {
            try await IslandController.start(state)
            isRunning = true
            message = nil
            watchActivity()
        } catch {
            message = error.localizedDescription
        }
    }

    func stop() async {
        await IslandController.stop()
        isRunning = false
    }

    /// App opened: pick up changes made by island buttons, bring the pet back
    /// if iOS ended the activity.
    func appBecameActive() async {
        state = IslandStorage.load()
        // Island buttons may have run outside the app: the activity knows best.
        if let incoming = IslandController.current?.content.state {
            adopt(incoming)
        }
        if let focus = state.focus, focus.isFinished() {
            mutate { $0.focus = nil }
        }
        await IslandController.reviveIfNeeded(state)
        isRunning = IslandController.current != nil
        watchActivity()
    }

    /// Island buttons (sleep, next activity, stop focus) run in the background
    /// and change the activity directly. While the app is open, pick those
    /// changes up so the next edit here doesn't overwrite them. Only the
    /// fields those buttons touch are taken over: names being typed stay.
    private func watchActivity() {
        watchTask?.cancel()
        guard let activity = IslandController.current else { return }
        watchTask = Task { [weak self] in
            for await content in activity.contentUpdates {
                guard let self, !Task.isCancelled else { return }
                self.adopt(content.state)
            }
        }
    }

    /// Take over what island buttons can change; keep everything else.
    private func adopt(_ incoming: IslandState) {
        var merged = state
        merged.isSleeping = incoming.isSleeping
        merged.activity = incoming.activity
        merged.pose = incoming.pose
        if incoming.focus == nil {
            merged.focus = nil
        }
        if merged != state {
            state = merged
            IslandStorage.save(merged)
        }
    }

    private func scheduleSync() {
        syncTask?.cancel()
        let snapshot = state
        syncTask = Task {
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            await IslandController.update(snapshot)
        }
    }

    // MARK: - Partner

    func importPartner(from text: String) -> Bool {
        do {
            let partner = try PairCode.parse(text)
            mutate { state in
                state.partner = partner
                if state.togetherSince == nil {
                    state.togetherSince = .now
                }
            }
            message = "\(partner.name) теперь рядом ♥"
            return true
        } catch {
            message = error.localizedDescription
            return false
        }
    }

    func removePartner() {
        mutate { $0.partner = nil }
    }

    // MARK: - Focus

    func startFocus(minutes: Int) {
        let start = Date.now
        let end = start.addingTimeInterval(TimeInterval(minutes * 60))
        mutate { state in
            state.focus = FocusSession(start: start, end: end)
            state.isSleeping = false
        }
        let name = state.me.name
        Task { await FocusNotifications.schedule(at: end, petName: name) }
        if !isRunning {
            Task { await self.start() }
        }
    }

    func stopFocus() {
        mutate { $0.focus = nil }
        FocusNotifications.cancel()
    }
}

private extension IslandState {
    /// Like `sanitized()` but keeps empty names so the user can clear a field
    /// and type a new name without it snapping back to the default.
    func sanitizedKeepingTyping() -> IslandState {
        var copy = self
        copy.me.name = NameSanitizer.cleanWhileTyping(me.name)
        copy.partner?.name = NameSanitizer.cleanWhileTyping(partner?.name ?? "")
        if !PetCatalog.contains(copy.me.kindID) {
            copy.me.kindID = PetCatalog.defaultID
        }
        if let partner = copy.partner, !PetCatalog.contains(partner.kindID) {
            copy.partner?.kindID = PetCatalog.defaultID
        }
        return copy
    }
}
