import { BASE_URL, getToken, request } from "./core.js";

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

