import { useEffect, useState } from 'react'
import { api } from '../api'

const PAGE_SIZE = 5

export default function Dashboard() {
  const [stats, setStats] = useState(null)
  const [activity, setActivity] = useState([])
  const [page, setPage] = useState(1)
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
    { label: 'Users', value: stats.users },
    { label: 'Trips', value: stats.trips },
    { label: 'Expenses', value: stats.expenses },
  ]
  const totalPages = Math.max(1, Math.ceil(activity.length / PAGE_SIZE))
  const visibleActivity = activity.slice((page - 1) * PAGE_SIZE, page * PAGE_SIZE)

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
          <>
            <ul className="activity-list">
              {visibleActivity.map((a) => (
                <li key={a.id}>
                  <span>{a.text}</span>
                  <span className="activity-time">{new Date(a.time).toLocaleString()}</span>
                </li>
              ))}
            </ul>

            <div className="pagination">
              <button
                className="btn-secondary"
                disabled={page === 1}
                onClick={() => setPage((current) => current - 1)}
              >
                Previous
              </button>
              <span>Page {page} of {totalPages}</span>
              <button
                className="btn-secondary"
                disabled={page === totalPages}
                onClick={() => setPage((current) => current + 1)}
              >
                Next
              </button>
            </div>
          </>
        )}
      </div>
    </div>
  )
}
