import Foundation
import QuartzCore
import UIKit
import Combine

/// TÍNH NĂNG CỐT LÕI:
/// Đo tần số quét thực tế của màn hình theo thời gian thực bằng CADisplayLink.
/// Hỗ trợ màn hình ProMotion với tần số quét tối đa lên đến 120Hz.
final class RefreshRateMonitor: ObservableObject {

    @Published private(set) var currentHz: Double = 0
    @Published private(set) var minHz: Double = 0
    @Published private(set) var maxObservedHz: Double = 0
    @Published private(set) var maximumDeviceHz: Int = 120 // Hỗ trợ tối đa 120Hz
    @Published private(set) var isProMotionCapable: Bool = false
    @Published private(set) var frameTimeMs: Double = 0    // Độ trễ khung hình tính bằng ms (8.33ms ở 120Hz)
    @Published private(set) var samples: [Double] = []     // Dữ liệu vẽ đồ thị dao động

    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var lastUIUpdateTimestamp: CFTimeInterval = 0
    private var smoothingBuffer: [Double] = []

    private let smoothingWindow = 8
    private let maxSampleHistory = 50
    private let uiUpdateInterval: CFTimeInterval = 0.06 // Cập nhật UI ~16 lần/giây mượt mà

    init() {
        determineDeviceCapabilities()
    }

    func determineDeviceCapabilities() {
        let screenMax = UIScreen.main.maximumFramesPerSecond
        let identifier = DeviceIdentifier.hardwareIdentifier()
        let device = DeviceDatabaseService.shared.lookup(identifier: identifier)

        let isProMotion = screenMax >= 120 || device.maxRefreshRateHz >= 120
        self.isProMotionCapable = isProMotion
        // Tần số tối đa: 120Hz nếu hỗ trợ ProMotion hoặc cấu hình tối đa 120Hz
        self.maximumDeviceHz = isProMotion ? 120 : max(screenMax, 60)
    }

    func start() {
        stop()
        determineDeviceCapabilities()
        currentHz = 0
        minHz = 0
        maxObservedHz = 0
        frameTimeMs = 0
        samples = []
        smoothingBuffer = []
        lastTimestamp = 0
        lastUIUpdateTimestamp = 0

        let link = CADisplayLink(target: self, selector: #selector(handleFrame(_:)))

        // Yêu cầu CADisplayLink mở rộng dải tần số quét từ 10Hz đến tối đa 120Hz
        if #available(iOS 15.0, *) {
            link.preferredFrameRateRange = CAFrameRateRange(
                minimum: 10,
                maximum: 120,
                preferred: 120
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

        // Lọc nhiễu bằng trung bình trượt ngắn
        smoothingBuffer.append(instantHz)
        if smoothingBuffer.count > smoothingWindow {
            smoothingBuffer.removeFirst()
        }
        let averaged = smoothingBuffer.reduce(0, +) / Double(smoothingBuffer.count)

        // Cập nhật min/max tức thì (giới hạn tối đa 120Hz)
        let clampedHz = min(max(averaged, 0), 120.0)
        if clampedHz >= 10 {
            if minHz == 0 {
                minHz = clampedHz
            } else if clampedHz < minHz {
                minHz = clampedHz
            }
        }
        if clampedHz > maxObservedHz {
            maxObservedHz = clampedHz
        }

        // Điều tiết cập nhật UI (Throttling) để giải phóng CPU render cho Main Thread
        let timeSinceLastUIUpdate = link.timestamp - lastUIUpdateTimestamp
        let significantJump = abs(clampedHz - currentHz) > 10

        if timeSinceLastUIUpdate >= uiUpdateInterval || significantJump {
            lastUIUpdateTimestamp = link.timestamp

            self.currentHz = clampedHz
            self.frameTimeMs = clampedHz > 0 ? (1000.0 / clampedHz) : 0

            self.samples.append(clampedHz)
            if self.samples.count > self.maxSampleHistory {
                self.samples.removeFirst()
            }
        }
    }
}
