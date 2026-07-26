const BASE_URL = import.meta.env.VITE_API_URL || '/api'

class AuthError extends Error {}

let onUnauthorized = null

export function setUnauthorizedHandler(handler) {
  onUnauthorized = handler
}

async function request(path, options) {
  const res = await fetch(`${BASE_URL}${path}`, {
    headers: { 'Content-Type': 'application/json' },
    credentials: 'include',
    ...options,
  })
  if (!res.ok) {
    const body = await res.json().catch(() => ({}))
    if (res.status === 401) {
      const err = new AuthError(body.error || 'Not authenticated')
      if (onUnauthorized) onUnauthorized()
      throw err
    }
    throw new Error(body.error || `Request failed: ${res.status}`)
  }
  return res.json()
}

export const api = {
  login: (email, password) => request('/auth/login', { method: 'POST', body: JSON.stringify({ email, password }) }),
  logout: () => request('/auth/logout', { method: 'POST' }),
  me: () => request('/auth/me'),

  getStats: () => request('/stats'),
  getActivity: () => request('/activity'),
  getDatabases: () => request('/databases'),
  getUsers: () => request('/users'),
  createUser: (user) => request('/users', { method: 'POST', body: JSON.stringify(user) }),
  updateUser: (id, user) => request(`/users/${id}`, { method: 'PUT', body: JSON.stringify(user) }),
  setUserActive: (id, active) => request(`/users/${id}/status`, { method: 'PUT', body: JSON.stringify({ active }) }),
}

export { AuthError }
