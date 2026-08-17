# MDaily

MDaily là ứng dụng quản lý chi tiêu cá nhân đa nền tảng (Desktop & Mobile) được thiết kế theo phong cách tối giản, hiện đại và tối ưu trải nghiệm người dùng.

## Tính năng chính

- **Quản lý chi tiêu**: Ghi chép, phân loại danh mục, hỗ trợ đính kèm ảnh và ghi chú.
- **Nhận diện hóa đơn (OCR & AI)**: Tự động trích xuất thông tin chi tiêu từ hình ảnh hóa đơn.
- **Thống kê & Báo cáo**: Theo dõi tổng quan hạn mức và phân bổ chi tiêu trực quan.
- **Trợ lý AI**: Tư vấn và phân tích thói quen tài chính cá nhân.
- **Thiết kế tối giản**: Giao diện lấy cảm hứng từ Apple Design System, mượt mà và trực quan.

## Cấu trúc dự án

```text
MDaily/
├── deskapp/       # Ứng dụng Desktop (Electron + React + TypeScript + Vite)
├── phoneapp/      # Ứng dụng Mobile iOS (Capacitor + React + TypeScript + Vite)
├── DESIGN.md      # Quy chuẩn thiết kế giao diện (Design System)
└── MDaily.png     # Logo thương hiệu ứng dụng
```

## Công nghệ sử dụng

- **Core**: React 19, TypeScript, Vite
- **Desktop**: Electron, Tesseract.js, LocalForage
- **Mobile**: Capacitor (iOS)
- **UI & Icons**: Custom CSS, Lucide Icons

## Cài đặt & Khởi chạy

### Yêu cầu hệ thống
- Node.js (v18 trở lên)
- npm

### 1. Ứng dụng Desktop (`deskapp`)

```bash
cd deskapp
npm install

# Chạy môi trường phát triển
npm run dev

# Đóng gói ứng dụng Desktop
npm run build
```

### 2. Ứng dụng Mobile (`phoneapp`)

```bash
cd phoneapp
npm install

# Chạy môi trường phát triển
npm run dev

# Đóng gói cho iOS via Capacitor
npm run build
npx cap sync ios
npx cap open ios
```

## Kiểm tra mã nguồn

Sử dụng Oxlint để kiểm tra chất lượng mã nguồn:

```bash
npm run lint
```
