import SwiftUI

/// Grid of all pets, cats first. Tap = choose and close.
struct PetPickerView: View {
    let title: String
    let selectedID: String
    let onPick: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 92), spacing: 10)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    ForEach(PetGroup.allCases, id: \.self) { group in
                        let pets = PetCatalog.entries(in: group)
                        Text("\(group.title) · \(pets.count)")
                            .font(Theme.pixelFont(15))
                            .foregroundStyle(Theme.cream)
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(pets) { pet in
                                PetTile(id: pet.id, name: pet.name, isSelected: pet.id == selectedID) {
                                    onPick(pet.id)
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
    let id: String
    let name: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // Only the selected pet is animated: dozens of timelines would
                // waste battery for nothing. LazyVGrid parses sprites on demand.
                PetPortrait(pet: PetCatalog.pet(id), pixel: 3, animated: isSelected)
                Text(name)
                    .font(Theme.roundedFont(12))
                    .foregroundStyle(isSelected ? Theme.peach : Theme.cream)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
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
        .accessibilityLabel(name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
