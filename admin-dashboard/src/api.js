const BASE_URL = 'http://localhost:4000/api'

class AuthError extends Error {}

async function request(path, options) {
  const res = await fetch(`${BASE_URL}${path}`, {
    headers: { 'Content-Type': 'application/json' },
    credentials: 'include',
    ...options,
  })
  if (!res.ok) {
    const body = await res.json().catch(() => ({}))
    if (res.status === 401) throw new AuthError(body.error || 'Not authenticated')
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
