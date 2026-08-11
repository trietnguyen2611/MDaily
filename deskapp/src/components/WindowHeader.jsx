import React from 'react';
import { Camera, Sparkles, MessageSquare, Settings, User, LogOut, RefreshCw } from 'lucide-react';

export const WindowHeader = ({
  currentUser,
  onOpenObjectModal,
  onOpenReceiptModal,
  onToggleChat,
  onOpenSettings,
  onOpenAuth,
  onResetData
}) => {
  return (
    <>
      {/* macOS Top Window Bar with Traffic Lights */}
      <div className="mac-title-bar">
        <div className="mac-traffic-lights">
          <button className="traffic-btn close" title="Đóng"></button>
          <button className="traffic-btn minimize" title="Thu nhỏ"></button>
          <button className="traffic-btn maximize" title="Phóng to"></button>
        </div>
        <div className="mac-window-title">
          <span> MDaily Expense Manager</span>
          <span style={{ opacity: 0.5 }}>|</span>
          <span style={{ fontSize: '11px', color: '#2997ff' }}>macOS Intel (Gemma 2 2B Local)</span>
        </div>
        <div className="mac-title-right">
          <button className="btn-dark-utility" onClick={onOpenSettings} title="Cấu hình Jan AI">
            <Settings size={14} />
            <span>Jan AI Server</span>
          </button>
          <button className="btn-dark-utility" onClick={onOpenAuth}>
            <User size={14} />
            <span>{currentUser ? currentUser.name : 'Đăng nhập'}</span>
          </button>
        </div>
      </div>

      {/* Apple Sub-Nav Frosted Bar */}
      <div className="mac-sub-nav">
        <div className="sub-nav-tagline">
          <span>Dashboard Nhật Ký Chi Tiêu</span>
          <span style={{ fontSize: '13px', fontWeight: 400, color: 'var(--color-ink-muted-48)' }}>
            ({currentUser?.email})
          </span>
        </div>
        <div className="sub-nav-actions">
          <button className="btn-secondary-pill" onClick={onOpenObjectModal}>
            <Camera size={16} />
            <span>Chụp/Import Đồ vật</span>
          </button>

          <button className="btn-primary-pill" onClick={onOpenReceiptModal}>
            <Sparkles size={16} />
            <span>Quét Hóa Đơn (*AI)</span>
          </button>

          <button className="btn-secondary-pill" onClick={onToggleChat} style={{ backgroundColor: 'rgba(0,102,204,0.08)' }}>
            <MessageSquare size={16} />
            <span>Hỏi AI Chatbot (*AI)</span>
          </button>

          <button
            onClick={onResetData}
            title="Khôi phục dữ liệu mẫu"
            style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--color-ink-muted-48)', padding: '6px' }}
          >
            <RefreshCw size={16} />
          </button>
        </div>
      </div>
    </>
  );
};
