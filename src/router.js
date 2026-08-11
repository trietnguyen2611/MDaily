/* ============================================================
   MDaily — SPA Router
   Simple hash-based router for single page app
   ============================================================ */

const routes = {};
let currentView = null;
let appContent = null;

/**
 * Register a route
 * @param {string} path - Route path (e.g., 'dashboard', 'add', 'scan', 'chat', 'categories')
 * @param {Function} viewFactory - Function that returns the view HTML and setup function
 */
export function registerRoute(path, viewFactory) {
  routes[path] = viewFactory;
}

/**
 * Navigate to a route
 * @param {string} path
 */
export function navigateTo(path) {
  window.location.hash = path;
}

/**
 * Get current route
 * @returns {string}
 */
export function getCurrentRoute() {
  return window.location.hash.slice(1) || 'dashboard';
}

/**
 * Initialize the router
 * @param {HTMLElement} container - The app content container
 */
export function initRouter(container) {
  appContent = container;

  const handleRoute = async () => {
    const path = getCurrentRoute();
    const viewFactory = routes[path];

    if (!viewFactory) {
      navigateTo('dashboard');
      return;
    }

    // Clean up current view if needed
    if (currentView && currentView.cleanup) {
      currentView.cleanup();
    }

    // Render the new view
    const view = await viewFactory();
    appContent.innerHTML = '';
    appContent.appendChild(view.element);

    // Run setup after DOM is attached
    if (view.setup) {
      view.setup();
    }

    currentView = view;

    // Update nav active state
    updateNavActive(path);
  };

  window.addEventListener('hashchange', handleRoute);

  // Initial route
  handleRoute();
}

/**
 * Update nav item active states
 * @param {string} activePath
 */
function updateNavActive(activePath) {
  document.querySelectorAll('.floating-nav__item').forEach(item => {
    const itemPath = item.dataset.route;
    if (itemPath === activePath) {
      item.classList.add('active');
    } else {
      item.classList.remove('active');
    }
  });
}
