import React, { useState } from 'react'
import { Home, Settings, Tag, Plus, PanelLeftClose, PanelLeftOpen } from 'lucide-react'
import './Sidebar.css'

interface SidebarProps {
  activeTab: string;
  onTabChange: (tab: string) => void;
}

export const Sidebar: React.FC<SidebarProps> = ({ activeTab, onTabChange }) => {
  const [isCollapsed, setIsCollapsed] = useState(false)

  return (
    <div className={`sidebar ${isCollapsed ? 'collapsed' : ''}`}>
      <div className="sidebar-header">
        {!isCollapsed && (
          <div className="sidebar-logo">
            <h1>MDaily</h1>
            <p>Quản lý tư bản</p>
          </div>
        )}
        <button 
          className="collapse-btn" 
          onClick={() => setIsCollapsed(!isCollapsed)}
          title={isCollapsed ? "Mở rộng" : "Thu gọn"}
        >
          {isCollapsed ? <PanelLeftOpen size={20} /> : <PanelLeftClose size={20} />}
        </button>
      </div>
      
      <div className="sidebar-primary-action">
        <button 
          className="btn-primary sidebar-add-btn" 
          onClick={() => onTabChange('add-expense')}
          title="Thêm chi tiêu"
        >
          <Plus size={20} />
          {!isCollapsed && <span>Thêm chi tiêu</span>}
        </button>
      </div>

      <nav className="sidebar-nav">
        <button 
          className={`nav-item ${activeTab === 'dashboard' ? 'active' : ''}`}
          onClick={() => onTabChange('dashboard')}
          title="Tổng quan"
        >
          <Home size={20} />
          {!isCollapsed && <span>Tổng quan</span>}
        </button>
        <button 
          className={`nav-item ${activeTab === 'reports' ? 'active' : ''}`}
          onClick={() => onTabChange('reports')}
          title="Phân loại"
        >
          <Tag size={20} />
          {!isCollapsed && <span>Phân loại</span>}
        </button>
        <button 
          className={`nav-item ${activeTab === 'settings' ? 'active' : ''}`}
          onClick={() => onTabChange('settings')}
          title="Cài đặt"
        >
          <Settings size={20} />
          {!isCollapsed && <span>Cài đặt</span>}
        </button>
      </nav>

      <div className="sidebar-footer">
        {/* Footer content if needed */}
      </div>
    </div>
  )
}
