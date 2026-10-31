import { useRef, useState } from 'react'
import { request } from '../../api/core'
import { schoolOperationPayload, SCHOOL_ACTIONS } from './schoolOperations'
import { useSchoolLanguage } from './useSchoolLanguage'

export default function SchoolOperationForm({ category, references, onSaved }) {
  const { t } = useSchoolLanguage()
  const definitions = SCHOOL_ACTIONS.filter(item => item.category === category)
  const [action, setAction] = useState(definitions[0]?.action || '')
  const [values, setValues] = useState({})
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [saved, setSaved] = useState(false)
  const pending = useRef(false)
  const definition = definitions.find(item => item.action === action)
  if (!definition) return null

  async function submit(event) {
    event.preventDefault()
    if (pending.current) return
    if (definition.destructive && !window.confirm(t('تأكيد هذا الإجراء؟ سيبقى السجل السابق محفوظًا حيث ينطبق.', 'Confirm this action? Previous records are preserved where applicable.'))) return
    pending.current = true; setBusy(true); setError(''); setSaved(false)
    try {
      const payload = { ...schoolOperationPayload(definition, values), expected_school_id: references.school.id }
      await request('/school/operations/' + definition.action, { method: definition.method || 'POST', body: JSON.stringify(payload) })
      setValues({}); setSaved(true); onSaved()
    } catch (err) { setError(err.message) }
    finally { pending.current = false; setBusy(false) }
  }

  const labelFor = row => row.label || [row.child_name || row.teacher_name || row.name || row.title || row.attendance_date || row.subject_name, row.section_name, row.academic_year_name].filter(Boolean).join(' — ') || String(row.id)
  return <form className="institution-school-form" onSubmit={submit}>
    <label>{t('الإجراء', 'Action')}<select value={action} disabled={busy} onChange={event => { setAction(event.target.value); setValues({}); setError(''); setSaved(false) }}>{definitions.map(item => <option key={item.action} value={item.action}>{t(item.ar, item.en)}</option>)}</select></label>
    {definition.fields.map(field => {
      const options = references[field.reference] || []
      const common = { disabled: busy, required: !field.optional && field.type !== 'checkbox', onChange: event => setValues(old => ({ ...old, [field.key]: field.type === 'checkbox' ? event.target.checked : event.target.value })) }
      return <label key={field.key}>{t(field.ar, field.en)}
        {field.type === 'select' ? <select {...common} value={values[field.key] || ''}>
          <option value="">{t('اختر…', 'Choose…')}</option>{options.map(row => <option key={row.id} value={row.id}>{labelFor(row)}</option>)}
        </select> : field.type === 'textarea' ? <textarea {...common} maxLength={50000} value={values[field.key] || ''} /> : field.type === 'checkbox' ? <input {...common} type="checkbox" checked={values[field.key] === true} /> : <input {...common} type={field.type} min={field.type === 'number' ? 1 : undefined} value={values[field.key] || ''} />}
      </label>
    })}
    {error && <p role="alert">{error}</p>}{saved && <p role="status">{t('تم الحفظ.', 'Saved.')}</p>}
    <button className="btn" disabled={busy}>{busy ? t('جارِ الحفظ…', 'Saving…') : t('حفظ', 'Save')}</button>
  </form>
}
