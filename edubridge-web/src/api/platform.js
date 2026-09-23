import { BASE_URL, getToken, request } from "./core.js";

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

// ===== نور — المساعد الذكي (المسار محمي بالتوكن) =====
export function askAssistant(messages, context) {
  const recent = messages.slice(-12);
  return request("/assistant/chat", {
    method: "POST",
    body: JSON.stringify({
      messages: recent,
      ...(context ? { context: context.slice(0, 1200) } : {}),
    }),
  });
}

// ===== المحادثات بين مستخدمي المنصة =====
export function fetchConversationUsers() {
  return request('/conversation-users');
}
export function fetchConversations() {
  return request('/conversations');
}
export function createConversation(otherUserId, subject) {
  return request('/conversations', { method: 'POST', body: JSON.stringify({ other_user_id: otherUserId, subject }) });
}
export function fetchConversationMessages(id) {
  return request(`/conversations/${id}/messages`);
}
export function sendConversationMessage(id, content) {
  return request(`/conversations/${id}/messages`, { method: 'POST', body: JSON.stringify({ content }) });
}


