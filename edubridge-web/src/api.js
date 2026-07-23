// طبقة الاتصال بالـ API — نفس الخادم الذي يستخدمه تطبيق الموبايل
// نستخدم hostname الحالي بدل localhost حتى يعمل من أي جهاز على الشبكة
const BASE_URL = `http://${window.location.hostname}:3000/api`;

// التوكن وبيانات المستخدم في localStorage
export function getToken() {
  return localStorage.getItem("token");
}

export function getUser() {
  const raw = localStorage.getItem("user");
  return raw ? JSON.parse(raw) : null;
}

export function logout() {
  localStorage.removeItem("token");
  localStorage.removeItem("user");
}

// طلب عام مع التوكن ومعالجة الأخطاء بشكل موحّد
async function request(path, options = {}) {
  const headers = { "Content-Type": "application/json", ...options.headers };
  const token = getToken();
  if (token) headers.Authorization = `Bearer ${token}`;

  let res;
  try {
    res = await fetch(`${BASE_URL}${path}`, { ...options, headers });
  } catch {
    // فشل الشبكة نفسه (السيرفر مطفأ مثلاً)
    throw new Error("تعذّر الاتصال بالسيرفر");
  }

  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    throw new Error(data.error || "حدث خطأ غير متوقع");
  }
  return data;
}

// تسجيل الدخول — يحفظ التوكن وبيانات المستخدم
export async function login(email, password) {
  const data = await request("/auth/login", {
    method: "POST",
    body: JSON.stringify({ email, password }),
  });
  localStorage.setItem("token", data.token);
  localStorage.setItem("user", JSON.stringify(data.user));
  return data.user;
}

// إنشاء حساب جديد
export function register(name, email, password, role) {
  return request("/auth/register", {
    method: "POST",
    body: JSON.stringify({ name, email, password, role }),
  });
}

// الأطفال (ولي الأمر يستلم أطفاله فقط من السيرفر)
export function fetchChildren() {
  return request("/children");
}

// دروس طفل حسب نوع إعاقته
export function fetchChildLessons(childId) {
  return request(`/children/${childId}/lessons`);
}

// كل الدروس (لصفحة التصفح)
export function fetchLessons() {
  return request("/lessons");
}

// تقدّم الطفل: التفاصيل والملخّص
export function fetchChildProgress(childId) {
  return request(`/progress/child/${childId}`);
}

export function fetchChildSummary(childId) {
  return request(`/progress/child/${childId}/summary`);
}

// تسجيل إتمام درس (معلّم/مختص/أدمن فقط)
export function markLessonDone(childId, lessonId) {
  return request("/progress", {
    method: "POST",
    body: JSON.stringify({ child_id: childId, lesson_id: lessonId, status: "done" }),
  });
}
