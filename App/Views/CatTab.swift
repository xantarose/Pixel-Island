import SwiftUI

/// Your pet: who it is, its colours, its pose and the atmosphere around it.
struct CatTab: View {
    @Environment(IslandModel.self) private var model

    @State private var showsPicker = false
    @State private var showsEditor = false

    var body: some View {
        let me = model.state.me
        let sprite = me.sprite

        TabPage(title: "Котик", subtitle: "Выбери, собери и назови своего питомца") {
            VStack(spacing: 14) {
                StageView(
                    script: Scripts.solo(.auto, width: 56, height: 16),
                    me: sprite,
                    partner: nil,
                    effect: model.state.resolvedEffect,
                    pixel: 5,
                    mode: .inApp
                )
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(Color.black, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                NameField(
                    placeholder: sprite.name,
                    text: model.nameBinding(forPartner: false),
                    onCommit: model.finishEditingNames
                )
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                Button {
                    showsEditor = true
                } label: {
                    Label("Собрать своего котика", systemImage: "paintpalette.fill")
                }
                .buttonStyle(PrimaryButtonStyle())

                Button {
                    showsPicker = true
                } label: {
                    Label("Выбрать из каталога · \(PetCatalog.count)", systemImage: "square.grid.2x2.fill")
                }
                .buttonStyle(SecondaryButtonStyle())

                Hint(text: me.look == nil
                     ? "Сейчас: \(sprite.name). В конструкторе можно перекрасить шёрстку, узор, глаза, носик и обводку."
                     : "Сейчас: свой окрас на основе «\(sprite.name)».")
            }

            Card(title: model.state.partner == nil ? "Поза" : "Поза в маленьком островке") {
                if model.state.partner != nil {
                    Hint(text: "С парой поза подбирается под совместное занятие сама. Занятия во вкладке «Пара».")
                }
                TileGrid {
                    ForEach(SoloPose.allCases, id: \.self) { pose in
                        OptionTile(title: pose.title, isSelected: model.state.pose == pose) {
                            model.mutate { $0.pose = pose; $0.isSleeping = false }
                        } preview: {
                            PosePreview(pet: sprite, pose: pose, animated: model.state.pose == pose)
                        }
                    }
                }
            }

            Card(title: "Атмосфера") {
                TileGrid {
                    ForEach(AtmosphereEffect.allCases, id: \.self) { effect in
                        OptionTile(title: effect.title, isSelected: model.state.effect == effect) {
                            model.mutate { $0.effect = effect }
                        } preview: {
                            EffectPreview(pet: sprite, effect: effect, animated: model.state.effect == effect)
                        }
                    }
                }
                Hint(text: "«Авто» подбирает эффект под занятие, а в ваши даты запускает конфетти.")
            }
        }
        .sheet(isPresented: $showsPicker) {
            PetPickerView(title: "Каталог", selectedID: me.displayID) { id in
                model.mutate { state in
                    state.me.kindID = id
                    state.me.look = nil
                }
            }
        }
        .sheet(isPresented: $showsEditor) {
            CatEditorView(title: "Свой котик", initial: me) { look in
                model.mutate { state in
                    state.me.look = look
                    if let look { state.me.kindID = look.baseID }
                }
            }
        }
    }
}
