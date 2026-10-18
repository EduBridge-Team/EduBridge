# EduBridge Mobile App

Flutter mobile application for the EduBridge education and accessibility platform.

The app provides role-based access for parents, teachers, specialists, administrators, ministry users, and institutions, with Arabic-first RTL support and accessibility-focused educational features.

## Tech stack

- Flutter
- Dart
- REST API integration with the Laravel backend
- JWT authentication
- Arabic RTL interface
- Text-to-speech support
- Role-based navigation and permissions

## Project structure

Main application code is under:

```text
lib/
```

The backend API configuration is managed from the app configuration files under `lib/`.

## Local setup

Install Flutter dependencies:

```bash
flutter pub get
```

Run the application:

```bash
flutter run
```

Run tests:

```bash
flutter test
```

## API connectivity

For local backend development:

- Physical Android device over USB: use `adb reverse tcp:3000 tcp:3000`, then connect to `http://127.0.0.1:3000/api`.
- Android emulator: use `http://10.0.2.2:3000/api`.
- Production API: `https://api.edubridge.win`.

Never commit production secrets or API keys to the Flutter application.

## Build

Android APK:

```bash
flutter build apk --release
```

Android App Bundle:

```bash
flutter build appbundle --release
```

Release builds are also produced through the repository's GitHub Actions workflows.

## Main capabilities

The mobile application includes:

- Authentication and profile management
- Parent and child flows
- Lessons and progress tracking
- Homework and evaluations
- Educational support workflows
- Notifications and conversations
- Accessibility features
- Noor educational assistant
- Role-aware dashboards and navigation

---

# تطبيق EduBridge للجوال

تطبيق Flutter الخاص بمنصة EduBridge التعليمية، والمصمم لدعم التعليم وإمكانية الوصول مع واجهة عربية RTL وصلاحيات مختلفة حسب دور المستخدم.

يدعم التطبيق أدوار ولي الأمر، المعلّم، الأخصائي، الأدمن، الوزارة، والمؤسسة، مع واجهات ومسارات مناسبة لكل دور.

## التقنيات

- Flutter
- Dart
- تكامل REST API مع Laravel
- مصادقة JWT
- واجهة عربية RTL
- دعم القراءة الصوتية
- تنقل وصلاحيات حسب الدور

## بنية المشروع

الكود الرئيسي للتطبيق موجود داخل:

```text
lib/
```

ويتم ضبط عنوان الـAPI وإعدادات الاتصال من ملفات الإعداد داخل `lib/`.

## التشغيل محليًا

تثبيت الاعتماديات:

```bash
flutter pub get
```

تشغيل التطبيق:

```bash
flutter run
```

تشغيل الاختبارات:

```bash
flutter test
```

## الاتصال بالـAPI

أثناء التطوير المحلي:

- جهاز Android حقيقي عبر USB: استخدم `adb reverse tcp:3000 tcp:3000` ثم اتصل بـ `http://127.0.0.1:3000/api`.
- محاكي Android: استخدم `http://10.0.2.2:3000/api`.
- API الإنتاج: `https://api.edubridge.win`.

لا تضع أسرار الإنتاج أو مفاتيح API داخل تطبيق Flutter ولا ترفعها إلى Git.

## البناء

إنشاء APK:

```bash
flutter build apk --release
```

إنشاء Android App Bundle:

```bash
flutter build appbundle --release
```

كما يتم إنشاء نسخ الإصدار من خلال GitHub Actions الموجودة في المستودع.

## الوظائف الرئيسية

يتضمن التطبيق:

- تسجيل الدخول وإدارة الحساب
- واجهات ولي الأمر والأطفال
- الدروس ومتابعة التقدم
- الواجبات والتقييمات
- مسارات الدعم التعليمي
- الإشعارات والمحادثات
- ميزات إمكانية الوصول
- المساعد التعليمي نور
- لوحات وتنقل حسب صلاحيات المستخدم

## Game launch lifecycle

The catalog and voice commands use `GameLauncher` with a `GamePlayer` supplied
from the selected child's data. Voice commands resolve a named child or show a
child picker; they do not supply a placeholder name or age. Incomplete child
data is reported instead of silently substituting an age.

`GameScreenFactory` owns catalog/voice ID aliases and game construction.
`GameLaunchCoordinator` rejects concurrent launches through preparation and the
route lifetime. The launcher prepares local content and queued results, verifies
that the account and source route remain current, starts progress recording,
then opens the game inside `ChildAdaptationScope`. Returning or failing releases
the launch guard and ends any started progress session in `finally`.

Catalog entries with no child ID retain practice mode; they cannot record a
child result. This lifecycle does not change API routes or authorization.


## Shared game UI and adaptation coverage

`GameStatChip` is the shared round/score/streak presentation used by symbols,
visual words, sequence and story games. Their distinct content, answer rules,
result recording and colours stay in their existing game implementations.
`GameRoundContinuation` owns manual/automatic advancement and cancellation.
The active lesson-video routes use `AdaptiveVideoPlayer`; the unreferenced
legacy `VideoLessonPlayer` implementation has been removed.

Runtime coverage of the following profile flags:

| Stored flag | Current coverage |
| --- | --- |
| `simpleIconsGrid` | Specialist-controlled simplified game/lesson catalogs for child routes; retains all eligible items and lesson actions. Specialist S10 stays unchanged. |
| `colorFiltersEnabled` | Stored profile and overview only; no colour-filter layer. |
| `eyeTrackingOptimized` | Stored profile and overview only; no eye-tracking integration. |
| `largeMouseCursor` | Stored profile and overview only; no custom cursor implementation. |

Keeping these fields preserves saved-profile compatibility. They must not be
advertised as completed assistive integrations. This cleanup does not add device
capabilities, alter saved child settings, or change the backend contract.
