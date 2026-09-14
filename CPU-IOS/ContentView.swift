import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            DisplayHzView()
                .tabItem { Label("Display Hz", systemImage: "waveform.path.ecg") }

            DeviceInfoView()
                .tabItem { Label("Device", systemImage: "iphone") }

            CPUMemoryView()
                .tabItem { Label("CPU/RAM", systemImage: "cpu") }

            BatteryView()
                .tabItem { Label("Battery", systemImage: "battery.100") }
        }
        .tint(.green)
    }
}

#Preview {
    ContentView()
}
