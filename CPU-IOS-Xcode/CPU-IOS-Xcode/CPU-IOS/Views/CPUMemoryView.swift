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
    private let coreCount = SystemInfoService.coreCount

    var body: some View {
        NavigationView {
            List {
                Section("CPU") {
                    HStack {
                        Text("Số nhân")
                        Spacer()
                        Text("\(coreCount)").foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Mức sử dụng")
                        Spacer()
                        Text("\(metrics.cpuUsage, specifier: "%.1f")%").foregroundColor(.secondary)
                    }
                    ProgressView(value: min(metrics.cpuUsage, 100), total: 100)
                        .tint(.green)
                }
                Section("RAM") {
                    HStack {
                        Text("Tổng")
                        Spacer()
                        Text(String(format: "%.2f GB", metrics.memory.totalGB)).foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Đang dùng")
                        Spacer()
                        Text(String(format: "%.2f GB", metrics.memory.usedGB)).foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Còn trống")
                        Spacer()
                        Text(String(format: "%.2f GB", metrics.memory.freeGB)).foregroundColor(.secondary)
                    }
                    ProgressView(value: metrics.memory.usedGB, total: max(metrics.memory.totalGB, 1))
                        .tint(.blue)
                }
            }
            .navigationTitle("CPU / RAM")
            .onAppear { metrics.start() }
            .onDisappear { metrics.stop() }
        }
    }
}

#Preview {
    CPUMemoryView()
}
