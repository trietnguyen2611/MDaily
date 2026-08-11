/* ============================================================
   MDaily — App Bootstrap
   Main entry point
   ============================================================ */

import './styles/design-tokens.css';
import './styles/global.css';
import './styles/components.css';
import './styles/responsive.css';

import { registerRoute, initRouter, navigateTo } from './router.js';
import DashboardView from './views/Dashboard.js';
import AddExpenseView from './views/AddExpense.js';
import ScanReceiptView from './views/ScanReceipt.js';
import ChatbotView from './views/Chatbot.js';
import CategoriesView from './views/Categories.js';

// SVG Icons
const icons = {
  dashboard: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/></svg>`,
  scan: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="2" width="20" height="20" rx="2"/><path d="M7 2v20M17 2v20M2 12h20M2 7h5M2 17h5M17 7h5M17 17h5"/></svg>`,
  add: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>`,
  chat: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>`,
  categories: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="8" y1="6" x2="21" y2="6"/><line x1="8" y1="12" x2="21" y2="12"/><line x1="8" y1="18" x2="21" y2="18"/><line x1="3" y1="6" x2="3.01" y2="6"/><line x1="3" y1="12" x2="3.01" y2="12"/><line x1="3" y1="18" x2="3.01" y2="18"/></svg>`
};

function init() {
  const app = document.getElementById('app');

  // Create app structure
  app.innerHTML = `
    <div id="app-content"></div>
    <nav class="floating-nav" id="floating-nav">
      <button class="floating-nav__item" data-route="dashboard" title="Trang chủ">
        ${icons.dashboard}
        <span class="floating-nav__item-label">Trang chủ</span>
      </button>
      <button class="floating-nav__item" data-route="scan" title="Quét hoá đơn">
        ${icons.scan}
        <span class="floating-nav__item-label">Quét</span>
      </button>
      <button class="floating-nav__item floating-nav__item--add" data-route="add" title="Thêm chi tiêu">
        ${icons.add}
      </button>
      <button class="floating-nav__item" data-route="chat" title="AI Chat">
        ${icons.chat}
        <span class="floating-nav__item-label">AI Chat</span>
      </button>
      <button class="floating-nav__item" data-route="categories" title="Danh mục">
        ${icons.categories}
        <span class="floating-nav__item-label">Danh mục</span>
      </button>
    </nav>
  `;

  // Register routes
  registerRoute('dashboard', DashboardView);
  registerRoute('add', AddExpenseView);
  registerRoute('scan', ScanReceiptView);
  registerRoute('chat', ChatbotView);
  registerRoute('categories', CategoriesView);

  // Init router
  const appContent = document.getElementById('app-content');
  initRouter(appContent);

  // Nav click handlers
  document.querySelectorAll('.floating-nav__item').forEach(item => {
    item.addEventListener('click', () => {
      const route = item.dataset.route;
      if (route) navigateTo(route);
    });
  });

  // Set default route
  if (!window.location.hash) {
    navigateTo('dashboard');
  }
}

// Initialize when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', init);
} else {
  init();
}
