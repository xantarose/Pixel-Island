import SwiftUI

/// A rounded dark card with a small caps title.
struct Card<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title.uppercased())
                .font(Theme.pixelFont(12))
                .tracking(1.5)
                .foregroundStyle(Theme.muted)
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Theme.cardBorder, lineWidth: 1.5)
        }
    }
}

/// Big, thumb-friendly main action.
struct PrimaryButtonStyle: ButtonStyle {
    var tint: Color = Theme.peach

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.roundedFont(17, weight: .bold))
            .foregroundStyle(Theme.background)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(tint, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Quiet secondary action.
struct SecondaryButtonStyle: ButtonStyle {
    var tint: Color = Theme.cream

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.roundedFont(15))
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity, minHeight: 46)
            .background(Theme.cardBorder.opacity(configuration.isPressed ? 1 : 0.6),
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

/// A pet sprite in a little framed "window", used in lists and cards.
struct PetPortrait: View {
    let pet: PetSprite
    var pixel: CGFloat = 3
    var animated = true

    var body: some View {
        Group {
            if animated {
                StageView(
                    script: Scripts.solo(.sit, width: 16, height: 16),
                    me: pet,
                    partner: nil,
                    effect: .none,
                    pixel: pixel,
                    mode: .inApp
                )
            } else {
                PixelFrameView(frame: pet.frame(.sit, 0), palette: pet.palette, pixel: pixel)
            }
        }
        .padding(6)
        .background(Color.black, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

/// Name field with a pencil, cleans the name when editing ends.
struct NameField: View {
    let placeholder: String
    @Binding var text: String
    var onCommit: () -> Void

    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 8) {
            TextField(placeholder, text: $text)
                .font(Theme.roundedFont(20, weight: .bold))
                .foregroundStyle(Theme.cream)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($focused)
                .onSubmit(onCommit)
            Image(systemName: "pencil")
                .foregroundStyle(Theme.muted)
                .accessibilityHidden(true)
        }
        .onChange(of: focused) { _, isFocused in
            if !isFocused { onCommit() }
        }
    }
}

/// Grid of tappable chips, one selected. Used for activities, poses, effects.
struct ChoiceGrid<Option: Hashable>: View {
    let options: [Option]
    let selection: Option
    let label: (Option) -> String
    let onSelect: (Option) -> Void

    private let columns = [GridItem(.adaptive(minimum: 104), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(options, id: \.self) { option in
                let isSelected = option == selection
                Button {
                    onSelect(option)
                } label: {
                    Text(label(option))
                        .font(Theme.roundedFont(14))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .foregroundStyle(isSelected ? Theme.background : Theme.cream)
                        .frame(maxWidth: .infinity, minHeight: 40)
                        .background(
                            isSelected ? Theme.peach : Theme.cardBorder.opacity(0.6),
                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .sensoryFeedback(.selection, trigger: isSelected)
            }
        }
    }
}
