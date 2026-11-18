// Keep independently successful reads while treating incomplete data as read-only.
// Never silently fall back to another school's previous academic or teacher data.
export async function loadTeacherSchoolData(loadAcademic, loadParticipants) {
  const [academic, participants] = await Promise.allSettled([
    loadAcademic(), loadParticipants(),
  ])
  const missing = []
  if (academic.status === 'rejected') missing.push('الهيكل الأكاديمي')
  if (participants.status === 'rejected') missing.push('المعلمين والتكليفات')
  return {
    academic: academic.status === 'fulfilled' ? academic.value : null,
    participants: participants.status === 'fulfilled' ? participants.value : null,
    error: missing.length ? `تعذّر تحميل ${missing.join(' و')}. لا يمكن تغيير التكليفات حتى تكتمل بيانات المدرسة، جرّب إعادة التحميل.` : '',
  }
}
