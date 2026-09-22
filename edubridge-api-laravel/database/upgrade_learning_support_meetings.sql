-- EduBridge learning-support meetings migration
-- Idempotent PostgreSQL migration. Preserves existing session/report data.

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name='sessions' AND column_name='therapy_request_id'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name='sessions' AND column_name='learning_support_request_id'
  ) THEN
    ALTER TABLE sessions RENAME COLUMN therapy_request_id TO learning_support_request_id;
  END IF;
END $$;

ALTER TABLE sessions ADD COLUMN IF NOT EXISTS learning_support_request_id INT REFERENCES learning_support_requests(id) ON DELETE SET NULL;
ALTER TABLE sessions ADD COLUMN IF NOT EXISTS type VARCHAR(32) NOT NULL DEFAULT 'followUp';
ALTER TABLE sessions ADD COLUMN IF NOT EXISTS duration_minutes INT NOT NULL DEFAULT 45;
ALTER TABLE sessions ADD COLUMN IF NOT EXISTS completed_at TIMESTAMP;
ALTER TABLE sessions ADD COLUMN IF NOT EXISTS notes TEXT;
ALTER TABLE sessions ADD COLUMN IF NOT EXISTS goals TEXT;
ALTER TABLE sessions ADD COLUMN IF NOT EXISTS recommendations TEXT;
ALTER TABLE sessions ADD COLUMN IF NOT EXISTS tags JSONB NOT NULL DEFAULT '[]'::jsonb;
ALTER TABLE sessions ADD COLUMN IF NOT EXISTS meeting_link TEXT;

ALTER INDEX IF EXISTS uq_sessions_therapy_request RENAME TO uq_sessions_learning_support_request;
CREATE UNIQUE INDEX IF NOT EXISTS uq_sessions_learning_support_request
  ON sessions(learning_support_request_id)
  WHERE learning_support_request_id IS NOT NULL;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name='weekly_reports' AND column_name='therapy_sessions_scheduled'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name='weekly_reports' AND column_name='learning_support_meetings_scheduled'
  ) THEN
    ALTER TABLE weekly_reports RENAME COLUMN therapy_sessions_scheduled TO learning_support_meetings_scheduled;
  END IF;
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name='weekly_reports' AND column_name='therapy_sessions_attended'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name='weekly_reports' AND column_name='learning_support_meetings_attended'
  ) THEN
    ALTER TABLE weekly_reports RENAME COLUMN therapy_sessions_attended TO learning_support_meetings_attended;
  END IF;
END $$;

ALTER TABLE weekly_reports ADD COLUMN IF NOT EXISTS learning_support_meetings_scheduled INT NOT NULL DEFAULT 0;
ALTER TABLE weekly_reports ADD COLUMN IF NOT EXISTS learning_support_meetings_attended INT NOT NULL DEFAULT 0;
