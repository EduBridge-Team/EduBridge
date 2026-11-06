import assert from 'node:assert/strict'
import { test } from 'node:test'
import { readFileSync } from 'node:fs'

test('Jabalia school readiness remains on demand and never shows approval buttons', () => {
  const source = readFileSync(
    new URL('../src/components/School/JabaliaAdmissionReadinessPanel.jsx', import.meta.url),
    'utf8'
  )
  const inbox = readFileSync(
    new URL('../src/components/School/SchoolEnrollmentPanel.jsx', import.meta.url),
    'utf8'
  )
  assert.match(inbox, /jabalia && inbox\.data\?\.school_id && <JabaliaAdmissionReadinessPanel/)
  assert.match(source, /expanded && allowedToRequest/)
  assert.match(source, /\/school\/jabalia\/admission-readiness/)
  assert.match(source, /getUser\(\)\?\.role !== 'school'/)
  assert.match(source, /موافقة المرشد والإدارة/)
  assert.match(source, /لا توجد موافقة نهائية/)
  assert.doesNotMatch(source, /approveEnrollment|decide\(|storage_path|original_filename|file_size/)
  assert.match(inbox, /!jabalia && <button className="btn"/)
})
