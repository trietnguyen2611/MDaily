// ExpenseStore.js - Local Storage & Cross-App Synchronization Service

const SYNC_CHANNEL_NAME = 'mdaily_sync_channel';
let broadcastChannel = null;

if (typeof window !== 'undefined' && 'BroadcastChannel' in window) {
  broadcastChannel = new BroadcastChannel(SYNC_CHANNEL_NAME);
}

// Preset Realistic Photos (Crisp SVG Canvas Mockups / Data URLs)
export const MOCK_EXPENSE_PHOTOS = {
  coffee: `data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="600" height="400" viewBox="0 0 600 400"><rect width="600" height="400" fill="%23fdf6ec"/><path d="M0 280 C150 250, 450 310, 600 280 L600 400 L0 400 Z" fill="%23e8d5c4"/><circle cx="300" cy="200" r="90" fill="%236f4e37" stroke="%23ffffff" stroke-width="8"/><ellipse cx="300" cy="200" rx="70" ry="70" fill="%234a3424"/><ellipse cx="280" cy="180" rx="35" ry="35" fill="%238c6239" opacity="0.6"/><text x="300" y="340" font-family="system-ui" font-size="20" font-weight="600" fill="%234a3424" text-anchor="middle">HIGHLANDS COFFEE &amp; CAKE</text></svg>`,
  
  electricity: `data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="600" height="400" viewBox="0 0 600 400"><rect width="600" height="400" fill="%23f0f4f8"/><rect x="120" y="40" width="360" height="320" rx="16" fill="%23ffffff" stroke="%23d2d2d7" stroke-width="2"/><text x="150" y="85" font-family="system-ui" font-size="20" font-weight="700" fill="%231d1d1f">EVN HÓA ĐƠN TIỀN ĐIỆN</text><text x="150" y="115" font-family="system-ui" font-size="13" fill="%237a7a7a">Kỳ: Tháng 08/2026</text><line x1="150" y1="135" x2="450" y2="135" stroke="%23e0e0e0" stroke-dasharray="4 4"/><text x="150" y="170" font-family="system-ui" font-size="14" fill="%231d1d1f">Điện tiêu thụ (kWh): 342 kWh</text><text x="150" y="200" font-family="system-ui" font-size="14" fill="%231d1d1f">Thuế VAT (8%): 92.592 đ</text><text x="150" y="260" font-family="system-ui" font-size="18" font-weight="700" fill="%230066cc">TỔNG CỘNG: 1.250.000 đ</text><rect x="150" y="290" width="100" height="35" rx="6" fill="%2334c759"/><text x="200" y="313" font-family="system-ui" font-size="13" font-weight="600" fill="%23ffffff" text-anchor="middle">ĐÃ THANH TOÁN</text></svg>`,
  
  airpods: `data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="600" height="400" viewBox="0 0 600 400"><rect width="600" height="400" fill="%23272729"/><rect x="180" y="100" width="240" height="180" rx="30" fill="%23ffffff" shadow="0 10 30 rgba(0,0,0,0.5)"/><rect x="290" y="105" width="20" height="4" rx="2" fill="%23e0e0e0"/><circle cx="300" cy="190" r="4" fill="%2334c759"/><text x="300" y="340" font-family="system-ui" font-size="22" font-weight="600" fill="%23ffffff" text-anchor="middle">Apple AirPods Pro 2</text><text x="300" y="370" font-family="system-ui" font-size="16" fill="%232997ff" text-anchor="middle">Store Mua Sắm - 5.490.000 đ</text></svg>`,
  
  taxi: `data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="600" height="400" viewBox="0 0 600 400"><rect width="600" height="400" fill="%23eef9f2"/><path d="M100 250 L180 140 L420 140 L500 250 Z" fill="%2300b14f"/><rect x="80" y="240" width="440" height="80" rx="16" fill="%2300b14f"/><circle cx="160" cy="320" r="30" fill="%231d1d1f"/><circle cx="440" cy="320" r="30" fill="%231d1d1f"/><text x="300" y="210" font-family="system-ui" font-size="24" font-weight="800" fill="%23ffffff" text-anchor="middle">GrabCar Sân Bay</text><text x="300" y="380" font-family="system-ui" font-size="16" font-weight="600" fill="%2300b14f" text-anchor="middle">Chuyến đi Tân Sơn Nhất - 320.000 đ</text></svg>`,
  
  shoes: `data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="600" height="400" viewBox="0 0 600 400"><rect width="600" height="400" fill="%23f4f4f6"/><path d="M120 280 Q 220 120 480 200 L460 280 Z" fill="%230066cc"/><ellipse cx="300" cy="285" rx="200" ry="15" fill="%231d1d1f"/><text x="300" y="340" font-family="system-ui" font-size="20" font-weight="700" fill="%231d1d1f" text-anchor="middle">Nike Air Max 270</text><text x="300" y="370" font-family="system-ui" font-size="15" fill="%237a7a7a" text-anchor="middle">Mua sắm thời trang - 2.890.000 đ</text></svg>`,
  
  supermarket: `data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="600" height="400" viewBox="0 0 600 400"><rect width="600" height="400" fill="%23fafafc"/><rect x="150" y="30" width="300" height="340" fill="%23ffffff" stroke="%23e0e0e0" stroke-width="1"/><text x="300" y="70" font-family="system-ui" font-size="20" font-weight="800" fill="%23d32f2f" text-anchor="middle">LOTTE MART</text><text x="300" y="95" font-family="system-ui" font-size="12" fill="%237a7a7a" text-anchor="middle">Siêu Thị Lotte Quan 7, TPHCM</text><line x1="170" y1="110" x2="430" y2="110" stroke="%231d1d1f"/><text x="180" y="140" font-family="system-ui" font-size="13" fill="%231d1d1f">Sữa tươi Vinamilk 1L x 4</text><text x="420" y="140" font-family="system-ui" font-size="13" fill="%231d1d1f" text-anchor="end">148.000</text><text x="180" y="170" font-family="system-ui" font-size="13" fill="%231d1d1f">Thịt bò Mỹ bít tết 500g</text><text x="420" y="170" font-family="system-ui" font-size="13" fill="%231d1d1f" text-anchor="end">295.000</text><text x="180" y="200" font-family="system-ui" font-size="13" fill="%231d1d1f">Rau củ hữu cơ &amp; Trái cây</text><text x="420" y="200" font-family="system-ui" font-size="13" fill="%231d1d1f" text-anchor="end">237.000</text><line x1="170" y1="230" x2="430" y2="230" stroke="%23e0e0e0" stroke-dasharray="3 3"/><text x="180" y="270" font-family="system-ui" font-size="16" font-weight="700" fill="%231d1d1f">TỔNG THANH TOÁN</text><text x="420" y="270" font-family="system-ui" font-size="16" font-weight="700" fill="%230066cc" text-anchor="end">680.000 đ</text></svg>`
};

const DEFAULT_PRESET_EXPENSES = [
  {
    id: 'exp-101',
    imageUrl: MOCK_EXPENSE_PHOTOS.electricity,
    title: 'Hóa đơn Điện Lực EVN Tháng 8',
    amount: 1250000,
    category: 'Hoá đơn',
    type: 'ai_receipt',
    date: '2026-08-10',
    merchant: 'EVN HCMC',
    items: [{ name: 'Điện sinh hoạt 342 kWh', price: 1157408 }, { name: 'VAT (8%)', price: 92592 }],
    notes: 'Đã thanh toán tự động qua trích nợ ngân hàng',
    createdTimestamp: Date.now() - 86400000 * 1
  },
  {
    id: 'exp-102',
    imageUrl: MOCK_EXPENSE_PHOTOS.coffee,
    title: 'Cà phê & Bánh ngọt Highlands',
    amount: 85000,
    category: 'Ăn uống',
    type: 'manual_object',
    date: '2026-08-11',
    merchant: 'Highlands Coffee',
    items: [{ name: 'Phin Sữa Đá L', price: 55000 }, { name: 'Bánh Mì Que', price: 30000 }],
    notes: 'Gặp đối tác tại Highlands Nguyễn Huệ',
    createdTimestamp: Date.now() - 3600000 * 5
  },
  {
    id: 'exp-103',
    imageUrl: MOCK_EXPENSE_PHOTOS.airpods,
    title: 'Tai nghe Apple AirPods Pro 2',
    amount: 5490000,
    category: 'Mua sắm',
    type: 'manual_object',
    date: '2026-08-08',
    merchant: 'TopZone Apple Store',
    items: [{ name: 'AirPods Pro Gen 2 USB-C', price: 5490000 }],
    notes: 'Nâng cấp tai nghe chống ồn làm việc',
    createdTimestamp: Date.now() - 86400000 * 3
  },
  {
    id: 'exp-104',
    imageUrl: MOCK_EXPENSE_PHOTOS.taxi,
    title: 'Chuyến xe GrabCar ra Sân bay',
    amount: 320000,
    category: 'Di chuyển',
    type: 'ai_receipt',
    date: '2026-08-07',
    merchant: 'Grab Vietnam',
    items: [{ name: 'Cước chuyến đi Tân Sơn Nhất', price: 290000 }, { name: 'Phí sân bay', price: 30000 }],
    notes: 'Đi công tác Hà Nội',
    createdTimestamp: Date.now() - 86400000 * 4
  },
  {
    id: 'exp-105',
    imageUrl: MOCK_EXPENSE_PHOTOS.supermarket,
    title: 'Hóa đơn Mua thực phẩm Lotte Mart',
    amount: 680000,
    category: 'Hoá đơn',
    type: 'ai_receipt',
    date: '2026-08-05',
    merchant: 'Lotte Mart Quận 7',
    items: [
      { name: 'Sữa tươi Vinamilk 1L', price: 148000 },
      { name: 'Thịt bò Mỹ bít tết', price: 295000 },
      { name: 'Rau củ & Trái cây', price: 237000 }
    ],
    notes: 'Mua đồ ăn tuần mới cho gia đình',
    createdTimestamp: Date.now() - 86400000 * 6
  },
  {
    id: 'exp-106',
    imageUrl: MOCK_EXPENSE_PHOTOS.shoes,
    title: 'Giày Chạy Bộ Nike Air Max',
    amount: 2890000,
    category: 'Mua sắm',
    type: 'manual_object',
    date: '2026-08-02',
    merchant: 'Nike Store Vincom',
    items: [{ name: 'Nike Air Max 270 Black', price: 2890000 }],
    notes: 'Giày thể thao rèn luyện sức khỏe',
    createdTimestamp: Date.now() - 86400000 * 9
  }
];

export class ExpenseStore {
  static DEFAULT_USER = {
    email: 'triet@apple.com',
    name: 'Triết Nguyễn',
    device: 'macOS Intel / iPhone 15 Pro',
    avatar: ''
  };

  static getCurrentUser() {
    try {
      const stored = localStorage.getItem('mdaily_current_user');
      if (stored) return JSON.parse(stored);
    } catch (e) {
      console.error(e);
    }
    // Default logged in demo user
    this.setCurrentUser(this.DEFAULT_USER);
    return this.DEFAULT_USER;
  }

  static setCurrentUser(user) {
    localStorage.setItem('mdaily_current_user', JSON.stringify(user));
    this.notifySync();
  }

  static login(email, password) {
    const user = {
      email,
      name: email.split('@')[0].toUpperCase(),
      device: 'Apple Sync Device',
      avatar: ''
    };
    this.setCurrentUser(user);
    return user;
  }

  static register(email, password, name) {
    const user = {
      email,
      name: name || email.split('@')[0],
      device: 'Apple Sync Device',
      avatar: ''
    };
    this.setCurrentUser(user);
    return user;
  }

  static logout() {
    localStorage.removeItem('mdaily_current_user');
    this.notifySync();
  }

  static getExpenses(userEmail) {
    const email = userEmail || this.getCurrentUser()?.email || 'triet@apple.com';
    const key = `mdaily_expenses_${email}`;
    try {
      const stored = localStorage.getItem(key);
      if (stored) {
        return JSON.parse(stored);
      }
    } catch (e) {
      console.error(e);
    }
    // Initialize default preset expenses for clean first render
    localStorage.setItem(key, JSON.stringify(DEFAULT_PRESET_EXPENSES));
    return DEFAULT_PRESET_EXPENSES;
  }

  static addExpense(expenseData) {
    const currentUser = this.getCurrentUser();
    if (!currentUser) return null;
    
    const key = `mdaily_expenses_${currentUser.email}`;
    const expenses = this.getExpenses(currentUser.email);
    
    const newExpense = {
      id: 'exp-' + Date.now() + '-' + Math.floor(Math.random() * 1000),
      imageUrl: expenseData.imageUrl || MOCK_EXPENSE_PHOTOS.coffee,
      title: expenseData.title || 'Chi tiêu mới',
      amount: Number(expenseData.amount) || 0,
      category: expenseData.category || 'Mua sắm',
      type: expenseData.type || 'manual_object',
      date: expenseData.date || new Date().toISOString().split('T')[0],
      merchant: expenseData.merchant || 'Cửa hàng',
      items: expenseData.items || [],
      notes: expenseData.notes || '',
      createdTimestamp: Date.now()
    };

    const updated = [newExpense, ...expenses];
    localStorage.setItem(key, JSON.stringify(updated));
    this.notifySync({ type: 'ADD_EXPENSE', expense: newExpense });
    return newExpense;
  }

  static deleteExpense(id) {
    const currentUser = this.getCurrentUser();
    if (!currentUser) return;
    
    const key = `mdaily_expenses_${currentUser.email}`;
    const expenses = this.getExpenses(currentUser.email);
    const updated = expenses.filter(e => e.id !== id);
    localStorage.setItem(key, JSON.stringify(updated));
    this.notifySync({ type: 'DELETE_EXPENSE', id });
  }

  static resetToDefaultData() {
    const currentUser = this.getCurrentUser();
    if (!currentUser) return;
    const key = `mdaily_expenses_${currentUser.email}`;
    localStorage.setItem(key, JSON.stringify(DEFAULT_PRESET_EXPENSES));
    this.notifySync({ type: 'RESET_DATA' });
  }

  static notifySync(payload = {}) {
    if (broadcastChannel) {
      broadcastChannel.postMessage({
        timestamp: Date.now(),
        user: this.getCurrentUser()?.email,
        ...payload
      });
    }
  }

  static subscribeSync(callback) {
    const handler = (e) => callback(e.data);
    if (broadcastChannel) {
      broadcastChannel.addEventListener('message', handler);
    }
    const windowHandler = () => callback({ type: 'WINDOW_STORAGE' });
    window.addEventListener('storage', windowHandler);

    return () => {
      if (broadcastChannel) {
        broadcastChannel.removeEventListener('message', handler);
      }
      window.removeEventListener('storage', windowHandler);
    };
  }
}
