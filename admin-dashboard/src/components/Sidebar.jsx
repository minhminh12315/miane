import { NavLink } from 'react-router-dom'
import { useAuth } from '../AuthContext'

export default function Sidebar() {
  const { user, logout } = useAuth()

  return (
    <aside className="sidebar">
      <div className="sidebar-title">MIANE Admin</div>
      <nav>
        <NavLink to="/" end className="nav-link">Dashboard</NavLink>
        <NavLink to="/users" className="nav-link">Users</NavLink>
        <NavLink to="/databases" className="nav-link">Databases</NavLink>
      </nav>
      <div className="sidebar-footer">
        <div className="sidebar-user">{user?.fullName}</div>
        <button className="btn-secondary" onClick={logout} style={{ width: '100%' }}>
          Logout
        </button>
      </div>
    </aside>
  )
}
