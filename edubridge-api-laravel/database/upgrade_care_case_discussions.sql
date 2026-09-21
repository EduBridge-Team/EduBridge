-- Phase 4: multi-member care teams + case discussions
-- Idempotent PostgreSQL upgrade.

CREATE TABLE IF NOT EXISTS child_teacher (
    id          SERIAL PRIMARY KEY,
    child_id    INT NOT NULL REFERENCES children(id) ON DELETE CASCADE,
    teacher_id  INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    subject     VARCHAR(120),
    assigned_at TIMESTAMP NOT NULL DEFAULT NOW(),
    created_at  TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (child_id, teacher_id)
);

INSERT INTO child_teacher (child_id, teacher_id, assigned_at, created_at)
SELECT id, assigned_teacher_id, NOW(), NOW()
FROM children
WHERE assigned_teacher_id IS NOT NULL
ON CONFLICT (child_id, teacher_id) DO NOTHING;

CREATE INDEX IF NOT EXISTS idx_child_teacher_child ON child_teacher(child_id);
CREATE INDEX IF NOT EXISTS idx_child_teacher_teacher ON child_teacher(teacher_id);

CREATE TABLE IF NOT EXISTS case_discussions (
    id            SERIAL PRIMARY KEY,
    child_id      INT NOT NULL REFERENCES children(id) ON DELETE CASCADE,
    topic         VARCHAR(180) NOT NULL,
    description   TEXT,
    status        VARCHAR(20) NOT NULL DEFAULT 'open',
    created_by_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    resolved_at   TIMESTAMP,
    created_at    TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS case_discussion_participants (
    id            SERIAL PRIMARY KEY,
    discussion_id INT NOT NULL REFERENCES case_discussions(id) ON DELETE CASCADE,
    user_id       INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at    TIMESTAMP NOT NULL DEFAULT NOW(),
    UNIQUE (discussion_id, user_id)
);

CREATE TABLE IF NOT EXISTS case_discussion_messages (
    id            SERIAL PRIMARY KEY,
    discussion_id INT NOT NULL REFERENCES case_discussions(id) ON DELETE CASCADE,
    sender_id     INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content       TEXT NOT NULL,
    type          VARCHAR(20) NOT NULL DEFAULT 'text',
    attachments   JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at    TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_case_discussions_child ON case_discussions(child_id);
CREATE INDEX IF NOT EXISTS idx_case_participants_user ON case_discussion_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_case_messages_discussion ON case_discussion_messages(discussion_id, created_at);
