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
