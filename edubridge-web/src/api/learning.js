import { BASE_URL, getToken, getUser, request } from "./core.js";

// الأطفال (ولي الأمر يستلم أطفاله فقط من السيرفر)
export function fetchChildren(params = {}) {
  const query = new URLSearchParams(params).toString();
  return request(`/children${query ? `?${query}` : ''}`);
}

// تفاصيل طفل واحد (مع نوع الإعاقة والمعلم المسؤول والحالة)
export function fetchChildDetails(childId) {
  return request(`/children/${childId}`).catch(error => {
    if (getUser()?.role !== 'specialist') throw error;
    return request(`/children/${childId}/assignment-preview`);
  });
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
export function fetchLessons(params = {}) {
  const query = new URLSearchParams(params).toString();
  return request(`/lessons${query ? `?${query}` : ''}`);
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



// إعدادات الوصول المشتركة بين الويب والموبايل
export function fetchChildAccessibilityProfile(childId) {
  return request(`/children/${childId}/accessibility-profile`);
}

export function saveChildAccessibilityProfile(childId, profile) {
  return request(`/children/${childId}/accessibility-profile`, {
    method: "PUT",
    body: JSON.stringify({ profile }),
  });
}

// النجوم ونتائج الألعاب
export function fetchChildEngagement(childId) {
  return request(`/children/${childId}/engagement`);
}

export function addChildStars(childId, count = 1, eventId = crypto.randomUUID()) {
  return request(`/children/${childId}/rewards/stars`, {
    method: "POST",
    body: JSON.stringify({ count, event_id: eventId }),
  });
}

export function recordGameAttempt(childId, gameKey, score, starsEarned = 0, durationSeconds = null, eventId = crypto.randomUUID()) {
  return request(`/children/${childId}/game-attempts`, {
    method: "POST",
    body: JSON.stringify({
      game_key: gameKey,
      event_id: eventId,
      score,
      stars_earned: starsEarned,
      ...(durationSeconds == null ? {} : { duration_seconds: durationSeconds }),
    }),
  });
}


// تنبيهات الطوارئ الخاصة بالطفل
export function fetchChildEmergencyAlerts(childId) {
  return request(`/children/${childId}/emergency-alerts`);
}

export function sendChildEmergencyAlert(childId, message = '') {
  return request(`/children/${childId}/emergency-alerts`, {
    method: "POST",
    body: JSON.stringify({ source: "web", ...(message ? { message } : {}) }),
  });
}

export function resolveEmergencyAlert(id) {
  return request(`/emergency-alerts/${id}/resolve`, {
    method: "PUT",
    body: "{}",
  });
}

export function saveChildEvaluation(childId, payload) {
  return request(`/evaluations/child/${childId}`, { method: 'POST', body: JSON.stringify(payload) });
}


// قاموس لغة الإشارة الفلسطينية
export function fetchSignLanguageCategories() {
  return request("/sign-language/categories");
}

export function fetchSignLanguageSigns(params = {}) {
  const query = new URLSearchParams(params).toString();
  return request(`/sign-language/signs${query ? `?${query}` : ''}`);
}
