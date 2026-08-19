import React, { useRef, useState, useEffect, useCallback } from 'react'
import { createPortal } from 'react-dom'
import './BottomSheet.css'

interface BottomSheetProps {
  isOpen: boolean
  onClose: () => void
  children: React.ReactNode
}

const VELOCITY_THRESHOLD = 0.35 // px/ms for swipe/flick dismiss
const DISMISS_DISTANCE = 90 // px drag down threshold

export const BottomSheet: React.FC<BottomSheetProps> = ({
  isOpen,
  onClose,
  children,
}) => {
  const [shouldRender, setShouldRender] = useState(false)
  const [phase, setPhase] = useState<'entering' | 'open' | 'closing' | 'closed'>('closed')
  const [dragOffset, setDragOffset] = useState(0)
  const [isDragging, setIsDragging] = useState(false)

  const panelRef = useRef<HTMLDivElement>(null)
  const touchStartY = useRef(0)
  const touchStartX = useRef(0)
  const touchStartTime = useRef(0)
  const lastTouchY = useRef(0)
  const isGestureActive = useRef(false)
  const isDraggingSheet = useRef(false)

  // Open / Close lifecycle
  useEffect(() => {
    let timer: any = null
    if (isOpen) {
      setShouldRender(true)
      setDragOffset(0)
      setIsDragging(false)
      // Start in entering state immediately
      setPhase('entering')
      timer = setTimeout(() => {
        setPhase('open')
      }, 380)
    } else if (shouldRender) {
      setPhase('closing')
      timer = setTimeout(() => {
        setPhase('closed')
        setShouldRender(false)
        setDragOffset(0)
        setIsDragging(false)
      }, 300)
    }

    return () => {
      if (timer) clearTimeout(timer)
    }
  }, [isOpen])

  // Find if any scrollable parent under target has scrollTop > 0
  const isTargetScrolled = (target: EventTarget | null): boolean => {
    let el = target as HTMLElement | null
    while (el && el !== panelRef.current && el !== document.body) {
      if (el.scrollHeight > el.clientHeight) {
        const overflowY = window.getComputedStyle(el).overflowY
        if (overflowY === 'auto' || overflowY === 'scroll') {
          if (el.scrollTop > 2) return true
        }
      }
      el = el.parentElement
    }
    return false
  }

  // --- Touch Gesture Handling for whole Sheet ---
  const handleTouchStart = useCallback((e: React.TouchEvent) => {
    const touch = e.touches[0]
    touchStartY.current = touch.clientY
    touchStartX.current = touch.clientX
    lastTouchY.current = touch.clientY
    touchStartTime.current = Date.now()
    isGestureActive.current = true
    isDraggingSheet.current = false
  }, [])

  const handleTouchMove = useCallback((e: React.TouchEvent) => {
    if (!isGestureActive.current) return
    const touch = e.touches[0]
    const deltaY = touch.clientY - touchStartY.current
    const deltaX = touch.clientX - touchStartX.current
    lastTouchY.current = touch.clientY

    // Determine if vertical drag
    if (!isDraggingSheet.current) {
      if (Math.abs(deltaY) > 8 && Math.abs(deltaY) > Math.abs(deltaX)) {
        // If pulling down
        if (deltaY > 0) {
          // Check if inner content is scrolled
          if (!isTargetScrolled(e.target)) {
            isDraggingSheet.current = true
            setIsDragging(true)
          }
        }
      }
    }

    if (isDraggingSheet.current) {
      // Pulling down sheet
      if (deltaY > 0) {
        setDragOffset(deltaY)
      } else {
        // Pulling up: slight resistance
        setDragOffset(deltaY * 0.15)
      }
    }
  }, [])

  const handleTouchEnd = useCallback(() => {
    if (!isGestureActive.current) return
    isGestureActive.current = false

    if (isDraggingSheet.current) {
      setIsDragging(false)
      isDraggingSheet.current = false

      const elapsed = Date.now() - touchStartTime.current
      const deltaY = lastTouchY.current - touchStartY.current
      const velocity = deltaY / Math.max(elapsed, 1)

      const isFlickDown = velocity > VELOCITY_THRESHOLD
      const isDraggedDownEnough = deltaY > DISMISS_DISTANCE

      if (deltaY > 0 && (isFlickDown || isDraggedDownEnough)) {
        // Dismiss sheet
        onClose()
      } else {
        // Spring back
        setDragOffset(0)
      }
    }
  }, [onClose])

  const handleOverlayClick = useCallback(() => {
    onClose()
  }, [onClose])

  if (!shouldRender) return null

  const isClosing = phase === 'closing'
  const isEntering = phase === 'entering'

  // Dynamic overlay opacity based on drag distance
  const overlayOpacity = isDragging
    ? Math.max(0, 1 - dragOffset / 350)
    : 1

  const panelClasses = [
    'bottom-sheet-panel',
    isEntering && 'entering',
    isClosing && 'closing',
    !isDragging && !isEntering && !isClosing && 'snapping',
  ].filter(Boolean).join(' ')

  const panelStyle: React.CSSProperties = {
    transform: isDragging 
      ? `translateY(${Math.max(0, dragOffset)}px)` 
      : undefined
  }

  return createPortal(
    <>
      <div
        className={`bottom-sheet-overlay ${isEntering ? 'entering' : ''} ${isClosing ? 'closing' : ''}`}
        onClick={handleOverlayClick}
        style={{ opacity: overlayOpacity }}
      />
      <div className="bottom-sheet-container">
        <div
          ref={panelRef}
          className={panelClasses}
          style={panelStyle}
          onTouchStart={handleTouchStart}
          onTouchMove={handleTouchMove}
          onTouchEnd={handleTouchEnd}
          onTouchCancel={handleTouchEnd}
        >
          {/* Top Grab Handle Area */}
          <div className="bottom-sheet-handle-zone">
            <div className="bottom-sheet-handle-indicator" />
          </div>

          {/* Sheet Body */}
          <div className="bottom-sheet-body">
            {children}
          </div>
        </div>
      </div>
    </>,
    document.body
  )
}
