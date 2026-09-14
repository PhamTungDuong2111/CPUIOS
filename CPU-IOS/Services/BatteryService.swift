import UIKit

enum BatteryService {
    static func enableMonitoring() {
        UIDevice.current.isBatteryMonitoringEnabled = true
    }

    static var level: Float {
        UIDevice.current.batteryLevel
    }

    static var state: String {
        switch UIDevice.current.batteryState {
        case .charging: return "Đang sạc"
        case .full: return "Đầy pin"
        case .unplugged: return "Dùng pin"
        case .unknown: return "Không rõ"
        @unknown default: return "Không rõ"
        }
    }
}
