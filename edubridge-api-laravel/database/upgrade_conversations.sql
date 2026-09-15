-- EduBridge conversations — safe to run repeatedly on PostgreSQL
CREATE TABLE IF NOT EXISTS conversations (
    id                 SERIAL PRIMARY KEY,
    participant_one_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    participant_two_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_by_id      INT REFERENCES users(id) ON DELETE SET NULL,
    subject            VARCHAR(150),
    created_at         TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at         TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT conversations_distinct_users CHECK (participant_one_id <> participant_two_id),
    CONSTRAINT conversations_unique_pair UNIQUE (participant_one_id, participant_two_id)
);

CREATE TABLE IF NOT EXISTS conversation_messages (
    id              SERIAL PRIMARY KEY,
    conversation_id INT NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id       INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content         TEXT,
    file_url        VARCHAR(2048),
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT conversation_messages_has_body CHECK (content IS NOT NULL OR file_url IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS idx_conversations_participant_one ON conversations(participant_one_id);
CREATE INDEX IF NOT EXISTS idx_conversations_participant_two ON conversations(participant_two_id);
CREATE INDEX IF NOT EXISTS idx_conversations_updated_at ON conversations(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_conversation_messages_conversation ON conversation_messages(conversation_id, id);
CREATE INDEX IF NOT EXISTS idx_conversation_messages_sender ON conversation_messages(sender_id);
