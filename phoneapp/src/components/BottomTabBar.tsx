import React, { useRef } from 'react'
import { LayoutDashboard, PlusCircle, PieChart, Settings, Camera } from 'lucide-react'
import './BottomTabBar.css'

interface BottomTabBarProps {
  activeTab: string
  onTabChange: (tab: string) => void
  onQuickPhotoCaptured?: (photoBase64: string) => void
  isCollapsed?: boolean
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
          if (width > height) {
            height = Math.round((height * maxDim) / width)
            width = maxDim
          } else {
            width = Math.round((width * maxDim) / height)
            height = maxDim
          }
        }

        const canvas = document.createElement('canvas')
        canvas.width = width
        canvas.height = height
        const ctx = canvas.getContext('2d')
        if (ctx) {
          ctx.drawImage(img, 0, 0, width, height)
          resolve(canvas.toDataURL('image/jpeg', quality))
        } else {
          resolve(e.target?.result as string)
        }
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
  isCollapsed = false 
}) => {
  const cameraInputRef = useRef<HTMLInputElement>(null)
  const [userExpanded, setUserExpanded] = React.useState(false)
  const prevCollapsed = useRef(isCollapsed)

  const [manualCollapsed, setManualCollapsed] = React.useState(false)

  React.useEffect(() => {
    if (!isCollapsed) {
      setUserExpanded(false)
      setManualCollapsed(false)
    }
    prevCollapsed.current = isCollapsed
  }, [isCollapsed])

  const effectiveCollapsed = (isCollapsed || manualCollapsed) && !userExpanded

  const tabs = [
    { id: 'dashboard', icon: LayoutDashboard, label: 'Tổng quan' },
    { id: 'reports', icon: PieChart, label: 'Báo cáo' },
    { id: 'quick-camera', icon: Camera, label: 'Chụp', isCamera: true },
    { id: 'add-expense', icon: PlusCircle, label: 'Thêm' },
    { id: 'settings', icon: Settings, label: 'Cài đặt' }
  ]

  const activeIndex = tabs.findIndex(t => t.id === activeTab)

  const handleCameraClick = () => {
    cameraInputRef.current?.click()
  }

  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return

    try {
      const compressedBase64 = await compressImage(file)
      if (compressedBase64 && onQuickPhotoCaptured) {
        onQuickPhotoCaptured(compressedBase64)
      }
    } catch (err) {
      console.error('Error processing camera image:', err)
    } finally {
      e.target.value = ''
    }
  }

  const handleTabClick = (tabId: string, isCamera?: boolean) => {
    if (effectiveCollapsed) {
      setUserExpanded(true)
      setManualCollapsed(false)
      return
    }
    if (activeTab === tabId && !isCamera) {
      setManualCollapsed(true)
      setUserExpanded(false)
      return
    }
    if (isCamera) {
      handleCameraClick()
    } else {
      onTabChange(tabId)
    }
  }

  return (
    <nav 
      className={`bottom-tab-bar ${effectiveCollapsed ? 'collapsed' : ''}`}
      onClick={(e) => {
        if (effectiveCollapsed) {
          e.stopPropagation()
          setUserExpanded(true)
        }
      }}
    >
      <input 
        type="file" 
        ref={cameraInputRef} 
        hidden 
        accept="image/*"
        capture="environment"
        onChange={handleFileChange} 
      />
      {activeIndex >= 0 && (
        <div 
          className="tab-active-indicator" 
          style={{ 
            width: 'calc((100% - 32px) / 5)',
            transform: `translateX(${activeIndex * 100}%)` 
          }}
        />
      )}
      {tabs.map(tab => {
        const isActive = activeTab === tab.id
        return (
          <button
            key={tab.id}
            type="button"
            className={`tab-btn ${isActive ? 'active' : ''} ${effectiveCollapsed && !isActive ? 'hidden' : ''}`}
            onClick={() => handleTabClick(tab.id, tab.isCamera)}
          >
            <tab.icon size={22} className="tab-icon" />
            <span className="tab-label">{tab.label}</span>
          </button>
        )
      })}
    </nav>
  )
}
