-- ============================================================
-- ترقية قاعدة البيانات — ميزات ولي الأمر (إضافة الأطفال والتقييمات والإشعارات)
-- آمنة وقابلة للتكرار (IF NOT EXISTS) — لن تُتلف أي بيانات موجودة.
-- تُنفَّذ على قاعدة التطوير محلياً وعلى قاعدة الاستضافة عبر phpPgAdmin.
-- ============================================================

-- أعمدة إضافية لجدول الأطفال (يستخدمها التطبيق والموقع في لوحة ولي الأمر)
ALTER TABLE children ADD COLUMN IF NOT EXISTS age                      INT;
ALTER TABLE children ADD COLUMN IF NOT EXISTS disability_type          VARCHAR(120);
ALTER TABLE children ADD COLUMN IF NOT EXISTS disability_description   TEXT;
ALTER TABLE children ADD COLUMN IF NOT EXISTS medical_history          TEXT;
ALTER TABLE children ADD COLUMN IF NOT EXISTS psychologist_notes       TEXT;
ALTER TABLE children ADD COLUMN IF NOT EXISTS special_needs            TEXT;
ALTER TABLE children ADD COLUMN IF NOT EXISTS preferred_learning_style VARCHAR(120);
ALTER TABLE children ADD COLUMN IF NOT EXISTS strengths                JSONB;
ALTER TABLE children ADD COLUMN IF NOT EXISTS challenges               JSONB;
ALTER TABLE children ADD COLUMN IF NOT EXISTS status                   VARCHAR(20) NOT NULL DEFAULT 'pending';
ALTER TABLE children ADD COLUMN IF NOT EXISTS assigned_teacher_id      INT REFERENCES users(id) ON DELETE SET NULL;

-- أعمدة إضافية للإشعارات (عمود message الموجود يبقى كنص الإشعار = body)
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS title VARCHAR(150);
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS type  VARCHAR(40);

-- جدول التقييمات (يُنشئه المعلّم/المختص، ويعرضه ولي الأمر)
CREATE TABLE IF NOT EXISTS evaluations (
    id                   SERIAL PRIMARY KEY,
    child_id             INT NOT NULL REFERENCES children(id) ON DELETE CASCADE,
    evaluator_id         INT REFERENCES users(id) ON DELETE SET NULL,
    evaluation_type      VARCHAR(60),
    cognitive_assessment TEXT,
    motor_assessment     TEXT,
    emotional_assessment TEXT,
    social_assessment    TEXT,
    recommendations      TEXT,
    educational_plan     TEXT,
    teaching_methods     JSONB,
    assigned_teacher_id  INT REFERENCES users(id) ON DELETE SET NULL,
    created_at           TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_evaluations_child ON evaluations(child_id);
CREATE INDEX IF NOT EXISTS idx_children_assigned_teacher ON children(assigned_teacher_id);
