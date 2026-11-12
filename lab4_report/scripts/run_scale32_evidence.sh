#!/bin/zsh
# Lab 4 - Task 3.2 scale test.
#
# Adds lessons and a 1,000,000-row Attendance table to the scale database, then
# measures the LEFT JOIN version against the NOT EXISTS version.
# Writes ../evidence/task3_2_scale_test.txt.
#
#   ./scripts/run_scale32_evidence.sh
#
# Requires the docker-compose stack to be up, and run_scale_evidence.sh to have
# built the scale database first:
#   cd .. && docker compose up -d && ./scripts/run_scale_evidence.sh
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

DB=(docker exec -i -e MYSQL_PWD=root "$CONTAINER" mysql -uroot)
QDB=(docker exec -i -e MYSQL_PWD=root "$CONTAINER" mysql -uroot -t educonnect_scale)

# No trailing semicolon: these strings are also wrapped in a subquery below.
LJ="SELECT u.FullName AS StudentName, c.Title AS CourseTitle FROM Enrollments e JOIN Users u ON u.UserID = e.UserID JOIN Courses c ON c.CourseID = e.CourseID JOIN Lessons l ON l.CourseID = c.CourseID LEFT JOIN Attendance a ON a.UserID = e.UserID AND a.LessonID = l.LessonID GROUP BY u.UserID, c.CourseID HAVING COUNT(a.AttID) = 0"
NE="SELECT u.FullName AS StudentName, c.Title AS CourseTitle FROM Enrollments e JOIN Users u ON u.UserID = e.UserID JOIN Courses c ON c.CourseID = e.CourseID WHERE EXISTS (SELECT 1 FROM Lessons l WHERE l.CourseID = c.CourseID) AND NOT EXISTS (SELECT 1 FROM Lessons l JOIN Attendance a ON a.LessonID = l.LessonID AND a.UserID = e.UserID WHERE l.CourseID = c.CourseID) GROUP BY u.UserID, c.CourseID"

timing() {
  $QDB -N -e "EXPLAIN ANALYZE $1" 2>/dev/null \
    | grep -oE "actual time=[0-9.]+\.\.[0-9.]+" | head -1 | grep -oE "\.\.[0-9.]+" | tr -d '.'
}

{
  echo "================================================================"
  echo "Lab 4 - Task 3.2 scale test"
  echo "MySQL 8.4.11 | database: educonnect_scale"
  echo "100,000 users, 4,999 courses, 1,000,000 enrolments,"
  echo "9,998 lessons, 1,000,000 attendance rows"
  echo "================================================================"
  echo
  echo "== building Lessons and Attendance =="
} > "$EV/task3_2_scale_test.txt"

$DB < "$SRC/14_scale_test_lessons_attendance.sql" >> "$EV/task3_2_scale_test.txt" 2>&1

echo >> "$EV/task3_2_scale_test.txt"
echo "== table sizes ==" >> "$EV/task3_2_scale_test.txt"
$QDB -e "ANALYZE TABLE Users, Enrollments, Lessons, Attendance;" >> "$EV/task3_2_scale_test.txt" 2>&1
$QDB -e "SELECT table_name, table_rows, ROUND(data_length/1024/1024,1) AS data_mb, ROUND(index_length/1024/1024,1) AS index_mb FROM information_schema.TABLES WHERE table_schema='educonnect_scale' AND table_name IN ('Users','Enrollments','Lessons','Attendance') ORDER BY table_name;" >> "$EV/task3_2_scale_test.txt" 2>&1

echo >> "$EV/task3_2_scale_test.txt"
echo "== A. Version A, LEFT JOIN: EXPLAIN ==" >> "$EV/task3_2_scale_test.txt"
$QDB -e "EXPLAIN $LJ" >> "$EV/task3_2_scale_test.txt" 2>&1
echo >> "$EV/task3_2_scale_test.txt"
echo "== B. Version A, LEFT JOIN: EXPLAIN ANALYZE ==" >> "$EV/task3_2_scale_test.txt"
$QDB -e "EXPLAIN ANALYZE $LJ" >> "$EV/task3_2_scale_test.txt" 2>&1
echo >> "$EV/task3_2_scale_test.txt"
echo "== C. Version A, LEFT JOIN: timings (3 runs, ms) ==" >> "$EV/task3_2_scale_test.txt"
for i in 1 2 3; do timing "$LJ" >> "$EV/task3_2_scale_test.txt"; echo "  run $i" >> "$EV/task3_2_scale_test.txt"; done

echo >> "$EV/task3_2_scale_test.txt"
echo "== D. Version B, NOT EXISTS: EXPLAIN ==" >> "$EV/task3_2_scale_test.txt"
$QDB -e "EXPLAIN $NE" >> "$EV/task3_2_scale_test.txt" 2>&1
echo >> "$EV/task3_2_scale_test.txt"
echo "== E. Version B, NOT EXISTS: EXPLAIN ANALYZE ==" >> "$EV/task3_2_scale_test.txt"
$QDB -e "EXPLAIN ANALYZE $NE" >> "$EV/task3_2_scale_test.txt" 2>&1
echo >> "$EV/task3_2_scale_test.txt"
echo "== F. Version B, NOT EXISTS: timings (3 runs, ms) ==" >> "$EV/task3_2_scale_test.txt"
for i in 1 2 3; do timing "$NE" >> "$EV/task3_2_scale_test.txt"; echo "  run $i" >> "$EV/task3_2_scale_test.txt"; done

echo >> "$EV/task3_2_scale_test.txt"
echo "== G. rows returned by each version ==" >> "$EV/task3_2_scale_test.txt"
$QDB -e "SELECT COUNT(*) AS RowsFromLeftJoinVersion FROM ($LJ) t;" >> "$EV/task3_2_scale_test.txt" 2>&1
$QDB -e "SELECT COUNT(*) AS RowsFromNotExistsVersion FROM ($NE) t;" >> "$EV/task3_2_scale_test.txt" 2>&1

echo "  wrote evidence/task3_2_scale_test.txt"
