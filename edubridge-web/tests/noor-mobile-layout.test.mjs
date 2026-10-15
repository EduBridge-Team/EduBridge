import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { test } from 'node:test'

const styles = readFileSync(
  new URL('../src/components/Noor/assistant-context.css', import.meta.url),
  'utf8',
)

test('Noor shortcuts wrap into a two-column grid on phones', () => {
  const mobile = styles.slice(styles.indexOf('@media (max-width: 640px)'))
  assert.match(mobile, /\.noor-quick-actions\s*\{[^}]*display:\s*grid/s)
  assert.match(mobile, /grid-template-columns:\s*repeat\(2,\s*minmax\(0,\s*1fr\)\)/)
  assert.match(mobile, /\.noor-quick-actions\s*\{[^}]*overflow-x:\s*hidden/s)
  assert.match(mobile, /\.noor-quick-action\s*\{[^}]*white-space:\s*normal/s)
  assert.match(mobile, /\.noor-quick-action\s*\{[^}]*overflow-wrap:\s*anywhere/s)
})

test('Noor input remains shrinkable and shortcuts remain scrollable on very narrow screens', () => {
  assert.match(styles, /\.noor-form textarea\s*\{[^}]*min-width:\s*0/s)
  assert.match(styles, /\.noor-quick-actions\s*\{[^}]*overflow-y:\s*auto/s)
  assert.match(styles, /@media \(max-width:\s*360px\)[\s\S]*grid-template-columns:\s*1fr/)
})
