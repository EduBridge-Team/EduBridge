import { useCallback, useEffect, useState } from 'react'
import { bulkCreateInstitutionInternalTeachers, createInstitutionInternalTeacher, fetchInstitutionInternalTeachers, resetInstitutionInternalTeacherPassword, setInstitutionInternalTeacherActive } from '../../api'

const EMPTY = { name: '', username: '' }

function parseCsv(csv) {
  const lines = csv.replace(/^\uFEFF/, '').trim().split(/\r?\n/).filter(Boolean)
  if (!lines.length) throw new Error('ملف CSV فارغ')
  const rows = lines.map(line => {
    // Quoted names and escaped double quotes are supported.
    const columns = []; let field = ''; let quoted = false
    for (let i = 0; i < line.length; i++) {
      const ch = line[i]
      if (ch === '"' && quoted && line[i + 1] === '"') { field += '"'; i++ }
      else if (ch === '"') quoted = !quoted
      else if (ch === ',' && !quoted) { columns.push(field.trim()); field = '' }
      else field += ch
    }
    if (quoted) throw new Error('تنسيق CSV غير صحيح')
    columns.push(field.trim())
    if (columns.length !== 2) throw new Error('كل سطر يجب أن يحتوي الاسم واسم المستخدم فقط')
    return { name: columns[0], username: columns[1].toLowerCase() }
  })
  if (rows[0].name.toLowerCase() === 'name' && rows[0].username === 'username') rows.shift()
  if (!rows.length || rows.length > 100) throw new Error('عدد الحسابات يجب أن يكون بين 1 و100')
  const pattern = /^[a-z0-9][a-z0-9._-]{1,63}$/
  if (rows.some(row => !row.name || row.name.length > 190 || !pattern.test(row.username))) {
    throw new Error('تحقق من الأسماء ومعرّفات الدخول في الملف')
  }
  if (new Set(rows.map(row => row.username)).size !== rows.length) throw new Error('يوجد اسم مستخدم مكرر في الملف')
  return rows
}

export default function InstitutionInternalTeachersPanel({ slug, onCreated }) {
  const [items, setItems] = useState([])
  const [domain, setDomain] = useState('')
  const [cursor, setCursor] = useState(null)
  const [form, setForm] = useState(EMPTY)
  const [csv, setCsv] = useState('')
  const [credentials, setCredentials] = useState([])
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const [notice, setNotice] = useState('')

  const reload = useCallback(async (after = null) => {
    const response = await fetchInstitutionInternalTeachers(slug, after)
    setDomain(response.internal_domain || '')
    setItems(previous => after ? [...previous, ...(response.identities || [])] : response.identities || [])
    setCursor(response.has_more ? response.next_after_id : null)
  }, [slug])

  useEffect(() => {
    if (!slug) return
    let active = true
    fetchInstitutionInternalTeachers(slug).then(data => {
      if (!active) return
      setDomain(data.internal_domain || '')
      setItems(data.identities || [])
      setCursor(data.has_more ? data.next_after_id : null)
    }).catch(e => { if (active) setError(e.message) })
    return () => { active = false }
  }, [slug])

  async function execute(action, success) {
    if (busy) return
    setBusy(true); setError(''); setNotice(''); setCredentials([])
    try {
      const response = await action()
      if (response.accounts) setCredentials(response.accounts)
      else if (response.temporary_password) setCredentials([{ login_identifier: items.find(i => i.id === response.identity_id)?.username + '@' + domain, temporary_password: response.temporary_password }])
      setNotice(success)
      await reload()
      onCreated?.()
    } catch (e) { setError(e.message) }
    finally { setBusy(false) }
  }

  return <section className="institution-panel" aria-label="حسابات المعلمين الداخلية">
    <h2>حسابات المعلمين الداخلية</h2>
    <p>أنشئ حسابات المعلمين مباشرة دون بريد إلكتروني. النطاق الداخلي <bdi dir="ltr">{domain || '—'}</bdi> مخصص للدخول فقط وليس صندوق بريد.</p>
    {error && <p className="state error" role="alert">{error}</p>}
    {notice && <p className="state success" role="status">{notice}</p>}
    <form className="institution-school-form" onSubmit={e => {
      e.preventDefault()
      execute(() => createInstitutionInternalTeacher(slug, form), 'تم إنشاء حساب المعلم. كلمة المرور تظهر مرة واحدة أدناه.')
      setForm(EMPTY)
    }}>
      <label>اسم المعلم<input required maxLength={190} value={form.name} onChange={e => setForm({ ...form, name: e.target.value })} /></label>
      <label>اسم المستخدم<input dir="ltr" required pattern="[a-z0-9][a-z0-9._-]{1,63}" value={form.username} onChange={e => setForm({ ...form, username: e.target.value.toLowerCase() })} /></label>
      <button className="btn" disabled={busy || !domain}>إنشاء الحساب بكلمة مرور أولية تلقائية</button>
    </form>
    <h3>استيراد معلمين من CSV</h3>
    <p>عمودان فقط: <code>name,username</code>. أول سطر يمكن أن يكون ترويسة. حد أقصى 100 معلم لكل دفعة. يتم إنشاء كلمات مرور مختلفة لكل حساب.</p>
    <input aria-label="ملف المعلمين CSV" type="file" accept=".csv,text/csv" disabled={busy} onChange={async e => {
      const file = e.target.files?.[0]
      if (!file) return
      if (file.size > 100000) { setError('الملف أكبر من الحد المسموح'); return }
      try { setCsv(await file.text()); setError('') } catch { setError('تعذرت قراءة الملف') }
      e.target.value = ''
    }} />
    <button type="button" className="btn outline" disabled={busy || !csv || !domain} onClick={() => {
      try { const rows = parseCsv(csv); execute(() => bulkCreateInstitutionInternalTeachers(slug, rows), 'تم إنشاء الحسابات بنجاح. احتفظ بكلمات المرور بأمان.'); setCsv('') }
      catch (e) { setError(e.message) }
    }}>استيراد المعلمين</button>
    {credentials.length > 0 && <section className="institution-panel" aria-label="كلمات مرور مؤقتة">
      <h3>بيانات الدخول المؤقتة (تظهر مرة واحدة)</h3>
      <p>شارك كلمة مرور كل معلم معه فقط من قناة آمنة. لا يُنشئ هذا النظام بريداً إلكترونياً.</p>
      {credentials.map(row => <p key={row.login_identifier}><bdi dir="ltr">{row.login_identifier}</bdi> : <code>{row.temporary_password || 'تم اختيار كلمة مرور يدوياً'}</code></p>)}
      <button type="button" className="btn outline" onClick={() => setCredentials([])}>إخفاء كلمات المرور</button>
    </section>}
    <h3>إدارة الحسابات الداخلية</h3>
    {items.length === 0 && <p>لا توجد حسابات داخلية بعد.</p>}
    {items.map(item => <article className="institution-panel" key={item.id}>
      <b>{item.name}</b> <bdi dir="ltr">{item.username}@{domain}</bdi>
      <p>{item.is_active && item.membership_active ? 'نشط' : 'معطّل'}{item.must_change_password ? ' | مطلوب تغيير كلمة المرور' : ''}</p>
      <button className="btn outline" disabled={busy} type="button" onClick={() => {
        if (!window.confirm('سيتم تغيير حالة الحساب وإلغاء جلساته القديمة، هل تريد المتابعة؟')) return
        execute(() => setInstitutionInternalTeacherActive(slug, item.id, !item.is_active), 'تم تحديث حالة الحساب')
      }}>{item.is_active ? 'تعطيل' : 'تفعيل'}</button>
      <button className="btn outline" disabled={busy} type="button" onClick={() => {
        if (!window.confirm('إنشاء كلمة مرور أولية جديدة وإلغاء جميع الجلسات القديمة؟')) return
        execute(() => resetInstitutionInternalTeacherPassword(slug, item.id), 'تم إنشاء كلمة مرور أولية جديدة')
      }}>إعادة تعيين كلمة المرور</button>
    </article>)}
    {cursor && <button type="button" className="btn outline" disabled={busy} onClick={() => reload(cursor).catch(e => setError(e.message))}>عرض المزيد</button>}
  </section>
}
