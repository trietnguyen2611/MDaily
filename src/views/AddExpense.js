/* ============================================================
   MDaily — Add Expense View
   Capture/import photo + manual price entry
   ============================================================ */

import { captureFromCamera, selectFromGallery, handleDrop } from '../services/camera.js';
import { addExpense } from '../services/db.js';
import { getAllCategories } from '../utils/categories.js';
import { navigateTo } from '../router.js';

export default async function AddExpenseView() {
  const element = document.createElement('div');
  element.className = 'view';

  let selectedImage = null;
  let selectedCategory = 'shopping';

  const categories = getAllCategories();

  element.innerHTML = `
    <div class="view-header" style="padding-bottom: 0;">
      <h1 class="view-header__title" style="font-size: 28px;">Thêm chi tiêu</h1>
      <p class="text-caption" style="color: var(--color-ink-muted-48); margin-top: 4px;">Chụp ảnh hoặc import ảnh đồ vật</p>
    </div>

    <!-- Image Capture Area -->
    <div style="padding: 0 var(--space-md);">
      <div class="image-capture" id="image-capture">
        <div class="image-capture__dropzone" id="dropzone">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
            <path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z"/>
            <circle cx="12" cy="13" r="4"/>
          </svg>
          <div style="text-align: center;">
            <p class="text-body-strong" style="color: var(--color-body-on-dark);">Chụp ảnh hoặc kéo thả</p>
            <p class="text-caption" style="color: var(--color-body-muted); margin-top: 4px;">Hỗ trợ JPG, PNG, HEIC</p>
          </div>
          <div style="display: flex; gap: 8px;">
            <button class="btn-primary btn-sm" id="camera-btn">
              📷 Chụp ảnh
            </button>
            <button class="btn-secondary btn-sm" style="color: var(--color-on-dark); border-color: rgba(255,255,255,0.3);" id="gallery-btn">
              🖼️ Chọn ảnh
            </button>
          </div>
        </div>

        <!-- Preview (hidden by default) -->
        <div id="preview-container" style="display: none;">
          <img class="image-capture__preview" id="preview-image" src="" alt="Preview">
          <div class="image-capture__actions">
            <button class="btn-icon" id="retake-btn" title="Chọn lại">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M1 4v6h6M23 20v-6h-6"/>
                <path d="M20.49 9A9 9 0 0 0 5.64 5.64L1 10m22 4l-4.64 4.36A9 9 0 0 1 3.51 15"/>
              </svg>
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Amount Input -->
    <div style="padding: var(--space-lg) var(--space-md) 0;">
      <div class="form-group">
        <label class="form-label">Số tiền (VNĐ)</label>
        <input type="number" class="form-input form-input--amount" id="amount-input"
               placeholder="0" inputmode="numeric" min="0">
      </div>

      <!-- Quick Amounts -->
      <div style="display: flex; gap: 8px; flex-wrap: wrap; margin-bottom: var(--space-lg);">
        <button class="btn-pearl quick-amount" data-amount="20000">20K</button>
        <button class="btn-pearl quick-amount" data-amount="50000">50K</button>
        <button class="btn-pearl quick-amount" data-amount="100000">100K</button>
        <button class="btn-pearl quick-amount" data-amount="200000">200K</button>
        <button class="btn-pearl quick-amount" data-amount="500000">500K</button>
      </div>

      <!-- Category Selector -->
      <div class="form-group">
        <label class="form-label">Danh mục</label>
        <div class="category-selector" id="category-selector">
          ${categories.map(cat => `
            <div class="category-selector__item ${cat.key === selectedCategory ? 'selected' : ''}"
                 data-category="${cat.key}">
              <span class="category-selector__icon">${cat.icon}</span>
              <span class="category-selector__name">${cat.name}</span>
            </div>
          `).join('')}
        </div>
      </div>

      <!-- Description -->
      <div class="form-group">
        <label class="form-label">Ghi chú (tuỳ chọn)</label>
        <input type="text" class="form-input" id="description-input"
               placeholder="Mô tả chi tiêu...">
      </div>

      <!-- Save Button -->
      <button class="btn-primary" style="width: 100%; padding: 14px;" id="save-btn" disabled>
        Lưu chi tiêu
      </button>
    </div>
  `;

  function setup() {
    const dropzone = element.querySelector('#dropzone');
    const previewContainer = element.querySelector('#preview-container');
    const previewImage = element.querySelector('#preview-image');
    const cameraBtn = element.querySelector('#camera-btn');
    const galleryBtn = element.querySelector('#gallery-btn');
    const retakeBtn = element.querySelector('#retake-btn');
    const amountInput = element.querySelector('#amount-input');
    const descInput = element.querySelector('#description-input');
    const saveBtn = element.querySelector('#save-btn');

    // Show preview
    function showPreview(imageDataUrl) {
      selectedImage = imageDataUrl;
      previewImage.src = imageDataUrl;
      dropzone.style.display = 'none';
      previewContainer.style.display = 'block';
      updateSaveButton();
    }

    // Reset to dropzone
    function resetImage() {
      selectedImage = null;
      dropzone.style.display = 'flex';
      previewContainer.style.display = 'none';
      updateSaveButton();
    }

    // Update save button state
    function updateSaveButton() {
      const hasImage = !!selectedImage;
      const hasAmount = amountInput.value && parseInt(amountInput.value) > 0;
      saveBtn.disabled = !(hasImage && hasAmount);
    }

    // Camera button
    cameraBtn.addEventListener('click', async (e) => {
      e.stopPropagation();
      try {
        const image = await captureFromCamera();
        showPreview(image);
      } catch (err) {
        console.error(err);
      }
    });

    // Gallery button
    galleryBtn.addEventListener('click', async (e) => {
      e.stopPropagation();
      try {
        const image = await selectFromGallery();
        showPreview(image);
      } catch (err) {
        console.error(err);
      }
    });

    // Dropzone click
    dropzone.addEventListener('click', async () => {
      try {
        const image = await selectFromGallery();
        showPreview(image);
      } catch (err) {
        console.error(err);
      }
    });

    // Drag and drop
    dropzone.addEventListener('dragover', (e) => {
      e.preventDefault();
      dropzone.classList.add('dragover');
    });

    dropzone.addEventListener('dragleave', () => {
      dropzone.classList.remove('dragover');
    });

    dropzone.addEventListener('drop', async (e) => {
      dropzone.classList.remove('dragover');
      try {
        const image = await handleDrop(e);
        showPreview(image);
      } catch (err) {
        console.error(err);
      }
    });

    // Retake
    retakeBtn.addEventListener('click', resetImage);

    // Amount input
    amountInput.addEventListener('input', updateSaveButton);

    // Quick amounts
    element.querySelectorAll('.quick-amount').forEach(btn => {
      btn.addEventListener('click', () => {
        amountInput.value = btn.dataset.amount;
        element.querySelectorAll('.quick-amount').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        updateSaveButton();
      });
    });

    // Category selector
    element.querySelectorAll('.category-selector__item').forEach(item => {
      item.addEventListener('click', () => {
        element.querySelectorAll('.category-selector__item').forEach(i => i.classList.remove('selected'));
        item.classList.add('selected');
        selectedCategory = item.dataset.category;
      });
    });

    // Save
    saveBtn.addEventListener('click', async () => {
      if (!selectedImage || !amountInput.value) return;

      saveBtn.disabled = true;
      saveBtn.textContent = 'Đang lưu...';

      try {
        await addExpense({
          image: selectedImage,
          amount: parseInt(amountInput.value),
          category: selectedCategory,
          description: descInput.value || '',
          date: new Date().toISOString(),
          aiExtracted: false,
          items: []
        });

        showToast('✅ Đã lưu chi tiêu');
        navigateTo('dashboard');
      } catch (err) {
        console.error('Save error:', err);
        saveBtn.disabled = false;
        saveBtn.textContent = 'Lưu chi tiêu';
        showToast('❌ Lỗi khi lưu');
      }
    });
  }

  return { element, setup };
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
