/* ============================================================
   MDaily — OCR Service (Tesseract.js)
   Client-side OCR for receipt text extraction
   ============================================================ */

import { createWorker } from 'tesseract.js';

let worker = null;

/**
 * Initialize Tesseract worker
 * @param {Function} onProgress - Progress callback (0-1)
 */
async function initWorker(onProgress) {
  if (worker) return worker;

  worker = await createWorker('vie+eng', 1, {
    logger: (m) => {
      if (m.status === 'recognizing text' && onProgress) {
        onProgress(m.progress);
      }
    }
  });

  return worker;
}

/**
 * Extract text from an image using OCR
 * @param {string|Blob|File} image - Image source (data URL, Blob, or File)
 * @param {Function} onProgress - Progress callback (0-1)
 * @returns {Promise<{text: string, confidence: number}>}
 */
export async function extractText(image, onProgress) {
  try {
    const w = await initWorker(onProgress);

    // If image is a Blob/File, convert to data URL
    let imageSource = image;
    if (image instanceof Blob) {
      imageSource = await blobToDataURL(image);
    }

    const { data } = await w.recognize(imageSource);

    return {
      text: data.text.trim(),
      confidence: data.confidence
    };
  } catch (error) {
    console.error('OCR Error:', error);
    throw new Error('Không thể nhận dạng văn bản từ ảnh');
  }
}

/**
 * Convert Blob to data URL
 * @param {Blob} blob
 * @returns {Promise<string>}
 */
function blobToDataURL(blob) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result);
    reader.onerror = reject;
    reader.readAsDataURL(blob);
  });
}

/**
 * Terminate the worker to free resources
 */
export async function terminateOCR() {
  if (worker) {
    await worker.terminate();
    worker = null;
  }
}
