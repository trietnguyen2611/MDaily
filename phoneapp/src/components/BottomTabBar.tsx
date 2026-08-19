import React, { useRef } from 'react'
import { LayoutDashboard, PlusCircle, PieChart, Settings, Camera } from 'lucide-react'
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

export const BottomTabBar: React.FC<BottomTabBarProps> = ({
  activeTab,
  onTabChange,
  onQuickPhotoCaptured,
  isKeyboardOpen = false
}) => {
  const cameraInputRef = useRef<HTMLInputElement>(null)

  const tabs = [
    { id: 'dashboard', icon: LayoutDashboard, label: 'Tổng quan' },
    { id: 'add-expense', icon: PlusCircle, label: 'Thêm' },
    { id: 'quick-camera', icon: Camera, label: 'Chụp', isCamera: true },
    { id: 'reports', icon: PieChart, label: 'Phân loại' },
    { id: 'settings', icon: Settings, label: 'Cài đặt' }
  ]

  const regularTabs = tabs.filter(t => !t.isCamera)
  const activeIndex = regularTabs.findIndex(t => t.id === activeTab)

  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return
    try {
      const compressedBase64 = await compressImage(file)
      if (compressedBase64 && onQuickPhotoCaptured) onQuickPhotoCaptured(compressedBase64)
    } catch (err) { console.error('Error processing camera image:', err) }
    finally { e.target.value = '' }
  }

  const handleTabClick = (tabId: string, isCamera?: boolean) => {
    if (isCamera) cameraInputRef.current?.click()
    else onTabChange(tabId)
  }

  return (
    <nav
      className={`bottom-tab-bar ${isKeyboardOpen ? 'keyboard-hidden' : ''}`}
      role="navigation"
      aria-label="Bottom Navigation"
    >
      <input
        type="file"
        ref={cameraInputRef}
        hidden
        accept="image/*"
        capture="environment"
        onChange={handleFileChange}
      />

      <div className="tab-items-wrapper">
        {/* Active pill indicator */}
        {activeIndex >= 0 && (
          <div
            className="tab-active-pill"
            style={{
              width: `calc(100% / ${regularTabs.length})`,
              transform: `translateX(${(activeIndex >= 2 ? activeIndex + 1 : activeIndex) * 100}%)`
            }}
          />
        )}

        {tabs.map((tab) => {
          const isActive = activeTab === tab.id

          if (tab.isCamera) {
            return (
              <button
                key={tab.id}
                type="button"
                className="tab-btn camera-action-tab"
                onClick={() => handleTabClick(tab.id, true)}
                title="Chụp nhanh hoá đơn"
              >
                <div className="camera-btn-inner">
                  <Camera size={22} className="camera-btn-icon" />
                </div>
                <span className="tab-label camera-label">{tab.label}</span>
              </button>
            )
          }

          return (
            <button
              key={tab.id}
              type="button"
              className={`tab-btn ${isActive ? 'active' : ''}`}
              onClick={() => handleTabClick(tab.id, false)}
            >
              <tab.icon size={21} className="tab-icon" />
              <span className="tab-label">{tab.label}</span>
            </button>
          )
        })}
      </div>
    </nav>
  )
}
