import SwiftUI
import Combine

struct BatteryView: View {
    @State private var level: Float = BatteryService.level
    @State private var state: String = BatteryService.state
    private let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "battery.100")
                    .font(.system(size: 64))
                    .foregroundColor(.green)
                Text("\(Int(max(level, 0) * 100))%")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                Text(state)
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding(.top, 40)
            .navigationTitle("Battery")
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
