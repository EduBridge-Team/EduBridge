import assert from 'node:assert/strict'
import { test } from 'node:test'
import { readFileSync } from 'node:fs'

test('teacher personnel document UI uses only a safe attachment flag', () => {
  const ui = readFileSync(new URL(
    '../src/pages/Dashboards/InstitutionTeachersPage.jsx', import.meta.url
  ), 'utf8')
  const api = readFileSync(new URL('../src/api/institutions.js', import.meta.url), 'utf8')
  assert.match(ui, /item\.has_file/)
  assert.doesNotMatch(ui, /item\.storage_path|item\.original_filename/)
  assert.match(ui, /disabled=\{documentSaving \|\| \(item\.type === 'contract' && !!item\.has_file\)\}/)
  assert.match(api, /link\.download = filename \|\| 'document\.' \+ suffix/)
  assert.match(api, /'application\/pdf': 'pdf'/)
  assert.match(api, /'image\/png': 'png'/)
  assert.match(api, /'image\/jpeg': 'jpg'/)
})

test('metadata-minimized teacher document controller never directly serializes raw document table rows', () => {
  const source = readFileSync(new URL(
    '../../edubridge-api-laravel/app/Http/Controllers/JabaliaTeacherDocumentController.php',
    import.meta.url
  ), 'utf8')
  assert.match(source, /private function publicMetadataQuery/)
  assert.match(source, /AS has_file/)
  assert.match(source, /\$this->publicMetadataQuery\(\)/)
  assert.match(source, /Storage::disk\('local'\)->download/)
  assert.match(source, /download_issued/)
  assert.match(source, /Cache-Control/)
})
