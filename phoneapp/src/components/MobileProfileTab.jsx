import React, { useState } from 'react';
import { User, ShieldCheck, Smartphone, Laptop, Settings, LogOut, CheckCircle2, Cpu } from 'lucide-react';
import { ExpenseStore } from '../services/ExpenseStore';
import { JanAIService } from '../services/JanAIService';

export const MobileProfileTab = ({ currentUser, onUserChange }) => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [janConfig, setJanConfig] = useState(JanAIService.getSettings());
  const [savedMsg, setSavedMsg] = useState('');

  const handleLogin = (e) => {
    e.preventDefault();
    if (!email) return;
    const u = ExpenseStore.login(email, password || '123456');
    onUserChange(u);
  };

  const handleLogout = () => {
    ExpenseStore.logout();
    onUserChange(null);
  };

  const handleSaveJanConfig = (e) => {
    e.preventDefault();
    JanAIService.saveSettings(janConfig);
    setSavedMsg('Đã lưu cấu hình Jan AI!');
    setTimeout(() => setSavedMsg(''), 2500);
  };

  return (
    <div className="ios-scroll-content">
      <div className="ios-card" style={{ textAlign: 'center', padding: '24px 16px' }}>
        <div style={{ width: '64px', height: '64px', borderRadius: '50%', background: 'var(--color-primary)', color: '#fff', fontSize: '28px', display: 'flex', alignItems: 'center', justifyContent: 'center', margin: '0 auto 12px auto' }}>
          
        </div>
        <h3 style={{ fontSize: '20px', fontWeight: 700, fontFamily: 'var(--font-display)' }}>
          {currentUser ? currentUser.name : 'Chưa đăng nhập'}
        </h3>
        <p style={{ fontSize: '13px', color: 'var(--color-ink-muted-48)' }}>
          {currentUser ? currentUser.email : 'Đăng nhập để đồng bộ với macOS'}
        </p>

        {currentUser && (
          <button
            onClick={handleLogout}
            style={{ marginTop: '16px', padding: '8px 16px', borderRadius: '99px', background: 'rgba(255,59,48,0.1)', color: '#ff3b30', border: 'none', fontWeight: 600, fontSize: '13px', cursor: 'pointer', display: 'inline-flex', alignItems: 'center', gap: '6px' }}
          >
            <LogOut size={14} />
            <span>Đăng xuất</span>
          </button>
        )}
      </div>

      {/* Sync Banner */}
      <div className="ios-card" style={{ background: 'var(--color-surface-pearl)' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px', fontWeight: 600, fontSize: '14px', color: '#34c759' }}>
          <ShieldCheck size={18} />
          <span>Đồng Bộ Trực Tiếp macOS &amp; iOS</span>
        </div>
        <p style={{ fontSize: '12px', color: 'var(--color-ink-muted-48)', marginTop: '4px' }}>
          Đăng nhập cùng 1 email trên deskapp (macOS) và phoneapp (iOS) sẽ tự động đồng bộ tất cả chi tiêu và hình ảnh.
        </p>
      </div>

      {/* Auth form if logged out */}
      {!currentUser && (
        <div className="ios-card">
          <h4 style={{ fontSize: '16px', fontWeight: 600, marginBottom: '12px' }}>Đăng Nhập Đồng Bộ</h4>
          <form onSubmit={handleLogin} style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
            <input
              type="email"
              placeholder="Email: triet@apple.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              style={{ height: '42px', borderRadius: '12px', border: '1px solid var(--color-hairline)', padding: '0 12px', fontSize: '14px' }}
              required
            />
            <input
              type="password"
              placeholder="Mật khẩu"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              style={{ height: '42px', borderRadius: '12px', border: '1px solid var(--color-hairline)', padding: '0 12px', fontSize: '14px' }}
            />
            <button
              type="submit"
              style={{ height: '44px', borderRadius: '99px', background: 'var(--color-primary)', color: '#fff', border: 'none', fontWeight: 600, fontSize: '15px' }}
            >
              Đăng Nhập
            </button>
          </form>
        </div>
      )}

      {/* Jan AI Server Settings */}
      <div className="ios-card">
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontWeight: 600, fontSize: '15px', marginBottom: '10px' }}>
          <Cpu size={18} color="var(--color-primary)" />
          <span>Cấu hình Jan AI Local</span>
        </div>

        {savedMsg && (
          <div style={{ fontSize: '12px', color: '#34c759', fontWeight: 600, marginBottom: '8px' }}>
            ✓ {savedMsg}
          </div>
        )}

        <form onSubmit={handleSaveJanConfig} style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
          <div>
            <label style={{ fontSize: '11px', color: 'var(--color-ink-muted-48)' }}>Jan AI Endpoint Server URL</label>
            <input
              type="text"
              value={janConfig.baseUrl}
              onChange={(e) => setJanConfig({ ...janConfig, baseUrl: e.target.value })}
              style={{ width: '100%', height: '40px', borderRadius: '10px', border: '1px solid var(--color-hairline)', padding: '0 12px', fontSize: '13px', marginTop: '2px' }}
            />
          </div>
          <div>
            <label style={{ fontSize: '11px', color: 'var(--color-ink-muted-48)' }}>Mô hình local (*Gemma 2 2B)</label>
            <input
              type="text"
              value={janConfig.model}
              onChange={(e) => setJanConfig({ ...janConfig, model: e.target.value })}
              style={{ width: '100%', height: '40px', borderRadius: '10px', border: '1px solid var(--color-hairline)', padding: '0 12px', fontSize: '13px', marginTop: '2px' }}
            />
          </div>
          <button
            type="submit"
            style={{ height: '40px', borderRadius: '99px', background: 'var(--color-ink)', color: '#fff', border: 'none', fontSize: '13px', fontWeight: 600, marginTop: '4px' }}
          >
            Lưu Cấu Hình AI
          </button>
        </form>
      </div>
    </div>
  );
};
