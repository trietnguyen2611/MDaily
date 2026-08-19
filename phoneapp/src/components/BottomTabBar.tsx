import React, { useRef } from 'react'
import { Home, Plus, PieChart, Settings, Sparkles } from 'lucide-react'
import './BottomTabBar.css'

interface BottomTabBarProps {
  activeTab: string
  onTabChange: (tab: string) => void
  onQuickPhotoCaptured?: (photoBase64: string) => void
  isKeyboardOpen?: boolean
}

const compressImage = (file: File, maxDim = 1280, quality = 0.8): Promise<string> => {
  return new Promise((resolve) => {
    const reader = new FileReader()
    reader.onload = (e) => {
      const img = new Image()
      img.onload = () => {
        let width = img.naturalWidth || img.width
        let height = img.naturalHeight || img.height
        if (width > maxDim || height > maxDim) {
          if (width > height) { height = Math.round((height * maxDim) / width); width = maxDim }
          else { width = Math.round((width * maxDim) / height); height = maxDim }
        }
        const canvas = document.createElement('canvas')
        canvas.width = width; canvas.height = height
        const ctx = canvas.getContext('2d')
        if (ctx) { ctx.drawImage(img, 0, 0, width, height); resolve(canvas.toDataURL('image/jpeg', quality)) }
        else resolve(e.target?.result as string)
      }
      img.onerror = () => resolve(e.target?.result as string)
      img.src = e.target?.result as string
    }
    reader.onerror = () => resolve('')
    reader.readAsDataURL(file)
  })
}

const DOCK_TABS = [
  { id: 'dashboard', icon: Home, label: 'Tổng quan' },
  { id: 'add-expense', icon: Plus, label: 'Thêm' },
  { id: 'reports', icon: PieChart, label: 'Phân loại' },
  { id: 'settings', icon: Settings, label: 'Cài đặt' }
]

export const BottomTabBar: React.FC<BottomTabBarProps> = ({
  activeTab,
  onTabChange,
  onQuickPhotoCaptured,
  isKeyboardOpen = false
}) => {
  const cameraInputRef = useRef<HTMLInputElement>(null)

  const activeIndex = DOCK_TABS.findIndex(t => t.id === activeTab)

  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return
    try {
      const compressedBase64 = await compressImage(file)
      if (compressedBase64 && onQuickPhotoCaptured) onQuickPhotoCaptured(compressedBase64)
    } catch (err) {
      console.error('Error processing camera image:', err)
    } finally {
      e.target.value = ''
    }
  }

  const handleCameraClick = () => {
    cameraInputRef.current?.click()
  }

  return (
    <div
      className={`liquid-dock-wrapper ${isKeyboardOpen ? 'keyboard-hidden' : ''}`}
      role="navigation"
      aria-label="Liquid Glass Dock"
    >
      <input
        type="file"
        ref={cameraInputRef}
        hidden
        accept="image/*"
        capture="environment"
        onChange={handleFileChange}
      />

      {/* Main Liquid Glass Capsule Dock */}
      <nav className="liquid-glass-dock">
        {/* Dynamic Glowing Teal/Cyan Active Pill */}
        {activeIndex >= 0 && (
          <div
            className="dock-active-pill"
            style={{
              transform: `translateX(${activeIndex * 100}%)`
            }}
          />
        )}

        <div className="dock-items-grid">
          {DOCK_TABS.map((tab) => {
            const isActive = activeTab === tab.id
            const IconComponent = tab.icon

            return (
              <button
                key={tab.id}
                type="button"
                className={`dock-tab-btn ${isActive ? 'active' : ''}`}
                onClick={() => onTabChange(tab.id)}
                title={tab.label}
                aria-label={tab.label}
                aria-selected={isActive}
              >
                <IconComponent size={22} className="dock-tab-icon" />
              </button>
            )
          })}
        </div>
      </nav>

      {/* Standalone Circular Liquid Glass Camera Action Button (Right) */}
      <button
        type="button"
        className="liquid-glass-circle-btn"
        onClick={handleCameraClick}
        title="Chụp nhanh hoá đơn & chi tiêu"
        aria-label="Chụp ảnh chi tiêu"
      >
        <div className="circle-sparkle-dot">
          <Sparkles size={11} />
        </div>

        {/* 4-Tile Vibrant Colorful 3D App Icon Badge */}
        <div className="vibrant-tiles-cluster">
          <span className="tile tile-cyan" />
          <span className="tile tile-blue" />
          <span className="tile tile-orange" />
          <span className="tile tile-green" />
        </div>
      </button>
    </div>
  )
}
