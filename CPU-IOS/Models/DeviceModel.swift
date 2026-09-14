import Foundation

/// Một dòng trong bảng tra "hw.machine" -> thông tin thương mại của thiết bị.
/// Apple không cấp API trả thẳng "Apple A17 Pro" hay "3nm" — mọi app kiểu
/// CPU-X đều phải tự duy trì bảng tra này.
struct DeviceModel: Codable, Identifiable {
    var id: String { identifier }
    let identifier: String      // vd "iPhone16,2"
    let marketingName: String   // vd "iPhone 15 Pro Max"
    let chip: String            // vd "Apple A17 Pro"
    let process: String         // vd "TSMC 3nm (N3B)"
    let maxClockGHz: Double     // vd 3.78
    let maxRefreshRateHz: Int   // vd 120 (ProMotion) hoặc 60
}
