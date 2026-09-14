import SwiftUI

struct FloatingMonitorHUDView: View {
    @ObservedObject var data = FloatingMonitorData.shared

    var body: some View {
        ZStack {
            // Nền kính mờ (Frosted glass HUD)
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(UIColor.secondarySystemBackground).opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 4) {
                // Hàng 1: Đồng hồ đếm thời gian (chừa lề cho nút X và nút phóng to hệ thống của PiP)
                HStack(spacing: 5) {
                    Image(systemName: "stopwatch.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.green)
                    Text(data.uptimeString)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)
                    Spacer()
                }
                .padding(.horizontal, 36) // Để không bị nút X (bên trái) và nút mở rộng (bên phải) che
                .padding(.top, 5)

                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 0.5)
                    .padding(.horizontal, 8)

                // Hàng 2: 2 cột thông số
                HStack(alignment: .top, spacing: 6) {
                    // Cột trái: Tốc độ mạng & Xung nhịp
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 3) {
                            Image(systemName: "wifi")
                                .font(.system(size: 9))
                                .foregroundColor(.blue)
                            Text("↑: \(data.uploadSpeed)")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .lineLimit(1)
                        }

                        HStack(spacing: 3) {
                            Image(systemName: "wifi")
                                .font(.system(size: 9))
                                .foregroundColor(.green)
                            Text("↓: \(data.downloadSpeed)")
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .lineLimit(1)
                        }

                        HStack(spacing: 2) {
                            Text("Freq.:")
                                .font(.system(size: 10, weight: .regular))
                                .foregroundColor(.secondary)
                            Text("\(data.cpuFreqMHz)MHz")
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                .foregroundColor(.primary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Cột phải: CPU %, FPS, RAM %
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 2) {
                            Text("CPU:")
                                .font(.system(size: 10, weight: .regular))
                                .foregroundColor(.secondary)
                            Text("\(data.cpuPercent)%")
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        }

                        HStack(spacing: 2) {
                            Text("FPS:")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                            Text("\(data.fps)")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundColor(data.fps >= 100 ? .green : (data.fps >= 60 ? .yellow : .orange))
                        }

                        HStack(spacing: 2) {
                            Text("RAM:")
                                .font(.system(size: 10, weight: .regular))
                                .foregroundColor(.secondary)
                            Text("\(data.ramPercent)%")
                                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 6)
            }
        }
        .frame(width: 220, height: 110)
    }
}

#Preview {
    FloatingMonitorHUDView()
        .preferredColorScheme(.dark)
}
