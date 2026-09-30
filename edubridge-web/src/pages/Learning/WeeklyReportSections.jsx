import FormField from '../../components/FormField'
export function WeeklyReportForm({
  busy,
  draft,
  onChange,
  onSubmit,
}) {
  return (
    <section className="fp-card fp-form-card weekly-report-form-card">
      <h3>إضافة/تحديث تقرير</h3>

      <form className="fp-form" onSubmit={onSubmit}>
        <div className="fp-row">
          <FormField label="بداية الأسبوع">
            <input
              type="date"
              value={draft.week_start}
              onChange={(event) => onChange({ ...draft, week_start: event.target.value })}
            />
          </FormField>
          <FormField label="الدروس المكتملة">
            <input
              type="number"
              min="0"
              placeholder="الدروس المكتملة"
              value={draft.lessons_completed}
              onChange={(event) => onChange({
                ...draft,
                lessons_completed: event.target.value,
              })}
            />
          </FormField>
        </div>

        <div className="meta">القيمة الحالية: {draft.progress_percentage}%</div>
        <FormField label="نسبة التقدم">
          <input
            type="range"
            min="0"
            max="100"
            value={draft.progress_percentage}
            onChange={(event) => onChange({
              ...draft,
              progress_percentage: event.target.value,
            })}
          />
        </FormField>

        <FormField label="ملاحظات المعلم">
          <textarea
            rows={3}
            placeholder="ملاحظات المعلم"
            value={draft.teacher_notes}
            onChange={(event) => onChange({ ...draft, teacher_notes: event.target.value })}
          />
        </FormField>

        <FormField label="الإنجازات — كل إنجاز في سطر">
          <textarea
            rows={3}
            placeholder="الإنجازات — كل إنجاز في سطر"
            value={draft.achievements}
            onChange={(event) => onChange({ ...draft, achievements: event.target.value })}
          />
        </FormField>

        <FormField label="نقاط للانتباه — كل نقطة في سطر">
          <textarea
            rows={3}
            placeholder="نقاط للانتباه — كل نقطة في سطر"
            value={draft.concerns}
            onChange={(event) => onChange({ ...draft, concerns: event.target.value })}
          />
        </FormField>

        <button className="btn" disabled={busy}>حفظ التقرير</button>
      </form>
    </section>
  )
}

export function WeeklyReportsGrid({ reports }) {
  return (
    <section className="fp-grid">
      {reports.length === 0 ? (
        <div className="fp-empty">لا توجد تقارير لهذا الطفل</div>
      ) : (
        reports.map((report) => (
          <article className="fp-card weekly-report-card" key={report.id}>
            <div className="fp-head">
              <h3>
                {new Date(report.week_start).toLocaleDateString('ar')}
                {' — '}
                {new Date(report.week_end).toLocaleDateString('ar')}
              </h3>
              <span className="fp-badge">
                {Math.round(report.progress_percentage || 0)}%
              </span>
            </div>

            <div className="fp-grid">
              <div>
                <div className="fp-stat">
                  {report.lessons_completed}/{report.lessons_total}
                </div>
                <small>الدروس</small>
              </div>
              <div>
                <div className="fp-stat">
                  {report.homework_submitted}/{report.homework_assigned}
                </div>
                <small>الواجبات</small>
              </div>
              <div>
                <div className="fp-stat">
                  {report.learning_support_meetings_attended}/
                  {report.learning_support_meetings_scheduled}
                </div>
                <small>اجتماعات الدعم</small>
              </div>
            </div>

            {report.teacher_notes && <p>{report.teacher_notes}</p>}

            {(report.achievements || []).length > 0 && (
              <div>
                <b>الإنجازات:</b> {(report.achievements || []).join('، ')}
              </div>
            )}

            {(report.concerns || []).length > 0 && (
              <div>
                <b>نقاط للانتباه:</b> {(report.concerns || []).join('، ')}
              </div>
            )}
          </article>
        ))
      )}
    </section>
  )
}
