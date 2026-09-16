-- ============================================================
-- ترقية قاعدة البيانات — مزامنة تكييفات واحتياجات الأبناء
-- آمنة وقابلة للتكرار (IF NOT EXISTS).
-- ============================================================

CREATE TABLE IF NOT EXISTS child_accessibility_profiles (
    id          SERIAL PRIMARY KEY,
    child_id    INT NOT NULL UNIQUE REFERENCES children(id) ON DELETE CASCADE,
    profile     JSONB NOT NULL,
    updated_by  INT REFERENCES users(id) ON DELETE SET NULL,
    created_at  TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_child_accessibility_profiles_child_id
    ON child_accessibility_profiles(child_id);
