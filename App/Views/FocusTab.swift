import SwiftUI

/// Focus timer, bedtime and a few tips.
struct FocusTab: View {
    @Environment(IslandModel.self) private var model

    @State private var showsTimerSheet = false

    var body: some View {
        TabPage(title: "Фокус", subtitle: "Питомец спит, пока ты занят делом") {
            focusCard
            sleepCard
            tipsCard
        }
        .sheet(isPresented: $showsTimerSheet) {
            FocusTimerSheet { minutes in
                model.startFocus(minutes: minutes)
            }
            .presentationDetents([.medium])
        }
    }

    private var focusCard: some View {
        Card(title: "Таймер") {
            if let focus = model.state.focus, !focus.isFinished() {
                HStack(spacing: 12) {
                    PetPortrait(pet: model.state.me.sprite, pixel: 3)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(timerInterval: focus.interval, countsDown: true)
                            .font(Theme.pixelFont(28, weight: .heavy))
                            .monospacedDigit()
                            .foregroundStyle(Theme.peach)
                        Text("до \(focus.end.formatted(date: .omitted, time: .shortened)), таймер виден на островке")
                            .font(Theme.roundedFont(13, weight: .regular))
                            .foregroundStyle(Theme.muted)
                    }
                }
                Button {
                    model.stopFocus()
                } label: {
                    Label("Остановить", systemImage: "stop.fill")
                }
                .buttonStyle(SecondaryButtonStyle(tint: Theme.peach))
            } else {
                TileGrid(minWidth: 90) {
                    ForEach([15, 25, 45, 60, 90], id: \.self) { minutes in
                        Button("\(minutes) мин") { model.startFocus(minutes: minutes) }
                            .buttonStyle(SecondaryButtonStyle(tint: Theme.peach))
                    }
                    Button {
                        showsTimerSheet = true
                    } label: {
                        Label("Своё", systemImage: "slider.horizontal.3")
                    }
                    .buttonStyle(SecondaryButtonStyle(tint: Theme.mint))
                }
                Hint(text: "В конце придёт уведомление, а питомец проснётся.")
            }
        }
    }

    private var sleepCard: some View {
        Card(title: "Сон") {
            Toggle(isOn: Binding(
                get: { model.state.isSleeping },
                set: { on in model.mutate { $0.isSleeping = on } }
            )) {
                Label("Уложить спать", systemImage: "moon.fill")
                    .font(Theme.roundedFont(15))
                    .foregroundStyle(Theme.cream)
            }
            .tint(Theme.peach)
            Hint(text: "Питомцы сворачиваются клубочком, над ними 💤 и звёзды.")
        }
    }

    private var tipsCard: some View {
        Card(title: "Полезно знать") {
            VStack(alignment: .leading, spacing: 10) {
                HelpLine(icon: "clock", text: "iOS держит питомца на островке до 8 часов. Открой приложение, и он вернётся сам.")
                HelpLine(icon: "wand.and.stars", text: "Автоматически: Команды → Автоматизация → «Время суток» → действие «Запустить Pixel Island».")
                HelpLine(icon: "hand.tap", text: "Зажми островок: там кнопки «Погладить», «Дальше», «Спать».")
                HelpLine(icon: "lock.shield", text: "Всё хранится только на телефоне. Ни серверов, ни аналитики.")
            }
        }
    }
}

struct HelpLine: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(Theme.peach)
                .frame(width: 22)
            Text(text)
                .font(Theme.roundedFont(14, weight: .regular))
                .foregroundStyle(Theme.cream.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
