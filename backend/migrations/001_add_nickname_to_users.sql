-- Migration to add nickname column to users table if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='nickname') THEN
        ALTER TABLE users ADD COLUMN nickname VARCHAR(255);
    END IF;
END $$;

-- Update existing users to have a default nickname from email if nickname is null
UPDATE users SET nickname = split_part(email, '@', 1) WHERE nickname IS NULL;
