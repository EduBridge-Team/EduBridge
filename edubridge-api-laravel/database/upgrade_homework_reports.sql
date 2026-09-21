-- Phase 3: homework + weekly reports
-- Idempotent PostgreSQL upgrade.

CREATE TABLE IF NOT EXISTS homeworks (
    id                 SERIAL PRIMARY KEY,
    title              VARCHAR(180) NOT NULL,
    description        TEXT NOT NULL,
    teacher_id         INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subject            VARCHAR(120),
    due_date           TIMESTAMP NOT NULL,
    assigned_child_ids JSONB NOT NULL DEFAULT '[]'::jsonb,
    attachment_urls    JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at         TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS homework_submissions (
    id           SERIAL PRIMARY KEY,
    homework_id  INT NOT NULL REFERENCES homeworks(id) ON DELETE CASCADE,
    child_id     INT NOT NULL REFERENCES children(id) ON DELETE CASCADE,
    text_answer  TEXT,
    file_url     TEXT,
    file_urls    JSONB NOT NULL DEFAULT '[]'::jsonb,
    grade        INT,
    feedback     TEXT,
    is_late      BOOLEAN NOT NULL DEFAULT FALSE,
    graded_by    INT REFERENCES users(id) ON DELETE SET NULL,
    graded_at    TIMESTAMP,
    submitted_at TIMESTAMP NOT NULL DEFAULT NOW(),
    created_at   TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (homework_id, child_id)
);

CREATE INDEX IF NOT EXISTS idx_homeworks_teacher ON homeworks(teacher_id);
CREATE INDEX IF NOT EXISTS idx_homeworks_due_date ON homeworks(due_date);
CREATE INDEX IF NOT EXISTS idx_homework_submissions_child ON homework_submissions(child_id);

CREATE TABLE IF NOT EXISTS weekly_reports (
    id                    SERIAL PRIMARY KEY,
    child_id              INT NOT NULL REFERENCES children(id) ON DELETE CASCADE,
    author_id             INT REFERENCES users(id) ON DELETE SET NULL,
    week_start            DATE NOT NULL,
    week_end              DATE NOT NULL,
    lessons_completed     INT NOT NULL DEFAULT 0,
    progress_percentage   NUMERIC(5,2) NOT NULL DEFAULT 0,
    teacher_notes         TEXT,
    specialist_notes      TEXT,
    parent_notes          TEXT,
    achievements          JSONB NOT NULL DEFAULT '[]'::jsonb,
    concerns              JSONB NOT NULL DEFAULT '[]'::jsonb,
    generated_at          TIMESTAMP NOT NULL DEFAULT NOW(),
    created_at            TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (child_id, week_start)
);

CREATE INDEX IF NOT EXISTS idx_weekly_reports_child_week
    ON weekly_reports(child_id, week_start DESC);
