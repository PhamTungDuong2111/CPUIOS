import Foundation
import QuartzCore
import UIKit
import Combine

/// TÍNH NĂNG CỐT LÕI của app.
///
/// Đo tần số quét thực tế của màn hình theo thời gian thực bằng CADisplayLink.
/// CADisplayLink được hệ thống gọi đúng mỗi lần panel vẽ khung hình mới, nên
/// khoảng cách thời gian giữa 2 lần gọi liên tiếp chính là chu kỳ quét thật.
///
/// Trên thiết bị ProMotion (iPhone 13 Pro trở lên, iPad Pro 120Hz), hệ điều
/// hành tự động điều chỉnh Hz theo nội dung: màn hình tĩnh -> Hz thấp (tiết
/// kiệm pin), có chuyển động/scroll -> Hz tăng dần tới tối đa (60/80/90/120Hz
/// tuỳ máy) — đây chính là hiện tượng "đôi lúc lên 120Hz" trong video mẫu.
final class RefreshRateMonitor: ObservableObject {

    @Published private(set) var currentHz: Double = 0
    @Published private(set) var minHz: Double = 0
    @Published private(set) var maxObservedHz: Double = 0
    @Published private(set) var maximumDeviceHz: Int = 60
    @Published private(set) var isProMotionCapable: Bool = false
    @Published private(set) var samples: [Double] = []   // để vẽ mini biểu đồ

    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var lastUIUpdateTimestamp: CFTimeInterval = 0
    private var smoothingBuffer: [Double] = []

    private let smoothingWindow = 8
    private let maxSampleHistory = 50
    private let uiUpdateInterval: CFTimeInterval = 0.08 // Cập nhật UI ~12 lần/giây để chống đơ nghẽn Main Thread

    init() {
        determineDeviceCapabilities()
    }

    func determineDeviceCapabilities() {
        let screenMax = UIScreen.main.maximumFramesPerSecond
        let identifier = DeviceIdentifier.hardwareIdentifier()
        let device = DeviceDatabaseService.shared.lookup(identifier: identifier)

        let isProMotion = screenMax > 60 || device.maxRefreshRateHz > 60
        self.isProMotionCapable = isProMotion
        self.maximumDeviceHz = max(screenMax, isProMotion ? 120 : 60)
    }

    func start() {
        stop()
        determineDeviceCapabilities()
        currentHz = 0
        minHz = 0
        maxObservedHz = 0
        samples = []
        smoothingBuffer = []
        lastTimestamp = 0
        lastUIUpdateTimestamp = 0

        let link = CADisplayLink(target: self, selector: #selector(handleFrame(_:)))

        // Cho phép CADisplayLink bám sát tần số quét phần cứng (hỗ trợ 10 - 120Hz)
        if #available(iOS 15.0, *) {
            let maxFPS = Float(max(maximumDeviceHz, 120))
            link.preferredFrameRateRange = CAFrameRateRange(
                minimum: 10,
                maximum: maxFPS,
                preferred: maxFPS
            )
        }
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
    }

    @objc private func handleFrame(_ link: CADisplayLink) {
        defer { lastTimestamp = link.timestamp }
        guard lastTimestamp != 0 else { return }

        let delta = link.timestamp - lastTimestamp
        guard delta > 0 else { return }

        let instantHz = 1.0 / delta

        // Lọc nhiễu bằng trung bình trượt ngắn gọn
        smoothingBuffer.append(instantHz)
        if smoothingBuffer.count > smoothingWindow {
            smoothingBuffer.removeFirst()
        }
        let averaged = smoothingBuffer.reduce(0, +) / Double(smoothingBuffer.count)

        // Cập nhật min/max nội bộ ngay lập tức
        if averaged >= 20 {
            if minHz == 0 {
                minHz = averaged
            } else if averaged < minHz {
                minHz = averaged
            }
        }
        if averaged > maxObservedHz {
            maxObservedHz = min(averaged, Double(maximumDeviceHz) * 1.05)
        }

        // ĐIỀU TIẾT CẬP NHẬT UI (Throttling):
        // Chỉ kích hoạt thông báo @Published cho SwiftUI theo chu kỳ uiUpdateInterval hoặc khi có bước nhảy vọt,
        // giúp giải phóng 95% CPU render của Main Thread, ngăn chặn triệt để tình trạng máy bị đơ cứng.
        let timeSinceLastUIUpdate = link.timestamp - lastUIUpdateTimestamp
        let significantJump = abs(averaged - currentHz) > 15

        if timeSinceLastUIUpdate >= uiUpdateInterval || significantJump {
            lastUIUpdateTimestamp = link.timestamp

            self.currentHz = averaged

            self.samples.append(averaged)
            if self.samples.count > self.maxSampleHistory {
                self.samples.removeFirst()
            }
        }
    }
}
