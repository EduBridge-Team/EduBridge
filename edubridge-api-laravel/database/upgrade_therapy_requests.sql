-- ============================================================
-- طلبات الدعم النفسي / الجلسات النفسية
-- آمن وقابل للتكرار على PostgreSQL
-- ============================================================

CREATE TABLE IF NOT EXISTS therapy_requests (
    id               SERIAL PRIMARY KEY,
    child_id         INT NOT NULL REFERENCES children(id) ON DELETE CASCADE,
    parent_id        INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    specialist_id    INT REFERENCES users(id) ON DELETE SET NULL,
    reason           VARCHAR(160) NOT NULL,
    description      TEXT,
    urgency          VARCHAR(16) NOT NULL DEFAULT 'medium',
    status           VARCHAR(20) NOT NULL DEFAULT 'pending',
    scheduled_at     TIMESTAMP,
    meeting_link     TEXT,
    specialist_notes TEXT,
    completed_at     TIMESTAMP,
    cancelled_at     TIMESTAMP,
    created_at       TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT therapy_requests_urgency_check
        CHECK (urgency IN ('low', 'medium', 'high')),
    CONSTRAINT therapy_requests_status_check
        CHECK (status IN ('pending', 'scheduled', 'completed', 'cancelled'))
);

CREATE INDEX IF NOT EXISTS idx_therapy_requests_child
    ON therapy_requests(child_id);
CREATE INDEX IF NOT EXISTS idx_therapy_requests_parent
    ON therapy_requests(parent_id);
CREATE INDEX IF NOT EXISTS idx_therapy_requests_specialist
    ON therapy_requests(specialist_id);
CREATE INDEX IF NOT EXISTS idx_therapy_requests_status
    ON therapy_requests(status);
CREATE INDEX IF NOT EXISTS idx_therapy_requests_created_at
    ON therapy_requests(created_at DESC);

-- يمنع أكثر من طلب مفتوح لنفس الطفل من نفس ولي الأمر.
CREATE UNIQUE INDEX IF NOT EXISTS uq_therapy_requests_open_parent_child
    ON therapy_requests(parent_id, child_id)
    WHERE status IN ('pending', 'scheduled');
