'use client'
import { useState, useEffect, useCallback } from 'react'
import Navbar from '../components/Navbar'
import VideoList from '../components/VideoList'
import ShareModal from '../components/ShareModal'
import NotificationToast from '../components/NotificationToast'
import { useAuth } from '../hooks/useAuth'
import { useActionCable } from '../hooks/useActionCable'
import client from '../api/client'

export default function Home() {
  const { user, login, register, logout } = useAuth()
  const [videos, setVideos]               = useState<any[]>([])
  const [showShareModal, setShowShareModal] = useState(false)
  const [notification, setNotification]   = useState<any>(null)

  useEffect(() => {
    client.get('/videos').then(r => setVideos(r.data)).catch(() => {})
  }, [])

  const onNotification = useCallback((data: any) => {
    if (data?.shared_by && data.shared_by !== (user as any)?.email) setNotification(data)
    if (data?.id) setVideos(prev => prev.some(v => v.id === data.id) ? prev : [data, ...prev])
  }, [user])
  useActionCable(user, onNotification)

  const handleLogin = async (email: string, password: string) => {
    try { await login(email, password) }
    catch { await register(email, password) }
  }

  return (
    <>
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
          onSuccess={(video: any) => { setVideos((prev: any[]) => prev.some(v => v.id === video.id) ? prev : [video, ...prev]); setShowShareModal(false) }}
        />
      )}
      {notification && (
        <NotificationToast
          notification={notification}
          onDismiss={() => setNotification(null)}
        />
      )}
    </>
  )
}
