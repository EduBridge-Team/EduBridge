import { computeJabaliaTimetableCoverage } from './jabaliaTimetableCoverage'

/**
 * Institution-only scheduling audit. No automatically inferred subject quota,
 * timetable mutation, or fabricated timetable activities.
 */
export default function JabaliaTimetableCoveragePanel({
  slug, settings, academic, quotas = [], entries = [],
}) {
  if (slug !== 'jabalia' || !settings || !academic) return null
  const { capacity, rows } = computeJabaliaTimetableCoverage(settings, academic, quotas, entries)
  return <section className="institution-panel" aria-label="تغطية الجدول والنصاب الأسبوعي">
    <h2>تغطية الجدول الأسبوعي للشُعب الحالية</h2>
    <p>يعرض هذا التقرير عدد الحصص المسموح بها في إعدادات الدوام الحالية، والحصص المحددة في نصاب المواد، وما أُدرج بالفعل في الجدول. الفترات غير المحددة ليست حصصًا ينبغي ملؤها تلقائيًا؛ يجب اعتماد توزيعها من الجمعية.</p>
    <p>السعة الأسبوعية لكل شعبة: <strong>{capacity}</strong> حصة وفق إعدادات المدرسة الحالية.</p>
    {!rows.length ? <p>لا توجد شُعب مرتبطة بسنة دراسية حالية لعرض تغطيتها.</p> :
      <div className="institution-actions">
        {rows.map((row) => <article key={row.section_id} className="institution-panel">
          <h3>{row.grade_name ? row.grade_name + ' — ' : ''}{row.section_name}</h3>
          <p>النصاب المعرف صراحة: <strong>{row.configured_quota_periods}</strong> من {row.capacity} حصة.</p>
          <p>فترات لم يُحدّد نصابها: <strong>{row.quota_not_defined}</strong>.</p>
          <p>حصص مجدولة بالفعل: <strong>{row.scheduled_periods}</strong>، وفترات دون حصة مجدولة: <strong>{row.unscheduled_slots}</strong>.</p>
          {row.quota_exceeds_capacity && <p role="alert">مجموع النصاب أكبر من سعة الأسبوع؛ راجع إعدادات الدوام والمواد.</p>}
          {row.duplicate_slot_entries > 0 && <p role="alert">هناك أكثر من حصة في الفترة نفسها داخل الشعبة: {row.duplicate_slot_entries} إدخالات إضافية.</p>}
          {row.scheduled_without_quota > 0 && <p>حصص جُدولت لمواد دون نصاب أسبوعي معرف: {row.scheduled_without_quota}. لا نفترض أنها غير مشروعة؛ راجع الجمعية.</p>}
          {row.targets.length ? <table>
            <thead><tr><th scope="col">المادة</th><th scope="col">النصاب المحدد</th>
              <th scope="col">المجدول</th><th scope="col">النقص</th></tr></thead>
            <tbody>{row.targets.map((target) => <tr key={target.subject_id}>
              <th scope="row">{target.subject_name}</th>
              <td>{target.expected}</td>
              <td>{target.scheduled}</td>
              <td>{target.shortfall}{target.excess > 0 ? ' — زيادة: ' + target.excess : ''}</td>
            </tr>)}</tbody>
          </table> : <p>لم يتم تحديد نصاب أسبوعي لأي مادة في هذه الشعبة.</p>}
        </article>)}
      </div>}
    <p>تنبيه: هذا فحص تغطية وبيانات إعداد، وليس اعتمادًا نهائيًا للجدول أو إلزامًا بتوزيع الفترات غير المحددة.</p>
  </section>
}
