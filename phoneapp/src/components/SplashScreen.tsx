import React, { useEffect, useState } from 'react'
import logoImg from '../assets/logo.png'
import './SplashScreen.css'

interface SplashScreenProps {
  onFinish?: () => void
  duration?: number
}

export const SplashScreen: React.FC<SplashScreenProps> = ({ onFinish, duration = 1200 }) => {
  const [isFadingOut, setIsFadingOut] = useState(false)
  const [isVisible, setIsVisible] = useState(true)

  useEffect(() => {
    const fadeTimer = setTimeout(() => {
      setIsFadingOut(true)
    }, duration)

    const removeTimer = setTimeout(() => {
      setIsVisible(false)
      if (onFinish) onFinish()
    }, duration + 500)

    return () => {
      clearTimeout(fadeTimer)
      clearTimeout(removeTimer)
    }
  }, [duration, onFinish])

  if (!isVisible) return null

  return (
    <div className={`splash-screen ${isFadingOut ? 'fade-out' : ''}`}>
      <div className="splash-content">
        <div className="splash-logo-container">
          <img src={logoImg} alt="MDaily Logo" className="splash-logo" />
        </div>
        <h1 className="splash-app-name">MDaily</h1>
        <p className="splash-tagline">Quản lý chi tiêu thông minh</p>
      </div>
    </div>
  )
}
