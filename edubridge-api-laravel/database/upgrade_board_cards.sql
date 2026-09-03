-- ============================================================
-- ترقية قاعدة البيانات — بطاقات لوحة EduBridge
-- توثيق الهوية، البحث برقم الهوية، حسابات الوزارة/المؤسسة،
-- الشهادات، تقييمات الدروس، الدعم الفني والشكاوى، دراسة الحالة.
-- آمنة وقابلة للتكرار (IF NOT EXISTS) — لا تُتلف أي بيانات موجودة.
-- ============================================================

-- ------------------------------------------------------------
-- 1) الأدوار: إضافة الوزارة والمؤسسة إلى قيد الدور
-- ------------------------------------------------------------
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;
ALTER TABLE users ADD CONSTRAINT users_role_check
    CHECK (role IN ('parent', 'teacher', 'specialist', 'admin', 'ministry', 'institution'));

-- ------------------------------------------------------------
-- 2) توثيق هوية المستخدمين (البطاقتان 4 و 9)
-- ------------------------------------------------------------
ALTER TABLE users ADD COLUMN IF NOT EXISTS national_id         VARCHAR(30);
ALTER TABLE users ADD COLUMN IF NOT EXISTS id_document_url      VARCHAR(255);
ALTER TABLE users ADD COLUMN IF NOT EXISTS verification_status  VARCHAR(20) NOT NULL DEFAULT 'pending';
ALTER TABLE users ADD COLUMN IF NOT EXISTS verification_note    TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS verified_at          TIMESTAMP;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'users_verification_status_check') THEN
        ALTER TABLE users ADD CONSTRAINT users_verification_status_check
            CHECK (verification_status IN ('pending', 'verified', 'rejected'));
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_users_national_id  ON users(national_id);
CREATE INDEX IF NOT EXISTS idx_users_verification ON users(verification_status);

-- ------------------------------------------------------------
-- 3) توثيق هوية الطالب وصلة القرابة (البطاقة 1)
-- ------------------------------------------------------------
ALTER TABLE children ADD COLUMN IF NOT EXISTS child_national_id        VARCHAR(30);
ALTER TABLE children ADD COLUMN IF NOT EXISTS guardian_national_id     VARCHAR(30);
ALTER TABLE children ADD COLUMN IF NOT EXISTS guardian_id_document_url VARCHAR(255);
ALTER TABLE children ADD COLUMN IF NOT EXISTS kinship_document_url     VARCHAR(255);
ALTER TABLE children ADD COLUMN IF NOT EXISTS doc_verification_status  VARCHAR(20) NOT NULL DEFAULT 'pending';
ALTER TABLE children ADD COLUMN IF NOT EXISTS doc_verification_note    TEXT;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'children_doc_verification_status_check') THEN
        ALTER TABLE children ADD CONSTRAINT children_doc_verification_status_check
            CHECK (doc_verification_status IN ('pending', 'verified', 'rejected'));
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_children_child_national ON children(child_national_id);

-- ------------------------------------------------------------
-- 4) شهادات المعلّم/المختص لإثبات الأهلية (البطاقة 9)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS certificates (
    id         SERIAL PRIMARY KEY,
    user_id    INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title      VARCHAR(150) NOT NULL,
    url        VARCHAR(255) NOT NULL,
    status     VARCHAR(20)  NOT NULL DEFAULT 'pending'
               CHECK (status IN ('pending', 'verified', 'rejected')),
    note       TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_certificates_user ON certificates(user_id);

-- ------------------------------------------------------------
-- 5) مراجعة المناهج من الوزارة (البطاقة 3)
-- ------------------------------------------------------------
ALTER TABLE lessons ADD COLUMN IF NOT EXISTS education_level   VARCHAR(60);
ALTER TABLE lessons ADD COLUMN IF NOT EXISTS curriculum_status VARCHAR(20) NOT NULL DEFAULT 'pending';
ALTER TABLE lessons ADD COLUMN IF NOT EXISTS reviewed_by       INT REFERENCES users(id) ON DELETE SET NULL;
ALTER TABLE lessons ADD COLUMN IF NOT EXISTS review_note       TEXT;
ALTER TABLE lessons ADD COLUMN IF NOT EXISTS reviewed_at       TIMESTAMP;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'lessons_curriculum_status_check') THEN
        ALTER TABLE lessons ADD CONSTRAINT lessons_curriculum_status_check
            CHECK (curriculum_status IN ('pending', 'approved', 'rejected'));
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_lessons_curriculum ON lessons(curriculum_status);

-- ------------------------------------------------------------
-- 6) تقييمات المادة التعليمية (البطاقة 8)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS lesson_ratings (
    id         SERIAL PRIMARY KEY,
    lesson_id  INT NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
    user_id    INT NOT NULL REFERENCES users(id)   ON DELETE CASCADE,
    stars      INT NOT NULL CHECK (stars BETWEEN 1 AND 5),
    comment    TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (lesson_id, user_id)   -- تقييم واحد لكل مستخدم لكل درس (يمنع التكرار)
);
CREATE INDEX IF NOT EXISTS idx_lesson_ratings_lesson ON lesson_ratings(lesson_id);

-- ------------------------------------------------------------
-- 7) الدعم الفني والشكاوى (البطاقة 11)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS support_tickets (
    id          SERIAL PRIMARY KEY,
    user_id     INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category    VARCHAR(20) NOT NULL DEFAULT 'support'
                CHECK (category IN ('support', 'complaint')),
    subject     VARCHAR(150) NOT NULL,
    message     TEXT NOT NULL,
    status      VARCHAR(20) NOT NULL DEFAULT 'open'
                CHECK (status IN ('open', 'in_progress', 'resolved', 'closed')),
    admin_reply TEXT,
    created_at  TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_support_tickets_user   ON support_tickets(user_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_status ON support_tickets(status);

-- ------------------------------------------------------------
-- 8) دراسة الحالة مع المختصين (البطاقة 7)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS consultations (
    id            SERIAL PRIMARY KEY,
    child_id      INT NOT NULL REFERENCES children(id) ON DELETE CASCADE,
    requester_id  INT NOT NULL REFERENCES users(id)    ON DELETE CASCADE,
    specialist_id INT REFERENCES users(id)             ON DELETE SET NULL,
    title         VARCHAR(150) NOT NULL,
    description   TEXT,
    status        VARCHAR(20) NOT NULL DEFAULT 'open'
                  CHECK (status IN ('open', 'assigned', 'in_progress', 'closed')),
    created_at    TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_consultations_child      ON consultations(child_id);
CREATE INDEX IF NOT EXISTS idx_consultations_specialist ON consultations(specialist_id);

-- ملاحظات المختص على دراسة الحالة (سجل زمني)
CREATE TABLE IF NOT EXISTS consultation_notes (
    id              SERIAL PRIMARY KEY,
    consultation_id INT NOT NULL REFERENCES consultations(id) ON DELETE CASCADE,
    author_id       INT NOT NULL REFERENCES users(id)         ON DELETE CASCADE,
    content         TEXT NOT NULL,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_consultation_notes_consultation ON consultation_notes(consultation_id);
