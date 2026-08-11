import React, { useState, useEffect } from 'react';
import { WindowHeader } from './components/WindowHeader';
import { Sidebar } from './components/Sidebar';
import { ExpenseCard } from './components/ExpenseCard';
import { ObjectPhotoModal } from './components/ObjectPhotoModal';
import { ReceiptAIModal } from './components/ReceiptAIModal';
import { AIChatDrawer } from './components/AIChatDrawer';
import { AuthModal } from './components/AuthModal';
import { JanAISettingsModal } from './components/JanAISettingsModal';
import { ExpenseStore } from './services/ExpenseStore';
import { Search, Sparkles, Plus, Wallet, PieChart, ShoppingBag, ShieldCheck, ArrowUpRight } from 'lucide-react';

export function App() {
  const [currentUser, setCurrentUser] = useState(null);
  const [expenses, setExpenses] = useState([]);
  const [activeCategory, setActiveCategory] = useState('ALL');
  const [searchQuery, setSearchQuery] = useState('');

  // Modals visibility
  const [isObjectModalOpen, setIsObjectModalOpen] = useState(false);
  const [isReceiptModalOpen, setIsReceiptModalOpen] = useState(false);
  const [isChatOpen, setIsChatOpen] = useState(false);
  const [isAuthOpen, setIsAuthOpen] = useState(false);
  const [isSettingsOpen, setIsSettingsOpen] = useState(false);

  // Load User and Expenses
  const loadData = () => {
    const user = ExpenseStore.getCurrentUser();
    setCurrentUser(user);
    const records = ExpenseStore.getExpenses(user?.email);
    setExpenses(records);
  };

  useEffect(() => {
    loadData();

    // Subscribe to cross-tab / cross-app real-time sync with phoneapp
    const unsubscribe = ExpenseStore.subscribeSync((event) => {
      console.log('Realtime sync event received in deskapp:', event);
      loadData();
    });

    return () => unsubscribe();
  }, []);

  const handleSaveExpense = (newExpenseData) => {
    ExpenseStore.addExpense(newExpenseData);
    loadData();
  };

  const handleDeleteExpense = (id) => {
    ExpenseStore.deleteExpense(id);
    loadData();
  };

  const handleResetData = () => {
    if (window.confirm('Khôi phục dữ liệu chi tiêu thử nghiệm mẫu?')) {
      ExpenseStore.resetToDefaultData();
      loadData();
    }
  };

  // Filter expenses
  const filteredExpenses = expenses.filter(item => {
    const matchesCategory = activeCategory === 'ALL' || item.category === activeCategory;
    const matchesSearch = searchQuery === '' ||
      item.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (item.merchant && item.merchant.toLowerCase().includes(searchQuery.toLowerCase())) ||
      (item.notes && item.notes.toLowerCase().includes(searchQuery.toLowerCase()));
    return matchesCategory && matchesSearch;
  });

  // Calculate totals
  const totalSpent = expenses.reduce((sum, item) => sum + item.amount, 0);
  const aiScannedCount = expenses.filter(i => i.type === 'ai_receipt').length;

  return (
    <div className="mac-desktop-viewport">
      <div className="mac-window">
        {/* Top Header & Navigation */}
        <WindowHeader
          currentUser={currentUser}
          onOpenObjectModal={() => setIsObjectModalOpen(true)}
          onOpenReceiptModal={() => setIsReceiptModalOpen(true)}
          onToggleChat={() => setIsChatOpen(!isChatOpen)}
          onOpenSettings={() => setIsSettingsOpen(true)}
          onOpenAuth={() => setIsAuthOpen(true)}
          onResetData={handleResetData}
        />

        {/* Main Window Body Layout */}
        <div className="mac-body-layout">
          {/* Left Floating Sidebar */}
          <Sidebar
            activeCategory={activeCategory}
            onSelectCategory={setActiveCategory}
            totalSpent={totalSpent}
          />

          {/* Right Scrollable Dashboard Container */}
          <main className="mac-main-content">
            {/* Apple Full-Bleed Tile Banner */}
            <div className="hero-tile-banner">
              <div>
                <div style={{ fontSize: '12px', fontWeight: 600, color: '#2997ff', textTransform: 'uppercase', letterSpacing: '1px', marginBottom: '8px' }}>
                  NHẬT KÝ CHI TIÊU HÌNH ẢNH
                </div>
                <h2>Dashboard Chi Tiêu</h2>
                <p>
                  Ghi nhận tự động qua ảnh chụp hóa đơn (*AI Gemma 2 2B) &amp; nhập đồ vật thực tế
                </p>
              </div>

              <div style={{ display: 'flex', gap: '12px' }}>
                <button className="btn-primary-pill" onClick={() => setIsReceiptModalOpen(true)}>
                  <Sparkles size={16} />
                  <span>Quét Hóa Đơn AI</span>
                </button>
                <button className="btn-secondary-pill" style={{ color: '#fff', borderColor: '#fff' }} onClick={() => setIsObjectModalOpen(true)}>
                  <Plus size={16} />
                  <span>Chụp Đồ Vật</span>
                </button>
              </div>
            </div>

            {/* Financial Overview Stats */}
            <div className="stats-overview-grid">
              <div className="stat-card">
                <div className="stat-card-title">TỔNG CHI TIÊU THÁNG 8</div>
                <div className="stat-card-value" style={{ color: 'var(--color-primary)' }}>
                  {totalSpent.toLocaleString('vi-VN')} đ
                </div>
              </div>
              <div className="stat-card">
                <div className="stat-card-title">SỐ KHOẢN GHI NHẬN</div>
                <div className="stat-card-value">{expenses.length} khoản</div>
              </div>
              <div className="stat-card">
                <div className="stat-card-title">QUÉT BẰNG AI GEMMA 2</div>
                <div className="stat-card-value" style={{ color: '#34c759' }}>
                  {aiScannedCount} hóa đơn
                </div>
              </div>
              <div className="stat-card">
                <div className="stat-card-title">TÀI KHOẢN ĐỒNG BỘ</div>
                <div className="stat-card-value" style={{ fontSize: '16px' }}>
                  {currentUser?.email}
                </div>
              </div>
            </div>

            {/* Filter & Search Bar */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: '16px' }}>
              <div className="filter-chip-bar">
                {['ALL', 'Hoá đơn', 'Mua sắm', 'Ăn uống', 'Di chuyển'].map((cat) => (
                  <button
                    key={cat}
                    className={`category-chip ${activeCategory === cat ? 'active' : ''}`}
                    onClick={() => setActiveCategory(cat)}
                  >
                    {cat === 'ALL' ? 'Tất cả chi tiêu' : cat}
                  </button>
                ))}
              </div>

              <div style={{ position: 'relative', width: '280px' }}>
                <Search size={16} style={{ position: 'absolute', left: '16px', top: '50%', transform: 'translateY(-50%)', color: 'var(--color-ink-muted-48)' }} />
                <input
                  type="text"
                  className="input-apple"
                  style={{ borderRadius: 'var(--radius-pill)', paddingLeft: '44px', height: '42px', fontSize: '14px' }}
                  placeholder="Tìm kiếm chi tiêu, cửa hàng..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                />
              </div>
            </div>

            {/* Expense Photo Timeline Grid */}
            <div>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
                <h3 style={{ fontFamily: 'var(--font-display)', fontSize: '22px', fontWeight: 600 }}>
                  Lịch Sử Ảnh Chi Tiêu ({filteredExpenses.length})
                </h3>
              </div>

              {filteredExpenses.length === 0 ? (
                <div style={{ background: 'var(--color-canvas)', padding: '60px', borderRadius: 'var(--radius-lg)', textAlign: 'center', border: '1px solid var(--color-hairline)' }}>
                  <ShoppingBag size={48} color="var(--color-ink-muted-48)" style={{ marginBottom: '16px' }} />
                  <h4 style={{ fontSize: '18px', fontWeight: 600 }}>Không tìm thấy chi tiêu nào</h4>
                  <p style={{ color: 'var(--color-ink-muted-48)', marginTop: '4px' }}>
                    Thử thay đổi từ khóa tìm kiếm hoặc chụp thêm ảnh chi tiêu mới
                  </p>
                </div>
              ) : (
                <div className="expense-photo-grid">
                  {filteredExpenses.map((expense) => (
                    <ExpenseCard
                      key={expense.id}
                      expense={expense}
                      onDelete={handleDeleteExpense}
                    />
                  ))}
                </div>
              )}
            </div>
          </main>
        </div>
      </div>

      {/* Modals & AI Chat Drawer */}
      <ObjectPhotoModal
        isOpen={isObjectModalOpen}
        onClose={() => setIsObjectModalOpen(false)}
        onSave={handleSaveExpense}
      />

      <ReceiptAIModal
        isOpen={isReceiptModalOpen}
        onClose={() => setIsReceiptModalOpen(false)}
        onSave={handleSaveExpense}
      />

      <AIChatDrawer
        isOpen={isChatOpen}
        onClose={() => setIsChatOpen(false)}
        expenses={expenses}
        currentUser={currentUser}
      />

      <AuthModal
        isOpen={isAuthOpen}
        onClose={() => setIsAuthOpen(false)}
        currentUser={currentUser}
        onLoginSuccess={(user) => {
          setCurrentUser(user);
          loadData();
        }}
      />

      <JanAISettingsModal
        isOpen={isSettingsOpen}
        onClose={() => setIsSettingsOpen(false)}
      />
    </div>
  );
}
