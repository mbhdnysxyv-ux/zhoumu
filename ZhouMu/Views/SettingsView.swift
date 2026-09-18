import SwiftUI

/// 设置页 v1.3：外观 + 学期 + 两张课表 + 灵动岛。
/// 用自定义卡片而不是系统 Form，保证和主界面一致的观感。
struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Palette.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    header

                    ScrollView {
                        VStack(spacing: 16) {
                            appearanceCard
                            semesterCard
                            scheduleLinksCard
                            liveActivityCard
                            previewCard
                            resetButton
                            footnote
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)
                    }
                }
            }
            .navigationDestination(for: ScheduleKind.self) { kind in
                ScheduleEditorView(kind: kind).environmentObject(settings)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - 顶部

    private var header: some View {
        HStack {
            Text("设置")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.primaryText)

            Spacer()

            Button { dismiss() } label: {
                Text("完成")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 9)
                    .background(Capsule().fill(Palette.accent))
            }
            .accessibilityLabel("完成设置")
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 14)
    }

    // MARK: - 外观

    private var appearanceCard: some View {
        SettingsCard(title: "外观",
                     caption: "浅色是白蓝配色，深色是黑蓝配色。") {
            Picker("外观", selection: $settings.themeMode) {
                ForEach(ThemeMode.allCases, id: \.self) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - 学期

    private var semesterCard: some View {
        SettingsCard(title: "开学日期",
                     caption: "以这一天为第 1 周的第 1 天，每 7 天进入下一周。") {
            // 用内嵌日历而不是 compact 弹出式选择器：弹出式在启动瞬间会被自动展开并回写当月 1 号。
            DatePicker("开学日期",
                       selection: $settings.startDate,
                       displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .environment(\.locale, Locale(identifier: "zh_CN"))
                .tint(Palette.accent)

            HStack {
                Button {
                    settings.startDate = SemesterCalculator.calendar.startOfDay(for: Date())
                } label: {
                    Text("设为今天")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Palette.accent)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(Palette.accentSoft.opacity(0.7)))
                }
                .buttonStyle(.plain)

                Spacer(minLength: 12)

                Text(settings.startDate.zhoumu_shortText)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.accentDeep)
            }

            Divider().overlay(Palette.line)

            Toggle(isOn: $settings.cyclingEnabled) {
                Text("启用周目循环")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(Palette.primaryText)
            }
            .tint(Palette.accent)

            if settings.cyclingEnabled {
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

            Text(cycleCaption)
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(Palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

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

    // MARK: - 两张课表入口

    private var scheduleLinksCard: some View {
        SettingsCard(title: "课表",
                     caption: "两张表互相独立：各自设置每日节数、上下课时间、固定或按周目轮换，也可以单独关闭。") {
            ForEach(ScheduleKind.allCases, id: \.self) { kind in
                NavigationLink(value: kind) {
                    scheduleLinkRow(kind)
                }
                .buttonStyle(.plain)

                if kind != ScheduleKind.allCases.last {
                    Divider().overlay(Palette.line)
                }
            }
        }
    }

    private func scheduleLinkRow(_ kind: ScheduleKind) -> some View {
        let table = settings.table(kind)
        return HStack(spacing: 12) {
            Image(systemName: kind == .regular ? "sun.max" : "moon.stars")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(table.enabled ? Palette.accent : Palette.faintText)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(kind.label)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Palette.primaryText)

                Text(scheduleSummary(kind))
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(Palette.secondaryText)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Palette.faintText)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
    }

    private func scheduleSummary(_ kind: ScheduleKind) -> String {
        let table = settings.table(kind)
        guard table.enabled else { return "已关闭" }
        var parts: [String] = []
        parts.append(table.rotatesByWeek ? "按周目轮换" : "固定")
        let counts = Set(table.periodsPerDay)
        if counts.count == 1, let only = counts.first {
            parts.append("每天 \(only) 节")
        } else {
            parts.append("每日节数不同")
        }
        parts.append(table.hasAnyTime ? "已填时间" : "未填时间")
        return parts.joined(separator: " · ")
    }

    // MARK: - 灵动岛

    private var liveActivityCard: some View {
        SettingsCard(title: "灵动岛提醒", caption: liveActivityCaption) {
            Toggle(isOn: $settings.liveActivityEnabled) {
                Text("启用灵动岛提醒")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(Palette.primaryText)
            }
            .tint(Palette.accent)

            if settings.liveActivityEnabled {
                Divider().overlay(Palette.line)

                HStack(spacing: 10) {
                    Image(systemName: settings.todayHasTimes ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(settings.todayHasTimes ? Palette.rest : Palette.warning)

                    Text(settings.todayHasTimes
                         ? "今天的课已填时间，提醒可用。"
                         : "今天没有可用的上课时间，提醒不会触发。")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var liveActivityCaption: String {
        "只在每节课上课前 5 分钟和下课前 5 分钟提醒，提醒里会写下节课名和距离上课还剩多久。" +
        "没填上下课时间的节次无法参与提醒。"
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
                    .foregroundStyle(Palette.accent)
            }

            Divider().overlay(Palette.line)

            HStack {
                Text("圈内")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(Palette.secondaryText)

                Spacer(minLength: 12)

                Text(ringPreview)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.accentDeep)
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

    private var ringPreview: String {
        let content = ClassSchedule.ringContent(
            at: Date(),
            tables: [.regular: settings.regular, .evening: settings.evening],
            displayWeek: settings.displayWeek()
        )
        return "\(content.caption) · \(content.subject)"
    }

    private var todayPhase: SemesterPhase {
        SemesterCalculator.phase(startDate: settings.startDate,
                                 cycleWeeks: settings.cycleWeeks,
                                 cyclingEnabled: settings.cyclingEnabled)
    }

    // MARK: - 重新引导 / 页脚

    private var resetButton: some View {
        Button {
            settings.resetSetupPromptHistory()
        } label: {
            Text("下次启动时重新显示开学设置")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Palette.accentDeep)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Palette.accentSoft.opacity(0.5))
                )
        }
        .buttonStyle(.plain)
    }

    private var footnote: some View {
        Text("每年 1 月和 7 月（放假开始月）的首次启动会自动弹出本页，方便设置新学期的开学日期。")
            .font(.system(size: 12, design: .rounded))
            .foregroundStyle(Palette.secondaryText)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 8)
    }
}

#Preview {
    SettingsView().environmentObject(AppSettings())
}
