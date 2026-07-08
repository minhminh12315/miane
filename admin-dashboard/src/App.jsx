import { Routes, Route, Navigate } from 'react-router-dom'
import { useAuth } from './AuthContext'
import Sidebar from './components/Sidebar'
import Login from './pages/Login'
import Dashboard from './pages/Dashboard'
import Users from './pages/Users'
import Databases from './pages/Databases'

export default function App() {
  const { user, loading } = useAuth()

  if (loading) {
    return <p className="page-subtitle" style={{ padding: 40 }}>Loading...</p>
  }

  if (!user) {
    return <Login />
  }

  return (
    <div className="layout">
      <Sidebar />
      <main className="content">
        <Routes>
          <Route path="/" element={<Dashboard />} />
          <Route path="/users" element={<Users />} />
          <Route path="/databases" element={<Databases />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </main>
    </div>
  )
}
