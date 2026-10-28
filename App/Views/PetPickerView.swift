import SwiftUI

/// Grid of all pets, cats first. Tap = choose and close.
struct PetPickerView: View {
    let title: String
    let selectedID: String
    let onPick: (PetSprite) -> Void

    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 96), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    ForEach(PetGroup.allCases, id: \.self) { group in
                        Text(group.title)
                            .font(Theme.pixelFont(15))
                            .foregroundStyle(Theme.cream)
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(PetCatalog.pets(in: group)) { pet in
                                PetTile(pet: pet, isSelected: pet.id == selectedID) {
                                    onPick(pet)
                                    dismiss()
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }
}

private struct PetTile: View {
    let pet: PetSprite
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // Only the selected pet is animated: dozens of timelines would
                // waste battery for nothing.
                PetPortrait(pet: pet, pixel: 3, animated: isSelected)
                Text(pet.name)
                    .font(Theme.roundedFont(13))
                    .foregroundStyle(isSelected ? Theme.peach : Theme.cream)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(isSelected ? Theme.peach : Theme.cardBorder, lineWidth: isSelected ? 2.5 : 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(pet.name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}
