#!/bin/zsh
# Lab 4 - Task 3.3 scale test.
#
# Builds a second database with 100,000 users, 4,999 courses and 1,000,000
# enrolments, then measures the query under four index configurations.
# Writes ../evidence/task3_3_scale_test.txt.
#
#   ./scripts/run_scale_evidence.sh
#
# Requires the docker-compose stack to be up:
#   cd .. && docker compose up -d
set -u
BASE="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$BASE/src"
EV="$BASE/evidence"
# Resolve the compose container by name, so a folder rename cannot break it.
CONTAINER="${LAB4_CONTAINER:-$(cd "$BASE" && docker compose ps -q mysql 2>/dev/null | head -1)}"
if [ -z "$CONTAINER" ]; then
  echo "no running mysql container; start it with: cd $BASE && docker compose up -d" >&2
  exit 1
fi

# Wait for MySQL to accept connections. docker compose up -d returns before the
# server is ready, so the first query would otherwise fail.
for i in {1..60}; do
  if docker exec -e MYSQL_PWD=root "$CONTAINER" mysql -uroot -e "SELECT 1" >/dev/null 2>&1; then
    break
  fi
  if [ "$i" = 60 ]; then
    echo "mysql did not become ready in 5 minutes" >&2
    exit 1
  fi
  sleep 5
done

Q="SELECT u.FullName, COUNT(e.EnrollID) AS EnrolledCourses FROM Users u LEFT JOIN Enrollments e ON u.UserID = e.UserID WHERE u.Role = 'student' GROUP BY u.UserID, u.FullName HAVING COUNT(e.EnrollID) > 0 ORDER BY EnrolledCourses DESC;"
Q2="SELECT u.FullName, COUNT(e.EnrollID) AS EnrolledCourses FROM Users u LEFT JOIN Enrollments e ON u.UserID = e.UserID WHERE u.Role = 'student' GROUP BY u.UserID HAVING COUNT(e.EnrollID) > 0 ORDER BY EnrolledCourses DESC;"

DB=(docker exec -i -e MYSQL_PWD=root "$CONTAINER" mysql -uroot)
QDB=(docker exec -i -e MYSQL_PWD=root "$CONTAINER" mysql -uroot -t educonnect_scale)

# Prints the total elapsed time in ms of the first node of the ANALYZE tree.
timing() {
  $QDB -N -e "EXPLAIN ANALYZE $1" 2>/dev/null \
    | grep -oE "actual time=[0-9.]+\.\.[0-9.]+" | head -1 | grep -oE "\.\.[0-9.]+" | tr -d '.'
}

{
  echo "================================================================"
  echo "Lab 4 - Task 3.3 scale test"
  echo "MySQL 8.4.11 | database: educonnect_scale"
  echo "100,000 users, 4,999 courses, 1,000,000 enrolments"
  echo "================================================================"
  echo
  echo "== rebuilding the scale database =="
} > "$EV/task3_3_scale_test.txt"

$DB < "$SRC/11_scale_test_schema.sql" >> "$EV/task3_3_scale_test.txt" 2>&1
$DB < "$SRC/12_scale_test_data.sql" >> "$EV/task3_3_scale_test.txt" 2>&1

echo >> "$EV/task3_3_scale_test.txt"
echo "== A. table sizes ==" >> "$EV/task3_3_scale_test.txt"
$QDB -e "ANALYZE TABLE Users, Courses, Enrollments;" >> "$EV/task3_3_scale_test.txt" 2>&1
$QDB -e "SELECT table_name, table_rows, ROUND(data_length/1024/1024,1) AS data_mb, ROUND(index_length/1024/1024,1) AS index_mb FROM information_schema.TABLES WHERE table_schema='educonnect_scale' ORDER BY table_name;" >> "$EV/task3_3_scale_test.txt" 2>&1

echo >> "$EV/task3_3_scale_test.txt"
echo "== B. EXPLAIN with no index on Role ==" >> "$EV/task3_3_scale_test.txt"
$QDB -e "EXPLAIN $Q" >> "$EV/task3_3_scale_test.txt" 2>&1
echo >> "$EV/task3_3_scale_test.txt"
echo "== C. EXPLAIN ANALYZE with no index on Role ==" >> "$EV/task3_3_scale_test.txt"
$QDB -e "EXPLAIN ANALYZE $Q" >> "$EV/task3_3_scale_test.txt" 2>&1
echo >> "$EV/task3_3_scale_test.txt"
echo "== D. timings, no index on Role (3 runs, ms) ==" >> "$EV/task3_3_scale_test.txt"
for i in 1 2 3; do timing "$Q" >> "$EV/task3_3_scale_test.txt"; echo "  run $i" >> "$EV/task3_3_scale_test.txt"; done

echo >> "$EV/task3_3_scale_test.txt"
echo "== E. with idx_users_role (Role) ==" >> "$EV/task3_3_scale_test.txt"
$QDB -e "CREATE INDEX idx_users_role ON Users (Role);" >> "$EV/task3_3_scale_test.txt" 2>&1
$QDB -e "EXPLAIN $Q" >> "$EV/task3_3_scale_test.txt" 2>&1
$QDB -e "EXPLAIN ANALYZE $Q" >> "$EV/task3_3_scale_test.txt" 2>&1
for i in 1 2 3; do timing "$Q" >> "$EV/task3_3_scale_test.txt"; echo "  run $i" >> "$EV/task3_3_scale_test.txt"; done

echo >> "$EV/task3_3_scale_test.txt"
echo "== F. with idx_users_role_id_name (Role, UserID, FullName) ==" >> "$EV/task3_3_scale_test.txt"
$QDB -e "DROP INDEX idx_users_role ON Users;" >> "$EV/task3_3_scale_test.txt" 2>&1
$QDB -e "CREATE INDEX idx_users_role_id_name ON Users (Role, UserID, FullName);" >> "$EV/task3_3_scale_test.txt" 2>&1
$QDB -e "EXPLAIN $Q" >> "$EV/task3_3_scale_test.txt" 2>&1
$QDB -e "EXPLAIN ANALYZE $Q" >> "$EV/task3_3_scale_test.txt" 2>&1
for i in 1 2 3; do timing "$Q" >> "$EV/task3_3_scale_test.txt"; echo "  run $i" >> "$EV/task3_3_scale_test.txt"; done

echo >> "$EV/task3_3_scale_test.txt"
echo "== G. same index, GROUP BY u.UserID only ==" >> "$EV/task3_3_scale_test.txt"
$QDB -e "EXPLAIN $Q2" >> "$EV/task3_3_scale_test.txt" 2>&1
$QDB -e "EXPLAIN ANALYZE $Q2" >> "$EV/task3_3_scale_test.txt" 2>&1
for i in 1 2 3; do timing "$Q2" >> "$EV/task3_3_scale_test.txt"; echo "  run $i" >> "$EV/task3_3_scale_test.txt"; done

echo >> "$EV/task3_3_scale_test.txt"
echo "== H. the recommended index, kept in place ==" >> "$EV/task3_3_scale_test.txt"
$QDB -e "SHOW INDEX FROM Users;" >> "$EV/task3_3_scale_test.txt" 2>&1

echo "  wrote evidence/task3_3_scale_test.txt"
