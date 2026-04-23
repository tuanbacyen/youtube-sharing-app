import { useState, useEffect, useCallback } from 'react'
import Navbar from './components/Navbar'
import VideoList from './components/VideoList'
import ShareModal from './components/ShareModal'
import NotificationToast from './components/NotificationToast'
import { useAuth } from './hooks/useAuth'
import { useActionCable } from './hooks/useActionCable'
import client from './api/client'

export default function App() {
  const { user, login, register, logout } = useAuth()
  const [videos, setVideos] = useState([])
  const [showShareModal, setShowShareModal] = useState(false)
  const [notifications, setNotifications] = useState([])

  const fetchVideos = useCallback(async () => {
    const res = await client.get('/videos')
    setVideos(res.data)
  }, [])

  useEffect(() => { fetchVideos() }, [fetchVideos])

  const handleNotification = useCallback((data) => {
    if (data.type === 'new_video') {
      setNotifications(prev => [...prev, { id: Date.now(), ...data }])
      fetchVideos()
    }
  }, [fetchVideos])

  useActionCable(user, handleNotification)

  const handleLogin = async (email, password) => {
    try {
      await login(email, password)
    } catch {
      await register(email, password)
    }
  }

  const handleShareSuccess = (video) => {
    setVideos(prev => [video, ...prev])
    setShowShareModal(false)
  }

  return (
    <div>
      <Navbar
        user={user}
        onLogin={handleLogin}
        onLogout={logout}
        onShareClick={() => setShowShareModal(true)}
      />
      <main style={{ padding: '24px', maxWidth: '900px', margin: '0 auto' }}>
        <VideoList videos={videos} />
      </main>
      {showShareModal && (
        <ShareModal
          onClose={() => setShowShareModal(false)}
          onSuccess={handleShareSuccess}
        />
      )}
      {notifications.map(n => (
        <NotificationToast
          key={n.id}
          notification={n}
          onDismiss={() => setNotifications(prev => prev.filter(x => x.id !== n.id))}
        />
      ))}
    </div>
  )
}
