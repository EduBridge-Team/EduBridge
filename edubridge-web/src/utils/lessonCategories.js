export const UNCATEGORIZED = 'غير مصنّف'
export const LESSON_CATEGORIES = ['الكل', 'القراءة', 'الرياضيات', 'مهارات الحياة', 'التواصل', 'الفنون', UNCATEGORIZED]
const ALIASES = { reading: 'القراءة', math: 'الرياضيات', mathematics: 'الرياضيات', life_skills: 'مهارات الحياة', communication: 'التواصل', arts: 'الفنون' }
export function lessonCategory(lesson) {
  const raw = typeof lesson.category === 'string' ? lesson.category.trim() : lesson.category?.name?.trim()
  return ALIASES[raw?.toLowerCase()] || raw || UNCATEGORIZED
}
export function filterLessons(lessons, query, category) {
  const needle = query.trim().toLocaleLowerCase('ar')
  return lessons.filter((lesson) => {
    const actual = lessonCategory(lesson)
    const text = `${lesson.title || ''} ${lesson.content || ''} ${actual}`.toLocaleLowerCase('ar')
    return (!needle || text.includes(needle)) && (category === 'الكل' || actual === category)
  })
}
