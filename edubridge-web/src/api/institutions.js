import { request } from './core'

function tenantPath(slug, suffix = '') {
  return `/institutions/${encodeURIComponent(slug)}${suffix}`
}

function schoolPath(slug, schoolId, suffix = '') {
  return tenantPath(slug, `/schools/${schoolId}${suffix}`)
}

export function fetchInstitutionSchools(slug) {
  return request(tenantPath(slug, '/schools'))
}

export function fetchInstitutionSchool(slug, schoolId) {
  return request(schoolPath(slug, schoolId))
}

export function createInstitutionSchool(slug, payload) {
  return request(tenantPath(slug, '/schools'), {
    method: 'POST',
    body: JSON.stringify(payload),
  })
}

export function fetchInstitutionParticipants(slug, schoolId) {
  return request(schoolPath(slug, schoolId, '/participants'))
}

export function fetchInstitutionAcademicOverview(slug, schoolId) {
  return request(schoolPath(slug, schoolId, '/academic'))
}

export function createInstitutionAcademicYear(slug, schoolId, payload) {
  return request(schoolPath(slug, schoolId, '/academic/years'), {
    method: 'POST',
    body: JSON.stringify(payload),
  })
}

export function createInstitutionAcademicTerm(slug, schoolId, academicYearId, payload) {
  return request(schoolPath(slug, schoolId, `/academic/years/${academicYearId}/terms`), {
    method: 'POST',
    body: JSON.stringify(payload),
  })
}

export function createInstitutionGrade(slug, schoolId, payload) {
  return request(schoolPath(slug, schoolId, '/academic/grades'), {
    method: 'POST',
    body: JSON.stringify(payload),
  })
}

export function createInstitutionSection(slug, schoolId, payload) {
  return request(schoolPath(slug, schoolId, '/academic/sections'), {
    method: 'POST',
    body: JSON.stringify(payload),
  })
}

export function createInstitutionSubject(slug, schoolId, payload) {
  return request(schoolPath(slug, schoolId, '/academic/subjects'), {
    method: 'POST',
    body: JSON.stringify(payload),
  })
}

export function assignInstitutionTeacher(slug, schoolId, payload) {
  return request(schoolPath(slug, schoolId, '/academic/teacher-assignments'), {
    method: 'POST',
    body: JSON.stringify(payload),
  })
}

export function removeInstitutionTeacherAssignment(slug, schoolId, assignmentId) {
  return request(schoolPath(slug, schoolId, `/academic/teacher-assignments/${assignmentId}`), {
    method: 'DELETE',
  })
}

export function enrollInstitutionStudent(slug, schoolId, payload) {
  return request(schoolPath(slug, schoolId, '/academic/student-enrollments'), {
    method: 'POST',
    body: JSON.stringify(payload),
  })
}

export function fetchInstitutionAttendance(slug, schoolId) {
  return request(schoolPath(slug, schoolId, '/attendance'))
}

export function fetchInstitutionTimetable(slug, schoolId) {
  return request(schoolPath(slug, schoolId, '/timetable'))
}

export function fetchInstitutionCurriculum(slug, schoolId) {
  return request(schoolPath(slug, schoolId, '/curriculum'))
}

export function fetchInstitutionTeacherInvitations(slug) {
  return request(tenantPath(slug, '/teacher-invitations'))
}

export function inviteInstitutionTeacher(slug, email) {
  return request(tenantPath(slug, '/teacher-invitations'), {
    method: 'POST', body: JSON.stringify({ email }),
  })
}

export function revokeInstitutionTeacherInvitation(slug, id) {
  return request(tenantPath(slug, `/teacher-invitations/${id}`), { method: 'DELETE' })
}

export function acceptInstitutionTeacherInvitation(token) {
  return request('/teacher-invitations/accept', { method: 'POST', body: JSON.stringify({ token }) })
}

export function fetchInstitutionTeacherMemberships(slug) {
  return request(tenantPath(slug, '/teachers'))
}

export function setInstitutionTeacherActive(slug, teacherId, isActive) {
  return request(tenantPath(slug, `/teachers/${teacherId}`), {
    method: 'PATCH', body: JSON.stringify({ is_active: isActive }),
  })
}

export function fetchInstitutionStudentHistory(slug, schoolId) {
  return request(schoolPath(slug, schoolId, '/academic/student-enrollments'))
}

export function closeInstitutionStudentEnrollment(slug, schoolId, enrollmentId, status) {
  return request(schoolPath(slug, schoolId, `/academic/student-enrollments/${enrollmentId}/status`), {
    method: 'PATCH', body: JSON.stringify({ status }),
  })
}

export function transferInstitutionStudent(slug, schoolId, enrollmentId, sectionId) {
  return request(schoolPath(slug, schoolId, `/academic/student-enrollments/${enrollmentId}/transfer`), {
    method: 'POST', body: JSON.stringify({ section_id: Number(sectionId) }),
  })
}

export function createInstitutionAttendanceSession(slug, schoolId, payload) {
  return request(schoolPath(slug, schoolId, '/attendance'), {
    method: 'POST', body: JSON.stringify(payload),
  })
}

export function fetchInstitutionAttendanceSession(slug, schoolId, sessionId) {
  return request(schoolPath(slug, schoolId, `/attendance/${sessionId}`))
}

export function markInstitutionAttendance(slug, schoolId, sessionId, payload) {
  return request(schoolPath(slug, schoolId, `/attendance/${sessionId}/records`), {
    method: 'PUT', body: JSON.stringify(payload),
  })
}

export function fetchInstitutionAttendanceReport(slug, schoolId, filters = {}) {
  const query = new URLSearchParams()
  for (const [key, value] of Object.entries(filters)) {
    if (value !== '' && value != null) query.set(key, String(value))
  }
  const suffix = query.toString()
  return request(schoolPath(slug, schoolId, `/attendance/report${suffix ? '?'+suffix : ''}`))
}

export function createInstitutionTimetableEntry(slug, schoolId, payload) {
  return request(schoolPath(slug, schoolId, '/timetable'), {
    method: 'POST', body: JSON.stringify(payload),
  })
}

export function deleteInstitutionTimetableEntry(slug, schoolId, entryId) {
  return request(schoolPath(slug, schoolId, `/timetable/${entryId}`), { method: 'DELETE' })
}

export function reportInstitutionTeacherAbsence(slug, schoolId, payload) {
  return request(schoolPath(slug, schoolId, '/teacher-absences'), {
    method: 'POST', body: JSON.stringify(payload),
  })
}

export function fetchInstitutionAvailableSubstitutes(slug, schoolId, entryId, date) {
  return request(schoolPath(slug, schoolId, `/timetable/${entryId}/available-substitutes?date=${encodeURIComponent(date)}`))
}

export function assignInstitutionSubstitute(slug, schoolId, entryId, payload) {
  return request(schoolPath(slug, schoolId, `/timetable/${entryId}/substitutions`), {
    method: 'POST', body: JSON.stringify(payload),
  })
}

export function fetchInstitutionManagementReport(slug, filters = {}) {
  const params = new URLSearchParams()
  if (filters.from) params.set('from', filters.from)
  if (filters.to) params.set('to', filters.to)
  return request(tenantPath(slug, '/management-report' + (params.toString() ? '?' + params : '')))
}

export function fetchJabaliaTeacherHistory(slug, schoolId, teacherId, page = 1) {
  return request(schoolPath(slug, schoolId, `/teachers/${teacherId}/history?page=${encodeURIComponent(page)}`))
}

export function updateJabaliaTeacherProfile(slug, schoolId, teacherId, payload) {
  return request(schoolPath(slug, schoolId, `/teachers/${teacherId}/profile`), {
    method: 'PATCH',
    body: JSON.stringify(payload),
  })
}

export function fetchJabaliaTeacherDocuments(slug, schoolId, teacherId, page = 1) {
  return request(schoolPath(slug, schoolId, `/teachers/${teacherId}/documents?page=${encodeURIComponent(page)}`))
}

export function createJabaliaTeacherDocument(slug, schoolId, teacherId, payload) {
  return request(schoolPath(slug, schoolId, `/teachers/${teacherId}/documents`), {
    method: 'POST', body: JSON.stringify(payload),
  })
}

export function deleteJabaliaTeacherDocument(slug, schoolId, teacherId, documentId) {
  return request(schoolPath(slug, schoolId, `/teachers/${teacherId}/documents/${documentId}`), { method: 'DELETE' })
}

export async function uploadJabaliaTeacherDocument(slug, schoolId, teacherId, documentId, file) {
  const form = new FormData()
  form.append('file', file)
  const response = await fetch(`${import.meta.env.VITE_API_URL || '/api'}${schoolPath(slug, schoolId, `/teachers/${teacherId}/documents/${documentId}/file`)}`, {
    method: 'POST',
    credentials: 'same-origin',
    headers: { 'X-EduBridge-Client': 'web' },
    body: form,
  })
  const data = await response.json().catch(() => ({}))
  if (!response.ok) throw new Error(data.error || data.message || `فشل رفع الملف (HTTP ${response.status})`)
  return data
}

export async function downloadJabaliaTeacherDocument(slug, schoolId, teacherId, documentId, filename) {
  const response = await fetch(`${import.meta.env.VITE_API_URL || '/api'}${schoolPath(slug, schoolId, `/teachers/${teacherId}/documents/${documentId}/file`)}`, {
    credentials: 'same-origin',
    headers: { 'X-EduBridge-Client': 'web' },
  })
  if (!response.ok) {
    const data = await response.json().catch(() => ({}))
    throw new Error(data.error || data.message || `فشل تنزيل الملف (HTTP ${response.status})`)
  }
  const blob = await response.blob()
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = filename || 'document'
  document.body.appendChild(link)
  link.click()
  link.remove()
  window.setTimeout(() => URL.revokeObjectURL(url), 60000)
}

export function fetchJabaliaTeacherTransfers(slug, schoolId, teacherId) {
  return request(schoolPath(slug, schoolId, `/teachers/${teacherId}/transfers`))
}
export function transferJabaliaTeacher(slug, schoolId, teacherId, payload) {
  return request(schoolPath(slug, schoolId, `/teachers/${teacherId}/transfers`), { method: 'POST', body: JSON.stringify(payload) })
}

export function previewJabaliaBulkPromotion(slug, schoolId, payload) {
  return request(schoolPath(slug, schoolId, '/academic/student-enrollments/bulk-promotion-preview'), {
    method: 'POST', body: JSON.stringify(payload),
  })
}

export function approveJabaliaBulkPromotion(slug, schoolId, payload) {
  return request(schoolPath(slug, schoolId, '/academic/student-enrollments/bulk-promotion-approve'), {
    method: 'POST', body: JSON.stringify({ ...payload, confirm: true }),
  })
}

export function fetchJabaliaTimetableSettings(slug, schoolId) {
  return request(schoolPath(slug, schoolId, '/timetable-settings'))
}

export function updateJabaliaTimetableSettings(slug, schoolId, payload) {
  return request(schoolPath(slug, schoolId, '/timetable-settings'), {
    method: 'PUT', body: JSON.stringify(payload),
  })
}

export function fetchJabaliaSubjectQuotas(slug, schoolId) {
  return request(schoolPath(slug, schoolId, '/subject-quotas'))
}

export function updateJabaliaSubjectQuota(slug, schoolId, payload) {
  return request(schoolPath(slug, schoolId, '/subject-quotas'), {
    method: 'PUT', body: JSON.stringify(payload),
  })
}
