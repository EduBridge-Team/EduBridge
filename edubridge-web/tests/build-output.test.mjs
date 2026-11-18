import assert from 'node:assert/strict'
import { test } from 'node:test'
import { readFile, stat, readdir } from 'node:fs/promises'
import { join, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'

const root = fileURLToPath(new URL('../', import.meta.url))
const dist = join(root, 'dist')

test('production web build has local entrypoints and compressed assets', async () => {
  const html = await readFile(join(dist, 'index.html'), 'utf8')
  assert.doesNotMatch(html, /src="\/src\/|href="\/src\//)
  const script = html.match(/<script type="module" src="(\/assets\/[^"]+\.js)"/)
  const css = html.match(/<link rel="stylesheet" href="(\/assets\/[^"]+\.css)"/)
  assert.ok(script, 'missing compiled module script')
  assert.ok(css, 'missing compiled stylesheet')
  for (const href of [script[1], css[1]]) {
    assert.match(href, /\/[\w-]+-[A-Z0-9]+\.(?:js|css)$/i)
    const target = join(dist, href.slice(1))
    assert.ok((await stat(target)).size > 1024, href + ' unexpectedly small')
    assert.ok((await stat(target + '.gz')).size > 0, href + ' lacks gzip')
    assert.ok((await stat(target + '.br')).size > 0, href + ' lacks brotli')
  }
  const scriptContents = await readFile(join(dist, script[1].slice(1)), 'utf8')
  assert.doesNotMatch(scriptContents, /import\.meta\.env|\bVITE_API_URL\b/)
  assert.ok((await readdir(join(dist, 'assets'))).some(name => name.endsWith('.woff2')),
    'locally served Cairo font is missing')
  assert.ok((await stat(join(dist, 'edubridge-icon.png'))).size > 0,
    'public icon not copied')
})
