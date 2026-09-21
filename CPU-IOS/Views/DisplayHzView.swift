import SwiftUI

/// Tab CỐT LÕI: Đo tần số quét màn hình (Hz) theo thời gian thực (tối đa 120Hz).
/// Tích hợp đồng hồ đo trực quan, bài test kích hoạt 120Hz và hỗ trợ PiP QUÉT TẦN SỐ HZ.
struct DisplayHzView: View {
    @StateObject private var monitor = RefreshRateMonitor()
    @StateObject private var pipManager = PiPFloatingMonitorManager.shared
    @ObservedObject private var lang = LanguageManager.shared

    @State private var spinnerAngle: Double = 0
    @State private var isStressTesting: Bool = false
    @State private var testOffset: CGFloat = 0
    @State private var touchDragOffset: CGSize = .zero

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {

                    // MARK: - Đồng hồ đo Hz (Speedometer Gauge Arc: 0 - 120Hz)
                    hzSpeedometerGauge
                        .padding(.top, 6)

                    // MARK: - Lưới 4 ô thống kê chi tiết
                    statsGrid
                        .padding(.horizontal)

                    // MARK: - Khu vực kích hoạt test 120Hz
                    quickTestCard
                        .padding(.horizontal)

                    // MARK: - Cửa sổ nổi PiP (Quét tần số Hz trên màn hình chính)
                    pipControlCard
                        .padding(.horizontal)

                    // MARK: - Biểu đồ dao động Hz theo thời gian (0 - 120Hz)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(lang.tr("Lịch sử tần số quét (0 - 120Hz)", "Refresh Rate History (0 - 120Hz)"))
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(String(format: lang.tr("Độ trễ: %.2f ms", "Frame Time: %.2f ms"), monitor.frameTimeMs))
                                .font(.caption2.monospaced())
                                .foregroundColor(hzColor(monitor.currentHz))
                        }

                        hzChart
                            .frame(height: 100)
                    }
                    .padding(.horizontal)

                    // MARK: - Khu vực tương tác tay ép ProMotion 120Hz
                    interactiveTestSection
                        .padding(.horizontal)

                    // MARK: - Thông tin công nghệ màn hình & Vòng xoay động
                    VStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: monitor.isProMotionCapable ? "sparkles" : "display")
                                .foregroundColor(monitor.isProMotionCapable ? .green : .blue)
                            Text(monitor.isProMotionCapable
                                 ? lang.tr("Màn hình ProMotion (Thích ứng linh hoạt 10 - 120Hz)", "ProMotion Display (Adaptive 10 - 120Hz)")
                                 : lang.tr("Màn hình tiêu chuẩn (Tần số cố định 60Hz)", "Standard Display (Fixed 60Hz)"))
                                .font(.footnote.weight(.medium))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(monitor.isProMotionCapable ? Color.green.opacity(0.12) : Color.blue.opacity(0.12))
                        )

                        Circle()
                            .trim(from: 0, to: 0.75)
                            .stroke(
                                AngularGradient(colors: [.green, .cyan, .yellow, .red], center: .center),
                                style: StrokeStyle(lineWidth: 5, lineCap: .round)
                            )
                            .frame(width: 44, height: 44)
                            .rotationEffect(.degrees(spinnerAngle))
                            .onAppear {
                                withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                                    spinnerAngle = 360
                                }
                            }
                    }
                    .padding(.vertical, 8)

                    Spacer(minLength: 24)
                }
            }
            .navigationTitle(lang.tr("Đo Tần Số Quét", "Display Hz"))
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
            .onAppear {
                BatteryService.enableMonitoring()
                monitor.start()
                FloatingMonitorData.shared.start()
            }
            .onDisappear {
                monitor.stop()
                if !pipManager.isPiPActive {
                    FloatingMonitorData.shared.stop()
                }
            }
        }
    }

    // MARK: - Đồng hồ đo Speedometer Gauge (0 - 120 Hz)
    private var hzSpeedometerGauge: some View {
        ZStack {
            // Vòng cung nền (0 - 120Hz tương ứng 240 độ)
            Circle()
                .trim(from: 0.15, to: 0.85)
                .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .frame(width: 220, height: 220)
                .rotationEffect(.degrees(90))

            // Vòng cung giá trị hiện tại (tỉ lệ currentHz / 120.0)
            let ratio = CGFloat(min(max(monitor.currentHz, 0), 120.0) / 120.0)
            let progress = 0.15 + (ratio * 0.70)
            Circle()
                .trim(from: 0.15, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [.orange, .yellow, .mint, .green],
                        center: .center,
                        startAngle: .degrees(135),
                        endAngle: .degrees(405)
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .frame(width: 220, height: 220)
                .rotationEffect(.degrees(90))
                .animation(.easeOut(duration: 0.12), value: ratio)

            // Hiển thị số Hz to ở giữa
            VStack(spacing: 2) {
                Text("\(Int(round(monitor.currentHz)))")
                    .font(.system(size: 68, weight: .black, design: .rounded))
                    .foregroundColor(hzColor(monitor.currentHz))
                    .contentTransition(.numericText())

                Text(lang.tr("Tần số quét (Hz)", "Refresh Rate (Hz)"))
                    .font(.caption.bold())
                    .foregroundColor(.secondary)

                HStack(spacing: 4) {
                    Circle()
                        .fill(monitor.currentHz >= 110 ? Color.green : (monitor.currentHz >= 60 ? Color.yellow : Color.orange))
                        .frame(width: 8, height: 8)
                    Text(monitor.currentHz >= 115 ? "120Hz ProMotion" : (monitor.currentHz >= 60 ? "60-90Hz" : "<60Hz Idle"))
                        .font(.caption2.bold())
                        .foregroundColor(.primary)
                }
                .padding(.top, 4)
            }

            // Các mốc vạch 0, 60, 120 Hz
            VStack {
                Spacer()
                HStack {
                    Text("0")
                        .font(.caption2.monospaced())
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("60")
                        .font(.caption2.monospaced().bold())
                        .foregroundColor(.yellow)
                    Spacer()
                    Text("120")
                        .font(.caption2.monospaced().bold())
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 40)
            }
            .frame(width: 240, height: 210)
        }
        .frame(height: 220)
    }

    // MARK: - Lưới 4 ô thống kê
    private var statsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            statBox(title: lang.tr("Thấp nhất", "Minimum"), value: "\(Int(round(monitor.minHz))) Hz", color: .orange)
            statBox(title: lang.tr("Cao nhất đạt được", "Peak Observed"), value: "\(Int(round(monitor.maxObservedHz))) Hz", color: .green)
            statBox(title: lang.tr("Tối đa máy hỗ trợ", "Max Display Hz"), value: "\(monitor.maximumDeviceHz) Hz", color: .mint)
            statBox(title: lang.tr("Độ trễ khung hình", "Frame Duration"), value: String(format: "%.1f ms", monitor.frameTimeMs), color: .blue)
        }
    }

    private func statBox(title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold().monospaced())
                .foregroundColor(color)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }

    // MARK: - Quick 120Hz Test Card
    private var quickTestCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(lang.tr("Bài test kích hoạt 120 FPS", "120 FPS Boost Test"))
                        .font(.headline)
                    Text(isStressTesting
                         ? lang.tr("Đang kích hoạt chuỗi khung hình cao...", "Running high-rate frame animation...")
                         : lang.tr("Chạy hiệu ứng mượt liên tục để đẩy màn hình lên 120Hz", "Run smooth animation to push display to 120Hz"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: runQuick120HzTest) {
                    HStack(spacing: 4) {
                        Image(systemName: isStressTesting ? "bolt.fill" : "play.fill")
                        Text(isStressTesting ? lang.tr("Đang test", "Testing") : lang.tr("Chạy test", "Run Test"))
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
                    .frame(height: 12)

                RoundedRectangle(cornerRadius: 6)
                    .fill(LinearGradient(colors: [.green, .mint, .cyan, .yellow], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 60, height: 12)
                    .offset(x: testOffset)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(14)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(14)
    }

    private func runQuick120HzTest() {
        guard !isStressTesting else { return }
        isStressTesting = true
        testOffset = 0

        withAnimation(.easeInOut(duration: 0.4).repeatCount(8, autoreverses: true)) {
            testOffset = 220
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3.3) {
            withAnimation(.easeOut(duration: 0.2)) {
                testOffset = 0
                isStressTesting = false
            }
        }
    }

    // MARK: - PiP Control Card (Quét tần số Hz trên cửa sổ nổi)
    private var pipControlCard: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Image(systemName: "pip.fill")
                            .foregroundColor(.green)
                        Text(lang.tr("Cửa Sổ Nổi PiP (Quét Tần Số Hz)", "Floating PiP (Hz Scanner)"))
                            .font(.headline)
                    }
                    Text(lang.tr("Nổi ngoài màn hình chính quét tần số Hz 60 ⇄ 120Hz", "Floating overlay scanning display Hz 60 ⇄ 120Hz"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()

                if pipManager.isPiPActive {
                    Text(lang.tr("ĐANG BẬT", "ACTIVE"))
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
                Text(lang.tr("Xem trước cửa sổ nổi (Đang quét Hz):", "Floating window preview (Scanning Hz):"))
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
                    Text(pipManager.isPiPActive
                         ? lang.tr("Tắt Cửa Sổ Nổi", "Stop Floating PiP")
                         : lang.tr("Bật Cửa Sổ Nổi (PiP Quét Hz)", "Start PiP (Hz Scanner)"))
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
                Text(lang.tr("Cách test quét tần số Hz ngoài màn hình:", "How to test Hz scanning on Home Screen:"))
                    .font(.caption.bold())
                    .foregroundColor(.primary)
                Text(lang.tr("1. Nhấn nút 'Bật Cửa Sổ Nổi (PiP Quét Hz)' ở trên.", "1. Tap 'Start PiP (Hz Scanner)' above."))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(lang.tr("2. Vuốt thanh gạt về Màn hình chính (Home) hoặc mở app bất kỳ.", "2. Swipe back to Home screen or open any application."))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(lang.tr("3. Cửa sổ nổi quét liên tục tần số Hz: khi để yên sẽ hạ thấp, khi vuốt lướt sẽ tăng lên 60/120 Hz!", "3. Floating HUD actively scans display Hz: idle drops, swiping boosts to 60/120 Hz!"))
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
            Text(lang.tr("Khu vực tương tác test 120Hz", "120Hz Interactive Test Area"))
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
                        Text(lang.tr("Kéo hoặc chạm liên tục vào đây", "Drag or tap rapidly here"))
                            .font(.subheadline.bold())
                        Text(lang.tr("Thao tác tay lập tức kích hoạt ProMotion lên 120Hz", "Touch gesture immediately boosts ProMotion to 120Hz"))
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
                                Text(String(format: lang.tr("Vuốt thử %d", "Swipe Test %d"), i))
                                    .font(.headline)
                            }
                            Text(lang.tr("Vuốt qua lại thật nhanh để xem Hz nhảy lên 120.", "Swipe quickly back and forth to see Hz jump to 120."))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 180, height: 84)
                        .padding(12)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                }
            }
        }
    }

    // MARK: - Chart & Helpers (Thang đo 0 - 120Hz)
    private var hzChart: some View {
        GeometryReader { geo in
            let maxVal: Double = 120.0 // Thang đo tối đa 120Hz
            ZStack(alignment: .topLeading) {
                // Vạch chuẩn 60Hz
                let y60 = geo.size.height * (1 - CGFloat(60.0 / maxVal))
                Path { path in
                    path.move(to: CGPoint(x: 0, y: y60))
                    path.addLine(to: CGPoint(x: geo.size.width, y: y60))
                }
                .stroke(Color.yellow.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))

                // Đường vẽ biểu đồ
                Path { path in
                    guard monitor.samples.count > 1 else { return }
                    let stepX = geo.size.width / CGFloat(max(monitor.samples.count - 1, 1))
                    for (index, value) in monitor.samples.enumerated() {
                        let x = CGFloat(index) * stepX
                        let normalized = min(max(value, 0), maxVal) / maxVal
                        let y = geo.size.height * (1 - CGFloat(normalized))
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(
                    LinearGradient(colors: [.yellow, .green], startPoint: .bottom, endPoint: .top),
                    style: StrokeStyle(lineWidth: 2.5, lineJoin: .round)
                )

                // Nhãn mốc 120Hz và 60Hz
                VStack {
                    HStack {
                        Text("120 Hz")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.green.opacity(0.8))
                        Spacer()
                    }
                    Spacer()
                    HStack {
                        Text("60 Hz")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.yellow.opacity(0.8))
                        Spacer()
                    }
                    .offset(y: -y60 / 2)
                }
                .padding(.leading, 4)
            }
        }
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }

    private func hzColor(_ hz: Double) -> Color {
        if hz >= 110 { return .green }
        if hz >= 90 { return .mint }
        if hz >= 60 { return .yellow }
        return .orange
    }
}

#Preview {
    DisplayHzView()
}
