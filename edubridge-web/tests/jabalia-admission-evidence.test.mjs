import test from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import {
  jabaliaReviewRequired, safeJabaliaEvidence,
  JABALIA_DOCUMENT_TYPES, JABALIA_DOCUMENT_LABELS,
} from '../src/components/School/jabaliaAdmissionEvidence.js'

test('Jabalia admission approval is disabled only when server sets explicit review requirement', () => {
  assert.equal(jabaliaReviewRequired({ requires_counselor_review: true }), true)
  for (const value of [false, undefined, null, 1, 'true']) {
    assert.equal(jabaliaReviewRequired({ requires_counselor_review: value }), false)
  }
  assert.equal(jabaliaReviewRequired(null), false)
})

test('safe evidence metadata omits sensitive paths and never implies an admission decision', () => {
  const source = {
    evidence_complete: true,
    admissions_approved: true,
    documents: [
      { id: 7, type: 'audiology_report', file_size: 200, storage_path: '/secret',
        original_filename: 'child-medical.pdf', mime_type: 'application/pdf',
        uploaded_by: 123, child_id: 999 },
      { id: 8, type: 'unrecognized', file_size: 100, storage_path: '/other' },
      { id: '8', type: 'father_identity' },
    ],
  }
  const summary = safeJabaliaEvidence(source)
  assert.deepEqual(summary.documents, [
    { id: 7, type: 'audiology_report', fileSize: 200 },
  ])
  assert.equal(summary.admissionApproved, false)
  assert.equal(summary.evidenceComplete, false)
  assert.equal(summary.missing.length, JABALIA_DOCUMENT_TYPES.length - 1)
  assert.equal(JSON.stringify(summary).includes('/secret'), false)
  assert.equal(JSON.stringify(summary).includes('child-medical.pdf'), false)
})

test('all five categories may be present without authorizing enrollment', () => {
  const summary = safeJabaliaEvidence({
    documents: JABALIA_DOCUMENT_TYPES.map((type, index) =>
      ({ id: index + 1, type, file_size: 100 }))
  })
  assert.equal(summary.evidenceComplete, true)
  assert.equal(summary.admissionApproved, false)
  assert.deepEqual(summary.missing, [])
  assert.equal(Object.keys(JABALIA_DOCUMENT_LABELS).length, 5)
})

test('school enrollment panel hides generic final decisions for Jabalia and uses on-demand evidence', () => {
  const view = readFileSync(new URL('../src/components/School/SchoolEnrollmentPanel.jsx', import.meta.url), 'utf8')
  const review = readFileSync(new URL('../src/components/School/JabaliaAdmissionEvidencePanel.jsx', import.meta.url), 'utf8')
  assert.match(view, /!jabalia && <button className="btn"/)
  assert.match(view, /<JabaliaAdmissionEvidencePanel/)
  assert.match(view, /if \(pending\.current \|\| jabalia\) return/)
  assert.match(view, /\{!jabalia && <>/)
  assert.match(review, /useSchoolResource\(expanded && allowedToRequest/)
  assert.doesNotMatch(review, /innerHTML/)
})
