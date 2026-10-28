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
    /// Blossoming tree with petals falling, 4 frames.
    case sakuraTree0
    case sakuraTree1
    case sakuraTree2
    case sakuraTree3
    case petals
    case cherries
    case butterfly
    case crown
    case fish
    case note
    case cloud
    case rainbow
    case snowflake
    case mushroom
    case tulip
    case sun
    case bow
    case clover

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
        "v": Color(hex: 0x6CCB5F),
        "V": Color(hex: 0x3E9A47),
        "b": Color(hex: 0x7FB8FF),
        "c": Color(hex: 0xCFE8FF),
        "O": Color(hex: 0xFF9F45),
        "u": Color(hex: 0xB89CFF),
        "A": Color(hex: 0xFFD45E),
        "L": Color(hex: 0xFFE1EC),
        "D": Color(hex: 0xD9608C),
        "n": Color(hex: 0x7A4A34),
        "N": Color(hex: 0x4A2A1E),
    ]

    static let sakuraTree: [StageGlyph] = [.sakuraTree0, .sakuraTree1, .sakuraTree2, .sakuraTree3]

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
        .petals: PixelFrame(rows: [
            ".K.....",
            "KK..k..",
            "...kk..",
            "......K",
            "..K..KK",
            ".KK....",
            "....k..",
        ]),
        .cherries: PixelFrame(rows: [
            "....VV.",
            "...V.V.",
            "..V..V.",
            ".V...V.",
            "RR..RR.",
            "RWR.RWR",
            "RRR.RRR",
            ".R...R.",
        ]),
        .butterfly: PixelFrame(rows: [
            "uu...uu",
            "uuu.uuu",
            "uKuguKu",
            ".uuguu.",
            "uuugukk",
            "uu.g.uu",
            ".......",
        ]),
        .crown: PixelFrame(rows: [
            "A..A..A",
            "AA.A.AA",
            "AAAAAAA",
            "ARAbARA",
            "AAAAAAA",
        ]),
        .fish: PixelFrame(rows: [
            "....bb..",
            "b..bbbb.",
            "bbbbbWbb",
            "bbbbbbbb",
            "b..bbbb.",
            "....bb..",
        ]),
        .note: PixelFrame(rows: [
            "...VVVV",
            "...V..V",
            "...V..V",
            "...V..V",
            ".VVV.VV",
            "VVVVVVV",
            ".VV..VV",
        ]),
        .cloud: PixelFrame(rows: [
            "..WW...",
            ".WWWW..",
            ".WWWWWW",
            "WWWWWWW",
            ".cccccc",
        ]),
        .rainbow: PixelFrame(rows: [
            "..RRR..",
            ".ROOOR.",
            "ROAAAOR",
            "OAv.vAO",
            "Av...vA",
            "v.....v",
        ]),
        .snowflake: PixelFrame(rows: [
            "...c...",
            ".c.c.c.",
            "..ccc..",
            "ccccccc",
            "..ccc..",
            ".c.c.c.",
            "...c...",
        ]),
        .mushroom: PixelFrame(rows: [
            "..RRR..",
            ".RWRRR.",
            "RRRRWRR",
            "RRRRRRR",
            "..WWW..",
            "..WWW..",
        ]),
        .tulip: PixelFrame(rows: [
            ".K.K.K.",
            ".KKKKK.",
            ".KKKKK.",
            "..KKK..",
            "...v...",
            ".v.v.v.",
            "..vvv..",
        ]),
        .sun: PixelFrame(rows: [
            "...A...",
            ".A...A.",
            "..AAA..",
            "AAAAAAA",
            "..AAA..",
            ".A...A.",
            "...A...",
        ]),
        .bow: PixelFrame(rows: [
            "KK...KK",
            "KKK.KKK",
            "KKKkKKK",
            "KKK.KKK",
            "KK...KK",
        ]),
        .clover: PixelFrame(rows: [
            ".vv.vv.",
            "vvvvvvv",
            ".vvvvv.",
            "vvvvvvv",
            ".vv.vv.",
            "...V...",
            "..V....",
        ]),
        .sakuraTree0: PixelFrame(rows: [
            "......LLK.......",
            "...LKKKKkKK.....",
            "..LKKkKKKKKKk...",
            ".KKKKKKkKKLKKK..",
            "LKkKKLKKKKkKKKk.",
            "KKKKKkKKKkKKKKK.",
            ".kKKKKKKnKKKkK..",
            "..KKkKnKnKKKk...",
            "....kKNnNnKk....",
            "......NnN...K...",
            ".......nN.....K.",
            ".......nN.......",
            "..L....nN.......",
            "......NnnNL.....",
            ".....NnnnnN.....",
            "................",
        ]),
        .sakuraTree1: PixelFrame(rows: [
            "......LLK.......",
            "...LKKKKkKK.....",
            "..LKKkKKKKKKk...",
            ".KKKKKKkKKLKKK..",
            "LKkKKLKKKKkKKKk.",
            "KKKKKkKKKkKKKKK.",
            ".kKKKKKKnKKKkK..",
            "..KKkKnKnKKKk...",
            "....kKNnNnKk....",
            "......NnN.......",
            ".......nN.......",
            ".......nN....K..",
            ".......nN......K",
            "......NnnN......",
            "...L.NnnnnN.....",
            "...........L....",
        ]),
        .sakuraTree2: PixelFrame(rows: [
            "......LLK.......",
            "...LKKKKkKK.....",
            "..LKKkKKKKKKk...",
            ".KKKKKKkKKLKKK..",
            "LKkKKLKKKKkKKKk.",
            "KKKKKkKKKkKKKKK.",
            ".kKKKKKKnKKKkK..",
            "..KKkKnKnKKKk...",
            "....kKNnNnKk....",
            ".L....NnN.......",
            "....L..nN.......",
            ".......nN.......",
            ".......nN.......",
            "......NnnN..K...",
            ".....NnnnnN...K.",
            "................",
        ]),
        .sakuraTree3: PixelFrame(rows: [
            "......LLK.......",
            "...LKKKKkKK.....",
            "..LKKkKKKKKKk...",
            ".KKKKKKkKKLKKK..",
            "LKkKKLKKKKkKKKk.",
            "KKKKKkKKKkKKKKK.",
            ".kKKKKKKnKKKkK..",
            "..KKkKnKnKKKk...",
            "....kKNnNnKk.K..",
            "......NnN.......",
            ".......nN.......",
            "..L....nN.......",
            ".....L.nN.......",
            "......NnnN......",
            ".....NnnnnN.....",
            ".............K..",
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
        case .sakuraTree:
            // The tree is 16 px tall: draw it at 2/3 scale to fit the island.
            let treePixel = pixel * 2 / 3
            let size = CGSize(width: 16 * treePixel, height: 16 * treePixel)
            SegmentPlayer(weights: [3, 3, 3, 3], size: size, mode: mode) { index in
                PixelFrameView(
                    frame: StageGlyph.sakuraTree[index % StageGlyph.sakuraTree.count].frame,
                    palette: StageGlyph.palette,
                    pixel: treePixel
                )
            }
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

    var glyph: StageGlyph {
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
        case .sakuraTree: return .sakuraTree0
        case .petals: return .petals
        case .cherries: return .cherries
        case .butterfly: return .butterfly
        case .crown: return .crown
        case .fish: return .fish
        case .note: return .note
        case .cloud: return .cloud
        case .rainbow: return .rainbow
        case .snowflake: return .snowflake
        case .mushroom: return .mushroom
        case .tulip: return .tulip
        case .sun: return .sun
        case .bow: return .bow
        case .clover: return .clover
        }
    }
}

struct PixelHeart: View {
    let pixel: CGFloat

    var body: some View {
        PixelFrameView(frame: StageGlyph.heart.frame, palette: StageGlyph.palette, pixel: pixel)
    }
}
