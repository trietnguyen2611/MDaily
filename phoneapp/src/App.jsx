import React, { useState, useEffect } from 'react';
import { MobileHeader } from './components/MobileHeader';
import { FloatingTabBar } from './components/FloatingTabBar';
import { MobileDashboard } from './components/MobileDashboard';
import { MobileObjectScanSheet } from './components/MobileObjectScanSheet';
import { MobileReceiptAISheet } from './components/MobileReceiptAISheet';
import { MobileAIChatTab } from './components/MobileAIChatTab';
import { MobileProfileTab } from './components/MobileProfileTab';
import { ExpenseStore } from './services/ExpenseStore';

export function App() {
  const [activeTab, setActiveTab] = useState('dashboard');
  const [currentUser, setCurrentUser] = useState(null);
  const [expenses, setExpenses] = useState([]);
  const [activeCategory, setActiveCategory] = useState('ALL');

  // Sheets visibility
  const [isObjectSheetOpen, setIsObjectSheetOpen] = useState(false);
  const [isReceiptSheetOpen, setIsReceiptSheetOpen] = useState(false);

  const loadData = () => {
    const user = ExpenseStore.getCurrentUser();
    setCurrentUser(user);
    const records = ExpenseStore.getExpenses(user?.email);
    setExpenses(records);
  };

  useEffect(() => {
    loadData();

    // Subscribe to cross-app real-time sync with deskapp
    const unsubscribe = ExpenseStore.subscribeSync((event) => {
      console.log('Realtime sync event received in phoneapp:', event);
      loadData();
    });

    return () => unsubscribe();
  }, []);

  const handleSaveExpense = (newExpense) => {
    ExpenseStore.addExpense(newExpense);
    loadData();
  };

  const handleDeleteExpense = (id) => {
    ExpenseStore.deleteExpense(id);
    loadData();
  };

  const handleResetData = () => {
    if (window.confirm('Khôi phục dữ liệu mẫu thử nghiệm?')) {
      ExpenseStore.resetToDefaultData();
      loadData();
    }
  };

  return (
    <div className="iphone-frame-wrapper">
      <div className="iphone-screen">
        {/* iOS Dynamic Island & Header */}
        <MobileHeader
          currentUser={currentUser}
          onOpenProfile={() => setActiveTab('profile')}
        />

        {/* Tab views */}
        {activeTab === 'dashboard' && (
          <MobileDashboard
            expenses={expenses}
            currentUser={currentUser}
            activeCategory={activeCategory}
            onSelectCategory={setActiveCategory}
            onDeleteExpense={handleDeleteExpense}
            onOpenReceiptSheet={() => setIsReceiptSheetOpen(true)}
            onOpenObjectSheet={() => setIsObjectSheetOpen(true)}
            onResetData={handleResetData}
          />
        )}

        {activeTab === 'chat_ai' && (
          <MobileAIChatTab
            expenses={expenses}
            currentUser={currentUser}
          />
        )}

        {activeTab === 'profile' && (
          <MobileProfileTab
            currentUser={currentUser}
            onUserChange={(u) => {
              setCurrentUser(u);
              loadData();
            }}
          />
        )}

        {/* Floating iOS Bottom Navigation Bar */}
        <FloatingTabBar
          activeTab={activeTab}
          onTabChange={setActiveTab}
          onOpenObjectSheet={() => setIsObjectSheetOpen(true)}
          onOpenReceiptSheet={() => setIsReceiptSheetOpen(true)}
        />

        {/* Bottom Sheets */}
        <MobileObjectScanSheet
          isOpen={isObjectSheetOpen}
          onClose={() => setIsObjectSheetOpen(false)}
          onSave={handleSaveExpense}
        />

        <MobileReceiptAISheet
          isOpen={isReceiptSheetOpen}
          onClose={() => setIsReceiptSheetOpen(false)}
          onSave={handleSaveExpense}
        />
      </div>
    </div>
  );
}
