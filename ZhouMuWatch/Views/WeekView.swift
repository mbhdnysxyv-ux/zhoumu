import SwiftUI

/// 手表主界面：抬腕就看到第几周，下面是今天的课。
struct WeekView: View {
    @EnvironmentObject private var settings: WatchSettings

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    weekBadge
                    todaySection
                }
                .padding(.horizontal, 4)
            }
            .navigationTitle("周目")
            .toolbar {
                NavigationLink { WatchSettingsView() } label: {
                    Image(systemName: "gearshape")
                }
            }
        }
    }

    // MARK: - 周目

    @ViewBuilder
    private var weekBadge: some View {
        switch settings.phase {
        case .notStarted(let days):
            VStack(spacing: 2) {
                Text("未开学").font(.system(size: 20, weight: .bold, design: .rounded))
                Text("还有 \(days) 天").font(.footnote).foregroundStyle(.secondary)
            }
            .padding(.vertical, 6)

        case .inSession(let info):
            VStack(spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text("第").font(.system(size: 15, weight: .semibold, design: .rounded))
                    Text("\(info.displayWeek)")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text("周").font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(Palette.accent)

                // 本周进度
                ProgressView(value: info.weekProgress)
                    .tint(Palette.accent)

                Text(info.isCycling ? "开学第 \(info.rawWeek) 周 · \(info.cycleWeeks) 周循环"
                                    : "开学第 \(info.rawWeek) 周")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - 今天的课

    private var todayClasses: [(period: Int, subject: String, time: String?)] {
        settings.todayClasses()
    }

    @ViewBuilder
    private var todaySection: some View {
        let classes = todayClasses
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("今天").font(.system(size: 13, weight: .semibold, design: .rounded))
                Spacer()
                Text(SemesterCalculator.weekdayShortNames[
                    SemesterCalculator.dayIndexInWeek(for: Date())])
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            if classes.isEmpty {
                Text("今天没有课")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ForEach(classes, id: \.period) { item in
                    HStack(spacing: 8) {
                        Text("\(item.period)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(Palette.accent)
                            .frame(width: 18, height: 18)
                            .background(Circle().fill(Palette.accentSoft))

                        Text(item.subject)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .lineLimit(1)

                        Spacer(minLength: 4)

                        if let time = item.time {
                            Text(time)
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                }
            }
        }
    }
}
