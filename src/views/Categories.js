/* ============================================================
   MDaily — Categories View
   Category breakdown with stats and visual bars
   ============================================================ */

import { getCategoryBreakdown, getCurrentMonthTotal, getExpensesByCategory } from '../services/db.js';
import { formatVND, getCurrentMonthName, formatRelativeDate } from '../utils/format.js';
import { getAllCategories, getCategory } from '../utils/categories.js';

export default async function CategoriesView() {
  const element = document.createElement('div');
  element.className = 'view';

  // Load data
  const [breakdown, monthTotal] = await Promise.all([
    getCategoryBreakdown(),
    getCurrentMonthTotal()
  ]);

  const maxCategoryTotal = Math.max(...Object.values(breakdown).map(b => b.total), 1);

  element.innerHTML = `
    <div class="view-header">
      <h1 class="view-header__title" style="font-size: 28px;">Danh mục</h1>
      <p class="text-caption" style="color: var(--color-ink-muted-48); margin-top: 4px;">${getCurrentMonthName()}</p>
    </div>

    <!-- Total Overview -->
    <div style="padding: 0 var(--space-md); margin-bottom: var(--space-lg);">
      <div class="card" style="text-align: center;">
        <p class="text-caption" style="color: var(--color-ink-muted-48);">Tổng chi tiêu tháng này</p>
        <p class="text-display-lg" style="font-size: 32px; margin-top: 4px;">${formatVND(monthTotal)}</p>

        <!-- Visual Pie-like bar -->
        <div style="display: flex; height: 8px; border-radius: var(--rounded-pill); overflow: hidden; margin-top: var(--space-md); gap: 2px;">
          ${Object.entries(breakdown).map(([key, data]) => {
            const pct = monthTotal > 0 ? (data.total / monthTotal * 100) : 0;
            const cat = getCategory(key);
            return pct > 0 ? `<div style="width: ${pct}%; background: ${cat.color}; border-radius: var(--rounded-pill);"></div>` : '';
          }).join('')}
          ${monthTotal === 0 ? '<div style="width: 100%; background: var(--color-hairline);"></div>' : ''}
        </div>

        <!-- Legend -->
        <div style="display: flex; justify-content: center; gap: var(--space-md); margin-top: var(--space-sm); flex-wrap: wrap;">
          ${Object.entries(breakdown).map(([key, data]) => {
            const cat = getCategory(key);
            const pct = monthTotal > 0 ? (data.total / monthTotal * 100).toFixed(0) : 0;
            return `
              <span class="text-fine-print" style="display: flex; align-items: center; gap: 4px;">
                <span style="width: 8px; height: 8px; border-radius: 50%; background: ${cat.color};"></span>
                ${cat.name} ${pct}%
              </span>
            `;
          }).join('')}
        </div>
      </div>
    </div>

    <!-- Category Stats List -->
    <div class="section-header">
      <h2 class="section-header__title">Chi tiết danh mục</h2>
    </div>

    <div class="category-stats" style="padding: 0 var(--space-md);">
      ${getAllCategories().map(cat => {
        const data = breakdown[cat.key] || { total: 0, count: 0 };
        const barWidth = maxCategoryTotal > 0 ? (data.total / maxCategoryTotal * 100) : 0;

        return `
          <div class="category-stat" data-category="${cat.key}">
            <div class="category-stat__icon category-stat__icon--${cat.key}">
              ${cat.icon}
            </div>
            <div class="category-stat__info">
              <div class="category-stat__name">${cat.name}</div>
              <div class="category-stat__count">${data.count} giao dịch</div>
              <div class="category-stat__bar">
                <div class="category-stat__bar-fill category-stat__bar-fill--${cat.key}" style="width: ${barWidth}%;"></div>
              </div>
            </div>
            <div class="category-stat__amount">${formatVND(data.total)}</div>
          </div>
        `;
      }).join('')}
    </div>

    <!-- Recent by category (expandable) -->
    <div id="category-detail" style="padding: var(--space-md);"></div>
  `;

  function setup() {
    // Click on category to show recent expenses
    element.querySelectorAll('.category-stat').forEach(stat => {
      stat.style.cursor = 'pointer';
      stat.addEventListener('click', async () => {
        const key = stat.dataset.category;
        const detailEl = element.querySelector('#category-detail');
        const cat = getCategory(key);

        // Toggle
        if (detailEl.dataset.active === key) {
          detailEl.innerHTML = '';
          detailEl.dataset.active = '';
          element.querySelectorAll('.category-stat').forEach(s => s.style.opacity = '1');
          return;
        }

        // Highlight selected
        element.querySelectorAll('.category-stat').forEach(s => {
          s.style.opacity = s.dataset.category === key ? '1' : '0.5';
        });

        detailEl.dataset.active = key;
        const expenses = await getExpensesByCategory(key);
        const recent = expenses.slice(0, 5);

        if (recent.length === 0) {
          detailEl.innerHTML = `
            <div class="card" style="text-align: center;">
              <p class="text-caption" style="color: var(--color-ink-muted-48);">
                Chưa có chi tiêu nào trong danh mục ${cat.name}
              </p>
            </div>
          `;
        } else {
          detailEl.innerHTML = `
            <div class="card">
              <p class="text-caption-strong" style="margin-bottom: var(--space-sm);">${cat.icon} ${cat.name} gần đây</p>
              ${recent.map(e => `
                <div style="display: flex; align-items: center; gap: var(--space-sm); padding: var(--space-xs) 0; border-bottom: 1px solid var(--color-divider-soft);">
                  <img src="${e.image}" style="width: 40px; height: 40px; border-radius: var(--rounded-sm); object-fit: cover;" alt="">
                  <div style="flex: 1;">
                    <div class="text-caption" style="font-weight: 600;">${formatVND(e.amount)}</div>
                    <div class="text-fine-print" style="color: var(--color-ink-muted-48);">${formatRelativeDate(e.createdAt)}</div>
                  </div>
                </div>
              `).join('')}
            </div>
          `;
        }
      });
    });

    // Animate bars on load
    setTimeout(() => {
      element.querySelectorAll('.category-stat__bar-fill').forEach(bar => {
        bar.style.transition = 'width 0.8s cubic-bezier(0.25, 0.1, 0.25, 1)';
      });
    }, 100);
  }

  return { element, setup };
}
