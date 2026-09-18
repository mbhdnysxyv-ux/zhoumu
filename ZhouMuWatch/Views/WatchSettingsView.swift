import SwiftUI

/// 手表端设置：开学日期、循环周数、今天各节课的科目。
///
/// 屏幕很小，所以课表只编辑「今天这一天」——
/// 完整的 7×N 课表在 iPhone 上更好编辑。
struct WatchSettingsView: View {
    @EnvironmentObject private var settings: WatchSettings
    @State private var editingPeriod: Int?

    var body: some View {
        List {
            Section("开学日期") {
                DatePicker("开学日期", selection: $settings.startDate, displayedComponents: .date)
                    .labelsHidden()
                Button("设为今天") {
                    settings.startDate = SemesterCalculator.calendar.startOfDay(for: Date())
                }
                .font(.footnote)
            }

            Section("周目循环") {
                Toggle("启用循环", isOn: $settings.cyclingEnabled)
                if settings.cyclingEnabled {
                    Stepper("\(settings.cycleWeeks) 周", value: $settings.cycleWeeks,
                            in: SemesterCalculator.cycleWeeksRange)
                }
            }

            Section("今天第几节") {
                ForEach(0..<settings.table.periodCount(day: todayIndex), id: \.self) { period in
                    Button {
                        editingPeriod = period
                    } label: {
                        HStack {
                            Text("第 \(period + 1) 节")
                            Spacer()
                            Text(currentSubject(period).isEmpty ? "无" : currentSubject(period))
                                .foregroundStyle(currentSubject(period).isEmpty ? .secondary : .primary)
                        }
                    }
                }
            }
        }
        .sheet(item: $editingPeriod) { period in
            SubjectEditor(period: period).environmentObject(settings)
        }
    }

    private var todayIndex: Int { SemesterCalculator.dayIndexInWeek(for: Date()) }

    private func currentSubject(_ period: Int) -> String {
        guard case .inSession(let info) = settings.phase else { return "" }
        let row = settings.table.rotatesByWeek ? max(0, info.displayWeek - 1) : 0
        return settings.table.subject(row: row, day: todayIndex, period: period)
    }
}

/// 单节科目编辑：只有「无」和「自定义」。
private struct SubjectEditor: View {
    @EnvironmentObject private var settings: WatchSettings
    @Environment(\.dismiss) private var dismiss

    let period: Int
    @State private var text = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                Text("第 \(period + 1) 节").font(.headline)

                TextField("科目", text: $text)

                HStack {
                    Button("设成无") {
                        apply("")
                        dismiss()
                    }
                    .tint(.secondary)

                    Button("保存") {
                        apply(text)
                        dismiss()
                    }
                    .tint(Palette.accent)
                }
            }
            .padding(.horizontal, 4)
        }
        .onAppear {
            guard case .inSession(let info) = settings.phase else { return }
            let row = settings.table.rotatesByWeek ? max(0, info.displayWeek - 1) : 0
            text = settings.table.subject(row: row,
                                          day: SemesterCalculator.dayIndexInWeek(for: Date()),
                                          period: period)
        }
    }

    private func apply(_ value: String) {
        guard case .inSession(let info) = settings.phase else { return }
        var table = settings.table
        let row = table.rotatesByWeek ? max(0, info.displayWeek - 1) : 0
        table.setSubject(value, row: row,
                         day: SemesterCalculator.dayIndexInWeek(for: Date()),
                         period: period)
        settings.table = table
    }
}

extension Int: @retroactive Identifiable {
    public var id: Int { self }
}
