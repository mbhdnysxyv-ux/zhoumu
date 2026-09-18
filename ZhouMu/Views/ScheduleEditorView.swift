import SwiftUI

/// 单张课表的编辑器（正课表 / 晚课表共用）。
///
/// 布局思路：手机上塞不下「N 周目 × 7 天 × M 节」的三维网格，
/// 所以改成 **先选周目、再选星期、然后竖着列出这一天的每一节**——
/// 每节一行，点一下改科目。
struct ScheduleEditorView: View {
    @EnvironmentObject private var settings: AppSettings

    let kind: ScheduleKind

    @State private var selectedDay = SemesterCalculator.dayIndexInWeek(for: Date())
    /// 「每天单独」模式下，正在编辑哪一天的时间。
    @State private var selectedTimeDay = SemesterCalculator.dayIndexInWeek(for: Date())
    @State private var selectedRow = 0
    @State private var editing: EditTarget?
    @State private var timesTarget: PeriodTarget?

    private struct EditTarget: Identifiable {
        let row: Int
        let day: Int
        let period: Int
        var id: String { "\(row)-\(day)-\(period)" }
    }

    private struct PeriodTarget: Identifiable {
        let period: Int
        /// 「每天单独」模式下是哪一天；统一模式为 nil。
        let day: Int?
        var id: String { "\(day ?? -1)-\(period)" }
    }

    private var table: ScheduleTable { settings.table(kind) }

    private var rowCount: Int {
        table.rowCount(cycleWeeks: settings.cycleWeeks)
    }

    var body: some View {
        ZStack {
            Palette.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    enableCard
                    layoutCard
                    if table.enabled {
                        periodCountCard
                        timesCard
                        subjectsCard
                    }
                    footnote
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle(kind.label)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editing) { target in
            SubjectEditorView(kind: kind, row: target.row, day: target.day, period: target.period)
                .environmentObject(settings)
        }
        .sheet(item: $timesTarget) { target in
            PeriodTimeEditorView(kind: kind, period: target.period, day: target.day)
                .environmentObject(settings)
        }
    }

    // MARK: - 启用

    private var enableCard: some View {
        SettingsCard(title: "启用",
                     caption: table.enabled
                        ? "已启用。首页和灵动岛都会把这张表算进去。"
                        : "已关闭。这张表不参与首页显示和时间轴合并。") {
            Toggle(isOn: Binding(
                get: { table.enabled },
                set: { var t = table; t.enabled = $0; settings.setTable(t, for: kind) }
            )) {
                Text("启用\(kind.label)")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(Palette.primaryText)
            }
            .tint(Palette.accent)
        }
    }

    // MARK: - 排布方式

    private var layoutCard: some View {
        SettingsCard(title: "排布方式", caption: layoutCaption) {
            Picker("排布方式", selection: Binding(
                get: { table.rotatesByWeek },
                set: { var t = table; t.rotatesByWeek = $0; t.normalize(); settings.setTable(t, for: kind) }
            )) {
                Text("固定").tag(false)
                Text("按周目轮换").tag(true)
            }
            .pickerStyle(.segmented)

            if table.rotatesByWeek {
                Divider().overlay(Palette.line)

                Stepper(value: $settings.cycleWeeks, in: SemesterCalculator.cycleWeeksRange) {
                    HStack {
                        Text("循环周数")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(Palette.primaryText)
                        Spacer(minLength: 12)
                        Text("\(settings.cycleWeeks) 周")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(Palette.accent)
                    }
                }
            }
        }
    }

    private var layoutCaption: String {
        table.rotatesByWeek
            ? "共 \(max(1, settings.cycleWeeks)) 排，分别对应周目 1 到 \(max(1, settings.cycleWeeks))，每周换一排。"
            : "只有一排，每周都上同一份课表。"
    }

    // MARK: - 每日节数

    private var periodCountCard: some View {
        SettingsCard(title: "每日节数",
                     caption: "每天可以不一样，最多 \(ScheduleTable.maxPeriods) 节。") {
            ForEach(0..<ScheduleTable.dayCount, id: \.self) { day in
                HStack {
                    Text(SemesterCalculator.weekdayShortNames[day])
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(Palette.primaryText)

                    Spacer(minLength: 8)

                    CountStepper(value: table.periodCount(day: day),
                                 range: ScheduleTable.minPeriods...ScheduleTable.maxPeriods,
                                 unit: "节") { newValue in
                        var t = table
                        t.periodsPerDay[day] = min(max(newValue, ScheduleTable.minPeriods), ScheduleTable.maxPeriods)
                        t.normalize()
                        settings.setTable(t, for: kind)
                    }
                }

                if day < ScheduleTable.dayCount - 1 {
                    Divider().overlay(Palette.line)
                }
            }
        }
    }

    // MARK: - 上下课时间

    private var timesCard: some View {
        // 统一模式：列出「最多节数」那么多行；
        // 每天单独模式：只列当前选中那天的节数。
        let count = table.timeMode == .perDay
            ? table.periodCount(day: selectedTimeDay)
            : (table.periodsPerDay.max() ?? 0)
        return SettingsCard(title: "上下课时间（可选）", caption: timesCaption) {
            // 安排方式
            Picker("安排方式", selection: Binding(
                get: { table.timeMode },
                set: { newMode in
                    var t = table
                    t.timeMode = newMode
                    // 切到「每天单独」时，用当前统一的时间给每天打底，别让用户白填
                    if newMode == .perDay { t.seedDailyTimesFromUnified() }
                    t.normalize()
                    settings.setTable(t, for: kind)
                }
            )) {
                ForEach(TimeMode.allCases, id: \.self) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            if table.timeMode == .perDay {
                Divider().overlay(Palette.line)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(0..<ScheduleTable.dayCount, id: \.self) { day in
                            chip(title: SemesterCalculator.weekdayColumnNames[day],
                                 selected: day == selectedTimeDay,
                                 highlighted: isTodayCell(day: day)) {
                                selectedTimeDay = day
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            Divider().overlay(Palette.line)

            ForEach(0..<count, id: \.self) { period in
                Button {
                    timesTarget = PeriodTarget(period: period,
                                               day: table.timeMode == .perDay ? selectedTimeDay : nil)
                } label: {
                    HStack(spacing: 12) {
                        Text("第 \(period + 1) 节")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(Palette.primaryText)

                        Spacer(minLength: 8)

                        if let t = table.time(forPeriod: period, day: table.timeMode == .perDay ? selectedTimeDay : nil) {
                            Text("\(DurationText.timeOfDay(minutes: t.start)) – \(DurationText.timeOfDay(minutes: t.end))")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundStyle(Palette.accent)
                                .monospacedDigit()
                        } else {
                            Text("未设置")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(Palette.faintText)
                        }

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Palette.faintText)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                if period < count - 1 {
                    Divider().overlay(Palette.line)
                }
            }
        }
    }

    private var timesCaption: String {
        table.hasAnyTime
            ? "已填时间。首页会按时间排时间轴，灵动岛也能用了。"
            : "一节都没填。此时首页只能显示当日晚课，灵动岛提醒不可用。"
    }

    // MARK: - 科目

    private var subjectsCard: some View {
        SettingsCard(title: "科目", caption: subjectsCaption) {
            // 周目选择（轮换时才出现）
            if rowCount > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(0..<rowCount, id: \.self) { row in
                            chip(title: "第 \(row + 1) 周", selected: row == selectedRow) {
                                selectedRow = min(row, rowCount - 1)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            // 星期选择
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(0..<ScheduleTable.dayCount, id: \.self) { day in
                        chip(title: SemesterCalculator.weekdayColumnNames[day],
                             selected: day == selectedDay,
                             highlighted: isTodayCell(day: day)) {
                            selectedDay = day
                        }
                    }
                }
                .padding(.vertical, 2)
            }

            Divider().overlay(Palette.line)

            // 这一天的每一节
            let row = min(selectedRow, max(0, rowCount - 1))
            ForEach(0..<table.periodCount(day: selectedDay), id: \.self) { period in
                periodRow(row: row, period: period)

                if period < table.periodCount(day: selectedDay) - 1 {
                    Divider().overlay(Palette.line)
                }
            }
        }
    }

    private func periodRow(row: Int, period: Int) -> some View {
        let subject = table.subject(row: row, day: selectedDay, period: period)
        let time = table.time(forPeriod: period)

        return Button {
            editing = EditTarget(row: row, day: selectedDay, period: period)
        } label: {
            HStack(spacing: 12) {
                Text("\(period + 1)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.accent)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(Palette.accentSoft))

                VStack(alignment: .leading, spacing: 1) {
                    Text(subject.isEmpty ? "无" : subject)
                        .font(.system(size: 16, weight: subject.isEmpty ? .medium : .bold, design: .rounded))
                        .foregroundStyle(subject.isEmpty ? Palette.faintText : Palette.primaryText)

                    if let time {
                        Text("\(DurationText.timeOfDay(minutes: time.start)) – \(DurationText.timeOfDay(minutes: time.end))")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(Palette.secondaryText)
                            .monospacedDigit()
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Palette.faintText)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var subjectsCaption: String {
        "点任意一节改科目，只有「无」和「自定义」两种。"
    }

    private func isTodayCell(day: Int) -> Bool {
        guard case .inSession(let info) = SemesterCalculator.phase(
            startDate: settings.startDate,
            cycleWeeks: settings.cycleWeeks,
            cyclingEnabled: settings.cyclingEnabled
        ) else { return false }
        let row = table.rotatesByWeek ? info.displayWeek - 1 : 0
        return row == selectedRow && SemesterCalculator.dayIndexInWeek(for: Date()) == day
    }

    private func chip(title: String, selected: Bool, highlighted: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: selected ? .bold : .medium, design: .rounded))
                .foregroundStyle(selected ? .white : Palette.primaryText)
                .frame(minWidth: 38)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    Capsule().fill(selected ? Palette.accent : Palette.cardSoft)
                )
                .overlay(
                    Capsule().stroke(highlighted && !selected ? Palette.accent : .clear, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
    }

    private var footnote: some View {
        Text("「固定」= 每周同一份；「按周目轮换」= 每周换一排。两者都能单独关闭。")
            .font(.system(size: 12, design: .rounded))
            .foregroundStyle(Palette.secondaryText)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 8)
    }
}

// MARK: - 单节科目编辑

/// 编辑一节：只有「无」和「自定义」两个选项。
struct SubjectEditorView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    let kind: ScheduleKind
    let row: Int
    let day: Int
    let period: Int

    @State private var isCustom = false
    @State private var text = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack {
            Palette.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(spacing: 16) {
                        SettingsCard(title: "科目") {
                            Picker("科目", selection: $isCustom) {
                                Text("无").tag(false)
                                Text("自定义").tag(true)
                            }
                            .pickerStyle(.segmented)

                            if isCustom {
                                TextField("例如：数学", text: $text)
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundStyle(Palette.primaryText)
                                    .focused($isFocused)
                                    .submitLabel(.done)
                                    .onSubmit(save)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 11)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Palette.cardSoft)
                                    )
                            }
                        }

                        Button(action: save) {
                            Text("保存")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Capsule().fill(Palette.accent))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
                }
            }
        }
        .onAppear {
            let existing = settings.subject(kind, row: row, day: day, period: period)
            isCustom = !existing.isEmpty
            text = existing
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(kind.label) · \(SemesterCalculator.weekdayShortNames[day]) 第 \(period + 1) 节")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.primaryText)
                Text("第 \(row + 1) 周目")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(Palette.secondaryText)
            }

            Spacer()

            Button { dismiss() } label: {
                Text("取消")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Palette.secondaryText)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 14)
    }

    private func save() {
        settings.setSubject(isCustom ? text : "", kind: kind, row: row, day: day, period: period)
        dismiss()
    }
}

// MARK: - 单节时间编辑

/// 编辑某一节的上下课时间；两个时间都清了就等于「未设置」。
struct PeriodTimeEditorView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    let kind: ScheduleKind
    let period: Int
    /// 「每天单独」模式下是哪一天；统一模式为 nil。
    var day: Int? = nil

    @State private var start = Date()
    @State private var end = Date()
    @State private var isEnabled = false

    private var table: ScheduleTable { settings.table(kind) }

    var body: some View {
        ZStack {
            Palette.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(spacing: 16) {
                        SettingsCard(title: "这一节的时间") {
                            Toggle(isOn: $isEnabled) {
                                Text("设置上下课时间")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundStyle(Palette.primaryText)
                            }
                            .tint(Palette.accent)

                            if isEnabled {
                                Divider().overlay(Palette.line)
                                timeRow(label: "上课", date: $start)
                                Divider().overlay(Palette.line)
                                timeRow(label: "下课", date: $end)
                            }
                        }

                        if isEnabled && end <= start {
                            Text("下课时间要晚于上课时间。")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(Palette.warning)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Button(action: save) {
                            Text("保存")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Capsule().fill(canSave ? Palette.accent : Palette.faintText))
                        }
                        .buttonStyle(.plain)
                        .disabled(!canSave)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
                }
            }
        }
        .onAppear(perform: load)
    }

    private var canSave: Bool { !isEnabled || end > start }

    private var headerTitle: String {
        if let day, SemesterCalculator.weekdayShortNames.indices.contains(day) {
            return "\(kind.label) · \(SemesterCalculator.weekdayShortNames[day]) 第 \(period + 1) 节"
        }
        return "\(kind.label) · 第 \(period + 1) 节"
    }

    private func timeRow(label: String, date: Binding<Date>) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Palette.primaryText)
            Spacer(minLength: 8)
            DatePicker("", selection: date, displayedComponents: .hourAndMinute)
                .labelsHidden()
                .datePickerStyle(.wheel)
                .frame(height: 90)
                .clipped()
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(headerTitle)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.primaryText)
                Text("不填的话，这节课不进时间轴")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(Palette.secondaryText)
            }

            Spacer()

            Button { dismiss() } label: {
                Text("取消")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Palette.secondaryText)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 14)
    }

    private func load() {
        let cal = SemesterCalculator.calendar
        let base = cal.startOfDay(for: Date())
        if let t = table.time(forPeriod: period, day: day) {
            isEnabled = true
            start = cal.date(byAdding: .minute, value: t.start, to: base) ?? base
            end = cal.date(byAdding: .minute, value: t.end, to: base) ?? base
        } else {
            isEnabled = false
            // 默认给一个常见档：8:00–8:45
            start = cal.date(byAdding: .minute, value: 8 * 60, to: base) ?? base
            end = cal.date(byAdding: .minute, value: 8 * 60 + 45, to: base) ?? base
        }
    }

    private func save() {
        var t = table
        // 每天单独模式下没传 day 是调用方的问题，兜底成周一
        if isEnabled {
            let cal = SemesterCalculator.calendar
            let base = cal.startOfDay(for: Date())
            let s = cal.dateComponents([.hour, .minute], from: start)
            let e = cal.dateComponents([.hour, .minute], from: end)
            let startMin = (s.hour ?? 0) * 60 + (s.minute ?? 0)
            let endMin = (e.hour ?? 0) * 60 + (e.minute ?? 0)
            _ = base
            let time = PeriodTime(start: startMin, end: endMin)
            guard time.isValid else { return }
            t.setTime(time, day: day ?? 0, period: period)
        } else {
            t.setTime(nil, day: day ?? 0, period: period)
        }
        settings.setTable(t, for: kind)
        dismiss()
    }
}

// MARK: - 卡片容器

struct SettingsCard<Content: View>: View {
    let title: String
    let caption: String?
    let content: Content

    init(title: String,
         caption: String? = nil,
         @ViewBuilder content: () -> Content) {
        self.title = title
        self.caption = caption
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Palette.accentDeep)

            content

            if let caption {
                Text(caption)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Palette.card)
                .shadow(color: Palette.accent.opacity(0.08), radius: 14, x: 0, y: 6)
        )
    }
}

// MARK: - 节数加减控件

/// 显示当前数值的加减控件。
///
/// 系统 `Stepper` 加 `.labelsHidden()` 之后只剩 `−` `+` 两个按钮，
/// 看不到现在是几节——这正是 v1.5 要修的。这里自己画一个：
///
///     [ − |  8 节 | + ]
private struct CountStepper: View {
    let value: Int
    let range: ClosedRange<Int>
    var unit: String = ""
    let onChange: (Int) -> Void

    var body: some View {
        HStack(spacing: 0) {
            button(systemName: "minus", enabled: value > range.lowerBound) {
                onChange(value - 1)
            }

            Text(unit.isEmpty ? "\(value)" : "\(value) \(unit)")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.accent)
                .monospacedDigit()
                .frame(minWidth: unit.isEmpty ? 34 : 52)

            button(systemName: "plus", enabled: value < range.upperBound) {
                onChange(value + 1)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Palette.accentSoft)
        )
    }

    private func button(systemName: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(enabled ? Palette.accent : Palette.faintText)
                .frame(width: 40, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}
