import React, { useRef, useState, useEffect, useCallback } from 'react'
import { createPortal } from 'react-dom'
import './BottomSheet.css'

export type SnapPoint = 'closed' | 'partial' | 'full'

interface BottomSheetProps {
  isOpen: boolean
  onClose: () => void
  children: React.ReactNode
  /** Initial snap point when opened. Default: 'partial' */
  initialSnap?: 'partial' | 'full'
}

// Heights as fraction of viewport
const SNAP_PARTIAL = 0.82
const SNAP_FULL = 1.0
// Thresholds
const CLOSE_DISTANCE = 120
const FULL_DISTANCE = 80
const VELOCITY_THRESHOLD = 0.5

export const BottomSheet: React.FC<BottomSheetProps> = ({
  isOpen,
  onClose,
  children,
  initialSnap = 'partial',
}) => {
  const [shouldRender, setShouldRender] = useState(false)
  const [phase, setPhase] = useState<'entering' | 'open' | 'closing' | 'closed'>('closed')
  const [snap, setSnap] = useState<SnapPoint>(initialSnap)
  const [dragOffset, setDragOffset] = useState(0)
  const [isDragging, setIsDragging] = useState(false)

  const panelRef = useRef<HTMLDivElement>(null)
  const touchStartY = useRef(0)
  const touchStartTime = useRef(0)
  const lastTouchY = useRef(0)
  const currentSnap = useRef<SnapPoint>(initialSnap)
  const startHeight = useRef(0)

  // Viewport height (for iOS keyboard)
  const [vh, setVh] = useState(window.innerHeight)

  useEffect(() => {
    const updateVh = () => {
      setVh(window.visualViewport?.height ?? window.innerHeight)
    }
    window.visualViewport?.addEventListener('resize', updateVh)
    return () => window.visualViewport?.removeEventListener('resize', updateVh)
  }, [])

  // Open / Close lifecycle
  useEffect(() => {
    if (isOpen && phase === 'closed') {
      setShouldRender(true)
      setSnap(initialSnap)
      currentSnap.current = initialSnap
      setDragOffset(0)

      // Wait for render, then play entry animation
      requestAnimationFrame(() => {
        setPhase('entering')
        setTimeout(() => setPhase('open'), 500)
      })
    } else if (!isOpen && (phase === 'open' || phase === 'entering')) {
      setPhase('closing')
      setTimeout(() => {
        setPhase('closed')
        setShouldRender(false)
        setSnap('closed')
        setDragOffset(0)
      }, 350)
    }
  }, [isOpen, phase, initialSnap])

  // --- Touch Gesture Handling ---
  const getSnapHeight = useCallback((s: SnapPoint) => {
    if (s === 'full') return vh * SNAP_FULL
    if (s === 'partial') return vh * SNAP_PARTIAL
    return 0
  }, [vh])

  const handleTouchStart = useCallback((e: React.TouchEvent) => {
    const touch = e.touches[0]
    touchStartY.current = touch.clientY
    lastTouchY.current = touch.clientY
    touchStartTime.current = Date.now()
    startHeight.current = getSnapHeight(currentSnap.current)
    setIsDragging(true)
  }, [getSnapHeight])

  const handleTouchMove = useCallback((e: React.TouchEvent) => {
    if (!isDragging) return
    const touch = e.touches[0]
    const delta = touch.clientY - touchStartY.current
    lastTouchY.current = touch.clientY

    // Allow dragging down freely, limit dragging up based on snap
    if (currentSnap.current === 'full' && delta < 0) {
      // Already full, don't go higher — apply rubber band
      setDragOffset(delta * 0.15)
    } else {
      setDragOffset(delta)
    }
  }, [isDragging])

  const handleTouchEnd = useCallback(() => {
    if (!isDragging) return
    setIsDragging(false)

    const elapsed = Date.now() - touchStartTime.current
    const distance = lastTouchY.current - touchStartY.current
    const velocity = Math.abs(distance) / Math.max(elapsed, 1)
    const isFlick = velocity > VELOCITY_THRESHOLD

    let nextSnap: SnapPoint = currentSnap.current

    if (distance > 0) {
      // Dragging DOWN
      if (distance > CLOSE_DISTANCE || (isFlick && distance > 40)) {
        if (currentSnap.current === 'full') {
          nextSnap = 'partial'
        } else {
          nextSnap = 'closed'
        }
      }
    } else {
      // Dragging UP
      const absDist = Math.abs(distance)
      if (absDist > FULL_DISTANCE || (isFlick && absDist > 30)) {
        if (currentSnap.current === 'partial') {
          nextSnap = 'full'
        }
      }
    }

    setDragOffset(0)

    if (nextSnap === 'closed') {
      onClose()
    } else {
      setSnap(nextSnap)
      currentSnap.current = nextSnap
    }
  }, [isDragging, onClose])

  const handleOverlayClick = useCallback(() => {
    onClose()
  }, [onClose])

  if (!shouldRender) return null

  const snapHeight = getSnapHeight(snap)
  const displayHeight = isDragging
    ? Math.max(0, startHeight.current - dragOffset)
    : snapHeight

  const isFull = snap === 'full' && !isDragging
  const isClosing = phase === 'closing'
  const isEntering = phase === 'entering'

  // Overlay opacity fades with drag
  const overlayOpacity = isDragging
    ? Math.max(0, 1 - (dragOffset / (vh * 0.5)))
    : 1

  const panelClasses = [
    'bottom-sheet-panel',
    isEntering && 'entering',
    isClosing && 'closing',
    !isDragging && !isEntering && 'snapping',
    isFull && 'snap-full',
  ].filter(Boolean).join(' ')

  return createPortal(
    <>
      <div
        className={`bottom-sheet-overlay ${isClosing ? 'closing' : ''}`}
        onClick={handleOverlayClick}
        style={{ opacity: overlayOpacity }}
      />
      <div className="bottom-sheet-container">
        <div
          ref={panelRef}
          className={panelClasses}
          style={{
            height: `${displayHeight}px`,
            maxHeight: `${vh}px`,
          }}
        >
          {/* Handle bar — drag target */}
          <div
            className="bottom-sheet-handle-zone"
            onTouchStart={handleTouchStart}
            onTouchMove={handleTouchMove}
            onTouchEnd={handleTouchEnd}
          >
            <div className="bottom-sheet-handle-indicator" />
          </div>

          {/* Content */}
          <div className="bottom-sheet-body">
            {children}
          </div>
        </div>
      </div>
    </>,
    document.body
  )
}
