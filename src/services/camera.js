/* ============================================================
   MDaily — Camera Service
   Handles image capture and file upload
   ============================================================ */

/**
 * Capture image from camera
 * @returns {Promise<string>} - Base64 data URL of captured image
 */
export async function captureFromCamera() {
  return new Promise((resolve, reject) => {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = 'image/*';
    input.capture = 'environment'; // Use rear camera on mobile

    input.onchange = async (e) => {
      const file = e.target.files[0];
      if (!file) {
        reject(new Error('Không có ảnh được chọn'));
        return;
      }

      try {
        const dataUrl = await processImage(file);
        resolve(dataUrl);
      } catch (err) {
        reject(err);
      }
    };

    input.click();
  });
}

/**
 * Select image from file system
 * @returns {Promise<string>} - Base64 data URL
 */
export async function selectFromGallery() {
  return new Promise((resolve, reject) => {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = 'image/*';

    input.onchange = async (e) => {
      const file = e.target.files[0];
      if (!file) {
        reject(new Error('Không có ảnh được chọn'));
        return;
      }

      try {
        const dataUrl = await processImage(file);
        resolve(dataUrl);
      } catch (err) {
        reject(err);
      }
    };

    input.click();
  });
}

/**
 * Process and compress an image file
 * @param {File} file
 * @param {number} maxWidth - Maximum width in pixels
 * @param {number} quality - JPEG quality (0-1)
 * @returns {Promise<string>} - Base64 data URL
 */
export async function processImage(file, maxWidth = 1200, quality = 0.85) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();

    reader.onload = (e) => {
      const img = new Image();
      img.onload = () => {
        const canvas = document.createElement('canvas');
        let { width, height } = img;

        // Resize if larger than maxWidth
        if (width > maxWidth) {
          height = (height * maxWidth) / width;
          width = maxWidth;
        }

        canvas.width = width;
        canvas.height = height;

        const ctx = canvas.getContext('2d');
        ctx.drawImage(img, 0, 0, width, height);

        const dataUrl = canvas.toDataURL('image/jpeg', quality);
        resolve(dataUrl);
      };

      img.onerror = () => reject(new Error('Không thể đọc ảnh'));
      img.src = e.target.result;
    };

    reader.onerror = () => reject(new Error('Không thể đọc file'));
    reader.readAsDataURL(file);
  });
}

/**
 * Handle drag-and-drop image
 * @param {DragEvent} event
 * @returns {Promise<string>} - Base64 data URL
 */
export async function handleDrop(event) {
  event.preventDefault();
  const file = event.dataTransfer.files[0];

  if (!file || !file.type.startsWith('image/')) {
    throw new Error('Vui lòng chọn file ảnh');
  }

  return await processImage(file);
}
