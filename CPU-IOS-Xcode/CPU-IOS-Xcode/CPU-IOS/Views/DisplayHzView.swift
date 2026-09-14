import SwiftUI

/// Tab CỐT LÕI: đo Hz màn hình theo thời gian thực và hỗ trợ cửa sổ nổi PiP giống video CPU-X.
struct DisplayHzView: View {
    @StateObject private var monitor = RefreshRateMonitor()
    @StateObject private var pipManager = PiPFloatingMonitorManager.shared
    @State private var spinnerAngle: Double = 0

    var body: some View {
        NavigationView {
            ZStack {
                // Invisible PiP source view in hierarchy for AVPictureInPictureController
                PiPSourceViewRepresentable()
                    .frame(width: 1, height: 1)
                    .opacity(0.01)

                ScrollView {
                    VStack(spacing: 20) {

                        // MARK: - Số Hz hiện tại (Số to)
                        VStack(spacing: 4) {
                            Text("\(monitor.currentHz, specifier: "%.0f")")
                                .font(.system(size: 76, weight: .bold, design: .rounded))
                                .foregroundColor(hzColor(monitor.currentHz))
                                .contentTransition(.numericText())
                                .animation(.easeInOut(duration: 0.2), value: monitor.currentHz)
                            Text("Hz hiện tại (Refresh Rate)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)

                        // MARK: - Min / Max quan sát được
                        HStack(spacing: 12) {
                            statBox(title: "Thấp nhất", value: monitor.minHz)
                            statBox(title: "Cao nhất", value: monitor.maxObservedHz)
                            statBox(title: "Tối đa máy", value: Double(monitor.maximumDeviceHz))
                        }
                        .padding(.horizontal)

                        // MARK: - Cửa sổ nổi PiP (Tính năng chính theo video YouTube)
                        pipControlCard
                            .padding(.horizontal)

                        // MARK: - Mini biểu đồ dao động Hz theo thời gian
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Lịch sử tần số quét")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            hzChart
                                .frame(height: 90)
                        }
                        .padding(.horizontal)

                        // MARK: - Khu vực vuốt để test 120Hz ngay trong app
                        interactiveTestSection
                            .padding(.horizontal)

                        // MARK: - Badge ProMotion & Vòng xoay kích hoạt
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: monitor.isProMotionCapable ? "checkmark.seal.fill" : "xmark.seal")
                                    .foregroundColor(monitor.isProMotionCapable ? .green : .gray)
                                Text(monitor.isProMotionCapable
                                     ? "Màn hình hỗ trợ ProMotion (Hz thích ứng 10-120Hz)"
                                     : "Màn hình chuẩn (Hz cố định 60)")
                                    .font(.footnote)
                            }

                            Circle()
                                .trim(from: 0, to: 0.75)
                                .stroke(
                                    AngularGradient(colors: [.green, .yellow, .red], center: .center),
                                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                                )
                                .frame(width: 50, height: 50)
                                .rotationEffect(.degrees(spinnerAngle))
                                .onAppear {
                                    withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                                        spinnerAngle = 360
                                    }
                                }
                        }
                        .padding(.vertical, 8)

                        Spacer(minLength: 20)
                    }
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

    // MARK: - PiP Control Card
    private var pipControlCard: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Image(systemName: "pip.fill")
                            .foregroundColor(.green)
                        Text("Cửa Sổ Nổi PiP (Giống Video)")
                            .font(.headline)
                    }
                    Text("Nổi trên màn hình chính đo FPS 60 ⇄ 120Hz")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()

                if pipManager.isPiPActive {
                    Text("ĐANG BẬT")
                        .font(.caption2.bold())
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.15))
                        .cornerRadius(6)
                }
            }

            // Preview mô phỏng cửa sổ nổi
            VStack(alignment: .leading, spacing: 6) {
                Text("Xem trước cửa sổ nổi:")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                FloatingMonitorHUDView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }

            // Nút kích hoạt PiP
            Button(action: {
                pipManager.togglePiP()
            }) {
                HStack {
                    Image(systemName: pipManager.isPiPActive ? "pip.exit" : "pip.enter")
                    Text(pipManager.isPiPActive ? "Tắt Cửa Sổ Nổi" : "Bật Cửa Sổ Nổi (PiP)")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    pipManager.isPiPActive
                    ? LinearGradient(colors: [.red.opacity(0.8), .orange], startPoint: .leading, endPoint: .trailing)
                    : LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing)
                )
                .foregroundColor(.white)
                .cornerRadius(12)
            }

            // Hướng dẫn test nhanh
            VStack(alignment: .leading, spacing: 4) {
                Text("Cách test giống video:")
                    .font(.caption.bold())
                    .foregroundColor(.primary)
                Text("1. Nhấn nút 'Bật Cửa Sổ Nổi (PiP)' ở trên.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("2. Vuốt thanh gạt về Màn hình chính (Home) hoặc mở app bất kỳ.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("3. Để yên máy sẽ thấy FPS là 60; vuốt liên tục qua lại giữa các trang sẽ nhảy vọt lên 120 FPS!")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(Color(UIColor.tertiarySystemBackground))
            .cornerRadius(10)
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }

    // MARK: - Interactive Test Area
    private var interactiveTestSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Khu vực vuốt test ProMotion trong app")
                .font(.caption)
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(1...5, id: \.self) { i in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: "hand.draw.fill")
                                    .foregroundColor(.green)
                                Text("Vuốt thẻ \(i)")
                                    .font(.headline)
                            }
                            Text("Vuốt qua lại thật nhanh để ép màn hình bộc lộ 120Hz.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 170, height: 80)
                        .padding(12)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                }
            }
        }
    }

    // MARK: - Chart & Helpers
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
