-- Phase 2: align therapy sessions with Flutter API and therapy requests.
-- Idempotent PostgreSQL upgrade.

ALTER TABLE sessions ADD COLUMN IF NOT EXISTS therapy_request_id INT REFERENCES therapy_requests(id) ON DELETE SET NULL;
ALTER TABLE sessions ADD COLUMN IF NOT EXISTS type VARCHAR(32) NOT NULL DEFAULT 'followUp';
ALTER TABLE sessions ADD COLUMN IF NOT EXISTS duration_minutes INT NOT NULL DEFAULT 45;
ALTER TABLE sessions ADD COLUMN IF NOT EXISTS completed_at TIMESTAMP;
ALTER TABLE sessions ADD COLUMN IF NOT EXISTS notes TEXT;
ALTER TABLE sessions ADD COLUMN IF NOT EXISTS goals TEXT;
ALTER TABLE sessions ADD COLUMN IF NOT EXISTS recommendations TEXT;
ALTER TABLE sessions ADD COLUMN IF NOT EXISTS mood_rating INT;
ALTER TABLE sessions ADD COLUMN IF NOT EXISTS tags JSONB NOT NULL DEFAULT '[]'::jsonb;
ALTER TABLE sessions ADD COLUMN IF NOT EXISTS meeting_link TEXT;

CREATE INDEX IF NOT EXISTS idx_sessions_child ON sessions(child_id);
CREATE INDEX IF NOT EXISTS idx_sessions_specialist ON sessions(specialist_id);
CREATE UNIQUE INDEX IF NOT EXISTS uq_sessions_therapy_request
    ON sessions(therapy_request_id)
    WHERE therapy_request_id IS NOT NULL;
