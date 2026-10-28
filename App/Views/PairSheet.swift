import SwiftUI

/// Two steps: send your code, paste theirs. No accounts, no server.
struct PairSheet: View {
    @Environment(IslandModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var pasted = ""
    @State private var error: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Text("Питомцы будут гулять вместе: твой слева, её или его справа. Обменяйтесь кодами, это 20 секунд.")
                        .font(Theme.roundedFont(15, weight: .regular))
                        .foregroundStyle(Theme.muted)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Card(title: "1. Отправь свой код") {
                        HStack(spacing: 12) {
                            PetPortrait(pet: model.state.me.sprite, pixel: 3)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(model.state.me.name)
                                    .font(Theme.roundedFont(18, weight: .bold))
                                    .foregroundStyle(Theme.cream)
                                Text("Код отправится сообщением, например в Telegram.")
                                    .font(Theme.roundedFont(13, weight: .regular))
                                    .foregroundStyle(Theme.muted)
                            }
                        }
                        ShareLink(item: PairCode.shareText(for: model.state.me)) {
                            Label("Поделиться кодом", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }

                    Card(title: "2. Вставь код партнёра") {
                        PasteButton(payloadType: String.self) { strings in
                            guard let text = strings.first else { return }
                            Task { @MainActor in
                                pasted = String(text.prefix(PairCode.maxInputLength))
                                importCode()
                            }
                        }
                        .buttonBorderShape(.capsule)
                        .tint(Theme.pink)
                        .frame(maxWidth: .infinity)

                        Text("или вручную:")
                            .font(Theme.roundedFont(13, weight: .regular))
                            .foregroundStyle(Theme.muted)

                        TextField("PI1.…", text: $pasted, axis: .vertical)
                            .font(Theme.pixelFont(13, weight: .regular))
                            .foregroundStyle(Theme.cream)
                            .lineLimit(2...4)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .padding(12)
                            .background(Color.black.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))
                            .onChange(of: pasted) { _, newValue in
                                if newValue.count > PairCode.maxInputLength {
                                    pasted = String(newValue.prefix(PairCode.maxInputLength))
                                }
                            }

                        if let error {
                            Text(error)
                                .font(Theme.roundedFont(13))
                                .foregroundStyle(Theme.danger)
                        }

                        Button("Добавить пару", action: importCode)
                            .buttonStyle(SecondaryButtonStyle(tint: Theme.pink))
                            .disabled(pasted.isEmpty)
                    }
                }
                .padding(16)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Пара")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }

    private func importCode() {
        if model.importPartner(from: pasted) {
            error = nil
            dismiss()
        } else {
            error = model.message
            model.message = nil
        }
    }
}
