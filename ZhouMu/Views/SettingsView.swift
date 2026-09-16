import SwiftUI

/// 设置页：开学日期设置 + 周目循环设置 + 课表。
/// 用自定义卡片而不是系统 Form，保证和主界面一样的「橙白极简」观感。
struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    @State private var editingCell: ScheduleCellID?

    var body: some View {
        ZStack {
            Palette.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(spacing: 16) {
                        startDateCard
                        cycleCard
                        scheduleCard
                        previewCard
                        resetButton
                        copyright
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
                }
            }
        }
        .sheet(item: $editingCell) { cell in
            SubjectEditorView(row: cell.row, day: cell.day)
                .environmentObject(settings)
        }
    }

    // MARK: - 顶部

    private var header: some View {
        HStack {
            Text("设置")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.primaryText)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("完成")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 9)
                    .background(Capsule().fill(Palette.orange))
            }
            .accessibilityLabel("完成设置")
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 14)
    }

    // MARK: - 开学日期

    private var startDateCard: some View {
        SettingsCard(title: "开学日期",
                     caption: "以这一天为第 1 周的第 1 天，每 7 天进入下一周。") {
            // 用内嵌日历而不是 compact 弹出式选择器：弹出式在启动瞬间会被自动展开并回写当月 1 号。
            DatePicker("开学日期",
                       selection: $settings.startDate,
                       displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "zh_CN"))
                .tint(Palette.orange)

            HStack {
                Button {
                    settings.startDate = SemesterCalculator.calendar.startOfDay(for: Date())
                } label: {
                    Text("设为今天")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Palette.orange)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(Palette.orangeSoft.opacity(0.7)))
                }
                .buttonStyle(.plain)

                Spacer(minLength: 12)

                Text(settings.startDate.zhoumu_shortText)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.orangeDeep)
            }
        }
    }

    // MARK: - 周目循环

    private var cycleCard: some View {
        SettingsCard(title: "周目循环", caption: cycleCaption) {
            Toggle(isOn: $settings.cyclingEnabled) {
                Text("启用周目循环")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(Palette.primaryText)
            }
            .tint(Palette.orange)

            if settings.cyclingEnabled {
                Divider().overlay(Palette.orangeSoft)

                Stepper(value: $settings.cycleWeeks,
                        in: SemesterCalculator.cycleWeeksRange) {
                    HStack {
                        Text("循环周数")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundStyle(Palette.primaryText)

                        Spacer(minLength: 12)

                        Text("\(settings.cycleWeeks) 周")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(Palette.orange)
                    }
                }
            }
        }
    }

    /// 用今天的真实数据解释循环规则。
    private var cycleCaption: String {
        switch todayPhase {
        case .inSession(let info) where info.isCycling:
            return "每 \(info.cycleWeeks) 周循环一次。今天是开学第 \(info.rawWeek) 周，按循环显示为第 \(info.displayWeek) 周。"
        case .inSession(let info):
            return "未开启循环，今天是开学第 \(info.rawWeek) 周，直接显示第 \(info.rawWeek) 周。"
        case .notStarted(let days):
            return "距离设定的开学日期还有 \(days) 天，开学后从第 1 周开始计算。"
        }
    }

    // MARK: - 课表

    /// 课表：每一排对应一个周目，一排里周一至周日各一格。
    private var scheduleCard: some View {
        SettingsCard(title: "课表", caption: scheduleCaption) {
            VStack(spacing: 5) {
                // 表头：周一 … 周日
                HStack(spacing: 4) {
                    Color.clear.frame(width: 30, height: 1)
                    ForEach(0..<7, id: \.self) { day in
                        Text(SemesterCalculator.weekdayColumnNames[day])
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(Palette.secondaryText)
                            .frame(maxWidth: .infinity)
                    }
                }

                ForEach(0..<settings.scheduleRowCount, id: \.self) { row in
                    HStack(spacing: 4) {
                        Text("\(row + 1)周")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(Palette.orangeDeep)
                            .frame(width: 30, alignment: .leading)

                        ForEach(0..<7, id: \.self) { day in
                            scheduleCell(row: row, day: day)
                        }
                    }
                }
            }
        }
    }

    private func scheduleCell(row: Int, day: Int) -> some View {
        let subject = settings.subject(row: row, day: day)
        let isToday = isCurrentCell(row: row, day: day)

        return Button {
            editingCell = ScheduleCellID(row: row, day: day)
        } label: {
            Text(subject.isEmpty ? "·" : subject)
                .font(.system(size: 11, weight: subject.isEmpty ? .regular : .semibold, design: .rounded))
                .foregroundStyle(subject.isEmpty ? Palette.secondaryText : Palette.orangeDeep)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity)
                .frame(height: 30)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(subject.isEmpty ? Palette.orangeSoft.opacity(0.35) : Palette.orangeSoft)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(isToday ? Palette.orange : Color.clear, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("第 \(row + 1) 周 \(SemesterCalculator.weekdayShortNames[day])\(subject.isEmpty ? "无课" : subject)")
    }

    /// 这一格是不是「今天」——用来描个橙色边框，方便对上号。
    private func isCurrentCell(row: Int, day: Int) -> Bool {
        guard case .inSession(let info) = todayPhase else { return false }
        return info.scheduleRowIndex == row && SemesterCalculator.dayIndexInWeek(for: Date()) == day
    }

    private var scheduleCaption: String {
        if !settings.cyclingEnabled {
            return "未开启周目循环，课表按同一份每周重复。每格点一下可以填科目。"
        }
        return "共 \(settings.scheduleRowCount) 排，分别对应周目 1 到 \(settings.scheduleRowCount)。每格只有「无」和「自定义」两种，点一下就能改。"
    }

    // MARK: - 预览

    private var previewCard: some View {
        SettingsCard(title: "预览") {
            HStack {
                Text("今天显示")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(Palette.primaryText)

                Spacer(minLength: 12)

                Text(previewText)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.orange)
            }
        }
    }

    private var previewText: String {
        switch todayPhase {
        case .inSession(let info):
            return "第 \(info.displayWeek) 周"
        case .notStarted(let days):
            return "未开学 · 还有 \(days) 天"
        }
    }

    private var todayPhase: SemesterPhase {
        SemesterCalculator.phase(startDate: settings.startDate,
                                 cycleWeeks: settings.cycleWeeks,
                                 cyclingEnabled: settings.cyclingEnabled)
    }

    // MARK: - 重新引导

    private var resetButton: some View {
        Button {
            settings.resetSetupPromptHistory()
        } label: {
            Text("下次启动时重新显示开学设置")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Palette.orangeDeep)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Palette.orangeSoft.opacity(0.5))
                )
        }
        .buttonStyle(.plain)
    }

    private var copyright: some View {
        Text("每年 1 月和 7 月（放假开始月）的首次启动会自动弹出本页，方便设置新学期的开学日期。")
            .font(.system(size: 12, design: .rounded))
            .foregroundStyle(Palette.secondaryText)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 8)
    }
}

// MARK: - 卡片容器

private struct SettingsCard<Content: View>: View {
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
                .foregroundStyle(Palette.orangeDeep)

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
                .shadow(color: Palette.orange.opacity(0.08), radius: 14, x: 0, y: 6)
        )
    }
}

// MARK: - 单格科目编辑

/// 课表里的一格（第几排、周几）。
struct ScheduleCellID: Identifiable, Equatable {
    let row: Int
    let day: Int
    var id: String { "\(row)-\(day)" }
}

/// 编辑一格的科目：只有「无」和「自定义」两个选项。
private struct SubjectEditorView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    let row: Int
    let day: Int

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
                                            .fill(Palette.background)
                                    )
                            }
                        }

                        Button(action: save) {
                            Text("保存")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Capsule().fill(Palette.orange))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
                }
            }
        }
        .onAppear {
            let existing = settings.subject(row: row, day: day)
            isCustom = !existing.isEmpty
            text = existing
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("第 \(row + 1) 周 · \(SemesterCalculator.weekdayShortNames[day])")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.primaryText)
                Text("这一节是什么科目")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(Palette.secondaryText)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
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
        settings.setSubject(isCustom ? text : "", row: row, day: day)
        dismiss()
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppSettings())
}
