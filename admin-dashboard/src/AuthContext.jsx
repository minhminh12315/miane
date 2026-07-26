import { createContext, useContext, useEffect, useState } from 'react'
import { api, setUnauthorizedHandler } from './api'

const AuthContext = createContext(null)

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    setUnauthorizedHandler(() => setUser(null))
    api.me()
      .then(setUser)
      .catch(() => setUser(null))
      .finally(() => setLoading(false))

    return () => setUnauthorizedHandler(null)
  }, [])

  async function login(email, password) {
    const me = await api.login(email, password)
    setUser(me)
  }

  async function logout() {
    await api.logout().catch(() => {})
    setUser(null)
  }

  return (
    <AuthContext.Provider value={{ user, loading, login, logout }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  return useContext(AuthContext)
}
