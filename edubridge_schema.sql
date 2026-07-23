-- ============================================================
-- EduBridge — Database Schema (PostgreSQL)
-- جسر تعليمي لأطفال ذوي الاحتياجات الخاصة
-- ============================================================
-- شغّل الأقسام بالترتيب. القسم 1 = النواة، لازم تشتغل أول.
-- ============================================================


-- ============================================================
-- 1) النواة الأساسية  (ابدأوا من هون)
-- ============================================================

-- المستخدمون: كل مين بيسجّل دخول (أهل / معلّم / مختص / أدمن)
CREATE TABLE users (
    id            SERIAL PRIMARY KEY,
    name          VARCHAR(100) NOT NULL,
    email         VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role          VARCHAR(20)  NOT NULL
                  CHECK (role IN ('parent', 'teacher', 'specialist', 'admin')),
    phone         VARCHAR(20),
    created_at    TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- أنواع الإعاقة (توحّد، صعوبات تعلّم، إعاقة سمعية ...)
CREATE TABLE disability_types (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR(80) NOT NULL UNIQUE,
    description TEXT
);

-- المؤسسات الداعمة
CREATE TABLE organizations (
    id      SERIAL PRIMARY KEY,
    name    VARCHAR(150) NOT NULL,
    contact VARCHAR(150),
    address VARCHAR(255)
);

-- الأطفال (ملف تعريفي — الطفل ما بيسجّل دخول)
CREATE TABLE children (
    id                 SERIAL PRIMARY KEY,
    name               VARCHAR(100) NOT NULL,
    birth_date         DATE,
    gender             VARCHAR(10) CHECK (gender IN ('male', 'female')),
    disability_type_id INT REFERENCES disability_types(id) ON DELETE RESTRICT,
    organization_id    INT REFERENCES organizations(id)    ON DELETE SET NULL,
    notes              TEXT,
    created_at         TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ربط الطفل بأوليّاء أمره (many-to-many)
CREATE TABLE child_parent (
    child_id  INT NOT NULL REFERENCES children(id) ON DELETE CASCADE,
    parent_id INT NOT NULL REFERENCES users(id)    ON DELETE CASCADE,
    PRIMARY KEY (child_id, parent_id)
);

-- الدروس
CREATE TABLE lessons (
    id                 SERIAL PRIMARY KEY,
    title              VARCHAR(150) NOT NULL,
    content            TEXT,
    disability_type_id INT REFERENCES disability_types(id) ON DELETE SET NULL,
    teacher_id         INT REFERENCES users(id)            ON DELETE SET NULL,
    created_at         TIMESTAMP NOT NULL DEFAULT NOW()
);

-- تقدّم الطفل بكل درس
CREATE TABLE progress (
    id           SERIAL PRIMARY KEY,
    child_id     INT NOT NULL REFERENCES children(id) ON DELETE CASCADE,
    lesson_id    INT NOT NULL REFERENCES lessons(id)  ON DELETE CASCADE,
    status       VARCHAR(15) NOT NULL DEFAULT 'not_started'
                 CHECK (status IN ('not_started', 'in_progress', 'done')),
    score        INT CHECK (score BETWEEN 0 AND 100),
    completed_at TIMESTAMP,
    UNIQUE (child_id, lesson_id)   -- صف واحد لكل طفل/درس
);


-- ============================================================
-- 2) الإضافات  (زيدوها بعد ما تشتغل النواة)
-- ============================================================

-- الوسائط المرتبطة بالدروس (صورة / فيديو / صوت)
CREATE TABLE media (
    id        SERIAL PRIMARY KEY,
    lesson_id INT NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
    type      VARCHAR(10) NOT NULL CHECK (type IN ('image', 'video', 'audio')),
    url       VARCHAR(255) NOT NULL
);

-- جلسات المختص مع الطفل
CREATE TABLE sessions (
    id            SERIAL PRIMARY KEY,
    specialist_id INT NOT NULL REFERENCES users(id)    ON DELETE CASCADE,
    child_id      INT NOT NULL REFERENCES children(id) ON DELETE CASCADE,
    scheduled_at  TIMESTAMP NOT NULL,
    status        VARCHAR(15) NOT NULL DEFAULT 'scheduled'
                  CHECK (status IN ('scheduled', 'done', 'cancelled'))
);

-- ملاحظات المعلّم / المختص عن الطفل
CREATE TABLE notes (
    id         SERIAL PRIMARY KEY,
    author_id  INT NOT NULL REFERENCES users(id)    ON DELETE CASCADE,
    child_id   INT NOT NULL REFERENCES children(id) ON DELETE CASCADE,
    content    TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- الإشعارات
CREATE TABLE notifications (
    id         SERIAL PRIMARY KEY,
    user_id    INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    message    VARCHAR(255) NOT NULL,
    is_read    BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);


-- ============================================================
-- 3) فهارس تحسّن الأداء  (اختياري بس مفيد)
-- ============================================================
CREATE INDEX idx_children_disability   ON children(disability_type_id);
CREATE INDEX idx_lessons_disability    ON lessons(disability_type_id);
CREATE INDEX idx_progress_child        ON progress(child_id);
CREATE INDEX idx_sessions_child        ON sessions(child_id);
CREATE INDEX idx_notes_child           ON notes(child_id);
CREATE INDEX idx_notifications_user    ON notifications(user_id);
