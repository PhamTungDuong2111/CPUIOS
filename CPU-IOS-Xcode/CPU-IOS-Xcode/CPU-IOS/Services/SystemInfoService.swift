import Foundation

struct MemoryInfo {
    let totalGB: Double
    let usedGB: Double
    let freeGB: Double
}

enum SystemInfoService {

    static var coreCount: Int {
        var size = MemoryLayout<Int32>.size
        var count: Int32 = 0
        sysctlbyname("hw.ncpu", &count, &size, nil, 0)
        return Int(count)
    }

    static var totalMemoryBytes: UInt64 {
        ProcessInfo.processInfo.physicalMemory
    }

    /// Đọc RAM đang dùng/free qua Mach host_statistics64 — API Darwin công khai,
    /// dùng cho mọi công cụ giám sát bộ nhớ trên macOS/iOS (kể cả Activity Monitor).
    static func currentMemoryInfo() -> MemoryInfo {
        var pagesize: vm_size_t = 0
        host_page_size(mach_host_self(), &pagesize)

        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)

        let result = withUnsafeMutablePointer(to: &stats) { pointer -> kern_return_t in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }

        let totalBytes = Double(totalMemoryBytes)
        guard result == KERN_SUCCESS else {
            return MemoryInfo(totalGB: totalBytes / 1e9, usedGB: 0, freeGB: totalBytes / 1e9)
        }

        let active = Double(stats.active_count) * Double(pagesize)
        let wired = Double(stats.wire_count) * Double(pagesize)
        let compressed = Double(stats.compressor_page_count) * Double(pagesize)
        let free = Double(stats.free_count) * Double(pagesize)

        let usedBytes = active + wired + compressed
        return MemoryInfo(
            totalGB: totalBytes / 1e9,
            usedGB: usedBytes / 1e9,
            freeGB: free / 1e9
        )
    }

    /// % CPU tổng hệ thống đang dùng, qua host_processor_info (Mach API).
    static func currentCPUUsagePercent() -> Double {
        var cpuInfo: processor_info_array_t!
        var numCpuInfo: mach_msg_type_number_t = 0
        var numCPUs: natural_t = 0

        let result = host_processor_info(
            mach_host_self(),
            PROCESSOR_CPU_LOAD_INFO,
            &numCPUs,
            &cpuInfo,
            &numCpuInfo
        )
        guard result == KERN_SUCCESS else { return 0 }

        var totalUsage: Double = 0
        for i in 0..<Int(numCPUs) {
            let offset = Int(CPU_STATE_MAX) * i
            let user = Double(cpuInfo[offset + Int(CPU_STATE_USER)])
            let sys = Double(cpuInfo[offset + Int(CPU_STATE_SYSTEM)])
            let nice = Double(cpuInfo[offset + Int(CPU_STATE_NICE)])
            let idle = Double(cpuInfo[offset + Int(CPU_STATE_IDLE)])
            let total = user + sys + nice + idle
            if total > 0 {
                totalUsage += (user + sys + nice) / total
            }
        }

        let deallocSize = vm_size_t(numCpuInfo) * vm_size_t(MemoryLayout<integer_t>.size)
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), deallocSize)

        return (totalUsage / Double(numCPUs)) * 100
    }
}
