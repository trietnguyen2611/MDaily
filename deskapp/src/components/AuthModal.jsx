import React, { useState } from 'react';
import { X, User, Lock, Mail, ShieldCheck, Smartphone, Laptop } from 'lucide-react';
import { ExpenseStore } from '../services/ExpenseStore';

export const AuthModal = ({ isOpen, onClose, currentUser, onLoginSuccess }) => {
  const [isRegister, setIsRegister] = useState(false);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [name, setName] = useState('');

  if (!isOpen) return null;

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!email || !password) return;

    let user;
    if (isRegister) {
      user = ExpenseStore.register(email, password, name);
    } else {
      user = ExpenseStore.login(email, password);
    }
    onLoginSuccess(user);
    onClose();
  };

  return (
    <div className="modal-overlay">
      <div className="modal-content-apple" style={{ maxWidth: '460px' }}>
        <div className="modal-header">
          <div>
            <h3>{isRegister ? 'Tạo Tài Khoản Đồng Bộ' : 'Đăng Nhập Tài Khoản'}</h3>
            <p style={{ fontSize: '13px', color: 'var(--color-ink-muted-48)' }}>
              Đồng bộ nhật ký chi tiêu tức thì giữa macOS và iOS
            </p>
          </div>
          <button onClick={onClose} style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--color-ink-muted-48)' }}>
            <X size={20} />
          </button>
        </div>

        <div style={{ padding: '12px', background: 'var(--color-canvas-parchment)', borderRadius: 'var(--radius-md)', display: 'flex', alignItems: 'center', gap: '12px' }}>
          <div style={{ display: 'flex', gap: '4px', color: 'var(--color-primary)' }}>
            <Laptop size={18} />
            <Smartphone size={18} />
          </div>
          <p style={{ fontSize: '12px', color: 'var(--color-ink-muted-80)', margin: 0 }}>
            Tất cả chi tiêu chụp trên iPhone hoặc macOS sẽ được đồng bộ trực tiếp trong tài khoản này.
          </p>
        </div>

        <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          {isRegister && (
            <div>
              <label style={{ fontSize: '13px', fontWeight: 600 }}>Họ và tên</label>
              <input
                type="text"
                className="input-apple"
                placeholder="VD: Triết Nguyễn"
                value={name}
                onChange={(e) => setName(e.target.value)}
                required
              />
            </div>
          )}

          <div>
            <label style={{ fontSize: '13px', fontWeight: 600 }}>Email tài khoản *</label>
            <input
              type="email"
              className="input-apple"
              placeholder="triet@apple.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
          </div>

          <div>
            <label style={{ fontSize: '13px', fontWeight: 600 }}>Mật khẩu *</label>
            <input
              type="password"
              className="input-apple"
              placeholder="••••••••"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
            />
          </div>

          <button type="submit" className="btn-primary-pill" style={{ justifyContent: 'center', width: '100%', height: '48px' }}>
            {isRegister ? 'Đăng Ký &amp; Đồng Bộ' : 'Đăng Nhập'}
          </button>

          <div style={{ textAlign: 'center', fontSize: '13px', color: 'var(--color-ink-muted-48)' }}>
            {isRegister ? 'Đã có tài khoản?' : 'Chưa có tài khoản?'} {' '}
            <button
              type="button"
              onClick={() => setIsRegister(!isRegister)}
              style={{ background: 'none', border: 'none', color: 'var(--color-primary)', fontWeight: 600, cursor: 'pointer' }}
            >
              {isRegister ? 'Đăng nhập ngay' : 'Tạo tài khoản mới'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
