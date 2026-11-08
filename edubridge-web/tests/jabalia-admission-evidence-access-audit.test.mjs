import test from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'

test('Jabalia admission access history is fetched only on click for a specific request', () => {
  const panel = readFileSync(
    new URL('../src/components/School/JabaliaAdmissionEvidenceAccessPanel.jsx', import.meta.url), 'utf8'
  )
  const parent = readFileSync(
    new URL('../src/components/School/JabaliaAdmissionEvidencePanel.jsx', import.meta.url), 'utf8'
  )
  assert.match(parent, /<JabaliaAdmissionEvidenceAccessPanel key=\{requestId\}/)
  assert.match(panel, /onClick=\{\(\) => load\(1\)\}/)
  assert.match(panel, /encodeURIComponent\(requestId\)/)
  assert.match(panel, /cache: 'no-store'/)
  assert.match(panel, /credentials: 'same-origin'/)
  assert.doesNotMatch(panel, /storage_path|original_filename|innerHTML|document\.write/)
  assert.match(panel, /دون عرض محتويات الملفات/)
})
