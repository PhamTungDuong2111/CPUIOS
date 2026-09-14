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
    @Published private(set) var maximumDeviceHz: Int = UIScreen.main.maximumFramesPerSecond
    @Published private(set) var isProMotionCapable: Bool = UIScreen.main.maximumFramesPerSecond > 60
    @Published private(set) var samples: [Double] = []   // để vẽ mini biểu đồ

    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var smoothingBuffer: [Double] = []

    private let smoothingWindow = 12
    private let maxSampleHistory = 60

    func start() {
        stop()
        currentHz = 0
        minHz = 0
        maxObservedHz = 0
        samples = []
        smoothingBuffer = []
        lastTimestamp = 0

        let link = CADisplayLink(target: self, selector: #selector(handleFrame(_:)))

        // Không giới hạn khoảng preferred range để CADisplayLink được phép bám
        // sát tần số quét thật của phần cứng (kể cả khi hệ thống đang hạ Hz).
        if #available(iOS 15.0, *) {
            let maxFPS = Float(UIScreen.main.maximumFramesPerSecond)
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

        // Lọc nhiễu bằng trung bình trượt — số hiển thị mượt hơn nhưng vẫn
        // phản ứng đủ nhanh khi máy đổi Hz.
        smoothingBuffer.append(instantHz)
        if smoothingBuffer.count > smoothingWindow {
            smoothingBuffer.removeFirst()
        }
        let averaged = smoothingBuffer.reduce(0, +) / Double(smoothingBuffer.count)

        currentHz = averaged
        minHz = minHz == 0 ? averaged : min(minHz, averaged)
        maxObservedHz = max(maxObservedHz, averaged)

        samples.append(averaged)
        if samples.count > maxSampleHistory {
            samples.removeFirst()
        }
    }
}
