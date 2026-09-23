# النشر الاحتياطي القديم على Alwaysdata (Termius / SSH)

> الإنتاج الأساسي الآن على Taqat: https://edubridge.win و https://api.edubridge.win
>
> هذا الدليل محفوظ فقط لمسار Alwaysdata الاحتياطي/القديم.

هذا المجلد يحتوي نسخة الموقع **الجاهزة للنشر** (`deploy/web`) وسكربت نشر واحد
(`deploy.sh`) حتى تُحدِّث الاستضافة من جوالك بدون كمبيوتر.

## الخطوات

1. ادمج آخر تغييرات إلى `main` على GitHub (تم).
2. من تطبيق **Termius** افتح جلسة SSH على الخادم، ونفّذ:

   ```bash
   cd ~/EduBridge && git pull --ff-only && bash deploy/deploy.sh
   ```

3. افتح `https://edubridge.alwaysdata.net` واضغط **Ctrl+Shift+R** لتجاوز الكاش.

## ماذا يفعل السكربت؟

1. **يرقّي قاعدة البيانات** بتشغيل `database/upgrade_parent_features.sql`
   (آمن وقابل للتكرار — `IF NOT EXISTS`، لا يمسّ بيانات موجودة) عبر اتصال
   Laravel نفسه (بدون إدخال كلمات مرور).
2. **يمسح إعدادات Laravel** المؤقتة (`php artisan config:clear`).
3. **ينظّف كاش Laravel** حتى تُحمّل الإعدادات والمسارات الجديدة.
4. **ينشر الموقع**: يستبدل ملفات `assets` القديمة كوحدة واحدة، ثم ينسخ كامل
   محتوى `deploy/web` — بما فيه صور الهوية الجديدة — إلى مجلد `public` دون
   المساس بملفات Laravel.

> نسخة الموقع في `deploy/web` مبنية بـ `VITE_API_URL=/api`. لإعادة بنائها لاحقاً:
> `cd edubridge-web && VITE_API_URL=/api npm run build` ثم انسخ ناتج `dist`
> إلى `deploy/web` (`index.html` تُسمّى `app.html`).


<!-- Auto-deploy verification marker: 2026-09-23 -->

## ملاحظة حول الحزمة الاحتياطية للموقع

مسار الإنتاج الحالي على Taqat **لا يعتمد على** `deploy/web`; يتم بناء واجهة React مباشرة أثناء نشر Taqat عبر `deploy/taqat-build.sh`.

إذا احتجت حزمة الويب القديمة/الاحتياطية (مثل نشر Alwaysdata)، شغّل GitHub Action باسم **Build deployable website** يدويًا من تبويب Actions. سيُنشئ Artifact باسم `EduBridge-Web-Deploy-<run_number>` يمكن تنزيله واستخدام محتوى مجلد `web` منه.

لا يقوم هذا الـ workflow بالكتابة إلى `main` أو تجاوز حماية الفروع.
