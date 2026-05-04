ALTER TABLE contents
    ADD COLUMN IF NOT EXISTS verification_status varchar(255);

ALTER TABLE custom_locations
    ADD COLUMN IF NOT EXISTS verification_status varchar(255);

UPDATE contents
SET verification_status = 'APPROVED'
WHERE verification_status IS NULL;

UPDATE custom_locations
SET verification_status = 'APPROVED'
WHERE verification_status IS NULL;

UPDATE contents
SET verification_status = 'APPROVED'
WHERE verification_status = 'VERIFIED';

UPDATE custom_locations
SET verification_status = 'APPROVED'
WHERE verification_status = 'VERIFIED';

ALTER TABLE contents
    ALTER COLUMN verification_status SET DEFAULT 'PENDING';

ALTER TABLE custom_locations
    ALTER COLUMN verification_status SET DEFAULT 'PENDING';

ALTER TABLE contents
    ALTER COLUMN verification_status SET NOT NULL;

ALTER TABLE custom_locations
    ALTER COLUMN verification_status SET NOT NULL;
