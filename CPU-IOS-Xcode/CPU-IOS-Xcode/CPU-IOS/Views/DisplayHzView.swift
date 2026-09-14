import SwiftUI

/// Tab CỐT LÕI: đo Hz màn hình theo thời gian thực, giống video ProMotion mẫu.
struct DisplayHzView: View {
    @StateObject private var monitor = RefreshRateMonitor()
    @State private var spinnerAngle: Double = 0

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {

                    // Số Hz hiện tại — số to, đây là thứ người dùng nhìn vào nhiều nhất
                    VStack(spacing: 4) {
                        Text("\(monitor.currentHz, specifier: "%.0f")")
                            .font(.system(size: 72, weight: .bold, design: .rounded))
                            .foregroundColor(hzColor(monitor.currentHz))
                            .contentTransition(.numericText())
                            .animation(.easeInOut(duration: 0.2), value: monitor.currentHz)
                        Text("Hz hiện tại")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)

                    // Min / Max quan sát được trong phiên đo này
                    HStack(spacing: 16) {
                        statBox(title: "Thấp nhất", value: monitor.minHz)
                        statBox(title: "Cao nhất", value: monitor.maxObservedHz)
                        statBox(title: "Tối đa máy", value: Double(monitor.maximumDeviceHz))
                    }
                    .padding(.horizontal)

                    // Mini biểu đồ dao động Hz theo thời gian
                    hzChart
                        .frame(height: 100)
                        .padding(.horizontal)

                    // Badge ProMotion
                    HStack {
                        Image(systemName: monitor.isProMotionCapable ? "checkmark.seal.fill" : "xmark.seal")
                            .foregroundColor(monitor.isProMotionCapable ? .green : .gray)
                        Text(monitor.isProMotionCapable
                             ? "Màn hình hỗ trợ ProMotion (Hz thích ứng)"
                             : "Màn hình chuẩn (Hz cố định 60)")
                            .font(.footnote)
                    }
                    .padding(.horizontal)

                    // Vòng xoay "kích hoạt" chuyển động để hệ thống bộc lộ Hz tối đa thật
                    VStack(spacing: 8) {
                        Circle()
                            .trim(from: 0, to: 0.75)
                            .stroke(
                                AngularGradient(colors: [.green, .yellow, .red], center: .center),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 70, height: 70)
                            .rotationEffect(.degrees(spinnerAngle))
                            .onAppear {
                                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                                    spinnerAngle = 360
                                }
                            }
                        Text("Animation này giữ màn hình chuyển động liên tục để đo đúng Hz tối đa — hãy thử vuốt màn hình để thấy số Hz tăng thêm.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .padding(.top, 8)

                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("Display Hz")
            .onAppear {
                BatteryService.enableMonitoring()
                monitor.start()
            }
            .onDisappear {
                monitor.stop()
            }
        }
    }

    private var hzChart: some View {
        GeometryReader { geo in
            let maxVal = max(monitor.maximumDeviceHz, 60)
            Path { path in
                guard monitor.samples.count > 1 else { return }
                let stepX = geo.size.width / CGFloat(max(monitor.samples.count - 1, 1))
                for (index, value) in monitor.samples.enumerated() {
                    let x = CGFloat(index) * stepX
                    let normalized = value / Double(maxVal)
                    let y = geo.size.height * (1 - CGFloat(normalized))
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(Color.green, style: StrokeStyle(lineWidth: 2, lineJoin: .round))
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    private func statBox(title: String, value: Double) -> some View {
        VStack(spacing: 4) {
            Text("\(value, specifier: "%.0f")")
                .font(.title2.bold())
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.gray.opacity(0.12))
        .cornerRadius(10)
    }

    private func hzColor(_ hz: Double) -> Color {
        if hz >= 90 { return .green }
        if hz >= 60 { return .yellow }
        return .orange
    }
}

#Preview {
    DisplayHzView()
}
