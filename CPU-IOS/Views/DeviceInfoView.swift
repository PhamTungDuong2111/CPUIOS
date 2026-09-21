import SwiftUI

struct DeviceInfoView: View {
    private let device: DeviceModel
    @ObservedObject private var lang = LanguageManager.shared

    init() {
        let identifier = DeviceIdentifier.hardwareIdentifier()
        self.device = DeviceDatabaseService.shared.lookup(identifier: identifier)
    }

    var body: some View {
        NavigationView {
            List {
                Section(lang.tr("Thiết bị", "Device")) {
                    infoRow(lang.tr("Tên thương mại", "Marketing Name"), device.marketingName)
                    infoRow(lang.tr("Mã định danh model", "Model Identifier"), device.identifier)
                }
                Section(lang.tr("Vi xử lý (Chip)", "Processor (Chip)")) {
                    infoRow(lang.tr("Tên Chip", "Chip"), device.chip)
                    infoRow(lang.tr("Tiến trình", "Process"), device.process)
                    if device.maxClockGHz > 0 {
                        infoRow(lang.tr("Xung nhịp tối đa", "Peak Clock"), String(format: "%.2f GHz", device.maxClockGHz))
                    }
                }
                Section(lang.tr("Màn hình", "Display")) {
                    infoRow(lang.tr("Tần số quét tối đa", "Max Refresh Rate"), "\(device.maxRefreshRateHz) Hz")
                }
                Section {
                    Text(lang.tr(
                        "Mã định danh model lấy qua sysctlbyname(\"hw.machine\") — API POSIX công khai. Tên/chip/tiến trình đối soát từ cơ sở dữ liệu DeviceDatabase.json.",
                        "Model identifier retrieved via sysctlbyname(\"hw.machine\") — public POSIX API. Chip/process details matched from DeviceDatabase.json."
                    ))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle(lang.tr("Thiết Bị", "Device"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        lang.toggleLanguage()
                    }) {
                        HStack(spacing: 4) {
                            Text(lang.currentLanguage.flag)
                            Text(lang.currentLanguage.shortCode)
                                .font(.caption.bold())
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.15))
                        .cornerRadius(8)
                    }
                }
            }
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
