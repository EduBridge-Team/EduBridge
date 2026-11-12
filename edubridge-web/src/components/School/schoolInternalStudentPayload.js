export function internalAccountPayload(form) {
  if (form.role !== 'student') {
    return {
      name: form.name, username: form.username,
      role: form.role, password: form.password,
    }
  }

  const sectionId = Number(form.section_id)
  if (!Number.isInteger(sectionId) || sectionId <= 0) {
    throw new Error('A current school section is required')
  }
  if (!/^\d{4}-\d{2}-\d{2}$/.test(form.birth_date || '')) {
    throw new Error('Student birth date is required')
  }

  return {
    name: form.name, username: form.username,
    role: 'student', password: form.password,
    create_new_student: true, birth_date: form.birth_date,
    section_id: sectionId,
  }
}
