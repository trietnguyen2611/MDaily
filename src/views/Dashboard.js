/* ============================================================
   MDaily — Dashboard View
   Photo grid of expenses + stats summary
   ============================================================ */

import { getAllExpenses, getCurrentMonthTotal, getPreviousMonthTotal, getCategoryBreakdown } from '../services/db.js';
import { formatVND, formatRelativeDate, getGreeting, getCurrentMonthName, formatShort } from '../utils/format.js';
import { getCategory } from '../utils/categories.js';
import { navigateTo } from '../router.js';

export default async function DashboardView() {
  const element = document.createElement('div');
  element.className = 'view';

  // Load data
  const [expenses, currentTotal, prevTotal, breakdown] = await Promise.all([
    getAllExpenses(),
    getCurrentMonthTotal(),
    getPreviousMonthTotal(),
    getCategoryBreakdown()
  ]);

  const diff = prevTotal > 0 ? ((currentTotal - prevTotal) / prevTotal * 100).toFixed(0) : 0;
  const isUp = diff > 0;

  element.innerHTML = `
    <div class="view-header">
      <p class="view-header__greeting">${getGreeting()}</p>
      <h1 class="view-header__title">Chi tiêu ${getCurrentMonthName()}</h1>
      <div class="view-header__total">${formatVND(currentTotal)}</div>
      ${prevTotal > 0 ? `
        <p class="stats-bar__delta ${isUp ? 'stats-bar__delta--up' : 'stats-bar__delta--down'}" style="text-align:center; margin-top: 4px;">
          ${isUp ? '↑' : '↓'} ${Math.abs(diff)}% so với tháng trước
        </p>
      ` : ''}
    </div>

    <!-- Category Stats Cards -->
    <div class="stats-bar" id="stats-bar">
      ${Object.entries(breakdown).map(([key, data]) => {
        const cat = getCategory(key);
        return `
          <div class="stats-bar__card" data-category="${key}">
            <div class="stats-bar__label">${cat.icon} ${cat.name}</div>
            <div class="stats-bar__value" style="font-size: 20px;">${formatShort(data.total)}</div>
            <div class="text-fine-print" style="color: var(--color-ink-muted-48); margin-top: 2px;">${data.count} giao dịch</div>
          </div>
        `;
      }).join('')}
    </div>

    <!-- Filter Pills -->
    <div class="filter-pills" id="filter-pills">
      <button class="filter-pill active" data-filter="all">Tất cả</button>
      <button class="filter-pill" data-filter="bills">📄 Hoá đơn</button>
      <button class="filter-pill" data-filter="shopping">🛍️ Mua sắm</button>
      <button class="filter-pill" data-filter="food">🍜 Ăn uống</button>
      <button class="filter-pill" data-filter="transport">🚗 Di chuyển</button>
    </div>

    <!-- Section Header -->
    <div class="section-header">
      <h2 class="section-header__title">Lịch sử chi tiêu</h2>
      <span class="text-caption" style="color: var(--color-ink-muted-48);">${expenses.length} mục</span>
    </div>

    <!-- Expense Grid -->
    ${expenses.length > 0 ? `
      <div class="expense-grid" id="expense-grid">
        ${renderExpenseCards(expenses)}
      </div>
    ` : `
      <div class="empty-state">
        <div class="empty-state__icon">📸</div>
        <h3 class="empty-state__title">Chưa có chi tiêu nào</h3>
        <p class="empty-state__desc">Chụp ảnh hoặc import ảnh để bắt đầu ghi nhận chi tiêu</p>
        <button class="btn-primary" style="margin-top: 24px;" id="empty-add-btn">Thêm chi tiêu</button>
      </div>
    `}

    <!-- Expense Detail Modal -->
    <div class="modal-overlay" id="expense-modal">
      <div class="modal">
        <img class="modal__image" id="modal-image" src="" alt="">
        <div class="modal__body" id="modal-body"></div>
      </div>
    </div>
  `;

  function setup() {
    // Filter pills
    const filterPills = element.querySelectorAll('.filter-pill');
    filterPills.forEach(pill => {
      pill.addEventListener('click', () => {
        filterPills.forEach(p => p.classList.remove('active'));
        pill.classList.add('active');

        const filter = pill.dataset.filter;
        const grid = element.querySelector('#expense-grid');
        if (grid) {
          const filtered = filter === 'all' ? expenses : expenses.filter(e => e.category === filter);
          grid.innerHTML = renderExpenseCards(filtered);
          bindCardClicks();
        }
      });
    });

    // Expense card clicks
    bindCardClicks();

    // Empty state add button
    const emptyAddBtn = element.querySelector('#empty-add-btn');
    if (emptyAddBtn) {
      emptyAddBtn.addEventListener('click', () => navigateTo('add'));
    }

    // Modal close
    const modal = element.querySelector('#expense-modal');
    modal.addEventListener('click', (e) => {
      if (e.target === modal) {
        modal.classList.remove('show');
      }
    });
  }

  function bindCardClicks() {
    element.querySelectorAll('.expense-card').forEach(card => {
      card.addEventListener('click', () => {
        const id = parseInt(card.dataset.id);
        const expense = expenses.find(e => e.id === id);
        if (expense) showExpenseDetail(expense);
      });
    });
  }

  function showExpenseDetail(expense) {
    const modal = element.querySelector('#expense-modal');
    const modalImage = element.querySelector('#modal-image');
    const modalBody = element.querySelector('#modal-body');
    const cat = getCategory(expense.category);

    modalImage.src = expense.image;
    modalBody.innerHTML = `
      <div style="display:flex; align-items:center; justify-content:space-between; margin-bottom: 16px;">
        <div>
          <div class="text-tagline">${formatVND(expense.amount)}</div>
          <div class="text-caption" style="color: var(--color-ink-muted-48);">${formatRelativeDate(expense.createdAt)}</div>
        </div>
        <span class="category-badge category-badge--${expense.category}">${cat.icon} ${cat.name}</span>
      </div>
      ${expense.description ? `<p class="text-body" style="margin-bottom: 16px;">${expense.description}</p>` : ''}
      ${expense.items && expense.items.length > 0 ? `
        <div style="border-top: 1px solid var(--color-hairline); padding-top: 12px;">
          <p class="text-caption-strong" style="margin-bottom: 8px;">Chi tiết hoá đơn</p>
          ${expense.items.map(item => `
            <div style="display:flex; justify-content:space-between; padding: 4px 0;">
              <span class="text-caption">${item.name}</span>
              <span class="text-caption" style="font-weight:600;">${formatVND(item.price)}</span>
            </div>
          `).join('')}
        </div>
      ` : ''}
      <button class="btn-secondary" style="width:100%; margin-top: 16px;" id="modal-delete-btn" data-id="${expense.id}">
        Xoá chi tiêu
      </button>
    `;

    modal.classList.add('show');

    // Delete button
    const deleteBtn = modalBody.querySelector('#modal-delete-btn');
    deleteBtn.addEventListener('click', async () => {
      const { deleteExpense } = await import('../services/db.js');
      await deleteExpense(expense.id);
      modal.classList.remove('show');
      // Refresh view
      navigateTo('dashboard');
    });
  }

  return { element, setup };
}

function renderExpenseCards(expenses) {
  if (expenses.length === 0) {
    return `
      <div class="empty-state" style="grid-column: 1/-1;">
        <div class="empty-state__icon">🔍</div>
        <h3 class="empty-state__title">Không có kết quả</h3>
        <p class="empty-state__desc">Không tìm thấy chi tiêu nào trong danh mục này</p>
      </div>
    `;
  }

  return expenses.map(expense => {
    const cat = getCategory(expense.category);
    return `
      <div class="expense-card" data-id="${expense.id}">
        <img class="expense-card__image" src="${expense.image}" alt="${expense.description || 'Chi tiêu'}" loading="lazy">
        <div class="expense-card__overlay">
          <div>
            <span class="category-badge category-badge--${expense.category}" style="margin-bottom:4px;">${cat.icon} ${cat.name}</span>
            <div class="expense-card__amount">${formatVND(expense.amount)}</div>
            <div class="expense-card__date">${formatRelativeDate(expense.createdAt)}</div>
          </div>
        </div>
      </div>
    `;
  }).join('');
}
