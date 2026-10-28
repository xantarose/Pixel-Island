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
    var pose: SoloPose
    var activity: CoupleActivity
    var effect: AtmosphereEffect

    static let initial = IslandState(
        me: .defaultMine,
        partner: nil,
        togetherSince: nil,
        isSleeping: false,
        focus: nil,
        showsHearts: false,
        pose: .auto,
        activity: .walk,
        effect: .auto
    )

    init(
        me: PetProfile,
        partner: PetProfile?,
        togetherSince: Date?,
        isSleeping: Bool,
        focus: FocusSession?,
        showsHearts: Bool,
        pose: SoloPose,
        activity: CoupleActivity,
        effect: AtmosphereEffect
    ) {
        self.me = me
        self.partner = partner
        self.togetherSince = togetherSince
        self.isSleeping = isSleeping
        self.focus = focus
        self.showsHearts = showsHearts
        self.pose = pose
        self.activity = activity
        self.effect = effect
    }

    /// Tolerant decoding: settings saved by an older version (or an unknown
    /// value from a newer one) fall back to defaults instead of wiping
    /// everything the user set up.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        me = try c.decode(PetProfile.self, forKey: .me)
        partner = try? c.decodeIfPresent(PetProfile.self, forKey: .partner)
        togetherSince = try? c.decodeIfPresent(Date.self, forKey: .togetherSince)
        isSleeping = (try? c.decodeIfPresent(Bool.self, forKey: .isSleeping)) ?? false
        focus = try? c.decodeIfPresent(FocusSession.self, forKey: .focus)
        showsHearts = (try? c.decodeIfPresent(Bool.self, forKey: .showsHearts)) ?? false
        pose = (try? c.decodeIfPresent(SoloPose.self, forKey: .pose)) ?? .auto
        activity = (try? c.decodeIfPresent(CoupleActivity.self, forKey: .activity)) ?? .walk
        effect = (try? c.decodeIfPresent(AtmosphereEffect.self, forKey: .effect)) ?? .auto
    }

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

    func isFocusing(isStale: Bool = false, now: Date = .now) -> Bool {
        guard let focus else { return false }
        return !isStale && !focus.isFinished(at: now)
    }

    /// The effect actually shown once "Авто" is resolved.
    var resolvedEffect: AtmosphereEffect {
        if showsHearts { return .hearts }
        if effect != .auto { return effect }
        if isSleeping { return .stars }
        return partner == nil ? .none : activity.defaultEffect
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
