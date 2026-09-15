import Foundation
#if canImport(Darwin)
import Darwin
#endif

struct NetworkSpeedData {
    let uploadBytesPerSec: Double
    let downloadBytesPerSec: Double

    var uploadFormatted: String {
        formatSpeed(uploadBytesPerSec)
    }

    var downloadFormatted: String {
        formatSpeed(downloadBytesPerSec)
    }

    private func formatSpeed(_ bytesPerSec: Double) -> String {
        if bytesPerSec >= 1_048_576 {
            return String(format: "%.1f MB/s", bytesPerSec / 1_048_576)
        } else if bytesPerSec >= 1024 {
            return String(format: "%.1f KB/s", bytesPerSec / 1024)
        } else {
            return String(format: "%.0f B/s", max(bytesPerSec, 0))
        }
    }
}

final class NetworkSpeedService {
    static let shared = NetworkSpeedService()

    private var lastRxBytes: UInt64 = 0
    private var lastTxBytes: UInt64 = 0
    private var lastTimestamp: Date?

    private init() {
        let (rx, tx) = fetchInterfaceBytes()
        self.lastRxBytes = rx
        self.lastTxBytes = tx
        self.lastTimestamp = Date()
    }

    func currentSpeed() -> NetworkSpeedData {
        let now = Date()
        let (rx, tx) = fetchInterfaceBytes()

        guard let prevTime = lastTimestamp else {
            lastRxBytes = rx
            lastTxBytes = tx
            lastTimestamp = now
            return NetworkSpeedData(uploadBytesPerSec: 0, downloadBytesPerSec: 0)
        }

        let deltaSeconds = now.timeIntervalSince(prevTime)
        guard deltaSeconds > 0 else {
            return NetworkSpeedData(uploadBytesPerSec: 0, downloadBytesPerSec: 0)
        }

        let deltaRx = rx >= lastRxBytes ? rx - lastRxBytes : 0
        let deltaTx = tx >= lastTxBytes ? tx - lastTxBytes : 0

        lastRxBytes = rx
        lastTxBytes = tx
        lastTimestamp = now

        let rxSpeed = Double(deltaRx) / deltaSeconds
        let txSpeed = Double(deltaTx) / deltaSeconds

        return NetworkSpeedData(
            uploadBytesPerSec: txSpeed,
            downloadBytesPerSec: rxSpeed
        )
    }

    private func fetchInterfaceBytes() -> (rx: UInt64, tx: UInt64) {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else {
            return (0, 0)
        }
        defer { freeifaddrs(ifaddr) }

        var totalRx: UInt64 = 0
        var totalTx: UInt64 = 0

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            guard let addr = ptr.pointee.ifa_addr, addr.pointee.sa_family == UInt8(AF_LINK) else {
                continue
            }
            let name = String(cString: ptr.pointee.ifa_name)
            // en0 = Wi-Fi, pdp_ip0/1/2 = Cellular
            if name.hasPrefix("en") || name.hasPrefix("pdp_ip") {
                if let data = ptr.pointee.ifa_data {
                    let ifData = data.assumingMemoryBound(to: if_data.self).pointee
                    totalRx += UInt64(ifData.ifi_ibytes)
                    totalTx += UInt64(ifData.ifi_obytes)
                }
            }
        }
        return (totalRx, totalTx)
    }
}
