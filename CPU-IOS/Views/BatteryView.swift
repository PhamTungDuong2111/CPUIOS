import SwiftUI
import Combine

struct BatteryView: View {
    @State private var level: Float = BatteryService.level
    @State private var state: String = BatteryService.state
    @ObservedObject private var lang = LanguageManager.shared
    private let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    private var localizedState: String {
        switch state {
        case "Đang sạc": return lang.tr("Đang sạc", "Charging")
        case "Đầy": return lang.tr("Đầy", "Full")
        case "Không sạc": return lang.tr("Không sạc", "Unplugged")
        default: return lang.tr(state, state)
        }
    }

    private var batteryIcon: String {
        let percent = Int(max(level, 0) * 100)
        if percent > 80 { return "battery.100" }
        if percent > 50 { return "battery.75" }
        if percent > 25 { return "battery.50" }
        return "battery.25"
    }

    private var batteryColor: Color {
        let percent = Int(max(level, 0) * 100)
        if percent > 20 { return .green }
        return .red
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: batteryIcon)
                    .font(.system(size: 72))
                    .foregroundColor(batteryColor)

                Text("\(Int(max(level, 0) * 100))%")
                    .font(.system(size: 54, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text(localizedState)
                    .font(.title3.weight(.medium))
                    .foregroundColor(.secondary)

                Spacer()
            }
            .padding(.top, 40)
            .navigationTitle(lang.tr("Tình Trạng Pin", "Battery"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        lang.toggleLanguage()
                    }) {
                        HStack(spacing: 4) {
                            Text(lang.currentLanguage.flag)
                            Text(lang.currentLanguage.shortCode)
                                .font(.caption.bold())
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.15))
                        .cornerRadius(8)
                    }
                }
            }
            .onAppear { refresh() }
            .onReceive(timer) { _ in refresh() }
        }
    }

    private func refresh() {
        level = BatteryService.level
        state = BatteryService.state
    }
}

#Preview {
    BatteryView()
}
