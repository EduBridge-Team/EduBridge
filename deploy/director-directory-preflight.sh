#!/usr/bin/env bash
# Aggregate-only preflight. No identity data is printed; no database writes.
set -Eeuo pipefail
if [[ $# -ne 2 || "$1" != "--stack" ]]; then
  echo "Usage: bash deploy/director-directory-preflight.sh --stack main|jabalia" >&2
  exit 2
fi
case "$2" in
  main) container="edubridge-postgres" ;;
  jabalia) container="edubridge-jabalia-postgres" ;;
  *) echo "ERROR: unsupported stack" >&2; exit 2 ;;
esac
command -v docker >/dev/null
command -v awk >/dev/null
echo "Read-only director preflight: $2"
if ! results="$(docker exec -i "$container" sh -c \
  'exec psql -X -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" -A -t -F "|"' <<'SQL'
WITH director AS (
    SELECT a.id, a.school_id, a.user_id, a.starts_at, a.ends_at,
           u.name, u.email, u.role AS user_role,
           LOWER(TRIM(u.email)) AS email_normalized
    FROM school_management_assignments a
    JOIN users u ON u.id = a.user_id
    WHERE a.role = 'director'
), checks AS (
    SELECT 'invalid_identity_or_dates' AS test_name, COUNT(*) AS total
    FROM director
    WHERE starts_at IS NULL OR TRIM(COALESCE(name, '')) = ''
       OR TRIM(COALESCE(email, '')) = ''
       OR LENGTH(TRIM(name)) > 150 OR LENGTH(TRIM(email)) > 190
       OR ends_at < starts_at
       OR DATE(starts_at) > CURRENT_DATE
       OR DATE(ends_at) > CURRENT_DATE
    UNION ALL
    SELECT 'different_people_same_school_email', COUNT(*) FROM (
        SELECT school_id, email_normalized
        FROM director
        GROUP BY school_id, email_normalized
        HAVING COUNT(DISTINCT user_id) > 1
    ) conflicts
    UNION ALL
    SELECT 'multiple_current_directors', COUNT(*) FROM (
        SELECT school_id FROM director WHERE ends_at IS NULL
        GROUP BY school_id HAVING COUNT(*) > 1
    ) conflicts
    UNION ALL
    SELECT 'director_active_in_multiple_schools', COUNT(*) FROM (
        SELECT user_id FROM director
        WHERE ends_at IS NULL AND user_role = 'school_director'
        GROUP BY user_id HAVING COUNT(DISTINCT school_id) > 1
    ) conflicts
    UNION ALL
    SELECT 'overlapping_history_pairs', COUNT(*) FROM director a
    JOIN director b ON a.school_id = b.school_id AND a.id < b.id
    WHERE DATE(a.starts_at) < COALESCE(DATE(b.ends_at), DATE('9999-12-31'))
      AND DATE(b.starts_at) < COALESCE(DATE(a.ends_at), DATE('9999-12-31'))
)
SELECT test_name, total FROM checks ORDER BY test_name;
SQL
)"; then
    echo "BLOCKED: unable to read director history; no migration attempted." >&2
    exit 1
fi
printf '%s\n' "$results"
if printf '%s\n' "$results" | awk -F '|' '
  NF != 2 || $2 !~ /^[0-9]+$/ || $2 + 0 != 0 { problem=1 }
  END { exit (problem ? 1 : 0) }
'; then
  echo "PASS: zero known director-history migration conflicts (read-only)."
else
  echo "BLOCKED: review legacy director history before migrating." >&2
  exit 1
fi
echo "LIMIT: does not validate backups, concurrent writes or Flutter staging."
