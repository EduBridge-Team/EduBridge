import { request } from './core'

function tenantPath(slug, suffix = '') {
  return `/institutions/${encodeURIComponent(slug)}${suffix}`
}

export function fetchInstitutionSchools(slug) {
  return request(tenantPath(slug, '/schools'))
}

export function fetchInstitutionSchool(slug, schoolId) {
  return request(tenantPath(slug, `/schools/${schoolId}`))
}

export function createInstitutionSchool(slug, payload) {
  return request(tenantPath(slug, '/schools'), {
    method: 'POST',
    body: JSON.stringify(payload),
  })
}

export function fetchInstitutionAcademicOverview(slug, schoolId) {
  return request(tenantPath(slug, `/schools/${schoolId}/academic`))
}

export function fetchInstitutionAttendance(slug, schoolId) {
  return request(tenantPath(slug, `/schools/${schoolId}/attendance`))
}

export function fetchInstitutionTimetable(slug, schoolId) {
  return request(tenantPath(slug, `/schools/${schoolId}/timetable`))
}

export function fetchInstitutionCurriculum(slug, schoolId) {
  return request(tenantPath(slug, `/schools/${schoolId}/curriculum`))
}
