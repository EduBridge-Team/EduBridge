import assert from 'node:assert/strict'
import { test } from 'node:test'
import { readFileSync } from 'node:fs'

test('Jabalia attendance report explains that only saved daily rolls count', () => {
  const source = readFileSync(
    new URL('../src/pages/Dashboards/InstitutionAttendancePage.jsx', import.meta.url), 'utf8'
  )
  assert.match(source, /report\.daily_recorded_only/)
  assert.match(source, /الحضور اليومي المؤكّد/)
  assert.match(source, /حالات «حاضر» الافتراضية قبل الحفظ/)
  assert.match(source, /الحالة الأولية غير مؤكدة حتى حفظ سجل حضور الطلاب/)
  assert.match(source, /slug === 'jabalia'/)
})
