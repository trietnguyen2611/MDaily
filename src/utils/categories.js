/* ============================================================
   MDaily — Category Definitions
   ============================================================ */

export const CATEGORIES = {
  bills: {
    key: 'bills',
    name: 'Hoá đơn',
    icon: '📄',
    color: '#ff6b35',
    bgColor: 'rgba(255, 107, 53, 0.12)'
  },
  shopping: {
    key: 'shopping',
    name: 'Mua sắm',
    icon: '🛍️',
    color: '#a855f7',
    bgColor: 'rgba(168, 85, 247, 0.12)'
  },
  food: {
    key: 'food',
    name: 'Ăn uống',
    icon: '🍜',
    color: '#10b981',
    bgColor: 'rgba(16, 185, 129, 0.12)'
  },
  transport: {
    key: 'transport',
    name: 'Di chuyển',
    icon: '🚗',
    color: '#3b82f6',
    bgColor: 'rgba(59, 130, 246, 0.12)'
  }
};

/**
 * Get category info by key
 * @param {string} key
 * @returns {Object}
 */
export function getCategory(key) {
  return CATEGORIES[key] || CATEGORIES.shopping;
}

/**
 * Get all categories as array
 * @returns {Array}
 */
export function getAllCategories() {
  return Object.values(CATEGORIES);
}
