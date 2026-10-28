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

/// Row of colour dots for the island outline.
struct KeylinePicker: View {
    let selection: KeylineColor
    let onSelect: (KeylineColor) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 40), spacing: 10)], spacing: 10) {
            ForEach(KeylineColor.allCases, id: \.self) { color in
                let isSelected = color == selection
                Button {
                    onSelect(color)
                } label: {
                    Group {
                        if color == .off {
                            Image(systemName: "nosign")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(Theme.muted)
                                .frame(width: 34, height: 34)
                                .background(Color.black, in: Circle())
                        } else {
                            Circle()
                                .fill(Color(hex: color.hex))
                                .frame(width: 34, height: 34)
                        }
                    }
                        .overlay {
                            Circle()
                                .strokeBorder(Theme.cream, lineWidth: isSelected ? 3 : 0)
                                .padding(-5)
                        }
                        .padding(5)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(color.title)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .sensoryFeedback(.selection, trigger: isSelected)
            }
        }
    }
}

/// "Своё время" for the focus timer: hours and minutes wheels.
struct FocusTimerSheet: View {
    let onStart: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var hours = 0
    @State private var minutes = 30

    private var total: Int { hours * 60 + minutes }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                HStack(spacing: 0) {
                    Picker("Часы", selection: $hours) {
                        ForEach(0..<6, id: \.self) { Text("\($0) ч").tag($0) }
                    }
                    .pickerStyle(.wheel)
                    Picker("Минуты", selection: $minutes) {
                        ForEach(0..<60, id: \.self) { Text("\($0) мин").tag($0) }
                    }
                    .pickerStyle(.wheel)
                }
                .frame(height: 160)

                Button {
                    onStart(total)
                    dismiss()
                } label: {
                    Label("Начать фокус", systemImage: "moon.zzz.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(total == 0)
                .opacity(total == 0 ? 0.5 : 1)
            }
            .padding(16)
            .frame(maxHeight: .infinity, alignment: .top)
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Своё время")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }
}

/// Badges shown as the real pixel pictures. The first tile removes the badge.
struct BadgePicker: View {
    let selection: IslandBadge
    let onSelect: (IslandBadge) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 64), spacing: 8)], spacing: 8) {
            ForEach(IslandBadge.allCases, id: \.self) { badge in
                let isSelected = badge == selection
                Button {
                    onSelect(badge)
                } label: {
                    VStack(spacing: 4) {
                        Group {
                            if badge == .none {
                                Image(systemName: "nosign")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(Theme.muted)
                            } else {
                                BadgeView(badge: badge, pixel: 3, mode: isSelected ? .inApp : .still)
                            }
                        }
                        .frame(height: 30)
                        Text(badge.title)
                            .font(Theme.roundedFont(11, weight: .medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .foregroundStyle(isSelected ? Theme.peach : Theme.cream)
                    }
                    .frame(maxWidth: .infinity, minHeight: 64)
                    .background(Color.black, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(isSelected ? Theme.peach : Theme.cardBorder, lineWidth: isSelected ? 2.5 : 1)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(badge.title)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
                .sensoryFeedback(.selection, trigger: isSelected)
            }
        }
    }
}
