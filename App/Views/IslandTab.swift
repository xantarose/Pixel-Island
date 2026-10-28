import SwiftUI

/// Everything about how the island looks: preview, start, width, badge,
/// outline, where particles fall, buttons and battery.
struct IslandTab: View {
    @Environment(IslandModel.self) private var model

    var body: some View {
        let state = model.state
        let me = state.me.sprite

        TabPage(title: "Островок", subtitle: "Так питомец выглядит у тебя на айфоне") {
            IslandPreview(state: state)
            launchCard

            Card(title: "Ширина") {
                TileGrid(minWidth: 140) {
                    ForEach(IslandWidth.allCases, id: \.self) { width in
                        OptionTile(title: width.title, isSelected: state.islandWidth == width) {
                            model.mutate { $0.islandWidth = width }
                        } preview: {
                            WidthPreview(pet: me, width: width)
                        }
                    }
                }
                Hint(text: state.islandWidth == .narrow
                     ? "Почти как пустой островок. Котик двигается на месте."
                     : "Островок чуть шире, котик ходит туда-сюда.")
            }

            Card(title: "Значок справа") {
                BadgePicker(selection: state.badge) { badge in
                    model.mutate { $0.badge = badge }
                }
            }

            Card(title: "Обводка острова") {
                KeylinePicker(selection: state.keyline) { color in
                    model.mutate { $0.keyline = color }
                }
                Hint(text: "Тонкую цветную обводку рисует сама iOS и сама решает, где её показать: обычно на тёмном фоне. Поверх многих приложений iOS её прячет, это не настраивается.")
            }

            Card(title: "Где падают эффекты") {
                TileGrid(minWidth: 140) {
                    ForEach(EffectScope.allCases, id: \.self) { scope in
                        OptionTile(title: scope.title, isSelected: state.effectScope == scope) {
                            model.mutate { $0.effectScope = scope }
                        } preview: {
                            ScopePreview(pet: me, scope: scope, animated: state.effectScope == scope)
                        }
                    }
                }
                Hint(text: "Сам эффект (сакура, снег…) выбирается во вкладке «Котик» или «Пара». Рисовать за краем чёрного острова iOS не даёт.")
            }

            Card(title: "Кнопки на островке") {
                Toggle(isOn: binding(\.buttonsOpenApp)) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Через приложение")
                            .font(Theme.roundedFont(15))
                            .foregroundStyle(Theme.cream)
                        Text("Если «Погладить», «Дальше», «Спать» не срабатывают, включи: нажатие откроет приложение и сразу выполнится.")
                            .font(Theme.roundedFont(12, weight: .regular))
                            .foregroundStyle(Theme.muted)
                    }
                }
                .tint(Theme.mint)
                buttonDiagnostics
            }

            Card(title: "Батарея") {
                Toggle(isOn: binding(\.batterySaver)) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Экономия батареи")
                            .font(Theme.roundedFont(15))
                            .foregroundStyle(Theme.cream)
                        Text("Котик замирает. В режиме энергосбережения айфона это включается само.")
                            .font(Theme.roundedFont(12, weight: .regular))
                            .foregroundStyle(Theme.muted)
                    }
                }
                .tint(Theme.mint)
            }
        }
    }

    private var launchCard: some View {
        VStack(spacing: 10) {
            if model.isRunning {
                Label("Питомец на островке", systemImage: "checkmark.circle.fill")
                    .font(Theme.roundedFont(15))
                    .foregroundStyle(Theme.mint)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: 10) {
                    Button("Перезапустить") { Task { await model.start() } }
                        .buttonStyle(SecondaryButtonStyle())
                    Button("Убрать") { Task { await model.stop() } }
                        .buttonStyle(SecondaryButtonStyle(tint: Theme.danger))
                }
            } else {
                Button {
                    Task { await model.start() }
                } label: {
                    Label("Выпустить на островок", systemImage: "pawprint.fill")
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
    }

    @ViewBuilder
    private var buttonDiagnostics: some View {
        if let last = IslandStorage.lastButton {
            Hint(text: "✅ Нажатия доходят. Последнее: «\(IslandAction(rawValue: last.name)?.title ?? last.name)» в \(last.date.formatted(date: .omitted, time: .shortened)).")
        } else {
            Hint(text: "Нажатия с островка пока не доходили до приложения. Нажми кнопку на островке и открой приложение снова: если тут ничего не появилось, включи «Через приложение».")
        }
    }

    private func binding(_ keyPath: WritableKeyPath<IslandState, Bool>) -> Binding<Bool> {
        Binding(
            get: { model.state[keyPath: keyPath] },
            set: { value in model.mutate { $0[keyPath: keyPath] = value } }
        )
    }
}
