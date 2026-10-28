import Foundation
import SwiftUI

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
    case auto, none, sakura, snow, rain, hearts, fireflies, leaves, stars, confetti

    var title: String {
        switch self {
        case .auto: return "Авто"
        case .none: return "Без"
        case .sakura: return "Сакура"
        case .snow: return "Снег"
        case .rain: return "Дождик"
        case .hearts: return "Сердечки"
        case .fireflies: return "Светлячки"
        case .leaves: return "Листопад"
        case .stars: return "Звёзды"
        case .confetti: return "Конфетти"
        }
    }

    var emoji: String {
        switch self {
        case .auto: return "🪄"
        case .none: return "▫️"
        case .sakura: return "🌸"
        case .snow: return "❄️"
        case .rain: return "🌧️"
        case .hearts: return "💗"
        case .fireflies: return "✨"
        case .leaves: return "🍂"
        case .stars: return "⭐"
        case .confetti: return "🎉"
        }
    }
}

/// How wide the compact island gets.
enum IslandWidth: String, Codable, CaseIterable, Hashable {
    /// As close to the empty system island as possible: pets stay in place.
    case narrow
    /// Pets walk a few steps; the island grows a bit.
    case wide

    var title: String {
        switch self {
        case .narrow: return "Узкий"
        case .wide: return "Широкий"
        }
    }

    var emoji: String {
        switch self {
        case .narrow: return "💊"
        case .wide: return "🛋️"
        }
    }
}

/// Little picture on the right side of the island (when there is no
/// partner pet or timer to show there).
enum IslandBadge: String, Codable, CaseIterable, Hashable {
    case none, heart, heartbeat, redHeart, whiteHeart, twoHearts, sparkle, star, moon, paw, sakura, sakuraTree
    case petals, cherries, butterfly, crown, fish, note, cloud, rainbow, snowflake, mushroom, tulip, sun, bow, clover

    var title: String {
        switch self {
        case .none: return "Убрать"
        case .heart: return "Сердечко"
        case .heartbeat: return "Бьётся"
        case .redHeart: return "Красное"
        case .whiteHeart: return "Белое"
        case .twoHearts: return "Два сердца"
        case .sparkle: return "Блёстка"
        case .star: return "Звезда"
        case .moon: return "Луна"
        case .paw: return "Лапка"
        case .sakura: return "Сакура"
        case .sakuraTree: return "Дерево сакуры"
        case .petals: return "Лепестки"
        case .cherries: return "Вишенки"
        case .butterfly: return "Бабочка"
        case .crown: return "Корона"
        case .fish: return "Рыбка"
        case .note: return "Нотка"
        case .cloud: return "Облачко"
        case .rainbow: return "Радуга"
        case .snowflake: return "Снежинка"
        case .mushroom: return "Грибок"
        case .tulip: return "Тюльпан"
        case .sun: return "Солнце"
        case .bow: return "Бантик"
        case .clover: return "Клевер"
        }
    }

    var emoji: String {
        switch self {
        case .none: return "▫️"
        case .heart: return "🩷"
        case .heartbeat: return "💓"
        case .redHeart: return "❤️"
        case .whiteHeart: return "🤍"
        case .twoHearts: return "💕"
        case .sparkle: return "✨"
        case .star: return "⭐"
        case .moon: return "🌙"
        case .paw: return "🐾"
        case .sakura: return "🌸"
        case .sakuraTree: return "🌳"
        case .petals: return "🌸"
        case .cherries: return "🍒"
        case .butterfly: return "🦋"
        case .crown: return "👑"
        case .fish: return "🐟"
        case .note: return "🎵"
        case .cloud: return "☁️"
        case .rainbow: return "🌈"
        case .snowflake: return "❄️"
        case .mushroom: return "🍄"
        case .tulip: return "🌷"
        case .sun: return "☀️"
        case .bow: return "🎀"
        case .clover: return "🍀"
        }
    }
}

/// Colour of the thin outline iOS draws around the island. iOS decides
/// where it is visible (mostly over dark content); `off` asks for none.
enum KeylineColor: String, Codable, CaseIterable, Hashable {
    case off, pink, red, peach, gold, mint, sky, lavender, white

    var title: String {
        switch self {
        case .off: return "Без обводки"
        case .pink: return "Розовая"
        case .red: return "Красная"
        case .peach: return "Персик"
        case .gold: return "Золото"
        case .mint: return "Мята"
        case .sky: return "Небо"
        case .lavender: return "Лаванда"
        case .white: return "Белая"
        }
    }

    var color: Color? {
        self == .off ? nil : Color(hex: hex)
    }

    var hex: UInt32 {
        switch self {
        case .off: return 0x000000
        case .pink: return 0xFF7FA8
        case .red: return 0xFF3B5C
        case .peach: return 0xFF9F7A
        case .gold: return 0xFFD45E
        case .mint: return 0x8FE3B0
        case .sky: return 0x7FB8FF
        case .lavender: return 0xB89CFF
        case .white: return 0xFFFFFF
        }
    }
}

/// Where particles fall: just around the pet, or across the whole island.
enum EffectScope: String, Codable, CaseIterable, Hashable {
    case pet, island

    var title: String {
        switch self {
        case .pet: return "Вокруг котика"
        case .island: return "На весь островок"
        }
    }

    var emoji: String {
        switch self {
        case .pet: return "🐈"
        case .island: return "🏝️"
        }
    }
}
