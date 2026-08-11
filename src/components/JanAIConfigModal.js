/**
 * JanAIConfigModal Component
 * Configures Jan AI Local Server API settings and tests Gemma 2 2B status.
 */

import { db } from '../services/db.js';
import { janAI } from '../services/jan-ai.js';

export function renderJanAIConfigModal(onClose = null) {
  const currentConfig = db.getJanConfig();
  let statusState = { checking: false, message: 'Chưa kiểm tra' };

  const overlay = document.createElement('div');
  overlay.className = 'jan-config-modal-overlay';
  overlay.style.cssText = `
    position: fixed; top: 0; left: 0; right: 0; bottom: 0;
    background: rgba(0, 0, 0, 0.5);
    backdrop-filter: blur(16px);
    z-index: 10000;
    display: flex; align-items: center; justify-content: center;
    padding: 20px;
  `;

  function renderContent() {
    overlay.innerHTML = `
      <div class="glass-panel" style="
        width: 100%; max-width: 460px; border-radius: 24px; padding: 28px;
        background: rgba(255, 255, 255, 0.92); box-shadow: 0 20px 50px rgba(0,0,0,0.3); position: relative;
      ">
        <button id="close-jan-btn" style="
          position: absolute; top: 18px; right: 18px; border: none; background: rgba(0,0,0,0.06);
          width: 32px; height: 32px; border-radius: 50%; cursor: pointer; display: flex; align-items: center; justify-content: center;
        ">
          <span class="material-symbols-outlined" style="font-size: 18px;">close</span>
        </button>

        <div style="display: flex; align-items: center; gap: 12px; margin-bottom: 20px;">
          <div style="
            width: 44px; height: 44px; border-radius: 14px; background: #1d1d1f; color: #fff;
            display: flex; align-items: center; justify-content: center; box-shadow: 0 4px 14px rgba(0,0,0,0.2);
          ">
            <span class="material-symbols-outlined" style="font-size: 24px; color: #2997ff;">memory</span>
          </div>
          <div>
            <h2 style="font-size: 18px; font-weight: 700; color: var(--color-ink);">Cấu hình Jan AI Server</h2>
            <p style="font-size: 12px; color: var(--color-ink-muted-48);">Chạy mô hình Gemma 2 2B Local trên Mac Intel</p>
          </div>
        </div>

        <form id="jan-config-form" style="display: flex; flex-direction: column; gap: 14px;">
          <div>
            <label style="font-size: 12px; font-weight: 600; color: var(--color-ink-muted-80); display: block; margin-bottom: 4px;">API Endpoint (Jan AI)</label>
            <input type="text" id="jan-endpoint" value="${currentConfig.endpoint || 'http://localhost:1337/v1'}" required style="
              width: 100%; padding: 10px 14px; border-radius: 12px; border: 1px solid rgba(0,0,0,0.15); font-size: 13px; outline: none;
            " />
          </div>

          <div>
            <label style="font-size: 12px; font-weight: 600; color: var(--color-ink-muted-80); display: block; margin-bottom: 4px;">Mô hình AI (Model ID)</label>
            <input type="text" id="jan-model" value="${currentConfig.model || 'gemma-2-2b-it'}" required style="
              width: 100%; padding: 10px 14px; border-radius: 12px; border: 1px solid rgba(0,0,0,0.15); font-size: 13px; outline: none;
            " />
          </div>

          <!-- Connection Test Box -->
          <div style="
            background: rgba(0,0,0,0.04); padding: 12px 16px; border-radius: 14px; display: flex; align-items: center; justify-content: space-between;
          ">
            <div style="font-size: 12px;">
              <span style="font-weight: 600; color: var(--color-ink);">Trạng thái kết nối:</span>
              <div id="jan-status-text" style="color: var(--color-ink-muted-48); margin-top: 2px;">
                ${statusState.message}
              </div>
            </div>
            <button type="button" id="btn-test-jan" class="btn-secondary" style="padding: 6px 14px; font-size: 12px;">
              Kiểm tra
            </button>
          </div>

          <div style="display: flex; gap: 10px; margin-top: 10px;">
            <button type="button" id="btn-jan-cancel" class="btn-secondary" style="flex: 1; justify-content: center; padding: 10px;">Đóng</button>
            <button type="submit" class="btn-primary" style="flex: 1; justify-content: center; padding: 10px;">Lưu Cấu Hình</button>
          </div>
        </form>
      </div>
    `;

    overlay.querySelector('#close-jan-btn').addEventListener('click', closeModal);
    overlay.querySelector('#btn-jan-cancel').addEventListener('click', closeModal);

    overlay.querySelector('#btn-test-jan').addEventListener('click', async () => {
      const endpoint = overlay.querySelector('#jan-endpoint').value;
      const model = overlay.querySelector('#jan-model').value;
      db.saveJanConfig({ endpoint, model });

      const statusEl = overlay.querySelector('#jan-status-text');
      statusEl.textContent = 'Đang kiểm tra kết nối...';
      const status = await janAI.checkConnection();
      statusEl.textContent = status.message;
      statusEl.style.color = status.online ? '#34c759' : '#ff3b30';
    });

    const form = overlay.querySelector('#jan-config-form');
    form.addEventListener('submit', (e) => {
      e.preventDefault();
      const endpoint = overlay.querySelector('#jan-endpoint').value;
      const model = overlay.querySelector('#jan-model').value;
      db.saveJanConfig({ endpoint, model });
      closeModal();
    });
  }

  function closeModal() {
    overlay.remove();
    if (onClose) onClose();
  }

  renderContent();
  document.body.appendChild(overlay);
}
