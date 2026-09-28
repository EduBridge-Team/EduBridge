// دراسة الحالة مع المختصين (البطاقة 7)
import { useCallback, useEffect, useState } from 'react'
import { Navigate } from 'react-router-dom'
import { Stethoscope } from 'lucide-react'
import {
  getUser,
  fetchConsultations,
  createConsultation,
  fetchConsultation,
  updateConsultation,
  addConsultationNote,
  fetchChildren,
} from '../../api'

import { ConsultationList, ConsultationRequestForm } from './ConsultationSections'

export default function ConsultationsPage() {
  const me = getUser()
  const isSpecialist = me && ['specialist', 'admin'].includes(me.role)
  const [items, setItems] = useState([])
  const [children, setChildren] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [form, setForm] = useState({ child_id: '', title: '', description: '' })
  const [sending, setSending] = useState(false)
  const [openId, setOpenId] = useState(null)
  const [detail, setDetail] = useState(null) // { consultation, notes }
  const [note, setNote] = useState('')

  const load = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const data = await fetchConsultations()
      setItems(data.consultations || [])
      const c = await fetchChildren()
      setChildren(c.children || [])
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    load()
  }, [load])

  if (!me) return <Navigate to="/login" replace />

  const submit = async (e) => {
    e.preventDefault()
    if (!form.child_id || !form.title.trim()) {
      setError('اختر الطفل وأدخل عنوان الحالة')
      return
    }
    setSending(true)
    setError(null)
    try {
      await createConsultation({
        child_id: Number(form.child_id),
        title: form.title.trim(),
        description: form.description.trim() || undefined,
      })
      setForm({ child_id: '', title: '', description: '' })
      await load()
    } catch (err) {
      setError(err.message)
    } finally {
      setSending(false)
    }
  }

  const openDetail = async (id) => {
    if (openId === id) {
      setOpenId(null)
      setDetail(null)
      return
    }
    setOpenId(id)
    setDetail(null)
    try {
      const d = await fetchConsultation(id)
      setDetail(d)
    } catch (err) {
      setError(err.message)
    }
  }

  const claim = async (id) => {
    try {
      await updateConsultation(id, { claim: true })
      const d = await fetchConsultation(id)
      setDetail(d)
      load()
    } catch (err) {
      setError(err.message)
    }
  }

  const setStatus = async (id, status) => {
    try {
      await updateConsultation(id, { status })
      const d = await fetchConsultation(id)
      setDetail(d)
      load()
    } catch (err) {
      setError(err.message)
    }
  }

  const submitNote = async (id) => {
    if (!note.trim()) return
    try {
      const d = await addConsultationNote(id, note.trim())
      setNote('')
      setDetail((prev) => ({ ...prev, notes: d.notes }))
    } catch (err) {
      setError(err.message)
    }
  }

  return (
    <div>
      <div className="page-title">
        <h2 style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <Stethoscope size={20} /> دراسة الحالة مع المختصين
        </h2>
      </div>

      {!isSpecialist && (
        <ConsultationRequestForm
          children={children}
          error={error}
          form={form}
          onChange={setForm}
          onSubmit={submit}
          sending={sending}
        />
      )}

      <div className="page-title" style={{ marginTop: 8 }}>
        <h3>{isSpecialist ? 'طلبات دراسة الحالة' : 'طلباتي'}</h3>
      </div>

      {error && isSpecialist && <div className="error-box">{error}</div>}

      <ConsultationList
        detail={detail}
        isSpecialist={isSpecialist}
        items={items}
        loading={loading}
        me={me}
        note={note}
        onClaim={claim}
        onNoteChange={setNote}
        onOpenDetail={openDetail}
        onSetStatus={setStatus}
        onSubmitNote={submitNote}
        openId={openId}
      />
    </div>
  )
}
