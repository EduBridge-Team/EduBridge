# النشر من الجوال (Termius / SSH)

هذا المجلد يحتوي نسخة الموقع **الجاهزة للنشر** (`deploy/web`) وسكربت نشر واحد
(`deploy.sh`) حتى تُحدِّث الاستضافة من جوالك بدون كمبيوتر.

## الخطوات

1. ادمج آخر تغييرات إلى `main` على GitHub (تم).
2. من تطبيق **Termius** افتح جلسة SSH على الخادم، ونفّذ:

   ```bash
   cd ~/EduBridge && git pull && bash deploy/deploy.sh
   ```

3. افتح `https://edubridge.alwaysdata.net` واضغط **Ctrl+Shift+R** لتجاوز الكاش.

## ماذا يفعل السكربت؟

1. **يرقّي قاعدة البيانات** بتشغيل `database/upgrade_parent_features.sql`
   (آمن وقابل للتكرار — `IF NOT EXISTS`، لا يمسّ بيانات موجودة) عبر اتصال
   Laravel نفسه (بدون إدخال كلمات مرور).
2. **يمسح إعدادات Laravel** المؤقتة (`php artisan config:clear`).
3. **ينشر الموقع**: ينسخ `deploy/web` (assets + icon.png + app.html) إلى
   مجلد `public` في الواجهة الخلفية.

> نسخة الموقع في `deploy/web` مبنية بـ `VITE_API_URL=/api`. لإعادة بنائها لاحقاً:
> `cd edubridge-web && VITE_API_URL=/api npm run build` ثم انسخ ناتج `dist`
> إلى `deploy/web` (`index.html` تُسمّى `app.html`).
