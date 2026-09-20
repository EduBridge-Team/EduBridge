-- Rich lesson media support (safe/idempotent for PostgreSQL production)

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_name = 'lessons' AND column_name = 'target_type'
    ) THEN
        ALTER TABLE lessons
            ADD COLUMN target_type VARCHAR(32) NOT NULL DEFAULT 'everyone';

        UPDATE lessons
        SET target_type = CASE
            WHEN disability_type_id IS NOT NULL THEN 'byDisability'
            ELSE 'everyone'
        END;
    END IF;
END $$;

ALTER TABLE lessons
    ADD COLUMN IF NOT EXISTS target_child_ids JSONB;

ALTER TABLE lessons
    ADD COLUMN IF NOT EXISTS audio_description TEXT;

ALTER TABLE media DROP CONSTRAINT IF EXISTS media_type_check;
ALTER TABLE media ALTER COLUMN type TYPE VARCHAR(20);
ALTER TABLE media ALTER COLUMN url TYPE VARCHAR(2048);
ALTER TABLE media
    ADD CONSTRAINT media_type_check
    CHECK (type IN ('image', 'video', 'audio', 'caption', 'sign_language'));
