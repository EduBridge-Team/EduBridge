// Safe, intentionally minimal metadata for Jabalia confidential admissions.
export const JABALIA_DOCUMENT_LABELS = Object.freeze({
  audiology_report: ['تقرير فحص السمع', 'Audiology assessment'],
  birth_certificate: ['شهادة الميلاد', 'Birth certificate'],
  medical_report: ['التقارير الطبية', 'Medical report'],
  child_photo: ['الصورة الشخصية', 'Child portrait'],
  father_identity: ['هوية الأب', "Father's identity"],
})

export const JABALIA_DOCUMENT_TYPES = Object.freeze(Object.keys(JABALIA_DOCUMENT_LABELS))

// Only an explicit boolean from the server changes the admission workflow.
export function jabaliaReviewRequired(inbox) {
  return inbox?.requires_counselor_review === true
}

export function safeJabaliaEvidence(payload) {
  const documents = Array.isArray(payload?.documents) ? payload.documents : []
  const valid = documents.filter(item =>
    Number.isSafeInteger(item?.id) && item.id > 0 &&
    Object.hasOwn(JABALIA_DOCUMENT_LABELS, item.type)
  ).map(item => ({
    id: item.id,
    type: item.type,
    fileSize: Number.isSafeInteger(item.file_size) && item.file_size >= 0
      ? item.file_size : null,
  }))
  const present = new Set(valid.map(item => item.type))
  const missing = JABALIA_DOCUMENT_TYPES.filter(type => !present.has(type))
  return {
    documents: valid,
    missing,
    present,
    // Existence of files never represents an approved enrollment.
    evidenceComplete: missing.length === 0,
    admissionApproved: false,
  }
}
