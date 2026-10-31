// Form metadata uses school-local references; the server resolves ownership again.
const field = (key, ar, en, type = 'text', reference = null, optional = false) => ({ key, ar, en, type, reference, optional })
const name = field('name', 'الاسم', 'Name')
const year = field('academic_year_id', 'السنة الدراسية', 'Academic year', 'select', 'academic_years')
const grade = field('grade_id', 'الصف', 'Grade', 'select', 'grades')
const section = field('section_id', 'الشعبة', 'Section', 'select', 'sections')
const subject = field('subject_id', 'المادة', 'Subject', 'select', 'subjects')
const position = field('position', 'الترتيب', 'Position', 'number')
const title = field('title', 'العنوان', 'Title')
const teacher = field('teacher_id', 'المعلم', 'Teacher', 'select', 'teachers')
const date = field('attendance_date', 'التاريخ', 'Date', 'date')
const period = field('period_number', 'رقم الحصة', 'Period number', 'number')
const enrollment = field('enrollment_id', 'تسجيل الطالب', 'Student enrollment', 'select', 'enrollments')

export const SCHOOL_ACTIONS = [
  { action: 'years', category: 'academic', ar: 'إضافة سنة دراسية', en: 'Add academic year', fields: [name, field('starts_on', 'تاريخ البداية', 'Start date', 'date'), field('ends_on', 'تاريخ النهاية', 'End date', 'date'), field('is_current', 'السنة الحالية', 'Current year', 'checkbox')] },
  { action: 'terms', category: 'academic', ar: 'إضافة فصل دراسي', en: 'Add academic term', fields: [year, name, position, field('starts_on', 'تاريخ البداية', 'Start date', 'date'), field('ends_on', 'تاريخ النهاية', 'End date', 'date')] },
  { action: 'grades', category: 'academic', ar: 'إضافة صف', en: 'Add grade', fields: [name, position] },
  { action: 'sections', category: 'academic', ar: 'إضافة شعبة', en: 'Add section', fields: [year, grade, name, field('capacity', 'السعة', 'Capacity', 'number')] },
  { action: 'subjects', category: 'academic', ar: 'إضافة مادة', en: 'Add subject', fields: [name, field('code', 'رمز المادة', 'Subject code', 'text', null, true)] },
  { action: 'assign-teacher', category: 'academic', ar: 'تكليف معلم', en: 'Assign teacher', fields: [section, subject, teacher] },
  { action: 'remove-teacher', method: 'DELETE', category: 'academic', ar: 'حذف تكليف معلم', en: 'Remove teacher assignment', fields: [field('assignment_id', 'التكليف', 'Assignment', 'select', 'teacher_assignments')], destructive: true },
  { action: 'student-status', method: 'PATCH', category: 'enrollment', ar: 'إنهاء تسجيل طالب', en: 'Close student enrollment', fields: [enrollment, field('status', 'الحالة', 'Status', 'select', 'closure_statuses')], destructive: true },
  { action: 'student-transfer', category: 'enrollment', ar: 'نقل طالب لشعبة أخرى', en: 'Transfer student to another section', fields: [enrollment, section], destructive: true },
  { action: 'attendance-create', category: 'attendance', ar: 'بدء سجل حضور', en: 'Create attendance session', fields: [section, date, period] },
  { action: 'timetable-create', category: 'timetable', ar: 'إضافة حصة للجدول', en: 'Add timetable entry', fields: [year, section, subject, { ...teacher, optional: true }, field('weekday', 'اليوم', 'Weekday', 'select', 'weekdays'), period, field('starts_at', 'بداية الحصة', 'Start time', 'time', null, true), field('ends_at', 'نهاية الحصة', 'End time', 'time', null, true), field('room', 'الغرفة', 'Room', 'text', null, true)] },
  { action: 'timetable-delete', method: 'DELETE', category: 'timetable', ar: 'حذف حصة', en: 'Delete timetable entry', fields: [field('entry_id', 'الحصة', 'Timetable entry', 'select', 'timetable')], destructive: true },
  { action: 'books', category: 'curriculum', ar: 'إضافة كتاب', en: 'Add book', fields: [grade, subject, title] },
  { action: 'units', category: 'curriculum', ar: 'إضافة وحدة', en: 'Add unit', fields: [field('book_id', 'الكتاب', 'Book', 'select', 'books'), title, position] },
  { action: 'lessons', category: 'curriculum', ar: 'إضافة درس', en: 'Add lesson', fields: [field('unit_id', 'الوحدة', 'Unit', 'select', 'units'), title, position, field('source_pages', 'الصفحات', 'Source pages', 'text', null, true), field('content_text', 'محتوى الدرس', 'Lesson content', 'textarea', null, true)] },
]

export function schoolOperationPayload(definition, values) {
  const payload = {}
  for (const field of definition.fields) {
    const value = values[field.key]
    if (field.type === 'checkbox') { payload[field.key] = value === true; continue }
    if (value == null || String(value).trim() === '') {
      if (!field.optional) throw new Error('Required field: ' + field.key)
      continue
    }
    if (field.type === 'number' || field.type === 'select' && !['closure_statuses'].includes(field.reference)) {
      const number = Number(value)
      if (!Number.isInteger(number) || number < 1) throw new Error('Invalid selection: ' + field.key)
      payload[field.key] = number
    } else payload[field.key] = String(value).trim()
  }
  return payload
}
