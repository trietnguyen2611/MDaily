/* ============================================================
   MDaily — Format Utilities
   Currency, date, and number formatting
   ============================================================ */

/**
 * Format a number as Vietnamese currency (VNĐ)
 * @param {number} amount
 * @returns {string}
 */
export function formatVND(amount) {
  if (amount === undefined || amount === null) return '0₫';
  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: 'VND',
    maximumFractionDigits: 0
  }).format(amount);
}

/**
 * Format a number with short notation (K, M)
 * @param {number} amount
 * @returns {string}
 */
export function formatShort(amount) {
  if (amount >= 1000000) {
    return (amount / 1000000).toFixed(1).replace('.0', '') + 'M';
  }
  if (amount >= 1000) {
    return (amount / 1000).toFixed(0) + 'K';
  }
  return amount.toString();
}

/**
 * Format date relative to now
 * @param {string} isoDate
 * @returns {string}
 */
export function formatRelativeDate(isoDate) {
  const date = new Date(isoDate);
  const now = new Date();
  const diff = now - date;
  const seconds = Math.floor(diff / 1000);
  const minutes = Math.floor(seconds / 60);
  const hours = Math.floor(minutes / 60);
  const days = Math.floor(hours / 24);

  if (seconds < 60) return 'Vừa xong';
  if (minutes < 60) return `${minutes} phút trước`;
  if (hours < 24) return `${hours} giờ trước`;
  if (days < 7) return `${days} ngày trước`;

  return date.toLocaleDateString('vi-VN', {
    day: 'numeric',
    month: 'short'
  });
}

/**
 * Format full date
 * @param {string} isoDate
 * @returns {string}
 */
export function formatFullDate(isoDate) {
  return new Date(isoDate).toLocaleDateString('vi-VN', {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
    year: 'numeric'
  });
}

/**
 * Format time
 * @param {string} isoDate
 * @returns {string}
 */
export function formatTime(isoDate) {
  return new Date(isoDate).toLocaleTimeString('vi-VN', {
    hour: '2-digit',
    minute: '2-digit'
  });
}

/**
 * Get greeting based on time of day
 * @returns {string}
 */
export function getGreeting() {
  const hour = new Date().getHours();
  if (hour < 12) return 'Chào buổi sáng';
  if (hour < 18) return 'Chào buổi chiều';
  return 'Chào buổi tối';
}

/**
 * Get current month name in Vietnamese
 * @returns {string}
 */
export function getCurrentMonthName() {
  return new Date().toLocaleDateString('vi-VN', {
    month: 'long',
    year: 'numeric'
  });
}
