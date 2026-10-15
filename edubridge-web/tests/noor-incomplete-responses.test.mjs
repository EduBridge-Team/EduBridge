import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { test } from 'node:test'

const widget = readFileSync(
  new URL('../src/components/Noor/AssistantWidget.jsx', import.meta.url), 'utf8',
)

test('Noor offers a direct continuation for token-limited text replies', () => {
  assert.match(widget, /lastMessage\.incomplete\s*&&\s*lastMessage\.source\s*!==\s*'image'/)
  assert.match(widget, /'أكمل الإجابة'/)
  assert.match(widget, /incomplete:\s*data\.incomplete\s*===\s*true/)
})

test('image replies retain their provenance instead of offering text-only image continuation', () => {
  assert.match(widget, /source:\s*'image'/)
  assert.match(widget, /incomplete:\s*analysis\.incomplete\s*===\s*true/)
})
