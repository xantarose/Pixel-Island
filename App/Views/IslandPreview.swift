import SwiftUI

/// What the island and the lock screen look like right now, drawn with the
/// very same views the Live Activity uses.
struct IslandPreview: View {
    let state: IslandState

    var body: some View {
        VStack(spacing: 14) {
            // Fake Dynamic Island: black pill, pet on the left, partner/timer on the right.
            HStack(spacing: 0) {
                CompactLeadingView(state: state, isStale: false, mode: .inApp)
                Spacer(minLength: 70)
                CompactTrailingView(state: state, isStale: false, mode: .inApp)
            }
            .padding(.horizontal, 14)
            .frame(height: 40)
            .background(Color.black, in: Capsule())
            .frame(maxWidth: 300)

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
