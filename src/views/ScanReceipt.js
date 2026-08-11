/* ============================================================
   MDaily — Scan Receipt View
   OCR + AI receipt analysis
   ============================================================ */

import { captureFromCamera, selectFromGallery, handleDrop } from '../services/camera.js';
import { extractText } from '../services/ocr.js';
import { analyzeReceipt, isAIAvailable } from '../services/ai.js';
import { addExpense } from '../services/db.js';
import { getCategory, getAllCategories } from '../utils/categories.js';
import { formatVND } from '../utils/format.js';
import { navigateTo } from '../router.js';

export default async function ScanReceiptView() {
  const element = document.createElement('div');
  element.className = 'view';

  let selectedImage = null;
  let scanResult = null;

  element.innerHTML = `
    <div class="view-header" style="padding-bottom: 0;">
      <h1 class="view-header__title" style="font-size: 28px;">Quét hoá đơn</h1>
      <p class="text-caption" style="color: var(--color-ink-muted-48); margin-top: 4px;">
        AI sẽ tự động nhận dạng và phân loại
      </p>
    </div>

    <!-- AI Status -->
    <div style="padding: 0 var(--space-md) var(--space-sm);">
      <div id="ai-status" class="scan-result__ai-badge" style="display: inline-flex;">
        <span class="spinner" style="width:14px;height:14px;border-width:2px;"></span>
        Đang kiểm tra AI...
      </div>
    </div>

    <!-- Image Capture Area -->
    <div style="padding: 0 var(--space-md);">
      <div class="image-capture" id="image-capture">
        <div class="image-capture__dropzone" id="dropzone">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <rect x="2" y="3" width="20" height="18" rx="2"/>
            <path d="M2 15l5-5 3 3 4-4 8 8"/>
          </svg>
          <div style="text-align: center;">
            <p class="text-body-strong" style="color: var(--color-body-on-dark);">Chụp ảnh hoá đơn</p>
            <p class="text-caption" style="color: var(--color-body-muted); margin-top: 4px;">AI sẽ tự động đọc nội dung</p>
          </div>
          <div style="display: flex; gap: 8px;">
            <button class="btn-primary btn-sm" id="camera-btn">📷 Chụp ảnh</button>
            <button class="btn-secondary btn-sm" style="color: var(--color-on-dark); border-color: rgba(255,255,255,0.3);" id="gallery-btn">🖼️ Chọn ảnh</button>
          </div>
        </div>

        <!-- Preview -->
        <div id="preview-container" style="display: none;">
          <img class="image-capture__preview" id="preview-image" src="" alt="Preview">
          <div class="image-capture__actions">
            <button class="btn-icon" id="retake-btn" title="Chọn lại">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M1 4v6h6M23 20v-6h-6"/>
                <path d="M20.49 9A9 9 0 0 0 5.64 5.64L1 10m22 4l-4.64 4.36A9 9 0 0 1 3.51 15"/>
              </svg>
            </button>
            <button class="btn-primary btn-sm" id="scan-btn">
              🔍 Quét hoá đơn
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Processing Indicator -->
    <div id="processing" style="display: none; padding: var(--space-lg) var(--space-md); text-align: center;">
      <div class="spinner" style="margin: 0 auto var(--space-md);"></div>
      <p class="text-body-strong" id="processing-status">Đang nhận dạng văn bản...</p>
      <div class="progress-bar" style="margin-top: var(--space-sm); max-width: 240px; margin-left: auto; margin-right: auto;">
        <div class="progress-bar__fill" id="progress-fill" style="width: 0%;"></div>
      </div>
    </div>

    <!-- Scan Results -->
    <div id="results-container" style="display: none;">
      <div class="scan-result">
        <div class="scan-result__header">
          <span class="scan-result__ai-badge">✨ Phân tích bởi AI</span>
          <span class="text-caption" style="color: var(--color-ink-muted-48); margin-left: auto;" id="ocr-confidence"></span>
        </div>
        <div class="scan-result__items" id="result-items"></div>
        <div class="scan-result__total">
          <span>Tổng cộng</span>
          <span id="result-total">0₫</span>
        </div>
      </div>

      <!-- Category Override -->
      <div style="padding: 0 var(--space-md);">
        <div class="form-group" style="margin-top: var(--space-md);">
          <label class="form-label">Danh mục</label>
          <div class="category-selector" id="category-selector">
            ${getAllCategories().map(cat => `
              <div class="category-selector__item" data-category="${cat.key}">
                <span class="category-selector__icon">${cat.icon}</span>
                <span class="category-selector__name">${cat.name}</span>
              </div>
            `).join('')}
          </div>
        </div>

        <!-- Amount Override -->
        <div class="form-group">
          <label class="form-label">Chỉnh sửa số tiền</label>
          <input type="number" class="form-input form-input--amount" id="amount-override"
                 placeholder="0" inputmode="numeric" min="0">
        </div>

        <!-- Save -->
        <button class="btn-primary" style="width: 100%; padding: 14px;" id="save-btn">
          ✅ Xác nhận và lưu
        </button>
      </div>

      <!-- Raw OCR Text (collapsible) -->
      <details style="padding: var(--space-md); margin-top: var(--space-sm);">
        <summary class="text-caption" style="color: var(--color-ink-muted-48); cursor: pointer;">Xem text OCR gốc</summary>
        <pre id="raw-ocr" style="font-size: 12px; white-space: pre-wrap; background: var(--color-canvas-parchment); padding: var(--space-sm); border-radius: var(--rounded-sm); margin-top: var(--space-xs); max-height: 200px; overflow-y: auto;"></pre>
      </details>
    </div>
  `;

  function setup() {
    const dropzone = element.querySelector('#dropzone');
    const previewContainer = element.querySelector('#preview-container');
    const previewImage = element.querySelector('#preview-image');
    const cameraBtn = element.querySelector('#camera-btn');
    const galleryBtn = element.querySelector('#gallery-btn');
    const retakeBtn = element.querySelector('#retake-btn');
    const scanBtn = element.querySelector('#scan-btn');
    const processing = element.querySelector('#processing');
    const processingStatus = element.querySelector('#processing-status');
    const progressFill = element.querySelector('#progress-fill');
    const resultsContainer = element.querySelector('#results-container');
    const aiStatus = element.querySelector('#ai-status');

    // Check AI availability
    checkAI();

    async function checkAI() {
      const available = await isAIAvailable();
      if (available) {
        aiStatus.innerHTML = '🟢 AI sẵn sàng (Gemma 2 2B)';
        aiStatus.style.color = 'var(--color-cat-food)';
      } else {
        aiStatus.innerHTML = '🔴 JAN AI chưa chạy — chỉ OCR';
        aiStatus.style.color = '#ef4444';
      }
    }

    function showPreview(imageDataUrl) {
      selectedImage = imageDataUrl;
      previewImage.src = imageDataUrl;
      dropzone.style.display = 'none';
      previewContainer.style.display = 'block';
      resultsContainer.style.display = 'none';
    }

    function resetAll() {
      selectedImage = null;
      scanResult = null;
      dropzone.style.display = 'flex';
      previewContainer.style.display = 'none';
      processing.style.display = 'none';
      resultsContainer.style.display = 'none';
    }

    // Camera
    cameraBtn.addEventListener('click', async (e) => {
      e.stopPropagation();
      try {
        const image = await captureFromCamera();
        showPreview(image);
      } catch (err) { console.error(err); }
    });

    // Gallery
    galleryBtn.addEventListener('click', async (e) => {
      e.stopPropagation();
      try {
        const image = await selectFromGallery();
        showPreview(image);
      } catch (err) { console.error(err); }
    });

    // Dropzone click
    dropzone.addEventListener('click', async () => {
      try {
        const image = await selectFromGallery();
        showPreview(image);
      } catch (err) { console.error(err); }
    });

    // Drag-drop
    dropzone.addEventListener('dragover', (e) => { e.preventDefault(); dropzone.classList.add('dragover'); });
    dropzone.addEventListener('dragleave', () => dropzone.classList.remove('dragover'));
    dropzone.addEventListener('drop', async (e) => {
      dropzone.classList.remove('dragover');
      try {
        const image = await handleDrop(e);
        showPreview(image);
      } catch (err) { console.error(err); }
    });

    // Retake
    retakeBtn.addEventListener('click', resetAll);

    // Scan button — the main flow
    scanBtn.addEventListener('click', async () => {
      if (!selectedImage) return;

      // Show processing
      previewContainer.style.display = 'none';
      processing.style.display = 'block';
      progressFill.style.width = '0%';
      processingStatus.textContent = 'Đang nhận dạng văn bản...';

      try {
        // Step 1: OCR
        const ocrResult = await extractText(selectedImage, (progress) => {
          progressFill.style.width = `${Math.round(progress * 60)}%`;
        });

        const rawOCR = element.querySelector('#raw-ocr');
        rawOCR.textContent = ocrResult.text;

        const ocrConfidence = element.querySelector('#ocr-confidence');
        ocrConfidence.textContent = `Độ chính xác: ${Math.round(ocrResult.confidence)}%`;

        // Step 2: AI Analysis (if available)
        progressFill.style.width = '65%';
        processingStatus.textContent = 'AI đang phân tích hoá đơn...';

        const aiAvailable = await isAIAvailable();
        let result;

        if (aiAvailable && ocrResult.text.length > 5) {
          try {
            result = await analyzeReceipt(ocrResult.text);
            progressFill.style.width = '100%';
          } catch {
            // AI failed, use basic parsing
            result = basicParse(ocrResult.text);
          }
        } else {
          result = basicParse(ocrResult.text);
        }

        scanResult = result;

        // Show results
        showResults(result);

      } catch (err) {
        console.error('Scan error:', err);
        processing.style.display = 'none';
        showPreview(selectedImage);
        showToast('❌ Lỗi khi quét hoá đơn');
      }
    });

    function showResults(result) {
      processing.style.display = 'none';
      resultsContainer.style.display = 'block';

      const resultItems = element.querySelector('#result-items');
      const resultTotal = element.querySelector('#result-total');
      const amountOverride = element.querySelector('#amount-override');

      if (result.items && result.items.length > 0) {
        resultItems.innerHTML = result.items.map(item => `
          <div class="scan-result__item">
            <span class="scan-result__item-name">${item.name}</span>
            <span class="scan-result__item-price">${formatVND(item.price)}</span>
          </div>
        `).join('');
      } else {
        resultItems.innerHTML = `
          <div class="scan-result__item">
            <span class="scan-result__item-name" style="color: var(--color-ink-muted-48);">
              ${result.description || 'Không nhận dạng được chi tiết'}
            </span>
          </div>
        `;
      }

      resultTotal.textContent = formatVND(result.total);
      amountOverride.value = result.total;

      // Set category
      const catItems = element.querySelectorAll('.category-selector__item');
      catItems.forEach(item => {
        item.classList.toggle('selected', item.dataset.category === result.category);
      });
    }

    // Category selector
    element.querySelectorAll('.category-selector__item').forEach(item => {
      item.addEventListener('click', () => {
        element.querySelectorAll('.category-selector__item').forEach(i => i.classList.remove('selected'));
        item.classList.add('selected');
        if (scanResult) scanResult.category = item.dataset.category;
      });
    });

    // Save
    const saveBtn = element.querySelector('#save-btn');
    saveBtn.addEventListener('click', async () => {
      if (!selectedImage || !scanResult) return;

      const amountOverride = element.querySelector('#amount-override');
      const selectedCat = element.querySelector('.category-selector__item.selected');

      saveBtn.disabled = true;
      saveBtn.textContent = 'Đang lưu...';

      try {
        await addExpense({
          image: selectedImage,
          amount: parseInt(amountOverride.value) || scanResult.total,
          category: selectedCat?.dataset.category || scanResult.category,
          description: scanResult.description || 'Hoá đơn',
          date: new Date().toISOString(),
          aiExtracted: true,
          items: scanResult.items || []
        });

        showToast('✅ Đã lưu hoá đơn');
        navigateTo('dashboard');
      } catch (err) {
        console.error('Save error:', err);
        saveBtn.disabled = false;
        saveBtn.textContent = '✅ Xác nhận và lưu';
        showToast('❌ Lỗi khi lưu');
      }
    });
  }

  return { element, setup };
}

/**
 * Basic text parsing fallback when AI is not available
 */
function basicParse(text) {
  const numbers = text.match(/[\d.,]+/g) || [];
  const amounts = numbers
    .map(n => parseInt(n.replace(/[.,]/g, '')))
    .filter(n => n >= 1000 && n < 100000000);

  const total = amounts.length > 0 ? Math.max(...amounts) : 0;

  return {
    items: [],
    total,
    category: 'shopping',
    description: text.slice(0, 100),
    raw: text
  };
}

function showToast(message) {
  let toast = document.querySelector('.toast');
  if (!toast) {
    toast = document.createElement('div');
    toast.className = 'toast';
    document.body.appendChild(toast);
  }
  toast.textContent = message;
  toast.classList.add('show');
  setTimeout(() => toast.classList.remove('show'), 2500);
}
