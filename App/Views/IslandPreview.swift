import SwiftUI

/// What the island and the lock screen look like right now, drawn with the
/// very same views the Live Activity uses.
struct IslandPreview: View {
    let state: IslandState

    var body: some View {
        VStack(spacing: 14) {
            // Fake Dynamic Island: black pill, pet on the left, partner/timer on the right.
            HStack(spacing: 0) {
                CompactLeadingView(state: state, mode: .inApp)
                // The camera sits here; the real island is ~126 pt wide.
                Spacer().frame(width: 72)
                CompactTrailingView(state: state, isStale: false, mode: .inApp)
            }
            .padding(.horizontal, 12)
            .frame(height: 37)
            .background(Color.black, in: Capsule())
            .overlay {
                Capsule().strokeBorder(Color(hex: state.keyline.hex).opacity(0.7), lineWidth: 1)
            }
            .fixedSize()

            LockScreenIslandView(state: state, isStale: false, mode: .inApp)
                .background(Theme.lockBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Theme.cardBorder, lineWidth: 1)
                }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        if let partner = state.partner {
            return "Превью: \(state.me.name) и \(partner.name) на островке"
        }
        return "Превью: \(state.me.name) на островке"
    }
}
