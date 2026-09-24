// طبقة الاتصال بالخادم — نفس الواجهة التي يستخدمها تطبيق الموبايل
// في الإنتاج نحدّد عنوان الواجهة وقت البناء عبر المتغير:
//   VITE_API_URL
// القيمة الافتراضية same-origin آمنة للإنتاج ولا تسبب mixed-content على HTTPS.
// للتطوير المحلي يمكن تمرير VITE_API_URL=http://localhost:3000/api.
export const BASE_URL = import.meta.env.VITE_API_URL || "/api";

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

export async function openProtectedFile(url) {
  if (!url) throw new Error("رابط الملف غير متاح");

  if (!url.startsWith("/api/private-files/")) {
    window.open(url, "_blank", "noopener,noreferrer");
    return;
  }

  // Open the tab synchronously from the user's click. Opening it only after
  // awaiting fetch() is treated as an unsolicited popup by mobile browsers.
  const popup = window.open("about:blank", "_blank");
  if (!popup) {
    throw new Error("المتصفح منع فتح الملف. اسمح بالنوافذ المنبثقة لهذا الموقع ثم حاول مرة أخرى.");
  }

  try {
    popup.document.title = "EduBridge";
    popup.document.body.innerHTML =
      '<div dir="rtl" style="font-family:sans-serif;padding:24px">جارِ تحميل الملف...</div>';

    const token = getToken();
    const res = await fetch(url, {
      headers: token ? { Authorization: `Bearer ${token}` } : {},
    });

    if (!res.ok) {
      let message = `تعذّر فتح الملف (HTTP ${res.status})`;
      try {
        const data = await res.json();
        message = data.error || data.message || message;
      } catch {}
      throw new Error(message);
    }

    const blob = await res.blob();
    const objectUrl = URL.createObjectURL(blob);

    popup.location.replace(objectUrl);
    window.setTimeout(() => URL.revokeObjectURL(objectUrl), 5 * 60 * 1000);
  } catch (err) {
    popup.close();
    throw err;
  }
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
export async function request(path, options = {}) {
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
export function register(name, email, password, role, nationalId, specialty) {
  return request("/auth/register", {
    method: "POST",
    body: JSON.stringify({
      name,
      email,
      password,
      role,
      ...(nationalId ? { national_id: nationalId } : {}),
      ...(specialty ? { specialty } : {}),
    }),
  });
}



export function forgotPassword(email) {
  return request("/auth/forgot-password", {
    method: "POST",
    body: JSON.stringify({ email }),
  });
}

export function resetPassword(email, token, password) {
  return request("/auth/reset-password", {
    method: "POST",
    body: JSON.stringify({ email, token, password }),
  });
}

export function resendEmailVerification(email) {
  return request("/auth/resend-verification", {
    method: "POST",
    body: JSON.stringify({ email }),
  });
}
