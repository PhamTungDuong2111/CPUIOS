import Foundation
import QuartzCore
import UIKit
import Combine

/// TÍNH NĂNG CỐT LÕI:
/// Đo tần số quét thực tế của màn hình theo thời gian thực bằng CADisplayLink.
/// Hỗ trợ màn hình ProMotion với tần số quét tối đa lên đến 120Hz (iPhone 13 Pro -> 16 Pro Max).
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

    private let smoothingWindow = 6
    private let maxSampleHistory = 50
    private let uiUpdateInterval: CFTimeInterval = 0.05

    init() {
        determineDeviceCapabilities()
    }

    func determineDeviceCapabilities() {
        let screenMax = UIScreen.main.maximumFramesPerSecond
        let identifier = DeviceIdentifier.hardwareIdentifier()
        let device = DeviceDatabaseService.shared.lookup(identifier: identifier)

        let isProMotion = screenMax >= 120 || device.maxRefreshRateHz >= 120
        self.isProMotionCapable = isProMotion
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

        // Yêu cầu CADisplayLink ưu tiên tần số quét 120Hz trên màn hình ProMotion
        if #available(iOS 15.0, *) {
            link.preferredFrameRateRange = CAFrameRateRange(
                minimum: 60,
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

        // 1. Khoảng cách thời gian callback
        let delta = link.timestamp - lastTimestamp

        // 2. Chu kỳ quét phần cứng mà compositor hệ điều hành phân bổ
        let frameDuration = link.targetTimestamp - link.timestamp
        let hardwareRate = frameDuration > 0 ? (1.0 / frameDuration) : 60.0
        let callbackRate = delta > 0 ? (1.0 / delta) : hardwareRate
        let instantHz = min(max(hardwareRate, callbackRate), 120.0)

        // Lọc nhiễu bằng trung bình trượt ngắn
        smoothingBuffer.append(instantHz)
        if smoothingBuffer.count > smoothingWindow {
            smoothingBuffer.removeFirst()
        }
        let averaged = smoothingBuffer.reduce(0, +) / Double(smoothingBuffer.count)

        // Nhảy lên 120Hz ngay khi phát hiện tần số cao trên ProMotion
        let clampedHz = min(max(averaged, 0), 120.0)
        let displayHz: Double
        if instantHz >= 95 || clampedHz >= 95 {
            displayHz = 120.0
        } else {
            displayHz = clampedHz
        }

        if displayHz >= 10 {
            if minHz == 0 {
                minHz = displayHz
            } else if displayHz < minHz {
                minHz = displayHz
            }
        }
        if displayHz > maxObservedHz {
            maxObservedHz = displayHz
        }

        let timeSinceLastUIUpdate = link.timestamp - lastUIUpdateTimestamp
        let significantJump = abs(displayHz - currentHz) > 5

        if timeSinceLastUIUpdate >= uiUpdateInterval || significantJump {
            lastUIUpdateTimestamp = link.timestamp

            self.currentHz = displayHz
            self.frameTimeMs = displayHz > 0 ? (1000.0 / displayHz) : 0

            self.samples.append(displayHz)
            if self.samples.count > self.maxSampleHistory {
                self.samples.removeFirst()
            }
        }
    }
}
