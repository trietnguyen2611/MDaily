import React, { useState, useEffect } from 'react';
import { X, Cpu, CheckCircle2, AlertTriangle, RefreshCw } from 'lucide-react';
import { JanAIService } from '../services/JanAIService';

export const JanAISettingsModal = ({ isOpen, onClose }) => {
  const [config, setConfig] = useState({
    baseUrl: 'http://localhost:1337/v1',
    model: 'gemma-2-2b-it',
    temperature: 0.3
  });
  const [connectionStatus, setConnectionStatus] = useState(null);
  const [isTesting, setIsTesting] = useState(false);

  useEffect(() => {
    if (isOpen) {
      const current = JanAIService.getSettings();
      setConfig(current);
      testServerConnection(current);
    }
  }, [isOpen]);

  const testServerConnection = async (conf) => {
    setIsTesting(true);
    setConnectionStatus(null);
    try {
      const res = await JanAIService.checkConnection();
      setConnectionStatus(res);
    } catch (e) {
      setConnectionStatus({ connected: false, models: [] });
    } finally {
      setIsTesting(false);
    }
  };

  if (!isOpen) return null;

  const handleSave = (e) => {
    e.preventDefault();
    JanAIService.saveSettings(config);
    onClose();
  };

  return (
    <div className="modal-overlay">
      <div className="modal-content-apple" style={{ maxWidth: '520px' }}>
        <div className="modal-header">
          <div>
            <h3 style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <Cpu size={20} color="var(--color-primary)" />
              <span>Cấu hình Jan AI Server (Mac Intel)</span>
            </h3>
            <p style={{ fontSize: '13px', color: 'var(--color-ink-muted-48)' }}>
              Cấu hình endpoint API kết nối mô hình local Gemma 2 2B IT Q4 K M
            </p>
          </div>
          <button onClick={onClose} style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--color-ink-muted-48)' }}>
            <X size={20} />
          </button>
        </div>

        {/* Health status banner */}
        <div style={{ padding: '14px 18px', borderRadius: 'var(--radius-md)', backgroundColor: connectionStatus?.connected ? 'rgba(52, 199, 89, 0.1)' : 'rgba(255, 149, 0, 0.1)', border: `1px solid ${connectionStatus?.connected ? '#34c759' : '#ff9500'}`, display: 'flex', alignItems: 'center', justifyBetween: 'space-between', gap: '12px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            {connectionStatus?.connected ? (
              <CheckCircle2 size={20} color="#34c759" />
            ) : (
              <AlertTriangle size={20} color="#ff9500" />
            )}
            <div>
              <div style={{ fontWeight: 600, fontSize: '14px', color: connectionStatus?.connected ? '#2e7d32' : '#d84315' }}>
                {connectionStatus?.connected ? 'Đã kết nối Jan AI Server Local' : 'Jan AI Server chưa kết nối'}
              </div>
              <div style={{ fontSize: '12px', opacity: 0.8 }}>
                {connectionStatus?.connected
                  ? `Đang chạy mô hình ${config.model} qua Jan AI`
                  : 'Sẽ tự động kích hoạt bộ xử lý dự phòng (Offline Fallback Engine)'}
              </div>
            </div>
          </div>
          <button
            type="button"
            className="btn-dark-utility"
            style={{ fontSize: '12px', padding: '6px 12px' }}
            onClick={() => testServerConnection(config)}
            disabled={isTesting}
          >
            <RefreshCw size={12} className={isTesting ? 'spin-icon' : ''} />
            <span>Kiểm tra</span>
          </button>
        </div>

        <form onSubmit={handleSave} style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          <div>
            <label style={{ fontSize: '13px', fontWeight: 600 }}>Jan AI Server URL (OpenAI API Format)</label>
            <input
              type="text"
              className="input-apple"
              placeholder="http://localhost:1337/v1"
              value={config.baseUrl}
              onChange={(e) => setConfig({ ...config, baseUrl: e.target.value })}
              required
            />
            <p style={{ fontSize: '11px', color: 'var(--color-ink-muted-48)', marginTop: '4px' }}>
              Mặc định cổng trên phần mềm Jan AI Mac Intel là http://localhost:1337/v1
            </p>
          </div>

          <div>
            <label style={{ fontSize: '13px', fontWeight: 600 }}>Tên mô hình AI (*Gemma 2 2B)</label>
            <input
              type="text"
              className="input-apple"
              placeholder="gemma-2-2b-it"
              value={config.model}
              onChange={(e) => setConfig({ ...config, model: e.target.value })}
              required
            />
            <p style={{ fontSize: '11px', color: 'var(--color-ink-muted-48)', marginTop: '4px' }}>
              Tên mô hình cài trên Jan AI: gemma-2-2b-it hoặc gemma-2-2b-it-Q4_K_M
            </p>
          </div>

          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px', marginTop: '12px' }}>
            <button type="button" className="btn-secondary-pill" onClick={onClose}>
              Hủy
            </button>
            <button type="submit" className="btn-primary-pill">
              Lưu Cấu Hình
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
