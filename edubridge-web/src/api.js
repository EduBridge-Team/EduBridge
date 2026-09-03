// طبقة الاتصال بالخادم — نفس الواجهة التي يستخدمها تطبيق الموبايل
// في الإنتاج نحدّد عنوان الواجهة وقت البناء عبر المتغير:
//   VITE_API_URL
// في التطوير نستخدم اسم المضيف الحالي حتى يعمل الموقع من أي جهاز على الشبكة
const BASE_URL =
  import.meta.env.VITE_API_URL || `http://${window.location.hostname}:3000/api`;

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

// تسجيل الدخول عبر Google — يحفظ التوكن وبيانات المستخدم
export async function googleLogin(idToken) {
  const data = await request("/auth/google", {
    method: "POST",
    body: JSON.stringify({ id_token: idToken }),
  });
  localStorage.setItem("token", data.token);
  localStorage.setItem("user", JSON.stringify(data.user));
  return data.user;
}

// إنشاء حساب جديد (رقم الهوية اختياري — يُستكمل توثيقه لاحقاً)
export function register(name, email, password, role, nationalId) {
  return request("/auth/register", {
    method: "POST",
    body: JSON.stringify({
      name,
      email,
      password,
      role,
      ...(nationalId ? { national_id: nationalId } : {}),
    }),
  });
}

// الأطفال (ولي الأمر يستلم أطفاله فقط من السيرفر)
export function fetchChildren() {
  return request("/children");
}

// تفاصيل طفل واحد (مع نوع الإعاقة والمعلم المسؤول والحالة)
export function fetchChildDetails(childId) {
  return request(`/children/${childId}`);
}

// تقييمات الطفل (يعرضها ولي الأمر ضمن تفاصيل الطفل)
export function fetchChildEvaluations(childId) {
  return request(`/children/${childId}/evaluations`);
}

// إضافة طفل جديد (ولي الأمر)
export function addChild(payload) {
  return request("/children", {
    method: "POST",
    body: JSON.stringify(payload),
  });
}

// تعديل بيانات طفل
export function updateChild(childId, payload) {
  return request(`/children/${childId}`, {
    method: "PUT",
    body: JSON.stringify(payload),
  });
}

// دروس طفل حسب نوع إعاقته
export function fetchChildLessons(childId) {
  return request(`/children/${childId}/lessons`);
}

// كل الدروس (لصفحة التصفح)
export function fetchLessons() {
  return request("/lessons");
}

// أنواع الإعاقة (قائمة مرجعية)
export function fetchDisabilityTypes() {
  return request("/disability-types");
}

// إضافة درس جديد (معلّم/أدمن)
export function createLesson(payload) {
  return request("/lessons", {
    method: "POST",
    body: JSON.stringify(payload),
  });
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

// ===== الإشعارات — لكل مستخدم إشعاراته =====

// كل إشعارات المستخدم الحالي
export function fetchNotifications() {
  return request("/notifications");
}

// عدد الإشعارات غير المقروءة (لشارة الجرس)
export function fetchUnreadNotificationsCount() {
  return request("/notifications/unread/count");
}

// تعليم إشعار كمقروء
export function markNotificationRead(id) {
  return request(`/notifications/${id}/read`, { method: "PUT" });
}

// تعليم كل الإشعارات كمقروءة
export function markAllNotificationsRead() {
  return request("/notifications/read-all", { method: "PUT" });
}

// ===== لوحة التحكم الإدارية (أدمن فقط) =====

// كل المستخدمين، مع فلترة اختيارية حسب الدور
export function fetchUsers(role) {
  const q = role ? `?role=${encodeURIComponent(role)}` : "";
  return request(`/users${q}`);
}

// تعديل مستخدم (الاسم/البريد/الدور/الهاتف)
export function updateUser(id, payload) {
  return request(`/users/${id}`, {
    method: "PUT",
    body: JSON.stringify(payload),
  });
}

// ربط طفل بولي أمر
export function linkParent(childId, parentId) {
  return request(`/children/${childId}/parents`, {
    method: "POST",
    body: JSON.stringify({ parent_id: parentId }),
  });
}

// حذف مستخدم (أدمن) — البطاقة 11
export function deleteUser(id) {
  return request(`/users/${id}`, { method: "DELETE" });
}

// ===== رفع الملفات (صور الهوية/الشهادات/المستندات) =====
// يرسل الملف كـ multipart ويعيد { url }
export async function uploadFile(file) {
  const fd = new FormData();
  fd.append("file", file);
  const token = getToken();
  const res = await fetch(`${BASE_URL}/uploads`, {
    method: "POST",
    headers: token ? { Authorization: `Bearer ${token}` } : {},
    body: fd,
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.error || "تعذّر رفع الملف");
  return data; // { url }
}

// ===== توثيق الهوية (البطاقات 1، 4، 9) =====
export function submitMyIdentity(payload) {
  return request("/me/identity", { method: "POST", body: JSON.stringify(payload) });
}
export function fetchMyVerification() {
  return request("/me/verification");
}
export function fetchVerificationUsers(status) {
  const q = status ? `?status=${encodeURIComponent(status)}` : "";
  return request(`/verifications/users${q}`);
}
export function reviewUserVerification(id, status, note) {
  return request(`/verifications/users/${id}`, {
    method: "PUT",
    body: JSON.stringify({ status, note }),
  });
}
export function fetchVerificationChildren(status) {
  const q = status ? `?status=${encodeURIComponent(status)}` : "";
  return request(`/verifications/children${q}`);
}
export function reviewChildVerification(id, status, note) {
  return request(`/verifications/children/${id}`, {
    method: "PUT",
    body: JSON.stringify({ status, note }),
  });
}

// ===== الشهادات (البطاقة 9) =====
export function fetchCertificates(opts = {}) {
  // opts: { userId?, status? } — الأدمن يمكنه الفلترة بالحالة أو بمستخدم محدّد
  const params = {};
  if (opts.userId) params.user_id = opts.userId;
  if (opts.status) params.status = opts.status;
  const q = new URLSearchParams(params).toString();
  return request(`/certificates${q ? `?${q}` : ""}`);
}
export function addCertificate(payload) {
  return request("/certificates", { method: "POST", body: JSON.stringify(payload) });
}
export function reviewCertificate(id, status, note) {
  return request(`/certificates/${id}`, {
    method: "PUT",
    body: JSON.stringify({ status, note }),
  });
}
export function deleteCertificate(id) {
  return request(`/certificates/${id}`, { method: "DELETE" });
}

// ===== البحث برقم الهوية (البطاقة 2) =====
export function searchByNationalId(q) {
  return request(`/search/national-id?q=${encodeURIComponent(q)}`);
}

// ===== مراجعة المناهج (البطاقة 3) =====
export function fetchMinistryLessons(status) {
  const q = status ? `?status=${encodeURIComponent(status)}` : "";
  return request(`/ministry/lessons${q}`);
}
export function reviewLessonCurriculum(id, status, note) {
  return request(`/ministry/lessons/${id}`, {
    method: "PUT",
    body: JSON.stringify({ status, note }),
  });
}

// ===== تقييمات الدروس (البطاقة 8) =====
export function fetchLessonRatings(lessonId) {
  return request(`/lessons/${lessonId}/ratings`);
}
export function rateLesson(lessonId, stars, comment) {
  return request(`/lessons/${lessonId}/ratings`, {
    method: "POST",
    body: JSON.stringify({ stars, comment }),
  });
}

// ===== الدعم الفني والشكاوى (البطاقة 11) =====
export function fetchTickets(params = {}) {
  const q = new URLSearchParams(params).toString();
  return request(`/support${q ? `?${q}` : ""}`);
}
export function createTicket(payload) {
  return request("/support", { method: "POST", body: JSON.stringify(payload) });
}
export function updateTicket(id, payload) {
  return request(`/support/${id}`, { method: "PUT", body: JSON.stringify(payload) });
}

// ===== دراسة الحالة مع المختصين (البطاقة 7) =====
export function fetchConsultations() {
  return request("/consultations");
}
export function fetchConsultation(id) {
  return request(`/consultations/${id}`);
}
export function createConsultation(payload) {
  return request("/consultations", { method: "POST", body: JSON.stringify(payload) });
}
export function updateConsultation(id, payload) {
  return request(`/consultations/${id}`, { method: "PUT", body: JSON.stringify(payload) });
}
export function addConsultationNote(id, content) {
  return request(`/consultations/${id}/notes`, {
    method: "POST",
    body: JSON.stringify({ content }),
  });
}
