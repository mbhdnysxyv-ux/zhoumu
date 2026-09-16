import SwiftUI

/// 橙白配色，集中在这里方便统一调整。
enum Palette {
    /// 主橙色。
    static let orange = Color(red: 0.980, green: 0.451, blue: 0.090)      // #FA7317
    /// 深橙，用于小字号文字，保证可读性。
    static let orangeDeep = Color(red: 0.835, green: 0.298, blue: 0.016)  // #D54C04
    /// 浅橙，用于轨道、未选中的圆点。
    static let orangeSoft = Color(red: 1.000, green: 0.898, blue: 0.804)  // #FFE5CD
    /// 底色：暖白。
    static let background = Color(red: 1.000, green: 0.976, blue: 0.957)  // #FFF9F4
    static let card = Color.white
    static let primaryText = Color(red: 0.180, green: 0.137, blue: 0.110)
    static let secondaryText = Color(red: 0.549, green: 0.470, blue: 0.427)
}
