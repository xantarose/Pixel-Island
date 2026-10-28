import Foundation

/// What your pet does when it is alone (or in the small island).
enum SoloPose: String, Codable, CaseIterable, Hashable {
    case auto, walk, sit, loaf, groom, play, nap

    var title: String {
        switch self {
        case .auto: return "Сам решает"
        case .walk: return "Гуляет"
        case .sit: return "Сидит"
        case .loaf: return "Лежит"
        case .groom: return "Умывается"
        case .play: return "Играет"
        case .nap: return "Дремлет"
        }
    }

    var emoji: String {
        switch self {
        case .auto: return "✨"
        case .walk: return "🐾"
        case .sit: return "🐈"
        case .loaf: return "🍞"
        case .groom: return "👅"
        case .play: return "🧶"
        case .nap: return "💤"
        }
    }
}

/// What the two pets do together.
enum CoupleActivity: String, Codable, CaseIterable, Hashable {
    case walk, cuddle, boop, nap, sakura, chase, yarn, stars

    var title: String {
        switch self {
        case .walk: return "Прогулка"
        case .cuddle: return "Обнимашки"
        case .boop: return "Чмок"
        case .nap: return "Тихий час"
        case .sakura: return "Под сакурой"
        case .chase: return "Догонялки"
        case .yarn: return "Клубок"
        case .stars: return "Звездопад"
        }
    }

    var emoji: String {
        switch self {
        case .walk: return "🚶"
        case .cuddle: return "🤗"
        case .boop: return "😽"
        case .nap: return "😴"
        case .sakura: return "🌸"
        case .chase: return "🏃"
        case .yarn: return "🧶"
        case .stars: return "🌠"
        }
    }

    /// Atmosphere used when the user leaves it on "Авто".
    var defaultEffect: AtmosphereEffect {
        switch self {
        case .cuddle: return .hearts
        case .nap: return .fireflies
        case .sakura: return .sakura
        case .stars: return .stars
        case .walk, .boop, .chase, .yarn: return .none
        }
    }

    /// Pose of each pet in the tiny compact island.
    var compactPose: SoloPose {
        switch self {
        case .walk, .chase: return .walk
        case .cuddle, .sakura: return .loaf
        case .boop, .stars: return .sit
        case .nap: return .nap
        case .yarn: return .play
        }
    }

    var next: CoupleActivity {
        let all = Self.allCases
        let index = all.firstIndex(of: self) ?? 0
        return all[(index + 1) % all.count]
    }
}

/// Particles drawn over the pets.
enum AtmosphereEffect: String, Codable, CaseIterable, Hashable {
    case auto, none, sakura, snow, hearts, fireflies, leaves, stars

    var title: String {
        switch self {
        case .auto: return "Авто"
        case .none: return "Без"
        case .sakura: return "Сакура"
        case .snow: return "Снег"
        case .hearts: return "Сердечки"
        case .fireflies: return "Светлячки"
        case .leaves: return "Листопад"
        case .stars: return "Звёзды"
        }
    }

    var emoji: String {
        switch self {
        case .auto: return "🪄"
        case .none: return "▫️"
        case .sakura: return "🌸"
        case .snow: return "❄️"
        case .hearts: return "💗"
        case .fireflies: return "✨"
        case .leaves: return "🍂"
        case .stars: return "⭐"
        }
    }
}
