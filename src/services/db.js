/**
 * Database & Storage Service for MDaily
 * Multi-user support, local persistence, real-time cross-device sync.
 */

const SYNC_CHANNEL_NAME = 'mdaily_realtime_sync';
const syncChannel = typeof BroadcastChannel !== 'undefined' ? new BroadcastChannel(SYNC_CHANNEL_NAME) : null;

// Initial sample seed data for new accounts
const SAMPLE_EXPENSES = [
  {
    id: 'exp_1',
    userEmail: 'demo@apple.com',
    title: 'Cà phê Highland & Bánh mì',
    amount: 65000,
    category: 'Ăn uống',
    date: new Date(Date.now() - 3600000 * 3).toISOString(),
    photo: 'https://images.unsplash.com/photo-1509042239860-f550ce710b93?auto=format&fit=crop&w=600&q=80',
    type: 'object',
    device: 'iPhone 15 Pro',
    note: 'Chụp ly cà phê sáng',
    merchant: 'Highlands Coffee'
  },
  {
    id: 'exp_2',
    userEmail: 'demo@apple.com',
    title: 'Hoá đơn siêu thị WinMart',
    amount: 348000,
    category: 'Hoá đơn',
    date: new Date(Date.now() - 3600000 * 24).toISOString(),
    photo: 'https://images.unsplash.com/photo-1554415707-6e8cfc93fe23?auto=format&fit=crop&w=600&q=80',
    type: 'receipt',
    device: 'MacBook Pro Intel',
    note: 'Tự động quét hoá đơn bằng AI',
    merchant: 'WinMart Vincom'
  },
  {
    id: 'exp_3',
    userEmail: 'demo@apple.com',
    title: 'Giày Sneaker Nike Air',
    amount: 1850000,
    category: 'Mua sắm',
    date: new Date(Date.now() - 3600000 * 48).toISOString(),
    photo: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=600&q=80',
    type: 'object',
    device: 'MacBook Pro Intel',
    note: 'Chụp sản phẩm mới mua',
    merchant: 'Nike Store'
  },
  {
    id: 'exp_4',
    userEmail: 'demo@apple.com',
    title: 'Chuyến xe GrabCar đến văn phòng',
    amount: 82000,
    category: 'Di chuyển',
    date: new Date(Date.now() - 3600000 * 72).toISOString(),
    photo: 'https://images.unsplash.com/photo-1449965408869-eaa3f722e40d?auto=format&fit=crop&w=600&q=80',
    type: 'receipt',
    device: 'iPhone 15 Pro',
    note: 'Cuống vé / e-receipt Grab',
    merchant: 'Grab Vietnam'
  }
];

class DBService {
  constructor() {
    this.listeners = new Set();
    this.init();

    if (syncChannel) {
      syncChannel.onmessage = (event) => {
        if (event.data && event.data.type === 'DATA_UPDATED') {
          this.notifyListeners();
        }
      };
    }

    window.addEventListener('storage', () => {
      this.notifyListeners();
    });
  }

  init() {
    if (!localStorage.getItem('mdaily_users')) {
      const defaultUser = {
        name: 'Steve Jobs',
        email: 'demo@apple.com',
        password: '123'
      };
      localStorage.setItem('mdaily_users', JSON.stringify([defaultUser]));
    }

    if (!localStorage.getItem('mdaily_expenses')) {
      localStorage.setItem('mdaily_expenses', JSON.stringify(SAMPLE_EXPENSES));
    }

    if (!localStorage.getItem('mdaily_jan_config')) {
      const defaultConfig = {
        endpoint: 'http://localhost:1337/v1',
        model: 'gemma-2-2b-it',
        autoUseAI: true
      };
      localStorage.setItem('mdaily_jan_config', JSON.stringify(defaultConfig));
    }

    if (!localStorage.getItem('mdaily_current_user')) {
      localStorage.setItem('mdaily_current_user', 'demo@apple.com');
    }
  }

  subscribe(callback) {
    this.listeners.add(callback);
    return () => this.listeners.delete(callback);
  }

  notifyListeners() {
    this.listeners.forEach((cb) => cb());
  }

  broadcastChange() {
    if (syncChannel) {
      syncChannel.postMessage({ type: 'DATA_UPDATED', timestamp: Date.now() });
    }
    this.notifyListeners();
  }

  // User Auth APIs
  getUsers() {
    return JSON.parse(localStorage.getItem('mdaily_users') || '[]');
  }

  saveUser(user) {
    const users = this.getUsers();
    users.push(user);
    localStorage.setItem('mdaily_users', JSON.stringify(users));
    this.broadcastChange();
  }

  getCurrentUserEmail() {
    return localStorage.getItem('mdaily_current_user') || 'demo@apple.com';
  }

  setCurrentUserEmail(email) {
    localStorage.setItem('mdaily_current_user', email);
    this.broadcastChange();
  }

  getCurrentUser() {
    const email = this.getCurrentUserEmail();
    const users = this.getUsers();
    return users.find((u) => u.email === email) || { name: 'Người dùng', email };
  }

  // Expense APIs
  getExpenses(userEmail = null) {
    const targetEmail = userEmail || this.getCurrentUserEmail();
    const all = JSON.parse(localStorage.getItem('mdaily_expenses') || '[]');
    return all.filter((e) => e.userEmail === targetEmail).sort((a, b) => new Date(b.date) - new Date(a.date));
  }

  addExpense(expense) {
    const all = JSON.parse(localStorage.getItem('mdaily_expenses') || '[]');
    const newRecord = {
      id: 'exp_' + Date.now() + '_' + Math.random().toString(36).substr(2, 5),
      userEmail: expense.userEmail || this.getCurrentUserEmail(),
      title: expense.title || 'Chi tiêu mới',
      amount: Number(expense.amount) || 0,
      category: expense.category || 'Hoá đơn',
      date: expense.date || new Date().toISOString(),
      photo: expense.photo || '',
      type: expense.type || 'object', // 'object' or 'receipt'
      device: expense.device || 'macOS',
      note: expense.note || '',
      merchant: expense.merchant || ''
    };
    all.unshift(newRecord);
    localStorage.setItem('mdaily_expenses', JSON.stringify(all));
    this.broadcastChange();
    return newRecord;
  }

  deleteExpense(id) {
    let all = JSON.parse(localStorage.getItem('mdaily_expenses') || '[]');
    all = all.filter((e) => e.id !== id);
    localStorage.setItem('mdaily_expenses', JSON.stringify(all));
    this.broadcastChange();
  }

  // Jan AI Config APIs
  getJanConfig() {
    return JSON.parse(localStorage.getItem('mdaily_jan_config') || '{}');
  }

  saveJanConfig(config) {
    localStorage.setItem('mdaily_jan_config', JSON.stringify(config));
    this.broadcastChange();
  }
}

export const db = new DBService();
