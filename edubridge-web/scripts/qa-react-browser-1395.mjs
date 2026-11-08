import assert from 'node:assert/strict';
import { mkdir } from 'node:fs/promises';
import { chromium } from 'playwright';

// Browser UI checks use synthetic in-memory API responses only.
// No real credentials, external API calls, or persistent database writes.
const origin = 'http://127.0.0.1:4173';
const screenshots = 'test-artifacts/react-ui';
const unexpectedApi = [];
const schoolA = { id: 8301, name: 'QA School A', address: 'Synthetic address A' };
const schoolB = { id: 8302, name: 'QA School B', address: 'Synthetic address B' };

function catalog(id) {
  return {
    school_id: id,
    academic_years: [],
    academic_terms: [],
    grades: [],
    sections: [],
    subjects: [],
  };
}

async function routeRequest(route) {
  const url = new URL(route.request().url());
  if (url.origin !== origin) {
    await route.abort('blockedbyclient');
    return;
  }
  const path = url.pathname;
  if (!path.startsWith('/api/')) {
    await route.continue();
    return;
  }

  let status = 200;
  let data = {};
  if (path === '/api/auth/login' && route.request().method() === 'POST') {
    const input = route.request().postDataJSON();
    assert.equal(input.email, 'synthetic-ui@example.test');
    data = {
      user: {
        id: 8101,
        name: 'QA Institution Owner',
        email: 'synthetic-ui@example.test',
        role: 'institution',
        verification_status: 'verified',
      },
    };
  } else if (path === '/api/institutions/my-organization') {
    data = {
      organization: {
        id: 8201,
        slug: 'qa-institution',
        name: 'QA Institution',
        is_active: true,
        settings: { display_name: 'QA Institution' },
      },
    };
  } else if (path === '/api/institutions/qa-institution/schools') {
    data = { schools: [schoolA, schoolB] };
  } else if (/^\/api\/institutions\/qa-institution\/schools\/830[12]\/academic$/.test(path)) {
    data = catalog(path.includes('/8301/') ? 8301 : 8302);
  } else if (/^\/api\/institutions\/qa-institution\/schools\/830[12]\/attendance$/.test(path)) {
    data = { attendance_sessions: [] };
  } else if (/^\/api\/institutions\/qa-institution\/schools\/830[12]\/timetable$/.test(path)) {
    data = { timetable: [] };
  } else if (/^\/api\/institutions\/qa-institution\/schools\/830[12]\/curriculum$/.test(path)) {
    data = { books: [] };
  } else if (path === '/api/admin/schools/8301/director') {
    data = { director: { name: 'QA Director A', email: 'director-a@example.test' } };
  } else if (path === '/api/admin/schools/8302/director') {
    data = { director: null };
  } else if (/^\/api\/admin\/schools\/830[12]\/management-history$/.test(path)) {
    data = { assignments: [] };
  } else if (/^\/api\/admin\/schools\/830[12]\/director-invitations$/.test(path)) {
    data = { invitations: [] };
  } else {
    unexpectedApi.push(path);
    status = 404;
    data = { error: 'Unexpected synthetic QA request' };
  }
  await route.fulfill({
    status,
    contentType: 'application/json',
    body: JSON.stringify(data),
  });
}

const browser = await chromium.launch({ headless: true });
try {
  await mkdir(screenshots, { recursive: true });
  const desktop = await browser.newContext({
    viewport: { width: 1280, height: 800 },
    locale: 'ar-PS',
  });
  await desktop.route('**/*', routeRequest);
  const page = await desktop.newPage();
  const pageErrors = [];
  page.on('pageerror', (error) => pageErrors.push(error.message));

  await page.goto(origin + '/login', { waitUntil: 'domcontentloaded' });
  await page.getByRole('heading', { name: 'أهلاً بعودتك' }).waitFor();
  assert.equal(await page.locator('html').getAttribute('dir'), 'rtl');
  await page.locator('#email').fill('synthetic-ui@example.test');
  await page.locator('#password').fill('SyntheticFakePass!');
  await page.getByRole('button', { name: 'تسجيل الدخول' }).click();

  await page.waitForURL('**/institution', { timeout: 15000 });
  await page.getByRole('button', { name: 'إدارة المدارس' }).first().click();
  await page.waitForURL('**/institution/schools', { timeout: 15000 });
  await page.getByRole('heading', { name: 'QA Institution' }).waitFor();
  await page.getByRole('heading', { name: 'إعداد الهيكل الأكاديمي' }).waitFor();
  const directorA = page.getByRole('heading', { name: /مدير المدرسة.*QA School A/ });
  await directorA.waitFor();
  await directorA.locator('..').getByText('QA Director A', { exact: false }).waitFor();
  console.log('PASS: React institution login, school A, and director A rendered');

  await page.getByRole('button', { name: /QA School B/ }).click();
  const directorB = page.getByRole('heading', { name: /مدير المدرسة.*QA School B/ });
  await directorB.waitFor();
  await directorB.locator('..').getByText('لم يُكلّف مدير بعد.').waitFor();
  assert.equal(await directorB.locator('..').getByText('QA Director A').count(), 0);
  await page.getByRole('heading', { name: 'إعداد الهيكل الأكاديمي' }).waitFor();
  await page.screenshot({ path: screenshots + '/institution-schools-desktop.png', fullPage: true });
  console.log('PASS: React school switch shows isolated UI data and academic forms');

  const mobile = await browser.newContext({
    viewport: { width: 390, height: 844 },
    deviceScaleFactor: 1,
    locale: 'ar-PS',
    isMobile: true,
    hasTouch: true,
  });
  await mobile.route('**/*', routeRequest);
  const mobilePage = await mobile.newPage();
  mobilePage.on('pageerror', (error) => pageErrors.push(error.message));
  await mobilePage.goto(origin + '/login', { waitUntil: 'domcontentloaded' });
  await mobilePage.getByRole('heading', { name: 'أهلاً بعودتك' }).waitFor();
  await mobilePage.locator('#email').waitFor();
  const widths = await mobilePage.evaluate(() => ({
    page: document.documentElement.scrollWidth,
    viewport: window.innerWidth,
  }));
  assert.ok(widths.page <= widths.viewport + 8, 'Mobile login has horizontal overflow');
  await mobilePage.screenshot({ path: screenshots + '/login-mobile.png', fullPage: true });
  console.log('PASS: React RTL and 390px mobile login rendering');

  assert.deepEqual(unexpectedApi, [], 'Unexpected API requests in mocked UI flow');
  assert.deepEqual(pageErrors, [], 'Uncaught browser exceptions');
  console.log('PASS: React isolated Chromium smoke completed (mocked API, no backend writes)');
  await mobile.close();
  await desktop.close();
} finally {
  await browser.close();
}
