import SwiftUI

/// The partner's pet, the pairing code, days together and joint activities.
struct CoupleTab: View {
    @Environment(IslandModel.self) private var model

    @State private var showsPairSheet = false
    @State private var showsPicker = false
    @State private var showsEditor = false

    var body: some View {
        TabPage(title: "Пара", subtitle: "Ваши питомцы вместе на островке") {
            if let partner = model.state.partner {
                partnerCard(partner)
                togetherCard
                activitiesCard(partner)
            } else {
                emptyState
            }
        }
        .sheet(isPresented: $showsPairSheet) {
            PairSheet()
        }
        .sheet(isPresented: $showsPicker) {
            PetPickerView(title: "Питомец пары", selectedID: model.state.partner?.displayID ?? "") { id in
                model.mutate { state in
                    state.partner?.kindID = id
                    state.partner?.look = nil
                }
            }
        }
        .sheet(isPresented: $showsEditor) {
            if let partner = model.state.partner {
                CatEditorView(title: "Котик пары", initial: partner) { look in
                    model.mutate { state in
                        state.partner?.look = look
                        if let look { state.partner?.kindID = look.baseID }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            StageView(
                script: Scripts.couple(.walk, width: 84, height: 20),
                me: model.state.me.sprite,
                partner: PetCatalog.pet("cat.bombay"),
                effect: .none,
                pixel: 3.5,
                mode: .inApp
            )
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Color.black, in: RoundedRectangle(cornerRadius: 22, style: .continuous))

            Hint(text: "Добавь питомца своей половинки: они будут гулять, обниматься, спать и играть вместе. Обменяйтесь кодами, это 20 секунд.")

            Button {
                showsPairSheet = true
            } label: {
                Label("Добавить пару", systemImage: "heart.fill")
            }
            .buttonStyle(PrimaryButtonStyle(tint: Theme.pink))
        }
    }

    private func partnerCard(_ partner: PetProfile) -> some View {
        Card(title: "Питомец пары") {
            HStack(spacing: 14) {
                PetPortrait(pet: partner.sprite, pixel: 4)
                NameField(
                    placeholder: partner.sprite.name,
                    text: model.nameBinding(forPartner: true),
                    onCommit: model.finishEditingNames
                )
            }
            HStack(spacing: 10) {
                Button {
                    showsEditor = true
                } label: {
                    Label("Перекрасить", systemImage: "paintpalette.fill")
                }
                .buttonStyle(SecondaryButtonStyle(tint: Theme.peach))
                Button {
                    showsPicker = true
                } label: {
                    Label("Другой", systemImage: "square.grid.2x2.fill")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            HStack(spacing: 10) {
                Button {
                    showsPairSheet = true
                } label: {
                    Label("Коды", systemImage: "qrcode")
                }
                .buttonStyle(SecondaryButtonStyle())
                Button(role: .destructive) {
                    model.removePartner()
                } label: {
                    Label("Убрать", systemImage: "xmark")
                }
                .buttonStyle(SecondaryButtonStyle(tint: Theme.danger))
            }
        }
    }

    private var togetherCard: some View {
        Card(title: "Вместе") {
            Toggle(isOn: Binding(
                get: { model.state.togetherSince != nil },
                set: { on in model.mutate { $0.togetherSince = on ? ($0.togetherSince ?? .now) : nil } }
            )) {
                Text("Считать дни вместе")
                    .font(Theme.roundedFont(15))
                    .foregroundStyle(Theme.cream)
            }
            .tint(Theme.pink)

            if let since = model.state.togetherSince {
                DatePicker(
                    "С какого дня",
                    selection: Binding(
                        get: { since },
                        set: { date in model.mutate { $0.togetherSince = min(date, .now) } }
                    ),
                    in: ...Date.now,
                    displayedComponents: .date
                )
                .font(Theme.roundedFont(15))
                .foregroundStyle(Theme.cream)
                .environment(\.locale, Locale(identifier: "ru_RU"))

                if let days = model.state.daysTogether() {
                    HStack(spacing: 8) {
                        PixelHeart(pixel: 2)
                        Text("Уже \(days) \(RussianPlural.days(days))")
                            .font(Theme.pixelFont(15))
                            .foregroundStyle(Theme.pink)
                    }
                }
                Hint(text: "Каждый месяц в ваш день и на 100, 200, 365… дней на островке летит конфетти.")
            }
        }
    }

    private func activitiesCard(_ partner: PetProfile) -> some View {
        let me = model.state.me.sprite
        let other = partner.sprite
        return Card(title: "Чем заняты") {
            TileGrid(minWidth: 140) {
                ForEach(CoupleActivity.allCases, id: \.self) { activity in
                    let isSelected = model.state.activity == activity && !model.state.isSleeping
                    OptionTile(title: activity.title, isSelected: isSelected) {
                        model.mutate { $0.activity = activity; $0.isSleeping = false }
                    } preview: {
                        ActivityPreview(me: me, partner: other, activity: activity, animated: isSelected)
                    }
                }
            }
        }
    }
}
