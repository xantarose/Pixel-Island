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

    var frame: PixelFrame { Self.frames[self] ?? PixelFrame(rows: []) }

    static let palette: [Character: Color] = [
        "o": Color(hex: 0x5A1F36),
        "P": Color(hex: 0xFF6F9F),
        "W": Color(hex: 0xFFF1F6),
        "Z": Color(hex: 0xCFC6FF),
        "Y": Color(hex: 0xFF8FB8),
        "y": Color(hex: 0xD9557F),
        "S": Color(hex: 0xFFF3A0),
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
            ".S.",
            "SSS",
            ".S.",
        ]),
    ]
}

struct PixelHeart: View {
    let pixel: CGFloat

    var body: some View {
        PixelFrameView(frame: StageGlyph.heart.frame, palette: StageGlyph.palette, pixel: pixel)
    }
}
