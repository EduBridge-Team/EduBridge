-- Final mobile API parity
-- Safe/idempotent PostgreSQL upgrade.

ALTER TABLE users ADD COLUMN IF NOT EXISTS avatar_url TEXT;

CREATE TABLE IF NOT EXISTS ministry_approvals (
    id                    SERIAL PRIMARY KEY,
    child_id              INT NOT NULL REFERENCES children(id) ON DELETE CASCADE,
    evaluation_id         INT REFERENCES evaluations(id) ON DELETE SET NULL,
    submitted_by          INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    teacher_id            INT REFERENCES users(id) ON DELETE SET NULL,
    educational_plan      TEXT NOT NULL,
    cognitive_assessment  TEXT,
    motor_assessment      TEXT,
    emotional_assessment  TEXT,
    social_assessment     TEXT,
    recommendations       TEXT,
    teaching_methods      JSONB NOT NULL DEFAULT '[]'::jsonb,
    status                VARCHAR(20) NOT NULL DEFAULT 'pending',
    review_reason         TEXT,
    reviewed_by           INT REFERENCES users(id) ON DELETE SET NULL,
    reviewed_at           TIMESTAMP,
    created_at            TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at            TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ministry_approvals_status ON ministry_approvals(status);
CREATE INDEX IF NOT EXISTS idx_ministry_approvals_child ON ministry_approvals(child_id);

CREATE TABLE IF NOT EXISTS plan_evaluations (
    id                   SERIAL PRIMARY KEY,
    plan_id              INT NOT NULL,
    child_id             INT NOT NULL REFERENCES children(id) ON DELETE CASCADE,
    evaluator_id         INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    is_plan_appropriate  BOOLEAN NOT NULL,
    notes_for_teacher    TEXT,
    recommended_changes  JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at           TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at           TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (plan_id, child_id, evaluator_id)
);

CREATE INDEX IF NOT EXISTS idx_plan_evaluations_child ON plan_evaluations(child_id);
