package com.bildunya.config;

import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class DatabaseCompatibilityInitializer implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(DatabaseCompatibilityInitializer.class);

    private final JdbcTemplate jdbcTemplate;

    @Override
    public void run(ApplicationArguments args) {
        execute("ALTER TABLE contents ADD COLUMN IF NOT EXISTS verification_status varchar(255)");
        execute("ALTER TABLE custom_locations ADD COLUMN IF NOT EXISTS verification_status varchar(255)");
        execute("ALTER TABLE custom_locations ADD COLUMN IF NOT EXISTS photo_urls jsonb DEFAULT '[]'::jsonb");
        execute("ALTER TABLE custom_locations ADD COLUMN IF NOT EXISTS tags jsonb DEFAULT '[]'::jsonb");
        execute("ALTER TABLE chat_conversations ADD COLUMN IF NOT EXISTS related_content_id bigint");
        execute("ALTER TABLE chat_messages ADD COLUMN IF NOT EXISTS conversation_id bigint");

        execute("UPDATE contents SET verification_status = 'APPROVED' WHERE verification_status IS NULL");
        execute("UPDATE custom_locations SET verification_status = 'APPROVED' WHERE verification_status IS NULL");
        execute("UPDATE contents SET verification_status = 'APPROVED' WHERE verification_status = 'VERIFIED'");
        execute("UPDATE custom_locations SET verification_status = 'APPROVED' WHERE verification_status = 'VERIFIED'");

        execute("ALTER TABLE contents ALTER COLUMN verification_status SET DEFAULT 'PENDING'");
        execute("ALTER TABLE custom_locations ALTER COLUMN verification_status SET DEFAULT 'PENDING'");
        execute("ALTER TABLE contents ALTER COLUMN verification_status SET NOT NULL");
        execute("ALTER TABLE custom_locations ALTER COLUMN verification_status SET NOT NULL");
    }

    private void execute(String sql) {
        try {
            jdbcTemplate.execute(sql);
        } catch (Exception e) {
            log.warn("Database compatibility statement skipped: {} ({})", sql, e.getMessage());
            log.debug("Database compatibility statement failed", e);
        }
    }
}
