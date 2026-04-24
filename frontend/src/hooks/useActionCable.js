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
    const proto  = window.location.protocol === 'https:' ? 'wss' : 'ws'
    const wsUrl  = `${proto}://${window.location.host}`
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
