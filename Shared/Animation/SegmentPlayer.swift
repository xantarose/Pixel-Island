import SwiftUI

/// Where an animation is shown. The two places animate in different ways.
enum PlaybackMode {
    /// Dynamic Island / lock screen: our code does not run while the pet is
    /// visible, so frames are switched by the system clock (`FrameWheel`).
    case liveActivity
    /// Inside the app: a normal `TimelineView` redraws the current frame.
    case inApp
}

/// Plays `weights.count` segments in a loop at `PetScene.fps` slots per second.
/// Segment `i` stays on screen for `weights[i]` slots.
struct SegmentPlayer<Content: View>: View {
    let weights: [Double]
    let size: CGSize
    let mode: PlaybackMode
    @ViewBuilder let content: (Int) -> Content

    private var period: TimeInterval {
        weights.reduce(0, +) / PetScene.fps
    }

    var body: some View {
        switch mode {
        case .liveActivity:
            FrameWheel(weights: weights, period: period, size: size, content: content)
        case .inApp:
            TimelineView(.animation(minimumInterval: 1 / PetScene.fps)) { context in
                content(index(at: context.date))
                    .frame(width: size.width, height: size.height)
            }
        }
    }

    /// Same clock for every player, so pets in one scene stay in sync.
    private func index(at date: Date) -> Int {
        let total = weights.reduce(0, +)
        guard total > 0 else { return 0 }
        let position = (date.timeIntervalSinceReferenceDate * PetScene.fps)
            .truncatingRemainder(dividingBy: total)
        var accumulated = 0.0
        for (i, weight) in weights.enumerated() {
            accumulated += weight
            if position < accumulated {
                return i
            }
        }
        return weights.count - 1
    }
}

/// Frame animation without running code.
///
/// All frames are stacked. Each one is masked by a slice of a huge ring whose
/// centre sits far below the viewport. The ring turns once per `period` with
/// the clock-hand effect, so slice after slice passes over the viewport and
/// exactly one frame is visible at a time. The ring is so big (radius = 100x
/// the viewport) that its edge crosses the viewport as an almost straight line,
/// which makes the switch between frames practically instant.
struct FrameWheel<Content: View>: View {
    let weights: [Double]
    let period: TimeInterval
    let size: CGSize
    @ViewBuilder let content: (Int) -> Content

    var body: some View {
        let side = max(size.width, size.height, 1)
        let radius = side * 100
        let total = max(weights.reduce(0, +), 1)
        let bounds = cumulativeAngles(total: total)

        ZStack {
            ForEach(weights.indices, id: \.self) { i in
                content(i)
                    .frame(width: size.width, height: size.height)
                    .mask {
                        RingSlice(startAngle: -bounds[i + 1], endAngle: -bounds[i], radius: radius)
                            .stroke(style: StrokeStyle(lineWidth: side * 1.5, lineCap: .butt))
                            .frame(width: size.width, height: size.height)
                            .clockHandRotation(period: period)
                            .offset(y: radius)
                    }
            }
        }
        .frame(width: size.width, height: size.height)
    }

    /// Angle (degrees) where each segment starts, plus 360 at the end.
    private func cumulativeAngles(total: Double) -> [Double] {
        var result: [Double] = [0]
        var accumulated = 0.0
        for weight in weights {
            accumulated += weight
            result.append(accumulated / total * 360)
        }
        return result
    }
}

/// An arc around the centre of its frame.
struct RingSlice: Shape {
    let startAngle: Double
    let endAngle: Double
    let radius: Double

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: radius,
            startAngle: .degrees(startAngle),
            endAngle: .degrees(endAngle),
            clockwise: false
        )
        return path
    }
}
