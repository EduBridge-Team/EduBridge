import { BASE_URL, getToken, request } from "./core.js";

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

// ===== Learning support requests & meetings =====
export function fetchLearningSupportRequests(params = {}) {
  const q = new URLSearchParams(params).toString();
  return request(`/learning-support/requests${q ? `?${q}` : ''}`);
}

export function createLearningSupportRequestWeb(payload) {
  return request('/learning-support/requests', {
    method: 'POST',
    body: JSON.stringify(payload),
  });
}

export function scheduleLearningSupportRequestWeb(id, payload) {
  return request(`/learning-support/requests/${id}/schedule`, {
    method: 'PUT',
    body: JSON.stringify(payload),
  });
}

export function cancelLearningSupportRequestWeb(id) {
  return request(`/learning-support/requests/${id}/cancel`, { method: 'PUT', body: '{}' });
}

export function fetchLearningSupportMeetings(childId) {
  const q = childId ? `?child_id=${encodeURIComponent(childId)}` : '';
  return request(`/learning-support/meetings${q}`);
}

export function completeLearningSupportMeetingWeb(id, payload) {
  return request(`/learning-support/meetings/${id}/complete`, {
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

