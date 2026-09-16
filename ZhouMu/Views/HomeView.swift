import SwiftUI

/// 主界面：打开软件直接显示今天是第几周。
struct HomeView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.scenePhase) private var scenePhase

    @State private var isShowingSettings = false
    @State private var referenceDate = Date()

    private var phase: SemesterPhase {
        SemesterCalculator.phase(startDate: settings.startDate,
                                 cycleWeeks: settings.cycleWeeks,
                                 cyclingEnabled: settings.cyclingEnabled,
                                 referenceDate: referenceDate)
    }

    var body: some View {
        ZStack {
            Palette.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                Spacer(minLength: 12)
                mainDisplay
                Spacer(minLength: 20)
                detailCard
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView()
                .environmentObject(settings)
        }
        .onAppear(perform: presentSetupIfNeeded)
        .onChange(of: scenePhase) { _, newPhase in
            // 从后台回到前台时刷新，避免跨天显示旧数据。
            if newPhase == .active { referenceDate = Date() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
            // 应用一直开着跨过零点时自动刷新。
            referenceDate = Date()
        }
    }

    // MARK: - 顶部

    private var header: some View {
        HStack {
            Text("周目")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Palette.orange)

            Spacer()

            Button {
                isShowingSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Palette.orange)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Palette.orangeSoft.opacity(0.6)))
            }
            .accessibilityLabel("设置")
        }
    }

    // MARK: - 中间：周目本体

    private var mainDisplay: some View {
        VStack(spacing: 22) {
            ring
            cycleIndicator
        }
    }

    private var ring: some View {
        var progress: Double = 0
        if case .inSession(let info) = phase {
            progress = info.weekProgress
        }

        return ZStack {
            Circle()
                .stroke(Palette.orangeSoft, style: StrokeStyle(lineWidth: 16))

            Circle()
                .trim(from: 0, to: progress)
                .stroke(Palette.orange, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                .rotationEffect(.degrees(-90))

            ringContent
        }
        .frame(width: 252, height: 252)
        .animation(.easeInOut(duration: 0.35), value: progress)
    }

    @ViewBuilder
    private var ringContent: some View {
        switch phase {
        case .inSession:
            // 圈内显示今天要上的科目；周目挪到圈下面（见 cycleIndicator）。
            VStack(spacing: 4) {
                Text(SemesterCalculator.weekdayShortNames[
                    SemesterCalculator.dayIndexInWeek(for: referenceDate)
                ])
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Palette.secondaryText)

                Text(todaySubjectText)
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.orange)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.4)
                    .padding(.horizontal, 30)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(todaySubjectAccessibilityLabel)

        case .notStarted(let days):
            VStack(spacing: 6) {
                Text("未开学")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.orange)
                Text("还有 \(days) 天")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(Palette.secondaryText)
            }
            .accessibilityElement(children: .combine)
        }
    }

    /// 圈内的科目文案：这一格是「无」时显示「无课」。
    private var todaySubjectText: String {
        let subject = settings.subjectForToday(referenceDate: referenceDate)
        return subject.isEmpty ? "无课" : subject
    }

    private var todaySubjectAccessibilityLabel: String {
        let subject = settings.subjectForToday(referenceDate: referenceDate)
        return subject.isEmpty ? "今天没有课" : "今天的科目是\(subject)"
    }

    @ViewBuilder
    private var cycleIndicator: some View {
        switch phase {
        case .inSession(let info):
            VStack(spacing: 10) {
                // 周目挪到圈的下面
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("第")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                    Text("\(info.displayWeek)")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .monospacedDigit()
                    Text("周")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(Palette.orange)

                if info.isCycling && info.cycleWeeks <= 12 {
                    CycleDots(total: info.cycleWeeks, current: info.displayWeek)
                }

                Text(subtitle(for: info))
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Palette.secondaryText)
            }

        case .notStarted:
            EmptyView()
        }
    }

    private func subtitle(for info: SessionInfo) -> String {
        info.isCycling
            ? "开学第 \(info.rawWeek) 周 · \(info.cycleWeeks) 周循环"
            : "开学第 \(info.rawWeek) 周"
    }

    // MARK: - 底部信息卡

    private var detailCard: some View {
        VStack(spacing: 14) {
            DetailRow(label: "开学日期", value: settings.startDate.zhoumu_shortText)

            Divider().overlay(Palette.orangeSoft)

            DetailRow(label: "今天", value: referenceDate.zhoumu_fullText)

            Divider().overlay(Palette.orangeSoft)

            DetailRow(label: trailingLabel, value: trailingValue, highlighted: true)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Palette.card)
                .shadow(color: Palette.orange.opacity(0.10), radius: 20, x: 0, y: 10)
        )
    }

    private var trailingLabel: String {
        switch phase {
        case .inSession: return "距下一周目"
        case .notStarted: return "距开学"
        }
    }

    private var trailingValue: String {
        switch phase {
        case .inSession(let info): return "\(info.daysUntilNextWeek) 天"
        case .notStarted(let days): return "\(days) 天"
        }
    }

    // MARK: - 启动引导

    private func presentSetupIfNeeded() {
        guard settings.shouldPresentSetupOnLaunch else { return }
        // 先登记再弹出，避免视图重建时重复弹出。
        settings.markSetupPrompted()
        // 等启动动画结束再弹，否则 sheet 会和启动动画抢时序。
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            isShowingSettings = true
        }
    }
}

// MARK: - 子视图

/// 循环中的位置：一排圆点，当前周目高亮。
private struct CycleDots: View {
    let total: Int
    let current: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(1...max(total, 1)), id: \.self) { index in
                Circle()
                    .fill(index == current ? Palette.orange : Palette.orangeSoft)
                    .frame(width: index == current ? 13 : 9,
                           height: index == current ? 13 : 9)
            }
        }
        .frame(height: 16)
        .animation(.easeInOut(duration: 0.25), value: current)
        .accessibilityHidden(true)
    }
}

/// 信息卡里的一行。
private struct DetailRow: View {
    let label: String
    let value: String
    var highlighted: Bool = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(Palette.secondaryText)

            Spacer(minLength: 0)

            Text(value)
                .font(.system(size: 15, weight: highlighted ? .bold : .semibold, design: .rounded))
                .foregroundStyle(highlighted ? Palette.orangeDeep : Palette.primaryText)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AppSettings())
}
