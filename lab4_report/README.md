# Lab 4 — SQL Fundamentals: Business Questions, Not Row Counts

Course **IT079IU** · Principles of Database Management · Lab 4
**Le Thanh Trung** · Student ID **ITCSIU25055**

Submission bundle for the EduConnect lab. The report is the PDF; everything
else is the SQL it refers to and the captured output of every query.

---

## Contents

| File | What it is |
|---|---|
| `PDMLab4_ITCSIU25055_LeThanhTrung.pdf` | the report, 23 pages |
| `PDMLab4_ITCSIU25055.docx` | the same report, editable |
| `src/00_schema.sql` | the six tables, exactly as the handout defines them |
| `src/01_seed.sql` | the seed data, exactly as the handout defines them |
| `src/02_task1_1_student_roster.sql` … `src/10_task3_3_explain.sql` | one file per task: the question, the query and the explanation |
| `src/11_scale_test_schema.sql`, `src/12_scale_test_data.sql` | the scale database: 100,000 users, 1,000,000 enrolments |
| `src/13_thinking_question_queries.sql` | the queries used to answer Part 8 |
| `src/14_scale_test_lessons_attendance.sql` | the scale database's lessons and 1,000,000 attendance rows |
| `evidence/*.txt` | the captured output of every query in the report |

---

## Running it

Requires MySQL 8.x. The first two scripts build the database:

```bash
mysql -uroot -p < src/00_schema.sql
mysql -uroot -p < src/01_seed.sql
```

Then each task file can be run on its own:

```bash
mysql -uroot -p -t educonnect < src/08_task3_1_students_at_risk.sql
```

The seed data is reproduced verbatim from the handout and was not modified.

---

## Files, mapped to the handout

| File | Handout part | What it does |
|---|---|---|
| `src/00_schema.sql` | 4.0 | the six tables, exactly as the handout defines them |
| `src/01_seed.sql` | 4.1 | the seed data, exactly as the handout defines them |
| `src/02_task1_1_student_roster.sql` | Task 1.1 | student roster, filtered on `Role` |
| `src/03_task1_2_courses_with_department.sql` | Task 1.2 | courses with their department; `LEFT` and `INNER` compared |
| `src/04_task1_3_recent_enrollments.sql` | Task 1.3 | 5 most recent enrolments, with a deterministic tie-break |
| `src/05_task2_1_enrollment_count_per_course.sql` | Task 2.1 | enrolment count per course; `LEFT` and `INNER` compared |
| `src/06_task2_2_average_grade_by_course.sql` | Task 2.2 | average grade, `WHERE` + `HAVING`, and the three averages compared |
| `src/07_task2_3_students_with_multiple_absences.sql` | Task 2.3 | students with more than one absence, with a rolled-back probe |
| `src/08_task3_1_students_at_risk.sql` | Task 3.1 | students at risk, `HAVING` only, with the trap case walked through |
| `src/09_task3_2_missing_attendance.sql` | Task 3.2 | missing attendance, `LEFT JOIN` and `NOT EXISTS`, plus the counter-example |
| `src/10_task3_3_explain.sql` | Task 3.3 | `EXPLAIN` and `EXPLAIN ANALYZE` of the given query |
| `src/11_scale_test_schema.sql` | 3.3 evidence | the scale database schema |
| `src/12_scale_test_data.sql` | 3.3 evidence | 100,000 users, 4,999 courses, 1,000,000 enrolments |
| `src/13_thinking_question_queries.sql` | Part 8 | the queries used to answer the thinking questions |
| `src/14_scale_test_lessons_attendance.sql` | 3.2 evidence | 9,998 lessons and 1,000,000 attendance rows |

Lab 2 and Lab 3 carry Workbench and RelaX screenshots, because those labs are
done through a GUI. Lab 4 is done from a SQL client, and the evidence of a
query is its output, so the evidence here is text: it can be read, searched
and diffed, which a screenshot of a terminal cannot.

---

## Key results

| Task | Result |
|---|---|
| 1.1 | 5 students, sorted by name |
| 1.2 | `LEFT JOIN` and `INNER JOIN` both return 5 rows, and why that is not an accident |
| 1.3 | 5 rows; a tie at 2024-09-07 falls inside the `LIMIT`, fixed with `e.EnrollID DESC` |
| 2.1 | `LEFT JOIN` 5 rows (Linear Algebra = 0); `INNER JOIN` 4 rows |
| 2.2 | 2 courses, 3 graded students each; `AVG` and `SUM/COUNT(*)` diverge on course 1 (7.5 vs 5.625) |
| 2.3 | no rows; only 2 absences exist, one per student. A rolled-back probe proves the `HAVING` threshold |
| 3.1 | no rows; no student has 3 courses with all grades NULL. A rolled-back probe proves the logic and the trap case |
| 3.2 | `LEFT JOIN` and `NOT EXISTS` both return 4 pairs; the naive form returns 6 |
| 3.3 | at scale: 821 ms with no index, 743 ms with an index on `Role`, **360 ms** with a covering index on `(Role, UserID, FullName)` |

---

## Two errors in the handout

Both are noted in the report, in one line each.

1. **Part 4.0, Step 4** says the verification query should show "7 foreign key
   constraints across the 6 tables". The schema it defines contains **8**, and
   the query returns 8. The query itself is correct; only the stated number is
   wrong.
2. **Part 6** says MySQL "in strict mode" rejects a `SELECT` whose
   non-aggregate columns are missing from the `GROUP BY`. The mechanism is the
   `ONLY_FULL_GROUP_BY` SQL mode, which is on by default in MySQL 8 and is not
   part of the strict-mode group. The behaviour described is correct; the name
   of the mode is not.

Every other number in the handout's Part 4.1 summary table was checked and
matches: 8 users (5 students, 3 instructors), 5 courses, 1 course with 0
enrolments, 11 enrolments, 3 NULL grades, 9 attendance records, 1 student with
0 attendance records.

---

## Verification

- The seed data is reproduced verbatim from the handout and was not modified.
- The probes in Tasks 2.3 and 3.1 run inside a transaction and are rolled
  back. The row counts of `Users` (8) and `Enrollments` (11) were verified
  afterwards, and the `Attendance` table holds 9 rows.
- Every query in `src/` was executed against the seed data. The captured
  output is in `evidence/`.
- The performance claims were measured with `EXPLAIN ANALYZE` on a scale
  database with 100,000 users, 1,000,000 enrolments and 1,000,000 attendance
  rows, three runs per configuration, and the medians are reported.
