import test from 'node:test'
import assert from 'node:assert/strict'
import { protectedFileUrl, safeFileBlob, privateMediaCrossOrigin } from '../src/api/protectedFileUrl.js'

test('private downloads follow the configured API origin and prefix', () => {
  const file = '/api/private-files/homework/12/child/7/result.pdf'
  assert.equal(protectedFileUrl('/api', file), file)
  assert.equal(protectedFileUrl('https://api.example.test/api/', file), 'https://api.example.test/api/private-files/homework/12/child/7/result.pdf')
  assert.equal(protectedFileUrl('/backend/api', file), '/backend/api/private-files/homework/12/child/7/result.pdf')
})

test('active uploaded content is rendered as text rather than executable same-origin HTML', async () => {
  for (const type of ['text/html', 'application/xhtml+xml', 'image/svg+xml']) {
    const original = new Blob(['<script>alert(1)</script>'], { type })
    const safe = safeFileBlob(original)
    assert.equal(safe.type, 'text/plain')
    assert.equal(await safe.text(), await original.text())
  }
  const pdf = new Blob(['pdf'], { type: 'application/pdf' })
  assert.equal(safeFileBlob(pdf), pdf)
  assert.equal(safeFileBlob(new Blob(['unknown'])).type, 'application/octet-stream')
})

test('signed video opts into CORS for captions while external legacy video keeps its behavior', () => {
  assert.equal(privateMediaCrossOrigin('https://api.example.test/api/private-files/lesson/10/video.mp4?signature=abc'), 'anonymous')
  assert.equal(privateMediaCrossOrigin('https://media.example.test/video.mp4'), undefined)
  assert.equal(privateMediaCrossOrigin(null), undefined)
})
