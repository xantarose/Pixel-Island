import ActivityKit
import Foundation

/// A pet chosen by someone: which sprite and what it is called.
struct PetProfile: Codable, Hashable {
    var kindID: String
    var name: String

    var sprite: PetSprite { PetCatalog.pet(kindID) }

    /// Never trust stored or received data: unknown kinds fall back to the
    /// default pet, names are cleaned and an empty name becomes the breed name.
    func sanitized() -> PetProfile {
        let kind = PetCatalog.contains(kindID) ? kindID : PetCatalog.defaultID
        let clean = NameSanitizer.clean(name)
        return PetProfile(kindID: kind, name: clean.isEmpty ? PetCatalog.pet(kind).name : clean)
    }

    static let defaultMine = PetProfile(kindID: PetCatalog.defaultID, name: "Рыжик")
}

/// A focus timer ("pomodoro"). The pet naps while you work.
struct FocusSession: Codable, Hashable {
    var start: Date
    var end: Date

    var interval: ClosedRange<Date> { start...max(end, start) }

    func isFinished(at date: Date = .now) -> Bool {
        date >= end
    }
}

/// Everything the island shows. Stored by the app and sent to the Live Activity.
/// Keep it small: ActivityKit caps the payload at 4 KB.
struct IslandState: Codable, Hashable {
    var me: PetProfile
    var partner: PetProfile?
    var togetherSince: Date?
    var isSleeping: Bool
    var focus: FocusSession?
    /// Short-lived "petted" reaction, never persisted as true.
    var showsHearts: Bool

    static let initial = IslandState(
        me: .defaultMine,
        partner: nil,
        togetherSince: nil,
        isSleeping: false,
        focus: nil,
        showsHearts: false
    )

    func sanitized() -> IslandState {
        var copy = self
        copy.me = me.sanitized()
        copy.partner = partner?.sanitized()
        if let since = togetherSince, since > .now {
            copy.togetherSince = nil
        }
        if let focus, focus.end < focus.start {
            copy.focus = nil
        }
        return copy
    }

    /// Whole days since `togetherSince`, counting the first day as day 1.
    func daysTogether(at date: Date = .now, calendar: Calendar = .current) -> Int? {
        guard let since = togetherSince else { return nil }
        let start = calendar.startOfDay(for: since)
        let today = calendar.startOfDay(for: date)
        let days = calendar.dateComponents([.day], from: start, to: today).day ?? 0
        return max(days, 0) + 1
    }
}

struct PixelIslandAttributes: ActivityAttributes {
    typealias ContentState = IslandState
}

enum RussianPlural {
    /// 1 день, 2 дня, 5 дней, 11 дней, 21 день.
    static func days(_ n: Int) -> String {
        let mod10 = n % 10
        let mod100 = n % 100
        if mod10 == 1 && mod100 != 11 { return "день" }
        if (2...4).contains(mod10) && !(12...14).contains(mod100) { return "дня" }
        return "дней"
    }
}
