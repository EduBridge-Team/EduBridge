-- EduBridge learning-support requests migration
-- Idempotent PostgreSQL migration. Preserves existing data.

DO $$
BEGIN
  IF to_regclass('public.learning_support_requests') IS NULL
     AND to_regclass('public.therapy_requests') IS NOT NULL THEN
    ALTER TABLE therapy_requests RENAME TO learning_support_requests;
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS learning_support_requests (
    id SERIAL PRIMARY KEY,
    child_id INT NOT NULL REFERENCES children(id) ON DELETE CASCADE,
    parent_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    specialist_id INT REFERENCES users(id) ON DELETE SET NULL,
    reason VARCHAR(160) NOT NULL,
    description TEXT,
    urgency VARCHAR(16) NOT NULL DEFAULT 'medium',
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    scheduled_at TIMESTAMP,
    meeting_link TEXT,
    specialist_notes TEXT,
    completed_at TIMESTAMP,
    cancelled_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname='therapy_requests_urgency_check') THEN
    ALTER TABLE learning_support_requests RENAME CONSTRAINT therapy_requests_urgency_check TO learning_support_requests_urgency_check;
  END IF;
  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname='therapy_requests_status_check') THEN
    ALTER TABLE learning_support_requests RENAME CONSTRAINT therapy_requests_status_check TO learning_support_requests_status_check;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='learning_support_requests_urgency_check') THEN
    ALTER TABLE learning_support_requests ADD CONSTRAINT learning_support_requests_urgency_check CHECK (urgency IN ('low','medium','high'));
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='learning_support_requests_status_check') THEN
    ALTER TABLE learning_support_requests ADD CONSTRAINT learning_support_requests_status_check CHECK (status IN ('pending','scheduled','completed','cancelled'));
  END IF;
END $$;

ALTER INDEX IF EXISTS idx_therapy_requests_child RENAME TO idx_learning_support_requests_child;
ALTER INDEX IF EXISTS idx_therapy_requests_parent RENAME TO idx_learning_support_requests_parent;
ALTER INDEX IF EXISTS idx_therapy_requests_specialist RENAME TO idx_learning_support_requests_specialist;
ALTER INDEX IF EXISTS idx_therapy_requests_status RENAME TO idx_learning_support_requests_status;
ALTER INDEX IF EXISTS idx_therapy_requests_created_at RENAME TO idx_learning_support_requests_created_at;
ALTER INDEX IF EXISTS uq_therapy_requests_open_parent_child RENAME TO uq_learning_support_requests_open_parent_child;

CREATE INDEX IF NOT EXISTS idx_learning_support_requests_child ON learning_support_requests(child_id);
CREATE INDEX IF NOT EXISTS idx_learning_support_requests_parent ON learning_support_requests(parent_id);
CREATE INDEX IF NOT EXISTS idx_learning_support_requests_specialist ON learning_support_requests(specialist_id);
CREATE INDEX IF NOT EXISTS idx_learning_support_requests_status ON learning_support_requests(status);
CREATE INDEX IF NOT EXISTS idx_learning_support_requests_created_at ON learning_support_requests(created_at DESC);
CREATE UNIQUE INDEX IF NOT EXISTS uq_learning_support_requests_open_parent_child
  ON learning_support_requests(parent_id, child_id)
  WHERE status IN ('pending','scheduled');
