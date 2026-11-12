#!/bin/zsh
# Lab 4 - capture the evidence for every task against a freshly reset seed
# database. Writes one file per task into ../evidence/.
#
#   ./scripts/run_evidence.sh
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

MYSQL=(docker exec -i -e MYSQL_PWD=root "$CONTAINER" mysql -uroot -t)

mkdir -p "$EV"

echo "== resetting the seed database =="
docker exec -i -e MYSQL_PWD=root "$CONTAINER" mysql -uroot < "$SRC/00_schema.sql" 2>/dev/null
docker exec -i -e MYSQL_PWD=root "$CONTAINER" mysql -uroot < "$SRC/01_seed.sql" 2>/dev/null

run() {
  local out="$1"; shift
  {
    echo "================================================================"
    echo "Lab 4 - $out"
    echo "MySQL 8.4.11 | database: educonnect | seed data as per handout Part 4.1"
    echo "================================================================"
    echo
  } > "$EV/$out.txt"
  $MYSQL educonnect < "$SRC/$1" >> "$EV/$out.txt" 2>&1
  if grep -qiE "^error|error [0-9]{4}|Error response" "$EV/$out.txt"; then
    echo "  !! FAILED in $out"
    grep -niE "^error|error [0-9]{4}|Error response" "$EV/$out.txt" | head -3
  else
    echo "  ok  evidence/$out.txt"
  fi
}

run task1_1_student_roster              02_task1_1_student_roster.sql
run task1_2_courses_with_department     03_task1_2_courses_with_department.sql
run task1_3_recent_enrollments          04_task1_3_recent_enrollments.sql
run task2_1_enrollment_count_per_course 05_task2_1_enrollment_count_per_course.sql
run task2_2_average_grade_by_course     06_task2_2_average_grade_by_course.sql
run task2_3_students_with_multiple_absences 07_task2_3_students_with_multiple_absences.sql
run task3_1_students_at_risk            08_task3_1_students_at_risk.sql
run task3_2_missing_attendance          09_task3_2_missing_attendance.sql
run task3_3_explain                     10_task3_3_explain.sql
run thinking_question_queries           13_thinking_question_queries.sql

echo "== final state check (must match the handout summary table) =="
$MYSQL educonnect <<'EOF'
SELECT (SELECT COUNT(*) FROM Users) AS Users,
       (SELECT COUNT(*) FROM Courses) AS Courses,
       (SELECT COUNT(*) FROM Enrollments) AS Enrollments,
       (SELECT COUNT(*) FROM Lessons) AS Lessons,
       (SELECT COUNT(*) FROM Attendance) AS Attendance,
       (SELECT COUNT(*) FROM Enrollments WHERE Grade IS NULL) AS NullGrades;
EOF
