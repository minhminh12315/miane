import { useEffect, useState } from 'react'
import { api } from '../api'

export default function Dashboard() {
  const [stats, setStats] = useState(null)
  const [activity, setActivity] = useState([])
  const [error, setError] = useState(null)

  useEffect(() => {
    Promise.all([api.getStats(), api.getActivity()])
      .then(([s, a]) => {
        setStats(s)
        setActivity(a)
      })
      .catch((err) => setError(err.message))
  }, [])

  if (error) {
    return <p className="error-text">Failed to load dashboard: {error}</p>
  }

  if (!stats) {
    return <p className="page-subtitle">Loading...</p>
  }

  const cards = [
    { label: 'Databases', value: stats.databases },
    { label: 'Users', value: stats.users },
    { label: 'Trips', value: stats.trips },
    { label: 'Expenses', value: stats.expenses },
  ]

  return (
    <div>
      <h1>Dashboard</h1>
      <p className="page-subtitle">Live overview of the MIANE system.</p>

      <div className="stat-grid">
        {cards.map((s) => (
          <div className="card stat-card" key={s.label}>
            <div className="stat-value">{s.value}</div>
            <div className="stat-label">{s.label}</div>
          </div>
        ))}
      </div>

      <div className="card">
        <h2>Recent Activity</h2>
        {activity.length === 0 ? (
          <p className="page-subtitle">No activity yet.</p>
        ) : (
          <ul className="activity-list">
            {activity.map((a) => (
              <li key={a.id}>
                <span>{a.text}</span>
                <span className="activity-time">{new Date(a.time).toLocaleString()}</span>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  )
}
