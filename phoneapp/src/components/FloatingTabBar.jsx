import React from 'react';
import { Home, Sparkles, Camera, MessageSquare, User } from 'lucide-react';

export const FloatingTabBar = ({ activeTab, onTabChange, onOpenObjectSheet, onOpenReceiptSheet }) => {
  return (
    <div className="ios-floating-tab-bar">
      <button
        className={`tab-button ${activeTab === 'dashboard' ? 'active' : ''}`}
        onClick={() => onTabChange('dashboard')}
      >
        <Home size={20} />
        <span>Trang chủ</span>
      </button>

      <button
        className={`tab-button ${activeTab === 'receipt_ai' ? 'active' : ''}`}
        onClick={onOpenReceiptSheet}
      >
        <Sparkles size={20} />
        <span>Quét AI (*AI)</span>
      </button>

      <button
        className="tab-button-scan-center"
        onClick={onOpenObjectSheet}
        title="Chụp đồ vật mới"
      >
        <Camera size={22} />
      </button>

      <button
        className={`tab-button ${activeTab === 'chat_ai' ? 'active' : ''}`}
        onClick={() => onTabChange('chat_ai')}
      >
        <MessageSquare size={20} />
        <span>AI Chat (*AI)</span>
      </button>

      <button
        className={`tab-button ${activeTab === 'profile' ? 'active' : ''}`}
        onClick={() => onTabChange('profile')}
      >
        <User size={20} />
        <span>Tài khoản</span>
      </button>
    </div>
  );
};
