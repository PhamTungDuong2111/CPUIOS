import SwiftUI

/// Giao diện HUD hiển thị trong cửa sổ nổi PiP (Picture-in-Picture)
/// Tích hợp tính năng QUÉT TẦN SỐ HZ MÀN HÌNH (Hz Scanner) nổi bật cùng CPU, RAM, Mạng
struct FloatingMonitorHUDView: View {
    @ObservedObject var data = FloatingMonitorData.shared
    @ObservedObject private var lang = LanguageManager.shared

    var body: some View {
        ZStack {
            // Nền kính mờ công nghệ cao (Frosted glass HUD) với viền phát sáng theo tần số Hz
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(UIColor.secondarySystemBackground).opacity(0.90))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            data.hz >= 100
                                ? Color.green.opacity(0.5)
                                : (data.hz >= 60 ? Color.yellow.opacity(0.3) : Color.white.opacity(0.2)),
                            lineWidth: 1.2
                        )
                )

            VStack(alignment: .leading, spacing: 3) {
                // Hàng 1: Đồng hồ đếm thời gian & Huy hiệu QUÉT TẦN SỐ HZ
                HStack(spacing: 4) {
                    Image(systemName: "stopwatch.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.green)
                    Text(data.uptimeString)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)

                    Spacer()

                    // HUY HIỆU QUÉT TẦN SỐ HZ (Hz Scanner Badge)
                    HStack(spacing: 3) {
                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(hzColor(data.hz))

                        Text("\(data.hz) Hz")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundColor(hzColor(data.hz))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(hzColor(data.hz).opacity(0.18))
                    .cornerRadius(6)
                }
                .padding(.horizontal, 34) // Chừa khoảng cách an toàn cho nút X và nút mở rộng hệ thống của PiP
                .padding(.top, 4)

                // Đường phân cách mờ
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 0.5)
                    .padding(.horizontal, 6)

                // Hàng 2: 2 cột thông số chi tiết
                HStack(alignment: .top, spacing: 6) {
                    // Cột trái: Tốc độ mạng & Xung nhịp
                    VStack(alignment: .leading, spacing: 2.5) {
                        HStack(spacing: 3) {
                            Image(systemName: "wifi")
                                .font(.system(size: 8))
                                .foregroundColor(.blue)
                            Text("↑: \(data.uploadSpeed)")
                                .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                                .lineLimit(1)
                        }

                        HStack(spacing: 3) {
                            Image(systemName: "wifi")
                                .font(.system(size: 8))
                                .foregroundColor(.green)
                            Text("↓: \(data.downloadSpeed)")
                                .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                                .lineLimit(1)
                        }

                        HStack(spacing: 2) {
                            Text("Freq:")
                                .font(.system(size: 9.5, weight: .regular))
                                .foregroundColor(.secondary)
                            Text("\(data.cpuFreqMHz)MHz")
                                .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                                .foregroundColor(.primary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Cột phải: CPU %, QUÉT HZ MÀN HÌNH, RAM %
                    VStack(alignment: .leading, spacing: 2.5) {
                        HStack(spacing: 2) {
                            Text("CPU:")
                                .font(.system(size: 9.5, weight: .regular))
                                .foregroundColor(.secondary)
                            Text("\(data.cpuPercent)%")
                                .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                        }

                        // QUÉT TẦN SỐ HZ CHÍNH XÁC (Hz Scanner readout)
                        HStack(spacing: 2) {
                            Text("Hz:")
                                .font(.system(size: 9.5, weight: .bold))
                                .foregroundColor(.secondary)
                            Text("\(data.hz)")
                                .font(.system(size: 13, weight: .black, design: .rounded))
                                .foregroundColor(hzColor(data.hz))
                            Text("Hz")
                                .font(.system(size: 8.5, weight: .bold))
                                .foregroundColor(hzColor(data.hz).opacity(0.8))
                        }

                        HStack(spacing: 2) {
                            Text("RAM:")
                                .font(.system(size: 9.5, weight: .regular))
                                .foregroundColor(.secondary)
                            Text("\(data.ramPercent)%")
                                .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 10)

                // Hàng 3: Thanh trạng thái quét màn hình (Live Hz Scanline Indicator)
                HStack(spacing: 4) {
                    Circle()
                        .fill(hzColor(data.hz))
                        .frame(width: 4, height: 4)
                    Text(lang.tr("Đang quét tần số Hz màn hình...", "Scanning display Hz..."))
                        .font(.system(size: 7.5, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(data.hz >= 100 ? "120Hz PRO" : (data.hz >= 60 ? "60Hz STD" : "\(data.hz)Hz"))
                        .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                        .foregroundColor(hzColor(data.hz))
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 4)
            }
        }
        .frame(width: 220, height: 110)
    }

    private func hzColor(_ hz: Int) -> Color {
        if hz >= 100 { return .green }
        if hz >= 60 { return .yellow }
        return .orange
    }
}

#Preview {
    FloatingMonitorHUDView()
        .preferredColorScheme(.dark)
}
