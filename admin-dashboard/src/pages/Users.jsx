import { useEffect, useState } from 'react'
import { api } from '../api'

const emptyForm = { fullName: '', email: '', tier: 'Basic', active: true, isAdmin: false }

export default function Users() {
  const [users, setUsers] = useState([])
  const [form, setForm] = useState(emptyForm)
  const [editingId, setEditingId] = useState(null)
  const [error, setError] = useState(null)
  const [tempPassword, setTempPassword] = useState(null)

  function loadUsers() {
    api.getUsers().then(setUsers).catch((err) => setError(err.message))
  }

  useEffect(loadUsers, [])

  function handleChange(e) {
    const { name, value, type, checked } = e.target
    setForm((f) => ({ ...f, [name]: type === 'checkbox' ? checked : value }))
  }

  async function handleSubmit(e) {
    e.preventDefault()
    if (!form.fullName || !form.email) return

    setError(null)
    try {
      if (editingId) {
        await api.updateUser(editingId, form)
      } else {
        const created = await api.createUser(form)
        if (created.tempPassword) setTempPassword({ email: created.email, password: created.tempPassword })
      }
      setForm(emptyForm)
      setEditingId(null)
      loadUsers()
    } catch (err) {
      setError(err.message)
    }
  }

  function handleEdit(user) {
    setEditingId(user.id)
    setTempPassword(null)
    setForm({ fullName: user.fullName, email: user.email, tier: user.tier, active: user.active })
  }

  async function handleToggleActive(user) {
    setError(null)
    try {
      await api.setUserActive(user.id, !user.active)
      loadUsers()
    } catch (err) {
      setError(err.message)
    }
  }

  function handleCancel() {
    setEditingId(null)
    setForm(emptyForm)
  }

  return (
    <div>
      <h1>Users</h1>
      <p className="page-subtitle">Manage real MIANE user accounts via the Identity.API admin endpoints (Admin role required).</p>

      {error && <p className="error-text">{error}</p>}
      {tempPassword && (
        <p className="error-text" style={{ background: '#dcfce7', color: '#166534' }}>
          Created {tempPassword.email} with temporary password <strong>{tempPassword.password}</strong> — share it once, the user should change it on first login.
        </p>
      )}

      <div className="card">
        <h2>{editingId ? 'Edit User' : 'Add User'}</h2>
        <form className="form-row" onSubmit={handleSubmit}>
          <input
            name="fullName"
            placeholder="Full name"
            value={form.fullName}
            onChange={handleChange}
          />
          <input
            name="email"
            placeholder="Email"
            value={form.email}
            onChange={handleChange}
            disabled={!!editingId}
            title={editingId ? 'Email cannot be changed here' : undefined}
          />
          <select name="tier" value={form.tier} onChange={handleChange}>
            <option value="Basic">Basic</option>
            <option value="Pro">Pro</option>
          </select>
          {!editingId && (
            <>
              <label className="checkbox-label">
                <input
                  type="checkbox"
                  name="active"
                  checked={form.active}
                  onChange={handleChange}
                />
                Active
              </label>
              <label className="checkbox-label">
                <input
                  type="checkbox"
                  name="isAdmin"
                  checked={form.isAdmin}
                  onChange={handleChange}
                />
                Grant Admin access
              </label>
            </>
          )}
          <button type="submit">{editingId ? 'Save' : 'Add'}</button>
          {editingId && (
            <button type="button" className="btn-secondary" onClick={handleCancel}>
              Cancel
            </button>
          )}
        </form>
      </div>

      <div className="card">
        <table className="data-table">
          <thead>
            <tr>
              <th>Full Name</th>
              <th>Email</th>
              <th>Tier</th>
              <th>Status</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            {users.map((u) => (
              <tr key={u.id}>
                <td>
                  {u.fullName}
                  {u.isAdmin && <span className="badge badge-admin" style={{ marginLeft: 8 }}>Admin</span>}
                </td>
                <td>{u.email}</td>
                <td>{u.tier}</td>
                <td>
                  <span className={u.active ? 'badge badge-active' : 'badge badge-inactive'}>
                    {u.active ? 'Active' : 'Inactive'}
                  </span>
                </td>
                <td className="actions-cell">
                  <button className="btn-secondary" onClick={() => handleEdit(u)}>Edit</button>
                  <button
                    className={u.active ? 'btn-danger' : 'btn-secondary'}
                    onClick={() => handleToggleActive(u)}
                  >
                    {u.active ? 'Deactivate' : 'Activate'}
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
