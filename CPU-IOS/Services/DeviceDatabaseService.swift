import Foundation

final class DeviceDatabaseService {
    static let shared = DeviceDatabaseService()

    private let devices: [DeviceModel]

    private init() {
        guard
            let url = Bundle.main.url(forResource: "DeviceDatabase", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let decoded = try? JSONDecoder().decode([DeviceModel].self, from: data)
        else {
            self.devices = []
            return
        }
        self.devices = decoded
    }

    /// Tra cứu theo hw.machine. Nếu không có trong bảng (máy quá mới), trả về
    /// một entry "Unknown Device" thay vì crash — đây là tình huống thật sự sẽ
    /// xảy ra mỗi khi Apple ra máy mới, cần cơ chế cập nhật từ xa để xử lý dứt điểm.
    func lookup(identifier: String) -> DeviceModel {
        devices.first(where: { $0.identifier == identifier })
            ?? DeviceModel(
                identifier: identifier,
                marketingName: "Thiết bị chưa xác định (\(identifier))",
                chip: "Không rõ — cần cập nhật database",
                process: "—",
                maxClockGHz: 0,
                maxRefreshRateHz: Int(UIScreenMaxRefreshRate.value)
            )
    }
}

import UIKit
enum UIScreenMaxRefreshRate {
    static var value: Int { UIScreen.main.maximumFramesPerSecond }
}
