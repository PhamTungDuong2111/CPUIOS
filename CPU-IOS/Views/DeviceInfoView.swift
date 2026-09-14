import SwiftUI

struct DeviceInfoView: View {
    private let device: DeviceModel

    init() {
        let identifier = DeviceIdentifier.hardwareIdentifier()
        self.device = DeviceDatabaseService.shared.lookup(identifier: identifier)
    }

    var body: some View {
        NavigationView {
            List {
                Section("Thiết bị") {
                    infoRow("Tên thương mại", device.marketingName)
                    infoRow("Model identifier", device.identifier)
                }
                Section("Chip") {
                    infoRow("Chip", device.chip)
                    infoRow("Tiến trình", device.process)
                    if device.maxClockGHz > 0 {
                        infoRow("Xung nhịp tối đa", String(format: "%.2f GHz", device.maxClockGHz))
                    }
                }
                Section("Màn hình") {
                    infoRow("Tần số quét tối đa", "\(device.maxRefreshRateHz) Hz")
                }
                Section {
                    Text("Model identifier lấy qua sysctlbyname(\"hw.machine\") — API POSIX công khai. Tên/chip/tiến trình lấy từ bảng tra nội bộ DeviceDatabase.json vì Apple không cung cấp API trả trực tiếp các thông tin này.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Device")
        }
    }

    private func infoRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value).foregroundColor(.secondary)
        }
    }
}

#Preview {
    DeviceInfoView()
}
