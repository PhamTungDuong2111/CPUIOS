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
        return max(Int(count), 1)
    }

    static var totalMemoryBytes: UInt64 {
        ProcessInfo.processInfo.physicalMemory
    }

    private static let bytesPerGB = 1024.0 * 1024.0 * 1024.0

    /// Đọc RAM đang dùng/free qua Mach host_statistics64 và tính theo đơn vị GiB nhị phân chuẩn (1024^3),
    /// đảm bảo máy 8GB (như iPhone 16 Pro Max) hiển thị chuẩn 8.00 GB chứ không bị lệch thành 8.59 GB.
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
            return MemoryInfo(totalGB: totalBytes / bytesPerGB, usedGB: 0, freeGB: totalBytes / bytesPerGB)
        }

        let active = Double(stats.active_count) * Double(pagesize)
        let wired = Double(stats.wire_count) * Double(pagesize)
        let compressed = Double(stats.compressor_page_count) * Double(pagesize)
        let free = Double(stats.free_count) * Double(pagesize)

        let usedBytes = active + wired + compressed
        return MemoryInfo(
            totalGB: totalBytes / bytesPerGB,
            usedGB: usedBytes / bytesPerGB,
            freeGB: free / bytesPerGB
        )
    }

    // Quản lý mẫu CPU trước đó để tính độ lệch (delta) chính xác
    private static var prevCpuInfo: processor_info_array_t?
    private static var prevNumCpuInfo: mach_msg_type_number_t = 0
    private static let cpuLock = NSLock()

    /// % CPU thời gian thực: tính toán theo độ chênh lệch số tick (delta) giữa 2 lần lấy mẫu liên tiếp.
    /// Nếu không tính delta, hệ thống sẽ chỉ trả về mức trung bình từ khi bật máy đến nay (sai số).
    static func currentCPUUsagePercent() -> Double {
        cpuLock.lock()
        defer { cpuLock.unlock() }

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

        guard result == KERN_SUCCESS, let currentCpuInfo = cpuInfo else {
            return fallbackAppCPUUsagePercent()
        }

        guard let previousCpuInfo = prevCpuInfo else {
            // Lần gọi đầu tiên: lưu lại mốc bắt đầu
            prevCpuInfo = currentCpuInfo
            prevNumCpuInfo = numCpuInfo
            return fallbackAppCPUUsagePercent()
        }

        var totalUsage: Double = 0
        for i in 0..<Int(numCPUs) {
            let offset = Int(CPU_STATE_MAX) * i
            let user = Double(currentCpuInfo[offset + Int(CPU_STATE_USER)] - previousCpuInfo[offset + Int(CPU_STATE_USER)])
            let sys = Double(currentCpuInfo[offset + Int(CPU_STATE_SYSTEM)] - previousCpuInfo[offset + Int(CPU_STATE_SYSTEM)])
            let nice = Double(currentCpuInfo[offset + Int(CPU_STATE_NICE)] - previousCpuInfo[offset + Int(CPU_STATE_NICE)])
            let idle = Double(currentCpuInfo[offset + Int(CPU_STATE_IDLE)] - previousCpuInfo[offset + Int(CPU_STATE_IDLE)])

            let deltaTotal = user + sys + nice + idle
            if deltaTotal > 0 {
                totalUsage += (user + sys + nice) / deltaTotal
            }
        }

        // Giải phóng bộ nhớ của mốc trước đó
        let deallocSize = vm_size_t(prevNumCpuInfo) * vm_size_t(MemoryLayout<integer_t>.size)
        vm_deallocate(mach_task_self_, vm_address_t(bitPattern: previousCpuInfo), deallocSize)

        // Lưu lại mốc hiện tại cho lần tính kế tiếp
        prevCpuInfo = currentCpuInfo
        prevNumCpuInfo = numCpuInfo

        let percent = (totalUsage / Double(max(numCPUs, 1))) * 100.0
        return min(max(percent, 0), 100)
    }

    /// Cơ chế dự phòng khi Mach host API bị sandbox iOS giới hạn
    private static func fallbackAppCPUUsagePercent() -> Double {
        var threadList: thread_act_array_t?
        var threadCount: mach_msg_type_number_t = 0
        guard task_threads(mach_task_self_, &threadList, &threadCount) == KERN_SUCCESS, let threads = threadList else {
            return 0
        }
        defer {
            let size = vm_size_t(threadCount) * vm_size_t(MemoryLayout<thread_act_t>.size)
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: threads), size)
        }

        var totalUsage: Double = 0
        for i in 0..<Int(threadCount) {
            var threadInfo = thread_basic_info()
            var count = mach_msg_type_number_t(THREAD_INFO_MAX)
            let kr = withUnsafeMutablePointer(to: &threadInfo) { ptr in
                ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                    thread_info(threads[i], thread_flavor_t(THREAD_BASIC_INFO), $0, &count)
                }
            }
            if kr == KERN_SUCCESS && (threadInfo.flags & TH_FLAGS_IDLE) == 0 {
                totalUsage += Double(threadInfo.cpu_usage) / Double(TH_USAGE_SCALE) * 100.0
            }
        }
        return min(max(totalUsage, 0), 100)
    }
}
