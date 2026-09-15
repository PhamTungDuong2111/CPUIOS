import SwiftUI

/// Tab CỐT LÕI: đo Hz màn hình theo thời gian thực và hỗ trợ cửa sổ nổi PiP giống video CPU-X.
struct DisplayHzView: View {
    @StateObject private var monitor = RefreshRateMonitor()
    @StateObject private var pipManager = PiPFloatingMonitorManager.shared
    @State private var spinnerAngle: Double = 0
    @State private var isStressTesting: Bool = false
    @State private var testOffset: CGFloat = 0
    @State private var touchDragOffset: CGSize = .zero

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {

                    // MARK: - Số Hz hiện tại (Số to)
                    VStack(spacing: 4) {
                        Text("\(monitor.currentHz, specifier: "%.0f")")
                            .font(.system(size: 76, weight: .bold, design: .rounded))
                            .foregroundColor(hzColor(monitor.currentHz))
                            .contentTransition(.numericText())

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

                    // MARK: - Khu vực kích hoạt test 120Hz tức thì
                    quickTestCard
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

    // MARK: - Quick 120Hz Test Card
    private var quickTestCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Bài test ép xung 120 FPS")
                        .font(.headline)
                    Text(isStressTesting ? "Đang chạy bài test tốc độ cao..." : "Kích hoạt hiệu ứng liên tục để xem màn hình đạt 120Hz")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: runQuick120HzTest) {
                    HStack(spacing: 4) {
                        Image(systemName: isStressTesting ? "bolt.fill" : "play.fill")
                        Text(isStressTesting ? "Đang test" : "Chạy test")
                    }
                    .font(.caption.bold())
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isStressTesting ? Color.orange : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(isStressTesting)
            }

            // Thanh chạy animation thử nghiệm khi bấm test
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 10)

                RoundedRectangle(cornerRadius: 6)
                    .fill(LinearGradient(colors: [.green, .yellow, .red], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 50, height: 10)
                    .offset(x: testOffset)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(14)
    }

    private func runQuick120HzTest() {
        guard !isStressTesting else { return }
        isStressTesting = true
        testOffset = 0

        // Kích hoạt animation mượt mà qua lại trong 3 giây để đẩy panel lên 120Hz
        withAnimation(.easeInOut(duration: 0.5).repeatCount(6, autoreverses: true)) {
            testOffset = 220
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.1) {
            withAnimation(.easeOut(duration: 0.2)) {
                testOffset = 0
                isStressTesting = false
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

            // Preview cửa sổ nổi đồng thời làm source view chuẩn cho PiP
            VStack(alignment: .leading, spacing: 6) {
                Text("Xem trước cửa sổ nổi:")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                ZStack {
                    PiPSourceViewRepresentable()
                        .frame(width: 220, height: 110)

                    FloatingMonitorHUDView()
                }
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
        VStack(alignment: .leading, spacing: 10) {
            Text("Khu vực tương tác test 120Hz")
                .font(.caption)
                .foregroundColor(.secondary)

            // Khu vực rê tay kích thích 120Hz
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.green.opacity(0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                    )

                HStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 32, height: 32)
                        .overlay(Image(systemName: "hand.tap.fill").foregroundColor(.white).font(.caption))
                        .offset(touchDragOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    self.touchDragOffset = CGSize(
                                        width: min(max(gesture.translation.width, -80), 80),
                                        height: 0
                                    )
                                }
                                .onEnded { _ in
                                    withAnimation(.spring()) {
                                        self.touchDragOffset = .zero
                                    }
                                }
                        )

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Kéo hoặc chạm liên tục vào đây")
                            .font(.subheadline.bold())
                        Text("Thao tác tay lập tức đẩy ProMotion lên 120Hz")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
            .frame(height: 56)

            // Thẻ cuộn ngang
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
                            Text("Vuốt qua lại thật nhanh để thấy Hz nhảy lên 120.")
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

