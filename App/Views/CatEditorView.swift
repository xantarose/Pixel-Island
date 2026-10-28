import SwiftUI
import UIKit

/// "Собери своего котика": pick a base cat, then recolour its parts.
struct CatEditorView: View {
    let title: String
    let initial: PetProfile
    let onSave: (CustomLook?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var baseID: String
    @State private var colors: [String: UInt32]
    @State private var oddEyes: Bool

    init(title: String, initial: PetProfile, onSave: @escaping (CustomLook?) -> Void) {
        self.title = title
        self.initial = initial
        self.onSave = onSave
        let base = PetCatalog.isCat(initial.displayID) ? initial.displayID : PetCatalog.defaultID
        _baseID = State(initialValue: base)
        _colors = State(initialValue: initial.look?.colors ?? [:])
        _oddEyes = State(initialValue: initial.look?.colors["F"] != nil)
    }

    private var look: CustomLook {
        var c = colors
        if !oddEyes { c["F"] = nil }
        return CustomLook(baseID: baseID, colors: c)
    }

    private var preview: PetSprite {
        PetCatalog.pet(look.baseID, colors: look.colors)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    StageView(
                        script: Scripts.solo(.auto, width: 48, height: 16),
                        me: preview,
                        partner: nil,
                        effect: .none,
                        pixel: 5,
                        mode: .inApp
                    )
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(Color.black, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                    Text("Основа: форма, ушки, хвост и узор")
                        .font(Theme.roundedFont(14, weight: .medium))
                        .foregroundStyle(Theme.muted)
                    basePicker

                    ForEach(CustomLook.parts) { part in
                        if part.role != "F" || oddEyes {
                            ColorRow(
                                title: part.title,
                                presets: Self.presets(for: part.role),
                                current: colors[part.role] ?? PetCatalog.palette(baseID)[Character(part.role)] ?? 0xFFFFFF,
                                isChanged: colors[part.role] != nil
                            ) { value in
                                colors[part.role] = value
                            } onReset: {
                                colors[part.role] = nil
                            }
                        }
                        if part.role == "E" {
                            Toggle("Разные глаза", isOn: $oddEyes)
                                .font(Theme.roundedFont(15))
                                .foregroundStyle(Theme.cream)
                                .tint(Theme.pink)
                        }
                    }

                    HStack(spacing: 10) {
                        Button("Сбросить цвета") {
                            colors = [:]
                            oddEyes = false
                        }
                        .buttonStyle(SecondaryButtonStyle(tint: Theme.danger))
                        Button("Как в каталоге") {
                            onSave(nil)
                            dismiss()
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                }
                .padding(16)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        onSave(look)
                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }

    private var basePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 8) {
                ForEach(PetCatalog.entries(in: .cats)) { entry in
                    let isSelected = entry.id == baseID
                    Button {
                        baseID = entry.id
                    } label: {
                        PetPortrait(pet: PetCatalog.pet(entry.id, colors: colors), pixel: 2.5, animated: false)
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(isSelected ? Theme.peach : .clear, lineWidth: 2.5)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(entry.name)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .padding(.vertical, 2)
        }
        .frame(height: 64)
    }

    static func presets(for role: String) -> [UInt32] {
        switch role {
        case "E", "F":
            return [0xF5D547, 0xF2A33A, 0x7CD67A, 0x3FCF8E, 0x4FA3F7, 0x8FF3FF, 0xB89CFF, 0xFF7FAA, 0xE8873A, 0x2A1A14]
        case "P":
            return [0xF28AA0, 0xFF5C8A, 0xE7A2A6, 0xC97A93, 0x8A5C6A, 0x2A2733, 0xFFB3CB, 0xB89CFF]
        case "o":
            return [0x0B090E, 0x3A1F14, 0x2E2427, 0x5E5A70, 0x5A1F36, 0x0D0F2E, 0xFFFFFF]
        default:
            return [0x26222E, 0x3B3946, 0x6F788C, 0x8E98AB, 0xCDD2DA, 0xF6F4F1, 0xF2E4CB, 0xEE9A4D,
                    0xC4642A, 0x6B4330, 0xB8754B, 0xE8AE5A, 0xC9B7C4, 0xFF9FC3, 0x9FE8CF, 0xC3A9F0]
        }
    }
}

/// One part: preset swatches + system colour picker for anything else.
private struct ColorRow: View {
    let title: String
    let presets: [UInt32]
    let current: UInt32
    let isChanged: Bool
    let onPick: (UInt32) -> Void
    let onReset: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(Theme.roundedFont(15))
                    .foregroundStyle(Theme.cream)
                Spacer()
                if isChanged {
                    Button("как было", action: onReset)
                        .font(Theme.roundedFont(13, weight: .regular))
                        .foregroundStyle(Theme.muted)
                }
                ColorPicker(
                    title,
                    selection: Binding(
                        get: { Color(hex: current) },
                        set: { onPick($0.rgbHex) }
                    ),
                    supportsOpacity: false
                )
                .labelsHidden()
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(presets, id: \.self) { value in
                        Button {
                            onPick(value)
                        } label: {
                            Circle()
                                .fill(Color(hex: value))
                                .frame(width: 30, height: 30)
                                .overlay {
                                    Circle().strokeBorder(
                                        value == current ? Theme.cream : Theme.cardBorder,
                                        lineWidth: value == current ? 3 : 1
                                    )
                                }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(String(format: "#%06X", value))
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(12)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private extension Color {
    /// 0xRRGGBB of this colour in sRGB (alpha ignored).
    var rgbHex: UInt32 {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a)
        func byte(_ v: CGFloat) -> UInt32 { UInt32(max(0, min(255, (v * 255).rounded()))) }
        return byte(r) << 16 | byte(g) << 8 | byte(b)
    }
}
