-- Phase 1: specialist specialty + follow-up suggestions
-- Idempotent PostgreSQL upgrade.

ALTER TABLE users
    ADD COLUMN IF NOT EXISTS specialty VARCHAR(32);

CREATE TABLE IF NOT EXISTS child_specialist (
    id            SERIAL PRIMARY KEY,
    child_id      INT NOT NULL REFERENCES children(id) ON DELETE CASCADE,
    specialist_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    specialty     VARCHAR(32) NOT NULL,
    assigned_at   TIMESTAMP NOT NULL DEFAULT NOW(),
    created_at    TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (child_id, specialist_id, specialty)
);

CREATE TABLE IF NOT EXISTS specialist_suggestions (
    id               SERIAL PRIMARY KEY,
    child_id         INT NOT NULL REFERENCES children(id) ON DELETE CASCADE,
    specialist_id    INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    suggested_by     INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    specialty        VARCHAR(32) NOT NULL,
    reason           TEXT NOT NULL,
    status           VARCHAR(20) NOT NULL DEFAULT 'pending',
    rejection_reason TEXT,
    responded_at     TIMESTAMP,
    created_at       TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_child_specialist_child
    ON child_specialist(child_id);
CREATE INDEX IF NOT EXISTS idx_child_specialist_specialist
    ON child_specialist(specialist_id);
CREATE INDEX IF NOT EXISTS idx_specialist_suggestions_target
    ON specialist_suggestions(specialist_id, status);
CREATE INDEX IF NOT EXISTS idx_specialist_suggestions_child
    ON specialist_suggestions(child_id);

CREATE UNIQUE INDEX IF NOT EXISTS uq_specialist_suggestions_pending
    ON specialist_suggestions(child_id, specialist_id, specialty)
    WHERE status = 'pending';
