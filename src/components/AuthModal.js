/**
 * AuthModal Component
 * Login & Registration Modal with Apple Floating Glass design.
 */

import { auth } from '../services/auth.js';

export function renderAuthModal(onSuccess, onClose) {
  let isRegisterMode = false;

  const overlay = document.createElement('div');
  overlay.className = 'auth-modal-overlay';
  overlay.style.cssText = `
    position: fixed;
    top: 0; left: 0; right: 0; bottom: 0;
    background: rgba(0, 0, 0, 0.5);
    backdrop-filter: blur(16px);
    z-index: 10000;
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 20px;
  `;

  function renderContent() {
    overlay.innerHTML = `
      <div class="glass-panel" style="
        width: 100%;
        max-width: 400px;
        border-radius: 24px;
        padding: 32px;
        box-shadow: 0 20px 50px rgba(0,0,0,0.3);
        position: relative;
        background: rgba(255, 255, 255, 0.85);
      ">
        <button id="close-auth-btn" style="
          position: absolute; top: 16px; right: 16px;
          border: none; background: rgba(0,0,0,0.05); width: 32px; height: 32px;
          border-radius: 50%; cursor: pointer; display: flex; align-items: center; justify-content: center;
        ">
          <span class="material-symbols-outlined" style="font-size: 18px;">close</span>
        </button>

        <div style="text-align: center; margin-bottom: 24px;">
          <div style="
            width: 56px; height: 56px; border-radius: 16px; background: var(--color-primary);
            color: #fff; display: inline-flex; align-items: center; justify-content: center; margin-bottom: 12px;
            box-shadow: 0 8px 20px rgba(0, 102, 204, 0.3);
          ">
            <span class="material-symbols-outlined" style="font-size: 32px;">sync</span>
          </div>
          <h2 style="font-size: 22px; font-weight: 700; color: var(--color-ink);">
            ${isRegisterMode ? 'Đăng ký Tài khoản MDaily' : 'Đăng nhập Đồng bộ'}
          </h2>
          <p style="font-size: 13px; color: var(--color-ink-muted-48); margin-top: 4px;">
            Đồng bộ dữ liệu thời gian thực giữa Mac Intel & iPhone
          </p>
        </div>

        <form id="auth-form" style="display: flex; flex-direction: column; gap: 14px;">
          ${
            isRegisterMode
              ? `
            <div>
              <label style="font-size: 12px; font-weight: 600; color: var(--color-ink-muted-80); display: block; margin-bottom: 4px;">Họ và tên</label>
              <input type="text" id="auth-name" placeholder="Steve Jobs" required style="
                width: 100%; padding: 12px 14px; border-radius: 12px; border: 1px solid rgba(0,0,0,0.15);
                font-size: 14px; outline: none; background: rgba(255,255,255,0.9);
              " />
            </div>
          `
              : ''
          }
          <div>
            <label style="font-size: 12px; font-weight: 600; color: var(--color-ink-muted-80); display: block; margin-bottom: 4px;">Email</label>
            <input type="email" id="auth-email" placeholder="steve@apple.com" value="demo@apple.com" required style="
              width: 100%; padding: 12px 14px; border-radius: 12px; border: 1px solid rgba(0,0,0,0.15);
              font-size: 14px; outline: none; background: rgba(255,255,255,0.9);
            " />
          </div>
          <div>
            <label style="font-size: 12px; font-weight: 600; color: var(--color-ink-muted-80); display: block; margin-bottom: 4px;">Mật khẩu</label>
            <input type="password" id="auth-password" placeholder="••••••••" value="123" required style="
              width: 100%; padding: 12px 14px; border-radius: 12px; border: 1px solid rgba(0,0,0,0.15);
              font-size: 14px; outline: none; background: rgba(255,255,255,0.9);
            " />
          </div>

          <div id="auth-error" style="color: #ff3b30; font-size: 12px; text-align: center; display: none;"></div>

          <button type="submit" class="btn-primary" style="width: 100%; justify-content: center; padding: 12px; font-size: 15px; margin-top: 8px;">
            ${isRegisterMode ? 'Tạo tài khoản' : 'Đăng nhập ngay'}
          </button>
        </form>

        <div style="margin-top: 20px; text-align: center; font-size: 13px; color: var(--color-ink-muted-48);">
          ${
            isRegisterMode
              ? 'Đã có tài khoản? <a href="#" id="toggle-auth" style="color: var(--color-primary); font-weight: 600; text-decoration: none;">Đăng nhập</a>'
              : 'Chưa có tài khoản? <a href="#" id="toggle-auth" style="color: var(--color-primary); font-weight: 600; text-decoration: none;">Đăng ký ngay</a>'
          }
        </div>
      </div>
    `;

    overlay.querySelector('#close-auth-btn').addEventListener('click', () => {
      overlay.remove();
      if (onClose) onClose();
    });

    overlay.querySelector('#toggle-auth').addEventListener('click', (e) => {
      e.preventDefault();
      isRegisterMode = !isRegisterMode;
      renderContent();
    });

    const form = overlay.querySelector('#auth-form');
    form.addEventListener('submit', (e) => {
      e.preventDefault();
      const email = overlay.querySelector('#auth-email').value;
      const password = overlay.querySelector('#auth-password').value;
      const errorEl = overlay.querySelector('#auth-error');

      if (isRegisterMode) {
        const name = overlay.querySelector('#auth-name').value;
        const res = auth.register(name, email, password);
        if (res.success) {
          overlay.remove();
          if (onSuccess) onSuccess(res.user);
        } else {
          errorEl.textContent = res.message;
          errorEl.style.display = 'block';
        }
      } else {
        const res = auth.login(email, password);
        if (res.success) {
          overlay.remove();
          if (onSuccess) onSuccess(res.user);
        } else {
          errorEl.textContent = res.message;
          errorEl.style.display = 'block';
        }
      }
    });
  }

  renderContent();
  document.body.appendChild(overlay);
}
