import Foundation
import UIKit
import AVKit
import AVFoundation
import Combine
import SwiftUI

// MARK: - Live Data for Floating Monitor HUD
final class FloatingMonitorData: ObservableObject {
    static let shared = FloatingMonitorData()

    @Published var fps: Int = 60
    @Published var cpuPercent: Int = 0
    @Published var cpuFreqMHz: Int = 4046
    @Published var uploadSpeed: String = "0.0 B/s"
    @Published var downloadSpeed: String = "0.0 B/s"
    @Published var ramPercent: Int = 0
    @Published var uptimeString: String = "0:00:00.0"

    private var metricsTimer: Timer?
    private var displayLink: CADisplayLink?
    private var sessionStartTime: Date = Date()
    private var lastDisplayTimestamp: CFTimeInterval = 0
    private var fpsSmoothingBuffer: [Double] = []

    private init() {
        refreshHardwareInfo()
    }

    func refreshHardwareInfo() {
        let identifier = DeviceIdentifier.hardwareIdentifier()
        let device = DeviceDatabaseService.shared.lookup(identifier: identifier)
        if device.identifier.hasPrefix("iPhone18,") {
            self.cpuFreqMHz = 4250
        } else if device.identifier == "iPhone17,1" || device.identifier == "iPhone17,2" {
            self.cpuFreqMHz = 4046
        } else if device.maxClockGHz > 0 {
            self.cpuFreqMHz = Int(round(device.maxClockGHz * 1000))
        } else {
            self.cpuFreqMHz = 4046
        }
    }

    func start() {
        stop()
        refreshHardwareInfo()
        sessionStartTime = Date()
        lastDisplayTimestamp = 0
        fpsSmoothingBuffer = []

        // CADisplayLink đo FPS mượt theo tần số quét thật của màn hình (hỗ trợ 10 - 120Hz)
        let link = CADisplayLink(target: self, selector: #selector(handleDisplayFrame(_:)))
        if #available(iOS 15.0, *) {
            let maxHz = Float(max(UIScreen.main.maximumFramesPerSecond, 120))
            link.preferredFrameRateRange = CAFrameRateRange(
                minimum: 10,
                maximum: maxHz,
                preferred: maxHz
            )
        }
        link.add(to: .main, forMode: .common)
        self.displayLink = link

        // Timer cập nhật CPU, RAM, Network, Uptime mỗi 0.5s
        metricsTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.updateMetrics()
        }
        updateMetrics()
    }

    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        metricsTimer?.invalidate()
        metricsTimer = nil
    }

    @objc private func handleDisplayFrame(_ link: CADisplayLink) {
        defer { lastDisplayTimestamp = link.timestamp }
        guard lastDisplayTimestamp != 0 else { return }

        // Tính FPS từ khoảng cách giữa 2 khung hình liên tiếp
        let delta = link.timestamp - lastDisplayTimestamp
        guard delta > 0 else { return }

        let instantFPS = 1.0 / delta
        fpsSmoothingBuffer.append(instantFPS)
        if fpsSmoothingBuffer.count > 6 {
            fpsSmoothingBuffer.removeFirst()
        }
        let avg = fpsSmoothingBuffer.reduce(0, +) / Double(fpsSmoothingBuffer.count)

        // Làm tròn đến các mức ProMotion chuẩn: 120, 90, 80, 60, 48, 30
        let roundedHz: Int
        if avg >= 105 {
            roundedHz = 120
        } else if avg >= 85 {
            roundedHz = 90
        } else if avg >= 70 {
            roundedHz = 80
        } else if avg >= 50 {
            roundedHz = 60
        } else {
            roundedHz = max(Int(round(avg)), 30)
        }

        if self.fps != roundedHz {
            self.fps = roundedHz
        }
    }

    private func updateMetrics() {
        // Uptime (hours:minutes:seconds.tenths)
        let elapsed = Date().timeIntervalSince(sessionStartTime)
        let totalSeconds = Int(elapsed)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        let tenths = Int((elapsed - Double(totalSeconds)) * 10)
        uptimeString = String(format: "%d:%02d:%02d.%d", hours, minutes, seconds, tenths)

        // CPU %
        let cpu = SystemInfoService.currentCPUUsagePercent()
        self.cpuPercent = Int(round(min(max(cpu, 0), 100)))

        // RAM %
        let mem = SystemInfoService.currentMemoryInfo()
        if mem.totalGB > 0 {
            let usedPercent = (mem.usedGB / mem.totalGB) * 100
            self.ramPercent = Int(round(usedPercent))
        }

        // Network Speed
        let speed = NetworkSpeedService.shared.currentSpeed()
        self.uploadSpeed = speed.uploadFormatted
        self.downloadSpeed = speed.downloadFormatted
    }
}

// MARK: - Silent Audio Player to prevent iOS from suspending PiP in background
final class SilentAudioPlayer {
    static let shared = SilentAudioPlayer()
    private var audioPlayer: AVAudioPlayer?

    func start() {
        guard audioPlayer == nil else { return }
        let silentData = createSilentWAVData()
        if let player = try? AVAudioPlayer(data: silentData) {
            player.numberOfLoops = -1
            player.volume = 0.001
            player.prepareToPlay()
            player.play()
            self.audioPlayer = player
        }
    }

    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
    }

    private func createSilentWAVData() -> Data {
        var data = Data()
        let sampleRate: UInt32 = 44100
        let numSamples: UInt32 = 44100
        let subChunk2Size = numSamples * 2
        let chunkSize = 36 + subChunk2Size

        data.append(contentsOf: "RIFF".utf8)
        data.append(withUnsafeBytes(of: chunkSize.littleEndian) { Data($0) })
        data.append(contentsOf: "WAVEfmt ".utf8)
        let subChunk1Size: UInt32 = 16
        data.append(withUnsafeBytes(of: subChunk1Size.littleEndian) { Data($0) })
        let audioFormat: UInt16 = 1
        data.append(withUnsafeBytes(of: audioFormat.littleEndian) { Data($0) })
        let numChannels: UInt16 = 1
        data.append(withUnsafeBytes(of: numChannels.littleEndian) { Data($0) })
        data.append(withUnsafeBytes(of: sampleRate.littleEndian) { Data($0) })
        let byteRate = sampleRate * 2
        data.append(withUnsafeBytes(of: byteRate.littleEndian) { Data($0) })
        let blockAlign: UInt16 = 2
        data.append(withUnsafeBytes(of: blockAlign.littleEndian) { Data($0) })
        let bitsPerSample: UInt16 = 16
        data.append(withUnsafeBytes(of: bitsPerSample.littleEndian) { Data($0) })
        data.append(contentsOf: "data".utf8)
        data.append(withUnsafeBytes(of: subChunk2Size.littleEndian) { Data($0) })
        data.append(Data(repeating: 0, count: Int(subChunk2Size)))
        return data
    }
}

// MARK: - PiP Manager with AVPictureInPictureVideoCallViewController
final class PiPFloatingMonitorManager: NSObject, ObservableObject, AVPictureInPictureControllerDelegate {
    static let shared = PiPFloatingMonitorManager()

    @Published var isPiPActive: Bool = false
    @Published var isSupported: Bool = AVPictureInPictureController.isPictureInPictureSupported()
    @Published var statusMessage: String = ""

    private var pipController: AVPictureInPictureController?
    private var callVC: AVPictureInPictureVideoCallViewController?
    private var hostingController: UIHostingController<FloatingMonitorHUDView>?
    private weak var sourceView: UIView?

    override private init() {
        super.init()
    }

    func setup(sourceView: UIView) {
        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            statusMessage = "Thiết bị này không hỗ trợ Picture in Picture."
            return
        }
        self.sourceView = sourceView

        if #available(iOS 15.0, *) {
            let callVC = AVPictureInPictureVideoCallViewController()
            callVC.preferredContentSize = CGSize(width: 220, height: 110)

            let hudView = FloatingMonitorHUDView()
            let hosting = UIHostingController(rootView: hudView)
            hosting.view.backgroundColor = .clear

            callVC.addChild(hosting)
            callVC.view.addSubview(hosting.view)
            hosting.didMove(toParent: callVC)

            hosting.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                hosting.view.topAnchor.constraint(equalTo: callVC.view.topAnchor),
                hosting.view.bottomAnchor.constraint(equalTo: callVC.view.bottomAnchor),
                hosting.view.leadingAnchor.constraint(equalTo: callVC.view.leadingAnchor),
                hosting.view.trailingAnchor.constraint(equalTo: callVC.view.trailingAnchor)
            ])

            self.callVC = callVC
            self.hostingController = hosting

            let contentSource = AVPictureInPictureController.ContentSource(
                activeVideoCallSourceView: sourceView,
                contentViewController: callVC
            )

            let pip = AVPictureInPictureController(contentSource: contentSource)
            pip.delegate = self
            // Chỉ kích hoạt tự động inline khi người dùng đã chủ động bật PiP
            pip.canStartPictureInPictureAutomaticallyFromInline = false
            self.pipController = pip
            statusMessage = "Đã sẵn sàng mở cửa sổ nổi PiP."
        }
    }

    func togglePiP() {
        if isPiPActive {
            stopPiP()
        } else {
            startPiP()
        }
    }

    func startPiP() {
        guard let pip = pipController else {
            statusMessage = "Chưa khởi tạo được PiP controller."
            return
        }

        configureAudioSession()
        SilentAudioPlayer.shared.start()
        FloatingMonitorData.shared.start()

        if #available(iOS 15.0, *) {
            pip.canStartPictureInPictureAutomaticallyFromInline = true
        }
        pip.startPictureInPicture()
        statusMessage = "Đang kích hoạt PiP..."
    }

    func stopPiP() {
        if #available(iOS 15.0, *) {
            pipController?.canStartPictureInPictureAutomaticallyFromInline = false
        }
        pipController?.stopPictureInPicture()
        SilentAudioPlayer.shared.stop()
        FloatingMonitorData.shared.stop()
        isPiPActive = false
        statusMessage = "Đã tắt cửa sổ nổi."
    }

    private func configureAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("AudioSession configuration error: \(error)")
        }
    }

    // MARK: - AVPictureInPictureControllerDelegate
    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        DispatchQueue.main.async {
            self.isPiPActive = true
            self.statusMessage = "Cửa sổ PiP đang nổi trên màn hình!"
        }
    }

    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        DispatchQueue.main.async {
            self.isPiPActive = false
            SilentAudioPlayer.shared.stop()
            self.statusMessage = "Đã đóng cửa sổ nổi PiP."
        }
    }

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: Error
    ) {
        DispatchQueue.main.async {
            self.isPiPActive = false
            SilentAudioPlayer.shared.stop()
            self.statusMessage = "Không thể mở PiP: \(error.localizedDescription)"
        }
    }
}

// MARK: - SwiftUI Source View Bridge
struct PiPSourceViewRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 220, height: 110))
        view.backgroundColor = .clear
        DispatchQueue.main.async {
            PiPFloatingMonitorManager.shared.setup(sourceView: view)
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
