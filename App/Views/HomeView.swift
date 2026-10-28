import SwiftUI

/// The only main screen: preview on top, then pet, couple, modes, help.
struct HomeView: View {
    @Environment(IslandModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase

    @State private var picker: PickerTarget?
    @State private var showsPairSheet = false
    @State private var showsTimerSheet = false
    @State private var editor: PickerTarget?

    enum PickerTarget: String, Identifiable {
        case mine
        case partner
        var id: String { rawValue }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                IslandPreview(state: model.state)
                launchCard
                myPetCard
                coupleCard
                activityCard
                islandCard
                modesCard
                helpCard
            }
            .padding(16)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.background.ignoresSafeArea())
        .overlay(alignment: .bottom) { toast }
        .sheet(item: $picker) { target in
            PetPickerView(
                title: target == .mine ? "Мой питомец" : "Питомец пары",
                selectedID: target == .mine ? model.state.me.displayID : (model.state.partner?.displayID ?? "")
            ) { id in
                model.mutate { state in
                    if target == .mine {
                        state.me.kindID = id
                        state.me.look = nil
                    } else {
                        state.partner?.kindID = id
                        state.partner?.look = nil
                    }
                }
            }
        }
        .sheet(item: $editor) { target in
            if let profile = target == .mine ? model.state.me : model.state.partner {
                CatEditorView(
                    title: target == .mine ? "Свой котик" : "Котик пары",
                    initial: profile
                ) { look in
                    model.mutate { state in
                        if target == .mine {
                            state.me.look = look
                            if let look { state.me.kindID = look.baseID }
                        } else {
                            state.partner?.look = look
                            if let look { state.partner?.kindID = look.baseID }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showsTimerSheet) {
            FocusTimerSheet { minutes in
                model.startFocus(minutes: minutes)
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showsPairSheet) {
            PairSheet()
        }
        .task {
            // onChange below doesn't fire for the initial phase of a cold launch.
            await model.appBecameActive()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await model.appBecameActive() }
            } else if phase == .background {
                model.flushSync()
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        HStack(spacing: 10) {
            PixelHeart(pixel: 3)
            Text("Pixel Island")
                .font(Theme.pixelFont(26, weight: .heavy))
                .foregroundStyle(Theme.cream)
            Spacer()
        }
        .padding(.top, 8)
        .accessibilityAddTraits(.isHeader)
    }

    private var launchCard: some View {
        VStack(spacing: 10) {
            if model.isRunning {
                Label("Питомец гуляет на островке", systemImage: "checkmark.circle.fill")
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

    private var myPetCard: some View {
        Card(title: "Мой питомец") {
            HStack(spacing: 14) {
                Button {
                    picker = .mine
                } label: {
                    PetPortrait(pet: model.state.me.sprite, pixel: 4)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Выбрать питомца")

                VStack(alignment: .leading, spacing: 6) {
                    NameField(
                        placeholder: model.state.me.sprite.name,
                        text: model.nameBinding(forPartner: false),
                        onCommit: model.finishEditingNames
                    )
                    Text(model.state.me.look == nil ? model.state.me.sprite.name : "свой окрас 🎨")
                        .font(Theme.roundedFont(13, weight: .regular))
                        .foregroundStyle(Theme.muted)
                }
            }
            HStack(spacing: 10) {
                Button("Выбрать другого") { picker = .mine }
                    .buttonStyle(SecondaryButtonStyle())
                Button("🎨 Свой окрас") { editor = .mine }
                    .buttonStyle(SecondaryButtonStyle(tint: Theme.peach))
            }
        }
    }

    @ViewBuilder
    private var coupleCard: some View {
        Card(title: "Пара") {
            if let partner = model.state.partner {
                HStack(spacing: 14) {
                    Button {
                        picker = .partner
                    } label: {
                        PetPortrait(pet: partner.sprite, pixel: 4)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Выбрать питомца пары")

                    VStack(alignment: .leading, spacing: 6) {
                        NameField(
                            placeholder: partner.sprite.name,
                            text: model.nameBinding(forPartner: true),
                            onCommit: model.finishEditingNames
                        )
                        Text("гуляет рядом с твоим")
                            .font(Theme.roundedFont(13, weight: .regular))
                            .foregroundStyle(Theme.muted)
                    }
                }

                togetherRow

                Button("🎨 Перекрасить котика пары") { editor = .partner }
                    .buttonStyle(SecondaryButtonStyle(tint: Theme.peach))

                HStack(spacing: 10) {
                    Button("Новый код") { showsPairSheet = true }
                        .buttonStyle(SecondaryButtonStyle())
                    Button("Убрать пару") { model.removePartner() }
                        .buttonStyle(SecondaryButtonStyle(tint: Theme.danger))
                }
            } else {
                Text("Добавь питомца своей половинки: они будут ходить навстречу друг другу, а между ними — сердечко.")
                    .font(Theme.roundedFont(15, weight: .regular))
                    .foregroundStyle(Theme.muted)
                Button {
                    showsPairSheet = true
                } label: {
                    Label("Добавить пару", systemImage: "heart.fill")
                }
                .buttonStyle(PrimaryButtonStyle(tint: Theme.pink))
            }
        }
    }

    private var togetherRow: some View {
        let hasDate = model.state.togetherSince != nil
        return VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: Binding(
                get: { hasDate },
                set: { on in model.mutate { $0.togetherSince = on ? ($0.togetherSince ?? .now) : nil } }
            )) {
                Text("Считать дни вместе")
                    .font(Theme.roundedFont(15))
                    .foregroundStyle(Theme.cream)
            }
            .tint(Theme.pink)

            if let since = model.state.togetherSince {
                DatePicker(
                    "Вместе с",
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
                    Text("Уже \(days) \(RussianPlural.days(days)) ♥")
                        .font(Theme.pixelFont(14))
                        .foregroundStyle(Theme.pink)
                }
            }
        }
    }

    private var activityCard: some View {
        Card(title: model.state.partner == nil ? "Чем занят" : "Чем заняты вместе") {
            if model.state.partner != nil {
                ChoiceGrid(
                    options: CoupleActivity.allCases,
                    selection: model.state.activity,
                    label: { "\($0.emoji) \($0.title)" }
                ) { activity in
                    model.mutate { $0.activity = activity; $0.isSleeping = false }
                }
                Text("В маленьком островке поза подбирается под занятие сама.")
                    .font(Theme.roundedFont(13, weight: .regular))
                    .foregroundStyle(Theme.muted)
            } else {
                ChoiceGrid(
                    options: SoloPose.allCases,
                    selection: model.state.pose,
                    label: { "\($0.emoji) \($0.title)" }
                ) { pose in
                    model.mutate { $0.pose = pose; $0.isSleeping = false }
                }
            }

            Text("Атмосфера")
                .font(Theme.pixelFont(12))
                .tracking(1.5)
                .foregroundStyle(Theme.muted)
                .padding(.top, 4)
            ChoiceGrid(
                options: AtmosphereEffect.allCases,
                selection: model.state.effect,
                label: { "\($0.emoji) \($0.title)" }
            ) { effect in
                model.mutate { $0.effect = effect }
            }
        }
    }

    private var islandCard: some View {
        Card(title: "Островок") {
            sectionLabel("Ширина")
            ChoiceGrid(
                options: IslandWidth.allCases,
                selection: model.state.islandWidth,
                label: { "\($0.emoji) \($0.title)" }
            ) { width in
                model.mutate { $0.islandWidth = width }
            }

            sectionLabel("Значок справа")
            BadgePicker(selection: model.state.badge) { badge in
                model.mutate { $0.badge = badge }
            }

            sectionLabel("Обводка")
            KeylinePicker(selection: model.state.keyline) { color in
                model.mutate { $0.keyline = color }
            }

            sectionLabel("Эффекты")
            ChoiceGrid(
                options: EffectScope.allCases,
                selection: model.state.effectScope,
                label: { "\($0.emoji) \($0.title)" }
            ) { scope in
                model.mutate { $0.effectScope = scope }
            }

            Toggle(isOn: Binding(
                get: { model.state.batterySaver },
                set: { on in model.mutate { $0.batterySaver = on } }
            )) {
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
            .padding(.top, 4)
        }
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(Theme.roundedFont(13, weight: .medium))
            .foregroundStyle(Theme.muted)
            .padding(.top, 2)
    }

    private var modesCard: some View {
        Card(title: "Режимы") {
            if let focus = model.state.focus, !focus.isFinished() {
                HStack {
                    Text("Фокус до \(focus.end.formatted(date: .omitted, time: .shortened))")
                        .font(Theme.roundedFont(15))
                        .foregroundStyle(Theme.cream)
                    Spacer()
                    Text(timerInterval: focus.interval, countsDown: true)
                        .font(Theme.pixelFont(15))
                        .monospacedDigit()
                        .foregroundStyle(Theme.peach)
                }
                Button("Остановить фокус", action: model.stopFocus)
                    .buttonStyle(SecondaryButtonStyle(tint: Theme.peach))
            } else {
                Text("Фокус: питомец спит, пока ты работаешь, таймер виден на островке.")
                    .font(Theme.roundedFont(15, weight: .regular))
                    .foregroundStyle(Theme.muted)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 8)], spacing: 8) {
                    ForEach([15, 25, 45, 60, 90], id: \.self) { minutes in
                        Button("\(minutes) мин") { model.startFocus(minutes: minutes) }
                            .buttonStyle(SecondaryButtonStyle(tint: Theme.peach))
                    }
                    Button("Своё…") { showsTimerSheet = true }
                        .buttonStyle(SecondaryButtonStyle(tint: Theme.mint))
                }
            }

            Toggle(isOn: Binding(
                get: { model.state.isSleeping },
                set: { on in model.mutate { $0.isSleeping = on } }
            )) {
                Label("Уложить спать", systemImage: "moon.fill")
                    .font(Theme.roundedFont(15))
                    .foregroundStyle(Theme.cream)
            }
            .tint(Theme.peach)
        }
    }

    private var helpCard: some View {
        Card(title: "Полезно знать") {
            VStack(alignment: .leading, spacing: 10) {
                HelpLine(icon: "clock", text: "iOS держит питомца на островке до 8 часов. Открой приложение, и он вернётся сам.")
                HelpLine(icon: "wand.and.stars", text: "Автоматически: Команды → Автоматизация → «Время суток» → действие «Запустить Pixel Island».")
                HelpLine(icon: "hand.tap", text: "Зажми островок: можно погладить питомца или уложить спать.")
                HelpLine(icon: "lock.shield", text: "Всё хранится только на телефоне. Ни серверов, ни аналитики.")
            }
        }
    }

    // MARK: - Toast

    @ViewBuilder
    private var toast: some View {
        if let message = model.message {
            Text(message)
                .font(Theme.roundedFont(14))
                .foregroundStyle(Theme.cream)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Theme.cardBorder, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .task(id: message) {
                    try? await Task.sleep(for: .seconds(4))
                    model.message = nil
                }
                .onTapGesture { model.message = nil }
        }
    }
}

private struct HelpLine: View {
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
