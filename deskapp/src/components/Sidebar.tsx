import React, { useState } from 'react'
import { Home, Settings, Tag, Plus, PanelLeftClose, PanelLeftOpen } from 'lucide-react'
import { APP_VERSION_LABEL } from '../constants'
import { t, getLanguage } from '../services/i18n'
import './Sidebar.css'

interface SidebarProps {
  activeTab: string
  onTabChange: (tab: string) => void
}

export const Sidebar: React.FC<SidebarProps> = ({ activeTab, onTabChange }) => {
  const [isCollapsed, setIsCollapsed] = useState(false)
  const lang = getLanguage()

  return (
    <div className={`sidebar ${isCollapsed ? 'collapsed' : ''}`}>
      <div className="sidebar-header">
        {!isCollapsed && (
          <div className="sidebar-logo">
            <h1>MDaily</h1>
            <p>macOS · {APP_VERSION_LABEL}</p>
          </div>
        )}
        <button
          className="collapse-btn"
          onClick={() => setIsCollapsed(!isCollapsed)}
          title={isCollapsed ? (lang === 'vi' ? 'Mở rộng' : 'Expand') : (lang === 'vi' ? 'Thu gọn' : 'Collapse')}
        >
          {isCollapsed ? <PanelLeftOpen size={20} /> : <PanelLeftClose size={20} />}
        </button>
      </div>

      <div className="sidebar-primary-action">
        <button
          className="btn-primary sidebar-add-btn"
          onClick={() => onTabChange('add-expense')}
          title={t('tab_add_expense', lang)}
        >
          <Plus size={20} />
          {!isCollapsed && <span>{t('tab_add_expense', lang)}</span>}
        </button>
      </div>

      <nav className="sidebar-nav">
        <button
          className={`nav-item ${activeTab === 'dashboard' ? 'active' : ''}`}
          onClick={() => onTabChange('dashboard')}
          title={t('tab_dashboard', lang)}
        >
          <Home size={20} />
          {!isCollapsed && <span>{t('tab_dashboard', lang)}</span>}
        </button>
        <button
          className={`nav-item ${activeTab === 'reports' ? 'active' : ''}`}
          onClick={() => onTabChange('reports')}
          title={t('tab_reports', lang)}
        >
          <Tag size={20} />
          {!isCollapsed && <span>{t('tab_reports', lang)}</span>}
        </button>
        <button
          className={`nav-item ${activeTab === 'settings' ? 'active' : ''}`}
          onClick={() => onTabChange('settings')}
          title={t('tab_settings', lang)}
        >
          <Settings size={20} />
          {!isCollapsed && <span>{t('tab_settings', lang)}</span>}
        </button>
      </nav>

      <div className="sidebar-footer">
        {/* Footer content */}
      </div>
    </div>
  )
}
