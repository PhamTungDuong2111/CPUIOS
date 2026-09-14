# CPU-IOS (App mẫu kiểu CPU-X cho iOS)

App mẫu SwiftUI minh hoạ cách xây dựng một ứng dụng thông tin phần cứng/hệ thống
kiểu **CPU-X**, với tính năng cốt lõi là **đo tần số quét màn hình theo thời gian
thực (Hz)** — giống video ProMotion nhảy 60 ⇄ 120Hz mà bạn gửi.

> Đây là **source code mẫu** (không phải file .xcodeproj build sẵn, vì file
> .xcodeproj nhị phân do người viết tay ngoài Xcode rất dễ hỏng). Cách mở nhanh
> nhất mất khoảng 2 phút, xem mục "Cách chạy" bên dưới.

## Tính năng đã làm trong bản mẫu này

| Tab | Nội dung | API dùng |
|---|---|---|
| **Display Hz** (cốt lõi) | Đo Hz thực tế của màn hình theo thời gian thực, min/max/hiện tại, phát hiện ProMotion | `CADisplayLink`, `UIScreen.maximumFramesPerSecond` |
| **Cửa sổ nổi PiP** (theo video) | Cửa sổ nhỏ nổi trên màn hình chính đo FPS 60 ⇄ 120Hz theo thao tác vuốt, CPU %, RAM %, tốc độ mạng, xung nhịp Freq (4046MHz) | `AVPictureInPictureVideoCallViewController`, `AVAudioSession` |
| Device Info | Model identifier (vd `iPhone16,2`), tên thương mại, chip, tiến trình, tra từ database nội bộ | `uname()/sysctlbyname("hw.machine")` + JSON lookup |
| CPU & RAM | Số nhân CPU, % CPU dùng, RAM tổng/dùng/free | `sysctl(hw.ncpu)`, `host_processor_info`, `host_statistics64` |
| Battery | % pin, trạng thái sạc | `UIDevice.current` |

## Vì sao đo được Hz mà không cần private API

iOS không cho app đọc trực tiếp "tần số quét hiện tại của panel" như một con số
hệ thống. Cách CPU-X (và các app đo Hz như "Blur Busters UFO Test", "Is My Phone
120Hz") thực sự làm là:

1. Gắn một `CADisplayLink` — callback này được hệ thống gọi **đúng mỗi lần màn
   hình vẽ lại một khung hình**, tức là tần số gọi callback ≈ tần số quét thật
   của panel tại thời điểm đó.
2. Đo khoảng thời gian `Δt` giữa 2 lần gọi liên tiếp (`link.timestamp`).
3. `Hz tức thời = 1 / Δt`.
4. Trên máy hỗ trợ ProMotion (`UIScreen.main.maximumFramesPerSecond > 60`, ví dụ
   iPhone 13 Pro trở lên), hệ điều hành **tự động hạ Hz khi nội dung tĩnh** (tiết
   kiệm pin) và **tăng lên khi có chuyển động/scroll/animation** — đây chính là
   hiện tượng "đôi lúc lên 120Hz" trong video bạn gửi. Vì vậy app có một hoạt ảnh
   nhỏ (kim đồng hồ đo xoay liên tục) để "ép" hệ thống bộc lộ Hz tối đa thật sự;
   nếu bạn để màn hình tĩnh hoàn toàn, Hz sẽ tụt về mức thấp (thường 60 hoặc thấp
   hơn) — đúng hành vi thật của ProMotion, không phải lỗi.
5. Toàn bộ API trên đều là **API công khai** của Apple, không đụng tới private
   API/Device Fingerprinting → an toàn khi nộp App Store.

Trên máy KHÔNG có ProMotion (Hz cố định 60), app vẫn hiển thị đúng nhưng số Hz sẽ
luôn quanh 60, không dao động — vì phần cứng không hỗ trợ.

## Cấu trúc thư mục

```
CPU-IOS/
└── CPU-IOS/
    ├── CPUIOSApp.swift              # Entry point
    ├── ContentView.swift            # TabView chính (giống layout CPU-X)
    ├── Models/
    │   ├── DeviceModel.swift        # Struct mô tả 1 thiết bị trong database
    │   └── DeviceDatabase.json      # Bảng tra hw.machine -> tên/chip/tiến trình
    ├── Services/
    │   ├── DeviceIdentifier.swift   # Lấy hw.machine qua sysctlbyname/uname
    │   ├── DeviceDatabaseService.swift # Load + tra JSON ở trên
    │   ├── SystemInfoService.swift  # CPU (%), RAM (host_statistics64), số nhân
    │   ├── RefreshRateMonitor.swift # <-- TÍNH NĂNG CỐT LÕI: đo Hz màn hình
    │   └── BatteryService.swift     # % pin, trạng thái sạc
    └── Views/
        ├── DisplayHzView.swift      # Màn hình đo Hz (tab đầu tiên)
        ├── DeviceInfoView.swift
        ├── CPUMemoryView.swift
        └── BatteryView.swift
```

## Cách chạy (30 giây)

Đây giờ là **project Xcode thật** (`.xcodeproj`), không cần dựng project mới hay
kéo thả file thủ công nữa:

1. Giải nén, double-click **`CPU-IOS.xcodeproj`** để mở thẳng trong Xcode
   (yêu cầu Xcode 15/16, khuyến nghị chạy trên macOS thật vì Xcode không có
   trên Windows/Linux).
2. Chọn target **CPU-IOS** (đã có sẵn scheme) và một thiết bị/simulator ở
   thanh trên cùng.
3. Nhấn **Cmd+R** để build & chạy. Xcode sẽ tự cấp Bundle Identifier tạm
   (`com.dd.CPU-IOS`) — nếu chạy trên máy thật, vào tab **Signing & Capabilities**
   của target, chọn **Team** cá nhân của bạn (Apple ID miễn phí là đủ để chạy
   thử trên máy mình) rồi Xcode tự ký lại.
4. Chạy trên **thiết bị thật** để thấy đúng hiệu ứng. Lưu ý: Simulator luôn báo
   cứng 60Hz vì không mô phỏng phần cứng màn hình thật — muốn thấy dao động
   60↔120Hz như video, phải chạy trên máy thật có ProMotion (iPhone 13 Pro trở
   lên, iPad Pro 120Hz...).
5. Vào tab **Display Hz**, để yên vài giây rồi thử vuốt/chạm màn hình — số Hz sẽ
   nhảy lên theo tương tác, giống hệt video bạn gửi.

> Ghi chú kỹ thuật: project dùng cơ chế **`GENERATE_INFOPLIST_FILE = YES`** của
> Xcode hiện đại nên không có file `Info.plist` tường minh trong thư mục nguồn —
> Xcode tự sinh lúc build, không ảnh hưởng gì đến việc mở/chạy project.

## Việc còn lại để "lên mức app thật" (không nằm trong bản mẫu)

- Mở rộng `DeviceDatabase.json` cho đầy đủ mọi model iPhone/iPad qua các đời.
- Cơ chế cập nhật database từ xa (remote config) để không phải chờ duyệt bản
  build mới mỗi khi Apple ra máy mới.
- Thêm các tab test cảm biến (camera, mic, loa, haptic, la bàn) bằng
  AVFoundation/CoreMotion/CoreHaptics.
- WidgetKit hiển thị pin/RAM trống ngoài màn hình chính.

## Giới hạn cần biết

- Hz đo được là **Hz thực tế của khung hình đang vẽ trên màn hình tại thời
  điểm đó**, không phải "Hz tối đa lý thuyết của chip" — đây cũng chính xác là
  cách app CPU-X và các app đo Hz khác hoạt động, không có API nào của Apple trả
  về "Hz hiện tại" như một con số tĩnh.
- Chạy trong Simulator sẽ luôn ra ~60Hz cố định, không phản ánh phần cứng thật.
