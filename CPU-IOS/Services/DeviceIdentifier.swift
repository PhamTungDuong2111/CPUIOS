import Foundation

enum DeviceIdentifier {
    /// Trả về mã định danh phần cứng kiểu "iPhone16,2".
    /// Đây là API POSIX công khai (sysctlbyname) — hợp lệ với App Review,
    /// KHÔNG phải private API.
    static func hardwareIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { partial, element in
            guard let value = element.value as? Int8, value != 0 else { return partial }
            return partial + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}
