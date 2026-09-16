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
  "$WEB_BUILD/edubridge-icon.png"; do
  [ -e "$required" ] || {
    echo "خطأ: ملف مطلوب للنشر غير موجود: $required" >&2
    exit 1
  }
done

# 2) ترقية قاعدة البيانات (آمنة وقابلة للتكرار — IF NOT EXISTS)
echo "==> (2/4) ترقية قاعدة البيانات..."
cd "$API"
php artisan tinker --execute="DB::unprepared(file_get_contents('database/upgrade_parent_features.sql')); echo 'db-ok';"
php artisan tinker --execute="DB::unprepared(file_get_contents('database/upgrade_board_cards.sql')); echo 'db-cards-ok';"
php artisan tinker --execute="DB::unprepared(file_get_contents('database/upgrade_conversations.sql')); echo 'db-chat-ok';"
php artisan tinker --execute="DB::unprepared(file_get_contents('database/upgrade_user_settings.sql')); echo 'db-settings-ok';"

# 3) مسح إعدادات Laravel المؤقتة (config + routes + cache) حتى تُحمَّل المسارات الجديدة
echo "==> (3/4) مسح إعدادات Laravel والمسارات..."
# تحديث خريطة التحميل التلقائي (لالتقاط أي أصناف/ملفات جديدة) إن توفّر composer
if command -v composer >/dev/null 2>&1; then
  composer dump-autoload -o >/dev/null 2>&1 || true
fi
php artisan config:clear
php artisan route:clear
php artisan cache:clear

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

# نسخ جميع الملفات العامة، بما فيها صور الهوية الجديدة، دون المساس بملفات Laravel.
find "$WEB_BUILD" -mindepth 1 -maxdepth 1 ! -name assets -exec cp -a {} "$PUBLIC/" \;

[ ! -d "$ASSETS_OLD" ] || rm -rf -- "$ASSETS_OLD"
trap - EXIT

echo "==> ✅ تم النشر. افتح https://edubridge.alwaysdata.net واعمل Ctrl+Shift+R"
