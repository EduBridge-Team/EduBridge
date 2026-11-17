import { weeklyGridRows } from './institutionWeeklyGrid'

export default function InstitutionWeeklyGrid({ entries, days, sectionId, periodCount, periods = [] }) {
  if (!sectionId) return <p>اختر شعبة من فلتر «تصفية حسب الشعبة» لعرض جدولها الأسبوعي.</p>
  const sectionEntries = entries.filter((entry) => String(entry.section_id) === String(sectionId))
  const rows = weeklyGridRows(sectionEntries, days, periodCount)
  if (!rows.length) return <p>لا تتوفر إعدادات الحصص لعرض الجدول الأسبوعي.</p>
  return <div className="institution-weekly-grid-scroll">
    <table className="institution-weekly-grid" aria-label="الجدول الأسبوعي للشعبة المحددة">
      <thead><tr><th scope="col">الحصة</th>{days.map((day) => <th scope="col" key={day.value}>{day.name}</th>)}</tr></thead>
      <tbody>{rows.map((row) => <tr key={row.period}>
        <th scope="row">الحصة {row.period}{periods[row.period - 1] ? <small> ({periods[row.period - 1].starts_at}–{periods[row.period - 1].ends_at})</small> : null}</th>
        {row.cells.map((cell) => <td key={cell.weekday}>
          {!cell.lessons.length ? <span className="institution-weekly-grid-empty">غير مجدولة</span> : cell.lessons.map((entry) =>
            <div key={entry.id} className="institution-weekly-grid-lesson">
              <strong>{entry.subject_name}</strong>
              <small>{entry.teacher_name || 'دون معلم'}</small>
              {entry.room ? <small>{entry.room}</small> : null}
            </div>)}
        </td>)}
      </tr>)}</tbody>
    </table>
    <p>الخانات غير المجدولة لا تعني وجود نصاب معتمد لها، ولا تُنشأ حصص تلقائيًا.</p>
  </div>
}
