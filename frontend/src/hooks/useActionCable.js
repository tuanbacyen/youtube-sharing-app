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

    const token = localStorage.getItem('token')
    // Use explicit WS URL env var if provided, otherwise derive from API URL.
    const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3969'
    const wsUrl  = process.env.NEXT_PUBLIC_WS_URL  || apiUrl.replace(/^http/, 'ws')
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
