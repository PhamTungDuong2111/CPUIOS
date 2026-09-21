import SwiftUI
import Combine

final class SystemMetricsTimer: ObservableObject {
    @Published var cpuUsage: Double = 0
    @Published var memory: MemoryInfo = SystemInfoService.currentMemoryInfo()
    private var timer: AnyCancellable?

    func start() {
        refresh()
        timer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.refresh() }
    }

    func stop() {
        timer?.cancel()
    }

    private func refresh() {
        cpuUsage = SystemInfoService.currentCPUUsagePercent()
        memory = SystemInfoService.currentMemoryInfo()
    }
}

struct CPUMemoryView: View {
    @StateObject private var metrics = SystemMetricsTimer()
    @ObservedObject private var lang = LanguageManager.shared
    private let coreCount = SystemInfoService.coreCount

    var body: some View {
        NavigationView {
            List {
                Section(lang.tr("Vi Xử Lý (CPU)", "CPU Processor")) {
                    HStack {
                        Text(lang.tr("Số nhân", "Cores"))
                        Spacer()
                        Text("\(coreCount)").foregroundColor(.secondary)
                    }
                    HStack {
                        Text(lang.tr("Mức sử dụng", "Usage"))
                        Spacer()
                        Text("\(metrics.cpuUsage, specifier: "%.1f")%").foregroundColor(.secondary)
                    }
                    ProgressView(value: min(metrics.cpuUsage, 100), total: 100)
                        .tint(.green)
                }
                Section(lang.tr("Bộ Nhớ RAM", "RAM Memory")) {
                    HStack {
                        Text(lang.tr("Tổng dung lượng", "Total"))
                        Spacer()
                        Text(String(format: "%.2f GB", metrics.memory.totalGB)).foregroundColor(.secondary)
                    }
                    HStack {
                        Text(lang.tr("Đang sử dụng", "Used"))
                        Spacer()
                        Text(String(format: "%.2f GB", metrics.memory.usedGB)).foregroundColor(.secondary)
                    }
                    HStack {
                        Text(lang.tr("Còn trống", "Free"))
                        Spacer()
                        Text(String(format: "%.2f GB", metrics.memory.freeGB)).foregroundColor(.secondary)
                    }
                    ProgressView(value: metrics.memory.usedGB, total: max(metrics.memory.totalGB, 1))
                        .tint(.blue)
                }
            }
            .navigationTitle(lang.tr("CPU / RAM", "CPU / RAM"))
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
            .onAppear { metrics.start() }
            .onDisappear { metrics.stop() }
        }
    }
}

#Preview {
    CPUMemoryView()
}
