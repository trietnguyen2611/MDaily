import React, { useState, useEffect, useRef } from 'react'
import {
  X,
  Camera,
  RefreshCw,
  ArrowUpDown,
  UploadCloud,
  DownloadCloud,
  Laptop,
  CheckCircle2,
  AlertCircle,
  Image as ImageIcon,
  KeyRound,
  Wifi
} from 'lucide-react'
import jsQR from 'jsqr'
import {
  getLastSyncServer,
  saveLastSyncServer,
  clearLastSyncServer,
  pingSyncServer,
  performTwoWayMerge,
  performPushToDesktop,
  performPullFromDesktop
} from '../services/sync'
import type { SyncServerConfig } from '../services/sync'
import { t, getLanguage } from '../services/i18n'
import './WifiSyncModal.css'

interface WifiSyncModalProps {
  isOpen: boolean
  onClose: () => void
  onSyncCompleted?: () => void
}

export const WifiSyncModal: React.FC<WifiSyncModalProps> = ({
  isOpen,
  onClose,
  onSyncCompleted
}) => {
  const lang = getLanguage()
  const [activeTab, setActiveTab] = useState<'scan' | 'manual' | 'connected'>('scan')
  const [pairedServer, setPairedServer] = useState<SyncServerConfig | null>(null)
  const [isScanning, setIsScanning] = useState(false)
  const [isSyncing, setIsSyncing] = useState(false)
  const [statusMessage, setStatusMessage] = useState<string | null>(null)
  const [errorMessage, setErrorMessage] = useState<string | null>(null)

  // Manual inputs
  const [manualIp, setManualIp] = useState('')
  const [manualPort, setManualPort] = useState('18321')
  const [manualToken, setManualToken] = useState('')

  // Video & Canvas refs for Camera QR Scanning
  const videoRef = useRef<HTMLVideoElement | null>(null)
  const canvasRef = useRef<HTMLCanvasElement | null>(null)
  const streamRef = useRef<MediaStream | null>(null)
  const animationFrameRef = useRef<number | null>(null)
  const fileInputRef = useRef<HTMLInputElement | null>(null)

  useEffect(() => {
    if (isOpen) {
      const saved = getLastSyncServer()
      if (saved) {
        setPairedServer(saved)
        setManualIp(saved.ip)
        setManualPort(saved.port.toString())
        setManualToken(saved.token)
        setActiveTab('connected')
      } else {
        setActiveTab('scan')
      }
      setErrorMessage(null)
      setStatusMessage(null)
    } else {
      stopCamera()
    }
  }, [isOpen])

  useEffect(() => {
    if (isOpen && activeTab === 'scan') {
      startCamera()
    } else {
      stopCamera()
    }
    return () => {
      stopCamera()
    }
  }, [isOpen, activeTab])

  const startCamera = async () => {
    setErrorMessage(null)
    setIsScanning(true)
    try {
      if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
        throw new Error('Camera not supported')
      }
      const stream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: 'environment', width: { ideal: 640 }, height: { ideal: 640 } }
      })
      streamRef.current = stream
      if (videoRef.current) {
        videoRef.current.srcObject = stream
        videoRef.current.setAttribute('playsinline', 'true')
        videoRef.current.play()
        requestAnimationFrame(scanQRCodeFromVideo)
      }
    } catch (err: any) {
      setIsScanning(false)
      setErrorMessage(t('camera_permission_error', lang))
    }
  }

  const stopCamera = () => {
    setIsScanning(false)
    if (animationFrameRef.current) {
      cancelAnimationFrame(animationFrameRef.current)
      animationFrameRef.current = null
    }
    if (streamRef.current) {
      streamRef.current.getTracks().forEach(track => track.stop())
      streamRef.current = null
    }
  }

  const handleDetectedPayload = async (qrText: string) => {
    try {
      let parsed: any = null
      try {
        parsed = JSON.parse(qrText)
      } catch {
        // Support URL format: mdaily://sync?ip=192.168.1.5&port=18321&token=ABC123
        if (qrText.startsWith('http://') || qrText.startsWith('mdaily://')) {
          const url = new URL(qrText.replace('mdaily://', 'http://'))
          parsed = {
            ip: url.searchParams.get('ip') || url.hostname,
            port: parseInt(url.searchParams.get('port') || '18321', 10),
            token: url.searchParams.get('token') || '',
            name: url.searchParams.get('name') || 'Desktop'
          }
        }
      }

      if (!parsed || !parsed.ip || !parsed.token) {
        setErrorMessage(t('qr_not_detected', lang))
        return
      }

      stopCamera()
      await connectToServer({
        ip: parsed.ip,
        port: parsed.port || 18321,
        token: parsed.token,
        name: parsed.name || 'MDaily Desktop'
      })
    } catch (err: any) {
      setErrorMessage(err?.message || t('sync_error', lang))
    }
  }

  const scanQRCodeFromVideo = () => {
    if (!videoRef.current || videoRef.current.readyState !== videoRef.current.HAVE_ENOUGH_DATA) {
      animationFrameRef.current = requestAnimationFrame(scanQRCodeFromVideo)
      return
    }

    const video = videoRef.current
    const canvas = canvasRef.current || document.createElement('canvas')
    canvasRef.current = canvas
    canvas.width = video.videoWidth
    canvas.height = video.videoHeight

    const ctx = canvas.getContext('2d', { willReadFrequently: true })
    if (ctx) {
      ctx.drawImage(video, 0, 0, canvas.width, canvas.height)
      const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height)
      const code = jsQR(imageData.data, imageData.width, imageData.height, {
        inversionAttempts: 'dontInvert'
      })

      if (code && code.data) {
        handleDetectedPayload(code.data)
        return
      }
    }

    animationFrameRef.current = requestAnimationFrame(scanQRCodeFromVideo)
  }

  const handleImageUpload = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return

    const reader = new FileReader()
    reader.onload = (event) => {
      const img = new Image()
      img.onload = () => {
        const canvas = document.createElement('canvas')
        canvas.width = img.width
        canvas.height = img.height
        const ctx = canvas.getContext('2d')
        if (ctx) {
          ctx.drawImage(img, 0, 0)
          const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height)
          const code = jsQR(imageData.data, imageData.width, imageData.height)
          if (code && code.data) {
            handleDetectedPayload(code.data)
          } else {
            setErrorMessage(t('qr_not_detected', lang))
          }
        }
      }
      img.src = event.target?.result as string
    }
    reader.readAsDataURL(file)
  }

  const connectToServer = async (config: SyncServerConfig) => {
    setIsSyncing(true)
    setErrorMessage(null)
    setStatusMessage('Đang kiểm tra kết nối với máy tính...')

    try {
      const pingResult = await pingSyncServer(config.ip, config.port)
      const fullConfig = {
        ...config,
        name: pingResult.deviceName || config.name || 'MDaily Desktop'
      }
      setPairedServer(fullConfig)
      saveLastSyncServer(fullConfig)
      setActiveTab('connected')
      setStatusMessage(`${t('paired_with', lang)}: ${fullConfig.name}`)
    } catch (err: any) {
      setErrorMessage(t('sync_error', lang))
    } finally {
      setIsSyncing(false)
    }
  }

  const handleManualConnect = (e: React.FormEvent) => {
    e.preventDefault()
    if (!manualIp.trim() || !manualToken.trim()) {
      setErrorMessage('Vui lòng nhập IP và Mã PIN')
      return
    }
    connectToServer({
      ip: manualIp.trim(),
      port: parseInt(manualPort, 10) || 18321,
      token: manualToken.trim().toUpperCase(),
      name: 'MDaily Desktop'
    })
  }

  const handleExecuteSync = async (mode: 'merge' | 'push' | 'pull') => {
    if (!pairedServer) return
    setIsSyncing(true)
    setErrorMessage(null)
    setStatusMessage(t('syncing', lang))

    try {
      let res: any
      if (mode === 'merge') {
        res = await performTwoWayMerge(pairedServer)
      } else if (mode === 'push') {
        res = await performPushToDesktop(pairedServer)
      } else if (mode === 'pull') {
        res = await performPullFromDesktop(pairedServer)
      }

      setStatusMessage(res?.message || t('sync_success', lang))
      onSyncCompleted?.()
    } catch (err: any) {
      setErrorMessage(err?.message || t('sync_error', lang))
    } finally {
      setIsSyncing(false)
    }
  }

  const handleDisconnect = () => {
    clearLastSyncServer()
    setPairedServer(null)
    setActiveTab('scan')
    setStatusMessage(null)
    setErrorMessage(null)
  }

  if (!isOpen) return null

  return (
    <div className="wifi-sync-overlay" onClick={onClose}>
      <div className="wifi-sync-modal" onClick={e => e.stopPropagation()}>
        {/* Header */}
        <div className="wifi-sync-header">
          <div className="wifi-sync-title-group">
            <div className="wifi-sync-icon-badge">
              <Wifi size={18} />
            </div>
            <div>
              <h3>{t('wifi_sync', lang)}</h3>
              <p className="wifi-sync-sub">{t('wifi_sync_desc', lang)}</p>
            </div>
          </div>
          <button className="btn-close-sync" onClick={onClose} aria-label="Close">
            <X size={20} />
          </button>
        </div>

        {/* Tab Navigation */}
        <div className="wifi-sync-nav-tabs">
          <button
            className={`sync-nav-tab ${activeTab === 'scan' ? 'active' : ''}`}
            onClick={() => { setActiveTab('scan'); setErrorMessage(null) }}
          >
            <Camera size={16} />
            <span>{t('scan_qr', lang)}</span>
          </button>
          <button
            className={`sync-nav-tab ${activeTab === 'manual' ? 'active' : ''}`}
            onClick={() => { setActiveTab('manual'); setErrorMessage(null) }}
          >
            <KeyRound size={16} />
            <span>{t('manual_ip_input', lang)}</span>
          </button>
          {pairedServer && (
            <button
              className={`sync-nav-tab ${activeTab === 'connected' ? 'active' : ''}`}
              onClick={() => { setActiveTab('connected'); setErrorMessage(null) }}
            >
              <Laptop size={16} />
              <span>{t('sync_connected', lang)}</span>
            </button>
          )}
        </div>

        {/* Body Content */}
        <div className="wifi-sync-body">
          {/* 1. Camera QR Scanner Tab */}
          {activeTab === 'scan' && (
            <div className="scanner-container">
              <div className={`camera-viewport-card ${isScanning ? 'scanning' : ''}`}>
                <video ref={videoRef} className="camera-video-stream" muted />
                <div className="qr-aim-box">
                  <span className="corner top-left" />
                  <span className="corner top-right" />
                  <span className="corner bottom-left" />
                  <span className="corner bottom-right" />
                  {isScanning && <div className="qr-laser-line" />}
                </div>
              </div>

              <p className="scanner-instruction">
                {t('scan_qr_desc', lang)}
              </p>

              <div className="scanner-action-row">
                <button
                  className="btn-sync-utility"
                  onClick={() => fileInputRef.current?.click()}
                >
                  <ImageIcon size={16} />
                  <span>{t('choose_qr_image', lang)}</span>
                </button>
                <input
                  type="file"
                  ref={fileInputRef}
                  style={{ display: 'none' }}
                  accept="image/*"
                  onChange={handleImageUpload}
                />
              </div>
            </div>
          )}

          {/* 2. Manual IP Tab */}
          {activeTab === 'manual' && (
            <form className="manual-connect-form" onSubmit={handleManualConnect}>
              <div className="sync-form-group">
                <label>{t('ip_address', lang)}</label>
                <input
                  type="text"
                  placeholder="192.168.1.xxx"
                  value={manualIp}
                  onChange={e => setManualIp(e.target.value)}
                  autoFocus
                />
              </div>

              <div className="sync-form-row">
                <div className="sync-form-group flex-1">
                  <label>{t('port', lang)}</label>
                  <input
                    type="number"
                    placeholder="18321"
                    value={manualPort}
                    onChange={e => setManualPort(e.target.value)}
                  />
                </div>
                <div className="sync-form-group flex-1">
                  <label>{t('token', lang)} (PIN)</label>
                  <input
                    type="text"
                    placeholder="A9F3C2"
                    value={manualToken}
                    onChange={e => setManualToken(e.target.value.toUpperCase())}
                  />
                </div>
              </div>

              <button
                type="submit"
                className="btn-sync-primary"
                disabled={isSyncing || !manualIp.trim() || !manualToken.trim()}
              >
                {isSyncing ? (
                  <>
                    <RefreshCw size={16} className="spinner" />
                    <span>{t('syncing', lang)}</span>
                  </>
                ) : (
                  <>
                    <Wifi size={16} />
                    <span>{t('connect', lang)}</span>
                  </>
                )}
              </button>
            </form>
          )}

          {/* 3. Connected & Sync Actions Tab */}
          {activeTab === 'connected' && pairedServer && (
            <div className="connected-sync-view">
              {/* Paired Machine Status Card */}
              <div className="paired-device-card">
                <div className="paired-device-left">
                  <div className="paired-device-icon">
                    <Laptop size={22} />
                  </div>
                  <div className="paired-device-info">
                    <h4>{pairedServer.name || 'MDaily Desktop'}</h4>
                    <span className="paired-ip-badge">
                      {pairedServer.ip}:{pairedServer.port}
                    </span>
                  </div>
                </div>
                <button className="btn-disconnect-link" onClick={handleDisconnect} title={t('disconnect', lang)}>
                  {t('disconnect', lang)}
                </button>
              </div>

              {/* Sync Actions Grid */}
              <div className="sync-actions-list">
                {/* 1. Two-Way Merge */}
                <div className="sync-action-card recommended" onClick={() => !isSyncing && handleExecuteSync('merge')}>
                  <div className="sync-action-icon merge">
                    <ArrowUpDown size={20} />
                  </div>
                  <div className="sync-action-info">
                    <div className="sync-action-header">
                      <span className="sync-action-title">{t('sync_two_way', lang)}</span>
                      <span className="sync-rec-badge">Khuyên dùng</span>
                    </div>
                    <p className="sync-action-desc">{t('sync_two_way_desc', lang)}</p>
                  </div>
                </div>

                {/* 2. Push to Desktop */}
                <div className="sync-action-card" onClick={() => !isSyncing && handleExecuteSync('push')}>
                  <div className="sync-action-icon push">
                    <UploadCloud size={20} />
                  </div>
                  <div className="sync-action-info">
                    <span className="sync-action-title">{t('sync_push', lang)}</span>
                    <p className="sync-action-desc">{t('sync_push_desc', lang)}</p>
                  </div>
                </div>

                {/* 3. Pull from Desktop */}
                <div className="sync-action-card" onClick={() => !isSyncing && handleExecuteSync('pull')}>
                  <div className="sync-action-icon pull">
                    <DownloadCloud size={20} />
                  </div>
                  <div className="sync-action-info">
                    <span className="sync-action-title">{t('sync_pull', lang)}</span>
                    <p className="sync-action-desc">{t('sync_pull_desc', lang)}</p>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* Feedback & Status Area */}
          {statusMessage && (
            <div className="sync-feedback success">
              <CheckCircle2 size={16} />
              <span>{statusMessage}</span>
            </div>
          )}

          {errorMessage && (
            <div className="sync-feedback error">
              <AlertCircle size={16} />
              <span>{errorMessage}</span>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
