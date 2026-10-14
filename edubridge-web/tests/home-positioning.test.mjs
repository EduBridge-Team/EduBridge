import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { test } from 'node:test'
import { INCLUSION_DIFFERENTIATORS } from '../src/pages/Public/homeData.js'

const read = (path) => readFileSync(new URL(path, import.meta.url), 'utf8')

test('first impression clearly names disability-focused inclusive education', () => {
  const home = read('../src/pages/Public/HomePage.jsx')
  const html = read('../index.html')

  assert.match(home, /HERO_TITLE_LINE_ONE = 'تعليم دامج للطلبة'/)
  assert.match(home, /HERO_TITLE_LINE_TWO = 'ذوي الهمم'/)
  assert.match(home, /صعوبات التعلّم/)
  assert.match(home, /to="\/#inclusion"/)
  assert.match(html, /name="description" content="[^"]*ذوي الهمم[^"]*"/)
  const publicCopy = [
    home,
    html,
    read('../src/pages/Public/HomeSections.jsx'),
    read('../src/pages/Public/AboutSections.jsx'),
    read('../src/pages/Public/homeData.js'),
    read('../src/pages/Public/aboutData.js'),
  ].join(' ')
  assert.doesNotMatch(publicCopy, /ذوي الإعاقة/)
})

test('differentiators specify adaptive learning and team support', () => {
  assert.equal(INCLUSION_DIFFERENTIATORS.length, 3)
  const allText = INCLUSION_DIFFERENTIATORS.map(({ title, text }) => title + ' ' + text).join(' ')
  assert.match(allText, /تكييف/)
  assert.match(allText, /المختص/)
  assert.match(allText, /وصول/)
  const sections = read('../src/pages/Public/HomeSections.jsx')
  assert.match(sections, /id="inclusion"/)
  assert.match(sections, /INCLUSION_DIFFERENTIATORS\.map/)
  assert.match(sections, /للمدارس والجمعيات والمؤسسات/)
  assert.match(sections, /mailto:support@edubridge\.win/)
})
