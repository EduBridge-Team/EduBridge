#!/usr/bin/env bash
# ============================================================
# نشر EduBridge على الاستضافة من الجوال (عبر SSH / Termius)
# يشغّل: فحص الحزمة + ترقية قاعدة البيانات + مسح Laravel + نشر الموقع
# الاستخدام على الخادم:
#   cd ~/EduBridge && git pull --ff-only && bash deploy/deploy.sh
# ============================================================
set -Eeuo pipefail

# جذر المشروع = مجلد هذا السكربت الأب
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
API="$ROOT/edubridge-api-laravel"
PUBLIC="$API/public"
WEB_BUILD="$ROOT/deploy/web"

echo "==> جذر المشروع: $ROOT"

# 1) فحص المتطلبات والحزمة قبل تغيير أي شيء في النسخة المنشورة
echo "==> (1/4) فحص متطلبات النشر..."
command -v php >/dev/null 2>&1 || {
  echo "خطأ: PHP غير متوفر على الخادم." >&2
  exit 1
}

for required in \
  "$API/artisan" \
  "$WEB_BUILD/app.html" \
  "$WEB_BUILD/assets" \
  "$WEB_BUILD/edubridge-logo.png" \
  "$WEB_BUILD/edubridge-icon.png" \
  "$WEB_BUILD/edubridge-hero-child.webp"; do
  [ -e "$required" ] || {
    echo "خطأ: ملف مطلوب للنشر غير موجود: $required" >&2
    exit 1
  }
done

# ضمان وجود JWT_SECRET ثابت قبل تشغيل المصادقة.
# إذا كان المتغير موجوداً بقيمة فلا نغيّره حتى لا تصبح التوكنات الحالية غير صالحة.
ENV_FILE="$API/.env"
if [ ! -f "$ENV_FILE" ]; then
  echo "خطأ: ملف $ENV_FILE غير موجود." >&2
  exit 1
fi

CURRENT_JWT_SECRET="$(sed -n 's/^JWT_SECRET=//p' "$ENV_FILE" | tail -1 | tr -d '\r" ' || true)"
if [ -z "$CURRENT_JWT_SECRET" ]; then
  echo "==> JWT_SECRET غير موجود؛ سيتم إنشاء مفتاح آمن وحفظه في .env..."
  GENERATED_JWT_SECRET="$(php -r 'echo bin2hex(random_bytes(32));')"
  if grep -q '^JWT_SECRET=' "$ENV_FILE"; then
    sed -i "s|^JWT_SECRET=.*|JWT_SECRET=$GENERATED_JWT_SECRET|" "$ENV_FILE"
  else
    printf '\nJWT_SECRET=%s\n' "$GENERATED_JWT_SECRET" >> "$ENV_FILE"
  fi
fi

# 2) ترقية قاعدة البيانات (آمنة وقابلة للتكرار — IF NOT EXISTS)
echo "==> (2/4) ترقية قاعدة البيانات..."
cd "$API"
php artisan tinker --execute="DB::unprepared(file_get_contents('database/upgrade_parent_features.sql')); echo 'db-ok';"
php artisan tinker --execute="DB::unprepared(file_get_contents('database/upgrade_board_cards.sql')); echo 'db-cards-ok';"
php artisan tinker --execute="DB::unprepared(file_get_contents('database/upgrade_conversations.sql')); echo 'db-chat-ok';"
php artisan tinker --execute="DB::unprepared(file_get_contents('database/upgrade_user_settings.sql')); echo 'db-settings-ok';"
php artisan tinker --execute="DB::unprepared(file_get_contents('database/upgrade_child_accessibility_profiles.sql')); echo 'db-accessibility-ok';"
php artisan tinker --execute="DB::unprepared(file_get_contents('database/upgrade_therapy_requests.sql')); echo 'db-therapy-requests-ok';"
php artisan tinker --execute="DB::unprepared(file_get_contents('database/upgrade_lesson_media.sql')); echo 'db-lesson-media-ok';"

# 3) مسح إعدادات Laravel المؤقتة (config + routes + cache) حتى تُحمَّل المسارات الجديدة
echo "==> (3/4) مسح إعدادات Laravel والمسارات..."
# تحديث خريطة التحميل التلقائي (لالتقاط أي أصناف/ملفات جديدة) إن توفّر composer
if command -v composer >/dev/null 2>&1; then
  composer dump-autoload -o >/dev/null 2>&1 || true
fi
php artisan config:clear
php artisan route:clear
php artisan cache:clear

# فحص المصادقة قبل إكمال النشر: قاعدة البيانات + عمود كلمة المرور + JWT.
echo "==> فحص جاهزية تسجيل الدخول..."
php artisan tinker --execute='
$columns = \Illuminate\Support\Facades\Schema::getColumnListing("users");
$passwordColumn = in_array("password_hash", $columns, true)
    ? "password_hash"
    : (in_array("password", $columns, true) ? "password" : null);
if (!$passwordColumn) {
    throw new \RuntimeException("users table has no password_hash/password column");
}
if (!in_array("role", $columns, true)) {
    throw new \RuntimeException("users table has no role column");
}
$secret = config("services.jwt.secret") ?: env("JWT_SECRET") ?: getenv("JWT_SECRET");
if (!is_string($secret) || trim($secret) === "") {
    throw new \RuntimeException("JWT_SECRET is missing");
}
\Firebase\JWT\JWT::encode(
    ["id" => 0, "role" => "parent", "iat" => time(), "exp" => time() + 60],
    trim($secret),
    "HS256"
);
echo "auth-ok password-column=" . $passwordColumn;
'

# 4) نشر الحزمة. نستبدل assets كوحدة واحدة حتى لا تبقى ملفات builds قديمة.
echo "==> (4/4) نشر الموقع والهوية الجديدة..."
ASSETS_NEXT="$PUBLIC/.edubridge-assets-next-$$"
ASSETS_OLD="$PUBLIC/.edubridge-assets-old-$$"

cleanup() {
  [ ! -d "$ASSETS_NEXT" ] || rm -rf -- "$ASSETS_NEXT"
}
trap cleanup EXIT

mkdir -p "$ASSETS_NEXT"
cp -a "$WEB_BUILD/assets/." "$ASSETS_NEXT/"

if [ -d "$PUBLIC/assets" ]; then
  mv "$PUBLIC/assets" "$ASSETS_OLD"
fi

if ! mv "$ASSETS_NEXT" "$PUBLIC/assets"; then
  [ ! -d "$ASSETS_OLD" ] || mv "$ASSETS_OLD" "$PUBLIC/assets"
  echo "خطأ: تعذّر استبدال ملفات الواجهة؛ تمت استعادة النسخة السابقة." >&2
  exit 1
fi

# نسخ جميع ملفات الواجهة العامة ما عدا .htaccess.
# مهم: .htaccess الخاص بـ Vite SPA يحتوي FallbackResource، ونسخه فوق
# Laravel public/.htaccess يمنع /api من الوصول إلى index.php ويسبب Apache HTTP 500.
find "$WEB_BUILD" -mindepth 1 -maxdepth 1 \
  ! -name assets \
  ! -name .htaccess \
  -exec cp -a {} "$PUBLIC/" \;

# أعد دائماً ملف Laravel .htaccess الأصلي من الـ commit الحالي.
# هذا يصلح أيضاً أي نشر قديم سبق أن استبدله بملف SPA.
git -C "$ROOT" show HEAD:edubridge-api-laravel/public/.htaccess > "$PUBLIC/.htaccess"

[ ! -d "$ASSETS_OLD" ] || rm -rf -- "$ASSETS_OLD"
trap - EXIT

echo "==> ✅ تم النشر. افتح https://edubridge.alwaysdata.net واعمل Ctrl+Shift+R"
