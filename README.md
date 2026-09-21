# CPU-IOS (App Giám Sát Phần Cứng & Đo Tần Số Quét Màn Hình 120Hz cho iOS)

Ứng dụng iOS Native hoàn chỉnh bằng **SwiftUI** theo phong cách **CPU-X**, tích hợp tính năng cốt lõi: **đo tần số quét màn hình theo thời gian thực (lên đến 120Hz ProMotion)** và **nút chuyển đổi ngôn ngữ song ngữ Tiếng Việt / Tiếng Anh**.

---

## 🌟 Tính năng nổi bật

| Tính năng | Mô tả chi tiết | Công nghệ / API |
|---|---|---|
| **Đo màn hình (Tối đa 120Hz)** | Đồng hồ đo vòng cung (Speedometer Gauge 0 - 120Hz), hiển thị tần số quét thực tế, cao nhất đạt được (Peak 120Hz), thấp nhất, tối đa máy và độ trễ khung hình (`Frame Time: ~8.33ms`). | `CADisplayLink`, `UIScreen.maximumFramesPerSecond`, `CAFrameRateRange` |
| **Đổi ngôn ngữ (VI / EN)** | Nút chuyển đổi ngôn ngữ nhanh chóng (`🇻🇳 VI` / `🇺🇸 EN`) ngay trên thanh công cụ, lưu trạng thái tức thì vào `UserDefaults`. | `LanguageManager`, SwiftUI `@ObservedObject` |
| **Cửa sổ nổi PiP (Picture-in-Picture)** | Cửa sổ HUD nổi bên ngoài màn hình chính hiển thị FPS (60 ⇄ 120Hz), mức CPU, RAM, tốc độ mạng tải lên/tải xuống và xung nhịp vi xử lý. | `AVPictureInPictureVideoCallViewController`, `AVAudioSession` |
| **Bài test kích hoạt 120 FPS** | Chạy chuỗi hoạt họa tốc độ cao và khu vực vuốt chạm tương tác để ép hệ thống kích hoạt tần số quét 120Hz ProMotion tối đa. | SwiftUI Animation, Gesture, CADisplayLink |
| **Thông tin thiết bị (Device Info)** | Nhận diện mã máy, tên thương mại, vi xử lý, tiến trình sản xuất và tần số quét tối đa hỗ trợ từ cơ sở dữ liệu. | `sysctlbyname("hw.machine")`, `DeviceDatabase.json` |
| **Giám sát CPU & RAM** | Số nhân CPU, mức % sử dụng vi xử lý, dung lượng RAM tổng, đang dùng và còn trống theo thời gian thực. | `host_processor_info`, `mach_host_self`, `host_statistics64` |
| **Tình trạng Pin (Battery)** | Mức phần trăm pin và trạng thái sạc (Đang sạc, Đầy, Rút sạc). | `UIDevice.batteryLevel`, `UIDevice.batteryState` |

---

## 🛠 Cách đo tần số quét màn hình (tối đa 120Hz)

1. Ứng dụng khởi tạo `CADisplayLink` liên kết trực tiếp với chu kỳ quét màn hình của hệ điều hành.
2. Với iOS 15 trở lên, dải tần số `preferredFrameRateRange` được cấu hình từ 10Hz đến tối đa 120Hz:
   ```swift
   link.preferredFrameRateRange = CAFrameRateRange(minimum: 10, maximum: 120, preferred: 120)
   ```
3. Thời gian giữa 2 lần cập nhật khung hình `Δt = link.timestamp - lastTimestamp` cho ra tần số quét thực tế: `Hz = 1.0 / Δt`.
4. Độ trễ hiển thị khung hình: `Frame Time = 1000.0 / Hz` (ở 120Hz tương ứng ~8.33ms).
5. Đồng hồ đo Speedometer Gauge hiển thị dải 0 - 120Hz với các mốc chuẩn 60Hz và 120Hz ProMotion.

---

## 📁 Cấu trúc thư mục mã nguồn

```
CPU-IOS/
├── CPU-IOS.xcodeproj/
│   └── project.pbxproj               # Cấu hình dự án Xcode
└── CPU-IOS/
    ├── CPUIOSApp.swift                # Điểm khởi chạy @main SwiftUI
    ├── ContentView.swift              # TabView chính & Nút đổi ngôn ngữ (VI/EN)
    ├── Models/
    │   ├── DeviceModel.swift          # Cấu trúc dữ liệu thiết bị
    │   └── DeviceDatabase.json        # Dữ liệu tra cứu iPhone / iPad
    ├── Services/
    │   ├── LanguageManager.swift      # Quản lý ngôn ngữ Tiếng Việt / Tiếng Anh
    │   ├── RefreshRateMonitor.swift   # Bộ đo tần số quét màn hình (lên đến 120Hz)
    │   ├── PiPFloatingMonitorManager.swift # Cửa sổ nổi PiP giám sát 120Hz
    │   ├── DeviceIdentifier.swift     # Lấy mã phần cứng hw.machine
    │   ├── DeviceDatabaseService.swift# Tra cứu cơ sở dữ liệu thiết bị
    │   ├── SystemInfoService.swift    # Đo CPU & RAM
    │   ├── NetworkSpeedService.swift  # Đo tốc độ mạng
    │   └── BatteryService.swift       # Đo pin
    └── Views/
        ├── DisplayHzView.swift        # Màn hình đo Hz & Speedometer Gauge (0 - 120Hz)
        ├── FloatingMonitorHUDView.swift# Giao diện HUD của cửa sổ nổi PiP
        ├── DeviceInfoView.swift       # Màn hình thông tin thiết bị
        ├── CPUMemoryView.swift        # Màn hình CPU & RAM
        └── BatteryView.swift          # Màn hình Pin
```

---

## 🚀 Hướng dẫn mở và chạy trên macOS (Xcode)

1. Mở file **`CPU-IOS.xcodeproj`** bằng **Xcode 15.0+** trên máy Mac.
2. Chọn target **CPU-IOS** và thiết bị chạy (khuyến nghị chạy trên **thiết bị iPhone/iPad Pro thật có màn hình 120Hz ProMotion** để trải nghiệm đầy đủ).
3. Nhấn **Cmd + R** để biên dịch và chạy ứng dụng.
4. Nhấn nút chuyển đổi ngôn ngữ `🇻🇳 VI` / `🇺🇸 EN` ở góc trên bên phải thanh công cụ để đổi ngôn ngữ tức thì.
