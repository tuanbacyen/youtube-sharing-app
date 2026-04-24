import { useEffect, useRef } from 'react'
import { createConsumer } from '@rails/actioncable'

export function useActionCable(user, onNotification) {
  const consumerRef = useRef(null)

  useEffect(() => {
    if (!user) {
      if (consumerRef.current) {
        consumerRef.current.disconnect()
        consumerRef.current = null
      }
      return
    }

    const token  = localStorage.getItem('token')
    const apiUrl = window.__API_URL__ || 'http://localhost:3969'
    const wsUrl  = apiUrl.replace(/^http/, 'ws')
    consumerRef.current = createConsumer(`${wsUrl}/cable?token=${token}`)
    consumerRef.current.subscriptions.create(
      { channel: 'NotificationsChannel' },
      { received: onNotification }
    )

    return () => {
      if (consumerRef.current) {
        consumerRef.current.disconnect()
        consumerRef.current = null
      }
    }
  }, [user, onNotification])
}
