/**
 * Camera & Image File Import Service
 * Supports device webcam live capture and local image file selection.
 */

export const cameraService = {
  /**
   * Read file input to Data URL with canvas compression
   */
  readFileAsDataURL(file) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = (e) => {
        const img = new Image();
        img.onload = () => {
          const canvas = document.createElement('canvas');
          let width = img.width;
          let height = img.height;
          const maxDim = 1000;

          if (width > maxDim || height > maxDim) {
            if (width > height) {
              height = Math.round((height * maxDim) / width);
              width = maxDim;
            } else {
              width = Math.round((width * maxDim) / height);
              height = maxDim;
            }
          }

          canvas.width = width;
          canvas.height = height;
          const ctx = canvas.getContext('2d');
          ctx.drawImage(img, 0, 0, width, height);
          resolve(canvas.toDataURL('image/jpeg', 0.85));
        };
        img.src = e.target.result;
      };
      reader.onerror = (err) => reject(err);
      reader.readAsDataURL(file);
    });
  },

  /**
   * Start webcam video stream on video element
   */
  async startCamera(videoElement) {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: 'environment', width: { ideal: 1280 }, height: { ideal: 720 } }
      });
      videoElement.srcObject = stream;
      await videoElement.play();
      return stream;
    } catch (err) {
      console.warn('Camera stream not accessible:', err);
      return null;
    }
  },

  /**
   * Capture photo frame from video element
   */
  captureFromVideo(videoElement) {
    const canvas = document.createElement('canvas');
    canvas.width = videoElement.videoWidth || 640;
    canvas.height = videoElement.videoHeight || 480;
    const ctx = canvas.getContext('2d');
    ctx.drawImage(videoElement, 0, 0, canvas.width, canvas.height);
    return canvas.toDataURL('image/jpeg', 0.85);
  },

  /**
   * Stop webcam video stream
   */
  stopCamera(stream) {
    if (stream && stream.getTracks) {
      stream.getTracks().forEach((track) => track.stop());
    }
  }
};
