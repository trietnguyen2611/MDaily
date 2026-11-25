# MDaily — Pure Native SwiftUI Personal Finance App

**MDaily** là ứng dụng quản lý chi tiêu cá nhân thuần Native SwiftUI (Apple Multiplatform), được thiết kế tối ưu cho **macOS 26+ (Apple Silicon)**, **iOS 26+**, **iPadOS 26+** và giao diện thích ứng **iPhone Duo** (*Folded / Unfolded* với thanh điều hướng bên phải và Inspector song song).

**MDaily** is a pure Native SwiftUI personal finance and expense management app built for **macOS 26+ (Apple Silicon)**, **iOS 26+**, **iPadOS 26+**, and **iPhone Duo** adaptive layouts, combining **OS 26+ Liquid Glass** navigation chrome with an Apple Gallery visual aesthetic.

---

## Tính năng chính / Key Features

- **Theo dõi thu chi & Ngân sách / Expense & Income Tracking** — Ghi nhận giao dịch nhanh chóng, phân loại danh mục, đính kèm ảnh hoá đơn và ghi chú.
- **Quét hoá đơn Vision OCR & Apple Intelligence (AFM)** — Trích xuất tự động số tiền, ngày tháng và nội dung từ ảnh hoá đơn trực tiếp trên thiết bị.
- **Trợ lý tài chính AI / AI Money Assistant** — Phân tích thói quen chi tiêu và gợi ý tiết kiệm bằng Apple Foundation Models trên thiết bị (hỗ trợ Tiếng Việt & English).
- **Đồng bộ mạng LAN không cần máy chủ / Peer-to-Peer LAN Sync** — Tự động phát hiện và đồng bộ dữ liệu giữa Mac, iPad và iPhone qua Bonjour (`_mdaily-sync._tcp`).
- **Giao diện thích ứng đa thiết bị / Adaptive Multiplatform UI** — Tự động chuyển đổi giữa thanh điều hướng nổi iPhone, thanh bên phải cho **iPhone Duo** (mở rộng Inspector khi mở gập), và `NavigationSplitView` + Inspector cho iPad & macOS.

---

## Yêu cầu hệ thống / Requirements

- **Xcode 27** (`objectVersion = 77`, Swift 6.0)
- **macOS 26.0+** (Apple Silicon `arm64` only)
- **iOS 26.0+ / iPadOS 26.0+**

---

## Cấu trúc dự án / Project Structure

```text
MDaily/
├── MDaily.xcodeproj/         # Xcode 27 Multiplatform Project
├── MDaily/
│   ├── App/                  # Entry point & app commands (MDailyApp.swift)
│   ├── Models/               # Codable domain models (Transaction, Category, Budget, ...)
│   ├── Services/             # Persistence, Vision OCR, AFM AI, Bonjour LAN Sync, Posture
│   ├── DesignSystem/         # Apple Gallery colors, typography & Liquid Glass modifiers
│   ├── Views/                # Adaptive SwiftUI views (Navigation, Dashboard, Transactions, Reports, Assistant, Settings)
│   ├── Assets.xcassets/      # AppIcon, AccentColor, Logo
│   ├── Info.plist            # Permissions & Bonjour service declarations
│   └── MDaily.entitlements   # App Sandbox, LAN client/server & user-selected files
├── DESIGN.md                 # Design system tokens & visual rules
└── md.icon/                  # Source brand icon assets
```

---

## Mở & Chạy / Build & Run

1. Mở `MDaily.xcodeproj` bằng **Xcode 27**.
2. Chọn scheme **MDaily** và thiết bị đích (**My Mac**, **iPhone**, hoặc **iPad Simulator**).
3. Nhấn `⌘R` để build và chạy ứng dụng.

Hoặc kiểm tra nhanh qua dòng lệnh:

```bash
xcodebuild -list -project MDaily.xcodeproj
```
