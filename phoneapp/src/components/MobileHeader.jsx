import React from 'react';
import { Wifi, Battery, Signal, Sparkles, User } from 'lucide-react';

export const MobileHeader = ({ currentUser, onOpenProfile }) => {
  const currentTime = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

  return (
    <>
      {/* iOS Top Status Bar & Dynamic Island */}
      <div className="ios-status-bar">
        <span className="ios-time">{currentTime}</span>
        <div className="dynamic-island">
          <Sparkles size={13} color="#2997ff" />
          <span>Gemma 2 2B</span>
        </div>
        <div className="ios-icons">
          <Signal size={14} />
          <Wifi size={14} />
          <Battery size={16} />
        </div>
      </div>

      {/* iOS App Top Bar */}
      <div className="ios-header">
        <div>
          <div style={{ fontSize: '11px', fontWeight: 600, color: 'var(--color-primary)', letterSpacing: '0.5px' }}>
            MDaily iOS
          </div>
          <h1>Nhật Ký Chi Tiêu</h1>
        </div>

        <button
          onClick={onOpenProfile}
          style={{
            width: '40px',
            height: '40px',
            borderRadius: '50%',
            backgroundColor: 'var(--color-canvas)',
            border: '1px solid var(--color-hairline)',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            cursor: 'pointer',
            boxShadow: '0 2px 8px rgba(0,0,0,0.06)'
          }}
        >
          <User size={18} color="var(--color-primary)" />
        </button>
      </div>
    </>
  );
};
