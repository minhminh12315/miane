import { useEffect, useState } from 'react'
import { api } from '../api'

export default function Databases() {
  const [databases, setDatabases] = useState([])
  const [openDb, setOpenDb] = useState(null)
  const [error, setError] = useState(null)

  useEffect(() => {
    let cancelled = false
    api
      .getDatabases()
      .then((data) => {
        if (cancelled) return
        setDatabases(data)
        setOpenDb(data[0]?.name ?? null)
      })
      .catch((err) => {
        if (!cancelled) setError(err.message)
      })
    return () => {
      cancelled = true
    }
  }, [])

  if (error) {
    return <p className="error-text">Failed to load databases: {error}</p>
  }

  return (
    <div>
      <h1>Databases</h1>
      <p className="page-subtitle">Live view of the 4 MIANE service databases (real schema and row counts).</p>

      {databases.map((db) => {
        const isOpen = openDb === db.name
        return (
          <div className="card" key={db.name}>
            <button
              className="db-header"
              onClick={() => setOpenDb(isOpen ? null : db.name)}
            >
              <div>
                <strong>{db.name}</strong>
                <span className="page-subtitle" style={{ marginLeft: 8 }}>{db.description}</span>
              </div>
              <span>{isOpen ? '-' : '+'}</span>
            </button>

            {isOpen && (
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Table</th>
                    <th>Rows</th>
                    <th>Columns</th>
                  </tr>
                </thead>
                <tbody>
                  {db.tables.map((t) => (
                    <tr key={t.name}>
                      <td>{t.name}</td>
                      <td>{t.rows.toLocaleString()}</td>
                      <td>{t.columns.join(', ')}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        )
      })}
    </div>
  )
}
