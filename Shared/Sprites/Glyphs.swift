import SwiftUI

/// Small sprites that are not pets: hearts, sleep "Z", a ball of yarn.
enum StageGlyph: Hashable {
    case heart
    case smallHeart
    /// 💤 drawn in two stages: the small "z" alone, then with a bigger "Z".
    case zzzOne
    case zzzTwo
    case yarn
    case sparkle
    // Badges for the right side of the island.
    case redHeart
    case whiteHeart
    case twoHearts
    case star
    case moon
    case paw
    case sakura

    var frame: PixelFrame { Self.frames[self] ?? PixelFrame(rows: []) }

    static let palette: [Character: Color] = [
        "o": Color(hex: 0x5A1F36),
        "P": Color(hex: 0xFF6F9F),
        "W": Color(hex: 0xFFF1F6),
        "Z": Color(hex: 0xCFC6FF),
        "Y": Color(hex: 0xFF8FB8),
        "y": Color(hex: 0xD9557F),
        "S": Color(hex: 0xFFF3A0),
        "R": Color(hex: 0xFF3B5C),
        "r": Color(hex: 0x8A1430),
        "g": Color(hex: 0x8E86A0),
        "M": Color(hex: 0xFFE9A8),
        "K": Color(hex: 0xFFB3CB),
        "k": Color(hex: 0xF07AA3),
        "B": Color(hex: 0xF6F2FA),
    ]

    private static let frames: [StageGlyph: PixelFrame] = [
        .heart: PixelFrame(rows: [
            ".oo.oo.",
            "oPPoPPo",
            "oPWPPPo",
            "oPPPPPo",
            ".oPPPo.",
            "..oPo..",
            "...o...",
        ]),
        .smallHeart: PixelFrame(rows: [
            "PP.PP",
            "PWPPP",
            "PPPPP",
            ".PPP.",
            "..P..",
        ]),
        .zzzOne: PixelFrame(rows: [
            ".........",
            ".........",
            ".........",
            ".........",
            ".........",
            "ZZZZ.....",
            "..Z......",
            ".Z.......",
            "ZZZZ.....",
        ]),
        .zzzTwo: PixelFrame(rows: [
            "....ZZZZZ",
            ".......Z.",
            "......Z..",
            ".....Z...",
            "....ZZZZZ",
            "ZZZZ.....",
            "..Z......",
            ".Z.......",
            "ZZZZ.....",
        ]),
        .yarn: PixelFrame(rows: [
            ".YYY.",
            "YyYYY",
            "YYyYY",
            "YYYyY",
            ".YYY.",
        ]),
        .sparkle: PixelFrame(rows: [
            "...W...",
            "...W...",
            "..WSW..",
            "WWSSSWW",
            "..WSW..",
            "...W...",
            "...W...",
        ]),
        .redHeart: PixelFrame(rows: [
            ".rr.rr.",
            "rRRrRRr",
            "rRWRRRr",
            "rRRRRRr",
            ".rRRRr.",
            "..rRr..",
            "...r...",
        ]),
        .whiteHeart: PixelFrame(rows: [
            ".gg.gg.",
            "gBBgBBg",
            "gBBBBBg",
            "gBBBBBg",
            ".gBBBg.",
            "..gBg..",
            "...g...",
        ]),
        .twoHearts: PixelFrame(rows: [
            "PP.PP.....",
            "PWPPP.....",
            "PPPPP.....",
            ".PPPRR.RR.",
            "..P.RWRRR.",
            "....RRRRR.",
            ".....RRR..",
            "......R...",
        ]),
        .star: PixelFrame(rows: [
            "...S...",
            "..SSS..",
            "SSSSSSS",
            ".SSSSS.",
            "..SSS..",
            ".SS.SS.",
            ".S...S.",
        ]),
        .moon: PixelFrame(rows: [
            "..MMMM.",
            ".MMM...",
            "MMM....",
            "MMM....",
            "MMM....",
            ".MMM...",
            "..MMMM.",
        ]),
        .paw: PixelFrame(rows: [
            "..KK.KK..",
            "..KK.KK..",
            "KK.....KK",
            "KK.kkk.KK",
            "..kkkkk..",
            ".kkkkkkk.",
            ".kkkkkkk.",
            "..kk.kk..",
        ]),
        .sakura: PixelFrame(rows: [
            "..K.K..",
            ".KKKKK.",
            "KKkSkKK",
            ".KSSSK.",
            "KKkSkKK",
            ".KKKKK.",
            "..K.K..",
        ]),
    ]
}

/// The picture on the right side of the island. `heartbeat` pulses.
struct BadgeView: View {
    let badge: IslandBadge
    let pixel: CGFloat
    let mode: PlaybackMode

    var body: some View {
        switch badge {
        case .none:
            EmptyView()
        case .heartbeat:
            let size = CGSize(width: 7 * pixel, height: 7 * pixel)
            SegmentPlayer(weights: [4, 2], size: size, mode: mode) { index in
                PixelFrameView(
                    frame: index == 0 ? StageGlyph.heart.frame : StageGlyph.smallHeart.frame,
                    palette: StageGlyph.palette,
                    pixel: pixel
                )
                .frame(width: size.width, height: size.height)
            }
        default:
            PixelFrameView(frame: glyph.frame, palette: StageGlyph.palette, pixel: pixel)
        }
    }

    private var glyph: StageGlyph {
        switch badge {
        case .none, .heart, .heartbeat: return .heart
        case .redHeart: return .redHeart
        case .whiteHeart: return .whiteHeart
        case .twoHearts: return .twoHearts
        case .sparkle: return .sparkle
        case .star: return .star
        case .moon: return .moon
        case .paw: return .paw
        case .sakura: return .sakura
        }
    }
}

struct PixelHeart: View {
    let pixel: CGFloat

    var body: some View {
        PixelFrameView(frame: StageGlyph.heart.frame, palette: StageGlyph.palette, pixel: pixel)
    }
}
