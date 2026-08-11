import React from 'react';
import { LayoutGrid, FileText, ShoppingBag, Utensils, Car, Sparkles, Cpu, ShieldCheck } from 'lucide-react';

export const Sidebar = ({ activeCategory, onSelectCategory, totalSpent }) => {
  const categories = [
    { id: 'ALL', name: 'Tất cả chi tiêu', icon: LayoutGrid },
    { id: 'Hoá đơn', name: 'Hoá đơn', icon: FileText },
    { id: 'Mua sắm', name: 'Mua sắm', icon: ShoppingBag },
    { id: 'Ăn uống', name: 'Ăn uống', icon: Utensils },
    { id: 'Di chuyển', name: 'Di chuyển', icon: Car }
  ];

  return (
    <aside className="mac-sidebar">
      <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
        <div>
          <div style={{ fontSize: '11px', fontWeight: 600, color: 'var(--color-ink-muted-48)', textTransform: 'uppercase', letterSpacing: '0.5px', marginBottom: '12px' }}>
            Danh mục chi tiêu
          </div>
          <div className="sidebar-nav-group">
            {categories.map(cat => {
              const Icon = cat.icon;
              const isActive = activeCategory === cat.id;
              return (
                <button
                  key={cat.id}
                  className={`sidebar-nav-item ${isActive ? 'active' : ''}`}
                  onClick={() => onSelectCategory(cat.id)}
                >
                  <Icon size={18} />
                  <span>{cat.name}</span>
                </button>
              );
            })}
          </div>
        </div>

        <div style={{ padding: '16px', background: 'var(--color-canvas-parchment)', borderRadius: 'var(--radius-lg)', border: '1px solid var(--color-hairline)' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '12px', fontWeight: 600, color: 'var(--color-primary)' }}>
            <Cpu size={14} />
            <span>LOCAL AI ENGINE</span>
          </div>
          <p style={{ fontSize: '12px', color: 'var(--color-ink-muted-48)', marginTop: '4px' }}>
            Gemma 2 2B IT Q4 K M trên Jan AI Server (Mac Intel)
          </p>
        </div>
      </div>

      <div style={{ padding: '14px', background: 'var(--color-surface-pearl)', borderRadius: 'var(--radius-md)', border: '1px solid var(--color-hairline)' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '12px', color: 'var(--color-ink-muted-48)' }}>
          <ShieldCheck size={14} color="#34c759" />
          <span>Tài khoản &amp; Đồng bộ iOS</span>
        </div>
        <div style={{ fontSize: '13px', fontWeight: 600, marginTop: '4px' }}>
          Đã kết nối BroadcastSync
        </div>
      </div>
    </aside>
  );
};
