import { useState, useEffect, useCallback } from 'react'
import client from '../api/client'

export function useAuth() {
  // Start null on both server and client so SSR HTML matches hydration.
  // Read localStorage only after mount to avoid the hydration mismatch.
  const [user, setUser] = useState(null)

  useEffect(() => {
    const token = localStorage.getItem('token')
    const email = localStorage.getItem('email')
    if (token && email) setUser({ token, email })
  }, [])

  const login = useCallback(async (email, password) => {
    const res = await client.post('/auth/login', { email, password })
    localStorage.setItem('token', res.data.token)
    localStorage.setItem('email', res.data.email)
    setUser({ token: res.data.token, email: res.data.email })
  }, [])

  const register = useCallback(async (email, password) => {
    const res = await client.post('/auth/register', { email, password })
    localStorage.setItem('token', res.data.token)
    localStorage.setItem('email', res.data.email)
    setUser({ token: res.data.token, email: res.data.email })
  }, [])

  const logout = useCallback(async () => {
    try {
      await client.delete('/auth/logout')
    } finally {
      localStorage.removeItem('token')
      localStorage.removeItem('email')
      setUser(null)
    }
  }, [])

  return { user, login, register, logout }
}
