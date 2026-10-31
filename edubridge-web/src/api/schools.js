import { request } from './core'

export function provisionSchool(payload, institutionSlug) {
  const path = institutionSlug
    ? `/institutions/${encodeURIComponent(institutionSlug)}/school-accounts`
    : '/admin/school-accounts'
  return request(path, { method: 'POST', body: JSON.stringify(payload) })
}

export function fetchSchoolDirector(schoolId) {
  return request(`/admin/schools/${encodeURIComponent(schoolId)}/director`)
}

export function appointSchoolDirector(schoolId, directorEmail) {
  return request(`/admin/schools/${encodeURIComponent(schoolId)}/director`, {
    method: 'POST', body: JSON.stringify({ director_email: directorEmail.trim().toLowerCase() }),
  })
}
