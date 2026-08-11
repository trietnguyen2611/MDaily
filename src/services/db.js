/* ============================================================
   MDaily — IndexedDB Service (via Dexie.js)
   Manages all expense data persistence
   ============================================================ */

import Dexie from 'dexie';

const db = new Dexie('MDaily');

db.version(1).stores({
  expenses: '++id, category, date, amount, createdAt',
  chatHistory: '++id, role, createdAt'
});

/**
 * Save a new expense
 * @param {Object} expense
 * @param {Blob|string} expense.image - Image blob or base64 data URL
 * @param {number} expense.amount - Amount in VNĐ
 * @param {string} expense.category - 'bills' | 'shopping' | 'food' | 'transport'
 * @param {string} expense.description - Optional description
 * @param {string} expense.date - ISO date string
 * @param {boolean} expense.aiExtracted - Whether data was extracted by AI
 * @param {Array} expense.items - Array of items (from receipt scan)
 * @returns {Promise<number>} - The new expense ID
 */
export async function addExpense(expense) {
  return await db.expenses.add({
    ...expense,
    createdAt: new Date().toISOString()
  });
}

/**
 * Get all expenses, newest first
 * @returns {Promise<Array>}
 */
export async function getAllExpenses() {
  return await db.expenses.orderBy('createdAt').reverse().toArray();
}

/**
 * Get expenses filtered by category
 * @param {string} category
 * @returns {Promise<Array>}
 */
export async function getExpensesByCategory(category) {
  return await db.expenses
    .where('category')
    .equals(category)
    .reverse()
    .sortBy('createdAt');
}

/**
 * Get expenses for a specific month
 * @param {number} year
 * @param {number} month - 0-indexed
 * @returns {Promise<Array>}
 */
export async function getExpensesByMonth(year, month) {
  const startDate = new Date(year, month, 1).toISOString();
  const endDate = new Date(year, month + 1, 0, 23, 59, 59).toISOString();

  return await db.expenses
    .where('createdAt')
    .between(startDate, endDate)
    .reverse()
    .sortBy('createdAt');
}

/**
 * Get total spending for current month
 * @returns {Promise<number>}
 */
export async function getCurrentMonthTotal() {
  const now = new Date();
  const expenses = await getExpensesByMonth(now.getFullYear(), now.getMonth());
  return expenses.reduce((sum, e) => sum + (e.amount || 0), 0);
}

/**
 * Get total spending for previous month
 * @returns {Promise<number>}
 */
export async function getPreviousMonthTotal() {
  const now = new Date();
  let year = now.getFullYear();
  let month = now.getMonth() - 1;
  if (month < 0) {
    month = 11;
    year--;
  }
  const expenses = await getExpensesByMonth(year, month);
  return expenses.reduce((sum, e) => sum + (e.amount || 0), 0);
}

/**
 * Get spending breakdown by category for current month
 * @returns {Promise<Object>}
 */
export async function getCategoryBreakdown() {
  const now = new Date();
  const expenses = await getExpensesByMonth(now.getFullYear(), now.getMonth());

  const breakdown = {
    bills: { total: 0, count: 0 },
    shopping: { total: 0, count: 0 },
    food: { total: 0, count: 0 },
    transport: { total: 0, count: 0 }
  };

  expenses.forEach(e => {
    if (breakdown[e.category]) {
      breakdown[e.category].total += e.amount || 0;
      breakdown[e.category].count++;
    }
  });

  return breakdown;
}

/**
 * Get expense context for AI chatbot (summary of spending patterns)
 * @returns {Promise<string>}
 */
export async function getExpenseContext() {
  const now = new Date();
  const currentMonthExpenses = await getExpensesByMonth(now.getFullYear(), now.getMonth());
  const prevMonthTotal = await getPreviousMonthTotal();
  const breakdown = await getCategoryBreakdown();

  const currentTotal = currentMonthExpenses.reduce((sum, e) => sum + (e.amount || 0), 0);
  const monthName = now.toLocaleDateString('vi-VN', { month: 'long', year: 'numeric' });

  let context = `Thông tin chi tiêu của người dùng:\n`;
  context += `- Tháng hiện tại (${monthName}): ${formatVND(currentTotal)}\n`;
  context += `- Tháng trước: ${formatVND(prevMonthTotal)}\n`;
  context += `- Số giao dịch tháng này: ${currentMonthExpenses.length}\n\n`;
  context += `Chi tiết theo danh mục tháng này:\n`;
  context += `- Hoá đơn: ${formatVND(breakdown.bills.total)} (${breakdown.bills.count} giao dịch)\n`;
  context += `- Mua sắm: ${formatVND(breakdown.shopping.total)} (${breakdown.shopping.count} giao dịch)\n`;
  context += `- Ăn uống: ${formatVND(breakdown.food.total)} (${breakdown.food.count} giao dịch)\n`;
  context += `- Di chuyển: ${formatVND(breakdown.transport.total)} (${breakdown.transport.count} giao dịch)\n`;

  if (currentMonthExpenses.length > 0) {
    context += `\n5 chi tiêu gần nhất:\n`;
    const recent = currentMonthExpenses.slice(0, 5);
    recent.forEach(e => {
      const date = new Date(e.createdAt).toLocaleDateString('vi-VN');
      context += `- ${date}: ${formatVND(e.amount)} (${getCategoryName(e.category)}) ${e.description || ''}\n`;
    });
  }

  return context;
}

/**
 * Delete an expense by ID
 * @param {number} id
 */
export async function deleteExpense(id) {
  await db.expenses.delete(id);
}

/**
 * Get single expense by ID
 * @param {number} id
 * @returns {Promise<Object>}
 */
export async function getExpense(id) {
  return await db.expenses.get(id);
}

/**
 * Save chat message
 * @param {Object} message - { role: 'user'|'assistant', content: string }
 */
export async function saveChatMessage(message) {
  return await db.chatHistory.add({
    ...message,
    createdAt: new Date().toISOString()
  });
}

/**
 * Get chat history
 * @returns {Promise<Array>}
 */
export async function getChatHistory() {
  return await db.chatHistory.orderBy('createdAt').toArray();
}

/**
 * Clear chat history
 */
export async function clearChatHistory() {
  await db.chatHistory.clear();
}

// Helper functions
function formatVND(amount) {
  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: 'VND'
  }).format(amount);
}

function getCategoryName(key) {
  const names = {
    bills: 'Hoá đơn',
    shopping: 'Mua sắm',
    food: 'Ăn uống',
    transport: 'Di chuyển'
  };
  return names[key] || key;
}

export default db;
