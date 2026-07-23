-- ============================================================
-- EduBridge — بيانات تجريبية (Seed)
-- شغّلها بعد إنشاء الجداول من edubridge_schema.sql
-- ملاحظة: باسورد كل الحسابات = password123
-- ============================================================

-- 1) أنواع الإعاقة
INSERT INTO disability_types (name, description) VALUES
  ('توحّد',         'اضطراب طيف التوحّد'),
  ('صعوبات تعلّم',  'صعوبات في القراءة أو الكتابة أو الحساب'),
  ('إعاقة سمعية',   'ضعف أو فقدان السمع'),
  ('إعاقة بصرية',   'ضعف أو فقدان البصر');

-- 2) المؤسسات الداعمة
INSERT INTO organizations (name, contact, address) VALUES
  ('جمعية الأمل للتربية الخاصة', '0599000000', 'دير البلح'),
  ('مركز النور للرعاية',         '0598111111', 'غزة');

-- 3) المستخدمون (الباسورد المشفّر = password123)
--    الأدوار: parent / teacher / specialist / admin
INSERT INTO users (name, email, password_hash, role, phone) VALUES
  ('أحمد المعلّم',  'teacher@edu.com',    '$2b$10$r7R4x.vLdScMQKTW5oqZQux.BNWtUjfNJwg5AyFR8YVeKCOG1UXC.', 'teacher',    '0591000000'),
  ('سارة المختصّة', 'specialist@edu.com', '$2b$10$r7R4x.vLdScMQKTW5oqZQux.BNWtUjfNJwg5AyFR8YVeKCOG1UXC.', 'specialist', '0592000000'),
  ('أبو محمد',      'parent@edu.com',     '$2b$10$r7R4x.vLdScMQKTW5oqZQux.BNWtUjfNJwg5AyFR8YVeKCOG1UXC.', 'parent',     '0593000000'),
  ('المشرف',        'admin@edu.com',      '$2b$10$r7R4x.vLdScMQKTW5oqZQux.BNWtUjfNJwg5AyFR8YVeKCOG1UXC.', 'admin',      '0594000000');

-- 4) الأطفال (نربط نوع الإعاقة والمؤسسة بالاسم لضمان الصحّة)
INSERT INTO children (name, birth_date, gender, disability_type_id, organization_id, notes) VALUES
  ('محمد',  '2016-04-10', 'male',
     (SELECT id FROM disability_types WHERE name = 'توحّد'),
     (SELECT id FROM organizations   WHERE name = 'جمعية الأمل للتربية الخاصة'),
     'يحب الأنشطة البصرية'),
  ('ليان',  '2015-09-22', 'female',
     (SELECT id FROM disability_types WHERE name = 'صعوبات تعلّم'),
     (SELECT id FROM organizations   WHERE name = 'مركز النور للرعاية'),
     'تحتاج دعم في القراءة'),
  ('يوسف',  '2017-01-15', 'male',
     (SELECT id FROM disability_types WHERE name = 'إعاقة سمعية'),
     NULL,
     'يعتمد على لغة الإشارة');

-- 5) ربط الأطفال بولي الأمر (parent@edu.com)
INSERT INTO child_parent (child_id, parent_id) VALUES
  ((SELECT id FROM children WHERE name = 'محمد'),
   (SELECT id FROM users WHERE email = 'parent@edu.com')),
  ((SELECT id FROM children WHERE name = 'ليان'),
   (SELECT id FROM users WHERE email = 'parent@edu.com'));

-- 6) الدروس (من إنشاء المعلّم، مرتبطة بنوع إعاقة)
INSERT INTO lessons (title, content, disability_type_id, teacher_id) VALUES
  ('التعرّف على المشاعر', 'بطاقات مصوّرة للمشاعر الأساسية',
     (SELECT id FROM disability_types WHERE name = 'توحّد'),
     (SELECT id FROM users WHERE email = 'teacher@edu.com')),
  ('روتين اليوم بالصور', 'جدول يومي بالصور لتنظيم النشاطات',
     (SELECT id FROM disability_types WHERE name = 'توحّد'),
     (SELECT id FROM users WHERE email = 'teacher@edu.com')),
  ('تمييز الحروف', 'تمارين لتمييز الحروف المتشابهة',
     (SELECT id FROM disability_types WHERE name = 'صعوبات تعلّم'),
     (SELECT id FROM users WHERE email = 'teacher@edu.com')),
  ('أساسيات لغة الإشارة', 'فيديوهات لإشارات الكلمات الشائعة',
     (SELECT id FROM disability_types WHERE name = 'إعاقة سمعية'),
     (SELECT id FROM users WHERE email = 'teacher@edu.com'));

-- 7) بعض التقدّم (للطفل محمد على درسين)
INSERT INTO progress (child_id, lesson_id, status, score, completed_at) VALUES
  ((SELECT id FROM children WHERE name = 'محمد'),
   (SELECT id FROM lessons  WHERE title = 'التعرّف على المشاعر'),
   'done', 85, NOW()),
  ((SELECT id FROM children WHERE name = 'محمد'),
   (SELECT id FROM lessons  WHERE title = 'روتين اليوم بالصور'),
   'in_progress', NULL, NULL);
