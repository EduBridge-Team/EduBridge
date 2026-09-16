-- ============================================================
-- ترقية قاعدة البيانات — تفضيلات المستخدم المتزامنة
-- آمنة وقابلة للتكرار (IF NOT EXISTS).
-- ============================================================

CREATE TABLE IF NOT EXISTS user_settings (
    id                    SERIAL PRIMARY KEY,
    user_id               INT NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
    theme_mode             VARCHAR(16) NOT NULL DEFAULT 'light',
    assistant_visible      BOOLEAN NOT NULL DEFAULT TRUE,
    microphone_visible     BOOLEAN NOT NULL DEFAULT TRUE,
    notifications_enabled  BOOLEAN NOT NULL DEFAULT TRUE,
    created_at             TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at             TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_user_settings_user_id ON user_settings(user_id);
