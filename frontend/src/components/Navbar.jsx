import { useState } from 'react'

export default function Navbar({ user, onLogin, onLogout, onShareClick }) {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')
    setLoading(true)
    try {
      await onLogin(email, password)
      setEmail('')
      setPassword('')
    } catch (err) {
      setError(err.response?.data?.error || 'Login failed. Try registering.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <nav style={styles.nav}>
      <div style={styles.logo}>🏠 Funny Movies</div>
      <div style={styles.right}>
        {user ? (
          <>
            <span style={styles.welcome}>Welcome {user.email}</span>
            <button onClick={onShareClick} style={styles.btn}>Share a movie</button>
            <button onClick={onLogout} style={styles.btn}>Logout</button>
          </>
        ) : (
          <form onSubmit={handleSubmit} style={styles.form}>
            <input type="email" name="email" placeholder="email" value={email}
              onChange={e => setEmail(e.target.value)} style={styles.input} required />
            <input type="password" name="password" placeholder="password" value={password}
              onChange={e => setPassword(e.target.value)} style={styles.input} required />
            <button type="submit" style={styles.btn} disabled={loading}>
              {loading ? '...' : 'Login / Register'}
            </button>
            {error && <span style={styles.error}>{error}</span>}
          </form>
        )}
      </div>
    </nav>
  )
}

const styles = {
  nav: { display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '12px 24px', borderBottom: '1px solid #ddd' },
  logo: { fontSize: '22px', fontWeight: 'bold' },
  right: { display: 'flex', alignItems: 'center', gap: '8px' },
  form: { display: 'flex', alignItems: 'center', gap: '8px' },
  input: { padding: '6px 10px', border: '1px solid #ccc', borderRadius: '4px', fontSize: '14px' },
  btn: { padding: '6px 14px', border: '1px solid #ccc', borderRadius: '4px', background: '#fff', fontSize: '14px' },
  welcome: { fontSize: '14px' },
  error: { color: 'red', fontSize: '12px' }
}
