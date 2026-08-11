import React from 'react'
import { Settings as SettingsIcon } from 'lucide-react'
import './SettingsPage.css'

export const SettingsPage: React.FC = () => {
  return (
    <div className="settings-container">
      <h2>Cài đặt</h2>

      <div className="settings-section">
        <h3>Chung</h3>
        <div className="settings-item">
          <div className="settings-item-info">
            <span className="settings-item-label">Tiền tệ</span>
            <span className="settings-item-desc">Đơn vị tiền tệ hiển thị trong ứng dụng</span>
          </div>
          <select className="settings-select" defaultValue="vnd">
            <option value="vnd">VNĐ (₫)</option>
            <option value="usd">USD ($)</option>
          </select>
        </div>
      </div>

      <div className="settings-section">
        <h3>Dữ liệu</h3>
        <div className="settings-item">
          <div className="settings-item-info">
            <span className="settings-item-label">Xoá tất cả dữ liệu</span>
            <span className="settings-item-desc">Xoá toàn bộ chi tiêu đã lưu</span>
          </div>
          <button className="btn-utility" style={{ color: '#ff3b30', borderColor: '#ff3b30' }}>
            Xoá
          </button>
        </div>
      </div>

      <div className="settings-section">
        <h3>Giới thiệu</h3>
        <div className="settings-item">
          <div className="settings-item-info">
            <span className="settings-item-label">MDaily</span>
            <span className="settings-item-desc">Phiên bản 1.0.0 — Quản lý tư bản của bạn</span>
          </div>
        </div>
      </div>
    </div>
  )
}
