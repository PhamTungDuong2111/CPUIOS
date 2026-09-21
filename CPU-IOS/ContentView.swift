import SwiftUI

struct ContentView: View {
    @ObservedObject private var lang = LanguageManager.shared

    var body: some View {
        TabView {
            DisplayHzView()
                .tabItem {
                    Label(lang.tr("Tần Số Hz", "Display Hz"), systemImage: "waveform.path.ecg")
                }

            DeviceInfoView()
                .tabItem {
                    Label(lang.tr("Thiết Bị", "Device"), systemImage: "iphone")
                }

            CPUMemoryView()
                .tabItem {
                    Label(lang.tr("CPU / RAM", "CPU / RAM"), systemImage: "cpu")
                }

            BatteryView()
                .tabItem {
                    Label(lang.tr("Pin", "Battery"), systemImage: "battery.100")
                }
        }
        .tint(.green)
    }
}

#Preview {
    ContentView()
}
