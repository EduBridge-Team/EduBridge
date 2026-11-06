import assert from 'node:assert/strict'
import { test } from 'node:test'
import { readFileSync } from 'node:fs'

test('Jabalia intake journal is on-demand, request scoped and never accepts admissions', () => {
  const panel = readFileSync(new URL(
    '../src/components/School/JabaliaAdmissionIntakeTriagePanel.jsx', import.meta.url
  ), 'utf8')
  const readiness = readFileSync(new URL(
    '../src/components/School/JabaliaAdmissionReadinessPanel.jsx', import.meta.url
  ), 'utf8')
  assert.match(readiness, /JabaliaAdmissionIntakeTriagePanel/)
  assert.match(readiness, /requestId=\{item\.request_id\} schoolId=\{schoolId\}/)
  assert.match(panel, /encodeURIComponent\(requestId\)/)
  assert.match(panel, /if \(!expanded\) load\(\)/)
  assert.match(panel, /expected_request_version: data\.request_version/)
  assert.match(panel, /expected_event_id: data\.latest_event_id/)
  assert.match(panel, /Number\(result\.school_id\) !== Number\(schoolId\)/)
  assert.match(panel, /تم توثيق المتابعة الإدارية دون اتخاذ قرار قبول/)
  assert.match(panel, /لا تثبت مراجعة المرشد/)
  assert.doesNotMatch(panel, /close_session|approveEnrollment|decision: 'approved'|medical_notes|storage_path/)
})


test('Jabalia inbox hides all final decisions until separate reviews exist', () => {
  const school = readFileSync(new URL(
    '../src/components/School/SchoolEnrollmentPanel.jsx', import.meta.url
  ), 'utf8')
  assert.match(school, /if \(pending\.current \|\| jabalia\) return/)
  assert.match(school, /\{!jabalia && <>\}/)
  assert.match(school, /قرار القبول أو الرفض النهائي متوقف/)
  assert.match(school, /قرار القبول النهائي/)
})
