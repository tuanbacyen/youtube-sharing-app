import { useState } from 'react'
import client from '../api/client'

export default function ShareModal({ onClose, onSuccess }) {
  const [url, setUrl] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')
    setLoading(true)
    try {
      const res = await client.post('/videos', { youtube_url: url })
      onSuccess(res.data)
    } catch (err) {
      setError(err.response?.data?.error || 'Failed to share video. Check the URL.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div style={styles.overlay} onClick={onClose}>
      <div style={styles.modal} onClick={e => e.stopPropagation()}>
        <fieldset style={styles.fieldset}>
          <legend style={{ padding: '0 8px' }}>Share a Youtube movie</legend>
          <form onSubmit={handleSubmit}>
            <div style={styles.row}>
              <label style={styles.label}>Youtube URL:</label>
              <input type="url" name="Youtube URL" value={url}
                onChange={e => setUrl(e.target.value)} style={styles.input}
                placeholder="https://www.youtube.com/watch?v=..." required />
            </div>
            {error && <p style={styles.error}>{error}</p>}
            <div style={{ textAlign: 'center' }}>
              <button type="submit" style={styles.btn} disabled={loading}>
                {loading ? 'Sharing...' : 'Share'}
              </button>
            </div>
          </form>
        </fieldset>
      </div>
    </div>
  )
}

const styles = {
  overlay: { position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100 },
  modal: { background: '#fff', padding: '32px', borderRadius: '8px', minWidth: '420px' },
  fieldset: { border: '1px solid #ccc', padding: '20px 24px', borderRadius: '4px' },
  row: { display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '20px' },
  label: { minWidth: '100px', fontSize: '14px' },
  input: { flex: 1, padding: '8px', border: '1px solid #ccc', borderRadius: '4px', fontSize: '14px' },
  btn: { padding: '8px 48px', border: '1px solid #ccc', borderRadius: '4px', fontSize: '14px' },
  error: { color: 'red', fontSize: '13px', marginBottom: '12px' }
}
