import { useEffect } from 'react'

export default function NotificationToast({ notification, onDismiss }) {
  useEffect(() => {
    const timer = setTimeout(onDismiss, 5000)
    return () => clearTimeout(timer)
  }, [onDismiss])

  return (
    <div style={styles.toast} data-testid="notification-toast">
      <strong>{notification.shared_by}</strong> shared a video:<br />
      <span style={styles.title}>{notification.title}</span>
      <button onClick={onDismiss} style={styles.close}>×</button>
    </div>
  )
}

const styles = {
  toast: { position: 'fixed', top: '20px', right: '20px', background: '#333', color: '#fff', padding: '16px 40px 16px 16px', borderRadius: '8px', maxWidth: '320px', zIndex: 200, lineHeight: '1.6', boxShadow: '0 4px 12px rgba(0,0,0,0.3)' },
  title: { fontStyle: 'italic' },
  close: { position: 'absolute', top: '8px', right: '10px', background: 'none', border: 'none', color: '#fff', fontSize: '20px' }
}
