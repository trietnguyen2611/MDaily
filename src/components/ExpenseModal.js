/**
 * ExpenseModal Component
 * Allows user to log expenses by photo of object + manual price,
 * or automatic receipt scan (*AI powered with Gemma 2 2B).
 */

import { db } from '../services/db.js';
import { janAI } from '../services/jan-ai.js';
import { ocrService } from '../services/ocr.js';
import { cameraService } from '../services/camera.js';

export function renderExpenseModal(platform = 'macOS', onSave = null) {
  let activeTab = 'object'; // 'object' or 'receipt'
  let capturedImage = 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=600&q=80';
  let isScanning = false;
  let videoStream = null;

  const overlay = document.createElement('div');
  overlay.className = 'expense-modal-overlay';
  overlay.style.cssText = `
    position: fixed; top: 0; left: 0; right: 0; bottom: 0;
    background: rgba(0, 0, 0, 0.6);
    backdrop-filter: blur(20px);
    z-index: 10000;
    display: flex; align-items: center; justify-content: center;
    padding: 16px;
  `;

  function renderContent() {
    overlay.innerHTML = `
      <div class="glass-panel" style="
        width: 100%; max-width: 520px;
        border-radius: 28px; padding: 24px;
        box-shadow: 0 25px 60px rgba(0,0,0,0.35);
        background: rgba(255, 255, 255, 0.92);
        max-height: 90vh; overflow-y: auto; position: relative;
      ">
        <button id="close-modal-btn" style="
          position: absolute; top: 18px; right: 18px;
          border: none; background: rgba(0,0,0,0.06); width: 32px; height: 32px;
          border-radius: 50%; cursor: pointer; display: flex; align-items: center; justify-content: center;
        ">
          <span class="material-symbols-outlined" style="font-size: 18px;">close</span>
        </button>

        <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 20px;">
          <h2 style="font-size: 20px; font-weight: 700; color: var(--color-ink);">Ghi nhận Chi tiêu</h2>
          <span style="font-size: 11px; background: rgba(0,102,204,0.1); color: var(--color-primary); padding: 4px 10px; border-radius: 20px; font-weight: 600;">
            Thiết bị: ${platform}
          </span>
        </div>

        <!-- Segmented Tab Switcher -->
        <div style="
          display: flex; background: rgba(0,0,0,0.06); padding: 4px; border-radius: 16px; margin-bottom: 20px;
        ">
          <button id="tab-object" style="
            flex: 1; padding: 10px; border: none; border-radius: 12px; font-size: 13px; font-weight: 600; cursor: pointer;
            background: ${activeTab === 'object' ? '#ffffff' : 'transparent'};
            color: ${activeTab === 'object' ? 'var(--color-ink)' : 'var(--color-ink-muted-48)'};
            box-shadow: ${activeTab === 'object' ? '0 2px 8px rgba(0,0,0,0.08)' : 'none'};
            display: flex; align-items: center; justify-content: center; gap: 6px; transition: all 0.2s ease;
          ">
            <span class="material-symbols-outlined" style="font-size: 18px;">photo_camera</span>
            Chụp đồ vật & Giá tiền
          </button>

          <button id="tab-receipt" style="
            flex: 1; padding: 10px; border: none; border-radius: 12px; font-size: 13px; font-weight: 600; cursor: pointer;
            background: ${activeTab === 'receipt' ? '#ffffff' : 'transparent'};
            color: ${activeTab === 'receipt' ? 'var(--color-ink)' : 'var(--color-ink-muted-48)'};
            box-shadow: ${activeTab === 'receipt' ? '0 2px 8px rgba(0,0,0,0.08)' : 'none'};
            display: flex; align-items: center; justify-content: center; gap: 6px; transition: all 0.2s ease;
          ">
            <span class="material-symbols-outlined" style="font-size: 18px;">receipt_long</span>
            Tự động theo Hoá đơn (*AI)
          </button>
        </div>

        <!-- Camera & Photo Container -->
        <div style="
          width: 100%; height: 200px; border-radius: 18px; background: #111; overflow: hidden;
          position: relative; margin-bottom: 16px; border: 1px dashed rgba(0,0,0,0.2);
          display: flex; align-items: center; justify-content: center;
        ">
          <video id="webcam-preview" autoplay playsinline style="width: 100%; height: 100%; object-fit: cover; display: none;"></video>
          <img id="image-preview" src="${capturedImage}" style="width: 100%; height: 100%; object-fit: cover;" />

          ${
            isScanning
              ? `
            <div style="
              position: absolute; inset: 0; background: rgba(0,0,0,0.7); backdrop-filter: blur(4px);
              display: flex; flex-direction: column; align-items: center; justify-content: center; color: #fff; gap: 10px;
            ">
              <span class="material-symbols-outlined style="font-size: 36px; animation: spin 1s linear infinite;">sync</span>
              <span style="font-size: 13px; font-weight: 600;">Gemma 2 2B đang phân tích hoá đơn...</span>
            </div>
          `
              : ''
          }

          <div style="position: absolute; bottom: 10px; right: 10px; display: flex; gap: 8px;">
            <button id="btn-webcam" class="btn-secondary" style="padding: 6px 12px; font-size: 12px; background: rgba(0,0,0,0.6); color: #fff;">
              <span class="material-symbols-outlined" style="font-size: 16px;">videocam</span> Camera
            </button>
            <label class="btn-secondary" style="padding: 6px 12px; font-size: 12px; background: rgba(0,0,0,0.6); color: #fff; cursor: pointer;">
              <span class="material-symbols-outlined" style="font-size: 16px;">upload</span> Import ảnh
              <input type="file" id="file-input" accept="image/*" style="display: none;" />
            </label>
          </div>
        </div>

        <form id="expense-form">
          <!-- Common Form Fields -->
          <div style="display: flex; flex-direction: column; gap: 12px;">
            <div>
              <label style="font-size: 12px; font-weight: 600; color: var(--color-ink-muted-80); display: block; margin-bottom: 4px;">
                Tên chi tiêu / Món đồ
              </label>
              <div style="display: flex; gap: 8px;">
                <input type="text" id="exp-title" placeholder="${activeTab === 'object' ? 'Ví dụ: Cà phê espresso' : 'Ví dụ: WinMart siêu thị'}" required style="
                  flex: 1; padding: 10px 14px; border-radius: 12px; border: 1px solid rgba(0,0,0,0.15); font-size: 14px; outline: none;
                " />
                ${
                  activeTab === 'object'
                    ? `
                  <button type="button" id="btn-ai-suggest" class="btn-secondary" title="Gợi ý danh mục bằng AI Gemma 2 2B" style="padding: 0 12px;">
                    <span class="material-symbols-outlined" style="font-size: 18px; color: var(--color-primary);">auto_awesome</span>
                  </button>
                `
                    : ''
                }
              </div>
            </div>

            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px;">
              <div>
                <label style="font-size: 12px; font-weight: 600; color: var(--color-ink-muted-80); display: block; margin-bottom: 4px;">Số tiền (VNĐ)</label>
                <input type="number" id="exp-amount" placeholder="45000" min="0" required style="
                  width: 100%; padding: 10px 14px; border-radius: 12px; border: 1px solid rgba(0,0,0,0.15); font-size: 15px; font-weight: 700; color: var(--color-primary); outline: none;
                " />
              </div>

              <div>
                <label style="font-size: 12px; font-weight: 600; color: var(--color-ink-muted-80); display: block; margin-bottom: 4px;">Danh mục (4 Loại)</label>
                <select id="exp-category" style="
                  width: 100%; padding: 10px 14px; border-radius: 12px; border: 1px solid rgba(0,0,0,0.15); font-size: 13px; font-weight: 600; outline: none; background: #fff;
                ">
                  <option value="Hoá đơn">📄 Hoá đơn</option>
                  <option value="Mua sắm">🛍️ Mua sắm</option>
                  <option value="Ăn uống" selected>🍔 Ăn uống</option>
                  <option value="Di chuyển">🚗 Di chuyển</option>
                </select>
              </div>
            </div>

            <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 12px;">
              <div>
                <label style="font-size: 12px; font-weight: 600; color: var(--color-ink-muted-80); display: block; margin-bottom: 4px;">Ngày giao dịch</label>
                <input type="date" id="exp-date" value="${new Date().toISOString().split('T')[0]}" style="
                  width: 100%; padding: 10px 14px; border-radius: 12px; border: 1px solid rgba(0,0,0,0.15); font-size: 13px; outline: none;
                " />
              </div>

              <div>
                <label style="font-size: 12px; font-weight: 600; color: var(--color-ink-muted-80); display: block; margin-bottom: 4px;">Ghi chú / Cửa hàng</label>
                <input type="text" id="exp-note" placeholder="Chi tiết hoặc địa điểm" style="
                  width: 100%; padding: 10px 14px; border-radius: 12px; border: 1px solid rgba(0,0,0,0.15); font-size: 13px; outline: none;
                " />
              </div>
            </div>

            ${
              activeTab === 'receipt'
                ? `
              <div style="
                background: rgba(0,102,204,0.06); padding: 10px 14px; border-radius: 12px; border: 1px solid rgba(0,102,204,0.15);
                display: flex; align-items: center; justify-content: space-between;
              ">
                <div style="display: flex; align-items: center; gap: 8px;">
                  <span class="material-symbols-outlined" style="color: var(--color-primary);">auto_awesome</span>
                  <span style="font-size: 12px; font-weight: 500; color: var(--color-ink);">Quét hoá đơn tự động bằng AI Gemma 2 2B</span>
                </div>
                <button type="button" id="btn-scan-receipt" class="btn-primary" style="padding: 6px 14px; font-size: 12px;">
                  Phân tích AI
                </button>
              </div>
            `
                : ''
            }
          </div>

          <div style="display: flex; gap: 12px; margin-top: 20px;">
            <button type="button" id="btn-cancel" class="btn-secondary" style="flex: 1; justify-content: center; padding: 12px;">
              Hủy
            </button>
            <button type="submit" class="btn-primary" style="flex: 1; justify-content: center; padding: 12px;">
              Lưu Chi Tiêu
            </button>
          </div>
        </form>
      </div>
    `;

    // Event listeners
    overlay.querySelector('#close-modal-btn').addEventListener('click', closeModal);
    overlay.querySelector('#btn-cancel').addEventListener('click', closeModal);

    overlay.querySelector('#tab-object').addEventListener('click', () => {
      activeTab = 'object';
      renderContent();
    });

    overlay.querySelector('#tab-receipt').addEventListener('click', () => {
      activeTab = 'receipt';
      renderContent();
    });

    // File Upload Listener
    const fileInput = overlay.querySelector('#file-input');
    fileInput.addEventListener('change', async (e) => {
      if (e.target.files && e.target.files[0]) {
        try {
          const dataUrl = await cameraService.readFileAsDataURL(e.target.files[0]);
          capturedImage = dataUrl;
          overlay.querySelector('#image-preview').src = capturedImage;

          if (activeTab === 'receipt') {
            triggerReceiptScan(dataUrl);
          }
        } catch (err) {
          console.error(err);
        }
      }
    });

    // Webcam stream Listener
    const btnWebcam = overlay.querySelector('#btn-webcam');
    btnWebcam.addEventListener('click', async () => {
      const videoEl = overlay.querySelector('#webcam-preview');
      const imgEl = overlay.querySelector('#image-preview');

      if (videoStream) {
        // Capture frame
        capturedImage = cameraService.captureFromVideo(videoEl);
        cameraService.stopCamera(videoStream);
        videoStream = null;
        videoEl.style.display = 'none';
        imgEl.style.display = 'block';
        imgEl.src = capturedImage;
        btnWebcam.innerHTML = '<span class="material-symbols-outlined" style="font-size: 16px;">videocam</span> Camera';

        if (activeTab === 'receipt') {
          triggerReceiptScan(capturedImage);
        }
      } else {
        videoStream = await cameraService.startCamera(videoEl);
        if (videoStream) {
          videoEl.style.display = 'block';
          imgEl.style.display = 'none';
          btnWebcam.innerHTML = '<span class="material-symbols-outlined" style="font-size: 16px;">photo_camera</span> Chụp ngay';
        }
      }
    });

    // AI Suggestion for Object Category
    const btnAiSuggest = overlay.querySelector('#btn-ai-suggest');
    if (btnAiSuggest) {
      btnAiSuggest.addEventListener('click', async () => {
        const titleInput = overlay.querySelector('#exp-title').value;
        if (!titleInput) {
          alert('Vui lòng nhập tên món đồ để AI gợi ý danh mục');
          return;
        }
        btnAiSuggest.disabled = true;
        const suggestedCat = await janAI.suggestObjectCategory(titleInput);
        overlay.querySelector('#exp-category').value = suggestedCat;
        btnAiSuggest.disabled = false;
      });
    }

    // Receipt Scan Trigger
    const btnScanReceipt = overlay.querySelector('#btn-scan-receipt');
    if (btnScanReceipt) {
      btnScanReceipt.addEventListener('click', () => {
        triggerReceiptScan(capturedImage);
      });
    }

    // Form Submit
    const form = overlay.querySelector('#expense-form');
    form.addEventListener('submit', (e) => {
      e.preventDefault();
      const title = overlay.querySelector('#exp-title').value;
      const amount = Number(overlay.querySelector('#exp-amount').value);
      const category = overlay.querySelector('#exp-category').value;
      const date = overlay.querySelector('#exp-date').value;
      const note = overlay.querySelector('#exp-note').value;

      db.addExpense({
        title,
        amount,
        category,
        date,
        photo: capturedImage,
        type: activeTab,
        device: platform,
        note
      });

      closeModal();
      if (onSave) onSave();
    });
  }

  async function triggerReceiptScan(imgUrl) {
    isScanning = true;
    renderContent();

    const parsed = await ocrService.processReceiptImage(imgUrl);

    isScanning = false;
    renderContent();

    // Auto fill form
    if (parsed) {
      overlay.querySelector('#exp-title').value = parsed.merchant || 'Hoá đơn dịch vụ';
      overlay.querySelector('#exp-amount').value = parsed.amount || 0;
      overlay.querySelector('#exp-category').value = parsed.category || 'Hoá đơn';
      if (parsed.date) overlay.querySelector('#exp-date').value = parsed.date;
      overlay.querySelector('#exp-note').value = parsed.items || 'Quét tự động từ ảnh';
    }
  }

  function closeModal() {
    if (videoStream) {
      cameraService.stopCamera(videoStream);
    }
    overlay.remove();
  }

  renderContent();
  document.body.appendChild(overlay);
}
