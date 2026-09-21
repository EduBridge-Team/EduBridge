// طبقة الاتصال بالخادم — نفس الواجهة التي يستخدمها تطبيق الموبايل
// في الإنتاج نحدّد عنوان الواجهة وقت البناء عبر المتغير:
//   VITE_API_URL
// القيمة الافتراضية same-origin آمنة للإنتاج ولا تسبب mixed-content على HTTPS.
// للتطوير المحلي يمكن تمرير VITE_API_URL=http://localhost:3000/api.
const BASE_URL = import.meta.env.VITE_API_URL || "/api";

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

export async function fetchMyProfile() {
  const data = await request("/me");
  const user = data.user || data;
  if (user?.id) {
    const current = getUser() || {};
    localStorage.setItem("user", JSON.stringify({ ...current, ...user }));
  }
  return user;
}

export function changeMyPassword(currentPassword, newPassword) {
  return request("/me/password", {
    method: "PUT",
    body: JSON.stringify({
      current_password: currentPassword,
      new_password: newPassword,
    }),
  });
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

  const raw = await res.text();
  let data = {};
  if (raw) {
    try {
      data = JSON.parse(raw);
    } catch {
      data = {};
    }
  }

  if (!res.ok) {
    const serverMessage =
      data.error ||
      data.message ||
      (res.status >= 500
        ? `خطأ في السيرفر (HTTP ${res.status})`
        : `تعذّر إكمال الطلب (HTTP ${res.status})`);
    throw new Error(serverMessage);
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

export function deleteChild(childId) {
  return request(`/children/${childId}`, { method: "DELETE" });
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

// إضافة درس جديد (معلّم/أدمن).
// يقبل JSON للدروس النصية أو FormData للدروس التي تحتوي وسائط.
export async function createLesson(payload) {
  if (!(payload instanceof FormData)) {
    return request("/lessons", {
      method: "POST",
      body: JSON.stringify(payload),
    });
  }

  const token = getToken();
  let res;
  try {
    res = await fetch(`${BASE_URL}/lessons`, {
      method: "POST",
      headers: token ? { Authorization: `Bearer ${token}` } : {},
      body: payload,
    });
  } catch {
    throw new Error("تعذّر الاتصال بالسيرفر");
  }

  const raw = await res.text();
  let data = {};
  if (raw) {
    try {
      data = JSON.parse(raw);
    } catch {
      data = {};
    }
  }

  if (!res.ok) {
    throw new Error(data.error || data.message || `تعذّر حفظ الدرس (HTTP ${res.status})`);
  }

  return data;
}


export async function updateLesson(id, payload) {
  if (!(payload instanceof FormData)) {
    return request(`/lessons/${id}`, {
      method: "PUT",
      body: JSON.stringify(payload),
    });
  }

  const token = getToken();
  let res;
  try {
    res = await fetch(`${BASE_URL}/lessons/${id}`, {
      method: "POST",
      headers: token ? { Authorization: `Bearer ${token}` } : {},
      body: payload,
    });
  } catch {
    throw new Error("تعذّر الاتصال بالسيرفر");
  }

  const raw = await res.text();
  let data = {};
  if (raw) {
    try {
      data = JSON.parse(raw);
    } catch {
      data = {};
    }
  }

  if (!res.ok) {
    throw new Error(data.error || data.message || `تعذّر تعديل الدرس (HTTP ${res.status})`);
  }

  return data;
}

export function deleteLesson(id) {
  return request(`/lessons/${id}`, { method: "DELETE" });
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


// ===== Homework =====
async function multipartRequest(path, formData, method = 'POST') {
  const token = getToken();
  let res;
  try {
    res = await fetch(`${BASE_URL}${path}`, {
      method,
      headers: token ? { Authorization: `Bearer ${token}` } : {},
      body: formData,
    });
  } catch {
    throw new Error('تعذّر الاتصال بالسيرفر');
  }

  const raw = await res.text();
  let data = {};
  if (raw) {
    try { data = JSON.parse(raw); } catch { data = {}; }
  }
  if (!res.ok) {
    throw new Error(data.error || data.message || `تعذّر إكمال الطلب (HTTP ${res.status})`);
  }
  return data;
}

export function fetchHomeworks(childId) {
  const q = childId ? `?child_id=${encodeURIComponent(childId)}` : '';
  return request(`/homeworks${q}`);
}

export function createHomeworkWeb(payload, files = []) {
  const fd = new FormData();
  fd.append('title', payload.title);
  fd.append('description', payload.description);
  fd.append('due_date', payload.due_date);
  if (payload.subject) fd.append('subject', payload.subject);
  fd.append('assigned_child_ids', JSON.stringify(payload.assigned_child_ids || []));
  files.forEach((file) => fd.append('attachments[]', file));
  return multipartRequest('/homeworks', fd);
}

export function submitHomeworkWeb(homeworkId, payload, files = []) {
  const fd = new FormData();
  fd.append('child_id', String(payload.child_id));
  if (payload.text_answer) fd.append('text_answer', payload.text_answer);
  files.forEach((file) => fd.append('files[]', file));
  return multipartRequest(`/homeworks/${homeworkId}/submit`, fd);
}

export function gradeHomeworkWeb(submissionId, grade, feedback) {
  return request(`/homeworks/submissions/${submissionId}/grade`, {
    method: 'PUT',
    body: JSON.stringify({ grade, feedback }),
  });
}

// ===== Weekly reports =====
export function fetchWeeklyReport(childId, weekStart) {
  const params = new URLSearchParams({ child_id: String(childId) });
  if (weekStart) params.set('week_start', weekStart);
  return request(`/reports/weekly?${params.toString()}`);
}

export function fetchChildWeeklyReports(childId) {
  return request(`/reports/weekly/child/${childId}`);
}

export function saveWeeklyReport(payload) {
  return request('/reports/weekly', {
    method: 'POST',
    body: JSON.stringify(payload),
  });
}

// ===== Therapy requests & sessions =====
export function fetchTherapyRequests(params = {}) {
  const q = new URLSearchParams(params).toString();
  return request(`/therapy/requests${q ? `?${q}` : ''}`);
}

export function createTherapyRequestWeb(payload) {
  return request('/therapy/requests', {
    method: 'POST',
    body: JSON.stringify(payload),
  });
}

export function scheduleTherapyRequestWeb(id, payload) {
  return request(`/therapy/requests/${id}/schedule`, {
    method: 'PUT',
    body: JSON.stringify(payload),
  });
}

export function cancelTherapyRequestWeb(id) {
  return request(`/therapy/requests/${id}/cancel`, { method: 'PUT', body: '{}' });
}

export function fetchTherapySessions(childId) {
  const q = childId ? `?child_id=${encodeURIComponent(childId)}` : '';
  return request(`/therapy/sessions${q}`);
}

export function completeTherapySessionWeb(id, payload) {
  return request(`/therapy/sessions/${id}/complete`, {
    method: 'PUT',
    body: JSON.stringify(payload),
  });
}

// ===== Care team =====
export function fetchCareTeam(childId) {
  return request(`/children/${childId}/care-team`);
}

export function fetchChildTeachers(childId) {
  return request(`/children/${childId}/teachers`);
}

export function fetchChildSpecialists(childId) {
  return request(`/children/${childId}/specialists`);
}

export function addCareTeamMember(childId, payload) {
  return request(`/children/${childId}/care-team`, {
    method: 'POST',
    body: JSON.stringify(payload),
  });
}

export function removeCareTeamMember(childId, userId) {
  return request(`/children/${childId}/care-team/${userId}`, { method: 'DELETE' });
}

// ===== Collaborative case discussions =====
export function fetchCaseDiscussions(childId) {
  const q = childId ? `?child_id=${encodeURIComponent(childId)}` : '';
  return request(`/case-discussions${q}`);
}

export function createCaseDiscussionWeb(payload) {
  return request('/case-discussions', { method: 'POST', body: JSON.stringify(payload) });
}

export function fetchCaseDiscussion(id) {
  return request(`/case-discussions/${id}`);
}

export function sendCaseDiscussionMessage(id, content, type = 'text') {
  return request(`/case-discussions/${id}/messages`, {
    method: 'POST',
    body: JSON.stringify({ content, type }),
  });
}

export function resolveCaseDiscussionWeb(id) {
  return request(`/case-discussions/${id}/resolve`, { method: 'PUT', body: '{}' });
}

// ===== Specialist workflow =====
export function setMySpecialty(specialty) {
  return request('/me/specialty', {
    method: 'PUT',
    body: JSON.stringify({ specialty }),
  });
}

export function fetchSpecialistSuggestions(status) {
  const q = status ? `?status=${encodeURIComponent(status)}` : '';
  return request(`/specialist-suggestions${q}`);
}

export function createSpecialistSuggestion(childId, payload) {
  return request(`/children/${childId}/specialist-suggestions`, {
    method: 'POST',
    body: JSON.stringify(payload),
  });
}

export function acceptSpecialistSuggestion(id) {
  return request(`/specialist-suggestions/${id}/accept`, { method: 'PUT', body: '{}' });
}

export function rejectSpecialistSuggestion(id, reason = '') {
  return request(`/specialist-suggestions/${id}/reject`, {
    method: 'PUT',
    body: JSON.stringify({ reason }),
  });
}


export function fetchParentLessons() {
  return request('/lessons?target_type=parents');
}
