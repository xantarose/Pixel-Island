import SwiftUI

/// Draws one `PixelFrame` with vector rectangles: one filled shape per colour.
/// Vector shapes stay crisp at any size and need no image files, which keeps
/// the Live Activity payload tiny.
struct PixelFrameView: View {
    let frame: PixelFrame
    let palette: [Character: Color]
    /// Size of one art pixel in points.
    let pixel: CGFloat
    var flipped = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(frame.layers) { layer in
                PixelLayerShape(runs: layer.runs, columns: frame.width)
                    .fill(palette[layer.role] ?? .clear)
            }
        }
        .frame(width: CGFloat(frame.width) * pixel, height: CGFloat(frame.height) * pixel)
        .scaleEffect(x: flipped ? -1 : 1, y: 1)
    }
}

struct PixelLayerShape: Shape {
    let runs: [PixelRun]
    let columns: Int

    func path(in rect: CGRect) -> Path {
        let size = rect.width / CGFloat(max(columns, 1))
        var path = Path()
        for run in runs {
            path.addRect(CGRect(
                x: rect.minX + CGFloat(run.x) * size,
                y: rect.minY + CGFloat(run.y) * size,
                width: CGFloat(run.length) * size,
                height: size
            ))
        }
        return path
    }
}

struct PixelHeart: View {
    let pixel: CGFloat

    var body: some View {
        PixelFrameView(frame: Glyphs.heart, palette: Glyphs.heartPalette, pixel: pixel)
    }
}
