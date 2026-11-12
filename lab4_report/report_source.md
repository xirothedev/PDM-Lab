---
title: "IT079IU - Principles of Database Management - Lab 4"
subtitle: "SQL Fundamentals: Business Questions, Not Row Counts"
author: "Le Thanh Trung - ITCSIU25055 - Lab 4"
date: "October 2026"
lang: en-GB
---

**Course** IT079IU — Principles of Database Management  
**Lab** 4 of 10  
**Student** Le Thanh Trung · **Student ID** ITCSIU25055  
**Database** EduConnect — `educonnect`  
**Server** MySQL 8.4.11, run in Docker; the SQL runs unchanged in MySQL Workbench or any other MySQL client  

Every query in this report was executed against the EduConnect database with the seed data from Part 4.1 of the handout. The captured output is in `evidence/`, the SQL is in `src/`.

---

## Contents {- .unnumbered}

- **1** Objective
- **2** Environment and database setup
  - 2.1 The six tables
  - 2.2 Why `utf8mb4`
  - 2.3 Why `Departments.ManagerID` allows NULL
  - 2.4 Verification
  - 2.5 The seed data is built to expose mistakes
- **3** Results
  - 3.1 Task 1.1 — Student roster
  - 3.2 Task 1.2 — Courses with their department
  - 3.3 Task 1.3 — Recent enrollments
  - 3.4 Task 2.1 — Enrolment count per course
  - 3.5 Task 2.2 — Average grade by course
  - 3.6 Task 2.3 — Students with multiple absences
  - 3.7 Task 3.1 — Students at risk
  - 3.8 Task 3.2 — The missing attendance problem
  - 3.9 Task 3.3 — EXPLAIN analysis
- **4** Discussion — Part 8 thinking questions
  - 4.1 Q1 — The NULL semantics trap
  - 4.2 Q2 — JOIN order and performance
  - 4.3 Q3 — HAVING versus a subquery
  - 4.4 Q4 — The “no attendance” problem
  - 4.5 Q5 — Scalability of GROUP BY
  - 4.6 Q6 — Business question versus SQL question
  - 4.7 Q7 — When LEFT JOIN breaks GROUP BY
- **5** Common mistakes
- **6** Part 7 checklist
- **7** Reflection
- **Appendix A** Contents of the submission bundle

## Objective

This lab moves from writing SQL that returns rows to writing SQL that answers a business question. The EduConnect database was built from scratch, and nine business questions were translated into queries. Every query was run against the seed data and its result inspected. The work covers the four ways real data breaks a query: NULL values, empty result sets, duplicate rows from an incorrectly scoped join, and a table large enough for an unindexed query to be slow. Three tasks return no rows on the seed data, and one of them has a trap that produces a plausible but wrong answer. The performance questions were answered by measurement: a second database with 100,000 users, 1,000,000 enrolments and 1,000,000 attendance rows, with the candidate queries run under `EXPLAIN ANALYZE`.

---

## Environment and database setup

### The six tables

| Table | Purpose | Rows |
|---|---|---|
| `Users` | People on the platform, `Role` = `student` or `instructor` | 8 |
| `Departments` | Academic departments, each with a manager who may be NULL | 2 |
| `Courses` | Courses, each belonging to a department and taught by an instructor | 5 |
| `Enrollments` | Who enrolled in what, with a `Grade` that is NULL until it is set | 11 |
| `Lessons` | Scheduled lessons belonging to a course | 5 |
| `Attendance` | One row per student per lesson: `present`, `absent` or `late` | 9 |

The tables were created in the handout's order, because `Departments` references `Users`, `Courses` references `Departments` and `Users`, and `Enrollments` references `Users` and `Courses`. Creating them out of order fails at the first foreign key that points at a table that does not exist yet.

### Why `utf8mb4`

The database was created with `CHARACTER SET utf8mb4` and `COLLATE utf8mb4_unicode_ci`. In MySQL, `utf8` is an alias for `utf8mb3`, which holds at most three bytes per character and cannot store four-byte characters such as emoji or some Vietnamese characters outside the precomposed set. `utf8mb4` holds four bytes and covers the whole Unicode range. The seed data contains Vietnamese names with full diacritics, so the choice is not academic.

### Why `Departments.ManagerID` allows NULL

`Departments.ManagerID` is nullable and its foreign key uses `ON DELETE SET NULL`. The reason is a circular dependency: `Departments` needs `Users` to exist before it can be created, because the manager is a user. If `ManagerID` were `NOT NULL`, the first department could not be inserted until a user existed, and a user could not be inserted until a department existed, because `Courses` requires both. Making the column nullable breaks the circle. The cost is that a department can exist with no manager, so every query that reports a manager must handle that NULL.

### Verification

The seed data was checked against the summary table in Part 4.1 of the handout. Every number matches.

**Table 1 — Row counts after the seed**

| Check | Handout expects | Measured |
|---|---|---|
| Total users | 8 (5 students, 3 instructors) | 8 (5 + 3) |
| Total courses | 5 | 5 |
| Courses with 0 enrollments | 1 (Linear Algebra) | 1 |
| Total enrollments | 11 | 11 |
| NULL grade rows | 3 | 3 |
| Total attendance records | 9 | 9 |
| Students with 0 attendance records | 1 (Hoang Van Em) | 1 |

**Table 2 — Foreign key constraints**

The handout says the verification query should show "7 foreign key constraints across the 6 tables". The schema it defines contains **8**, and the query returns 8.

| # | Constraint | From | To |
|---|---|---|---|
| 1 | `fk_dept_manager` | `Departments.ManagerID` | `Users.UserID` |
| 2 | `fk_course_dept` | `Courses.DeptID` | `Departments.DeptID` |
| 3 | `fk_course_instructor` | `Courses.InstructorID` | `Users.UserID` |
| 4 | `fk_enroll_user` | `Enrollments.UserID` | `Users.UserID` |
| 5 | `fk_enroll_course` | `Enrollments.CourseID` | `Courses.CourseID` |
| 6 | `fk_lesson_course` | `Lessons.CourseID` | `Courses.CourseID` |
| 7 | `fk_att_lesson` | `Attendance.LessonID` | `Lessons.LessonID` |
| 8 | `fk_att_user` | `Attendance.UserID` | `Users.UserID` |

A second error appears in Part 6. The handout says MySQL "in strict mode" rejects a `SELECT` whose non-aggregate columns are missing from the `GROUP BY`. The mechanism is the `ONLY_FULL_GROUP_BY` SQL mode, which is enabled by default in MySQL 8 and is not part of the strict-mode group. The behaviour described is correct; the name of the mode is not.

### The seed data is built to expose mistakes

Three properties of the seed data are deliberate, and each breaks a query that would pass on tidier data:

- **Course 5, Linear Algebra, has no enrollments.** A query that counts students per course must show it with a count of 0. An `INNER JOIN` hides it, and that hides a course the academic office wants to review.
- **User 5, Hoang Van Em, has no attendance rows at all.** He is absent from every attendance report, which is not the same as a student marked present at every lesson: it means there is no data.
- **Three enrollments have a NULL grade.** `AVG`, `COUNT(column)` and `COUNT(*)` behave differently when a NULL is present, and the difference decides the average.

---

## Results

### Task 1.1 — Student roster

**Business question.** The academic office needs a list of all students on the platform, sorted alphabetically by name, showing their name and email. Instructors should not appear.

```sql
SELECT u.FullName,
       u.Email
FROM Users u
WHERE u.Role = 'student'
ORDER BY u.FullName;
```

**Table 3 — Result**

| FullName | Email |
|---|---|
| Hoang Van Em | em.hoang@edu.vn |
| Le Van Cuong | cuong.le@edu.vn |
| Nguyen Van An | an.nguyen@edu.vn |
| Pham Thi Dung | dung.pham@edu.vn |
| Tran Thi Bich | bich.tran@edu.vn |

**Why `WHERE u.Role = 'student'` and nothing else.** `Users` holds exactly two roles, `student` and `instructor`, declared as an `ENUM`. No other column separates the two groups, so `Role` is the only possible filter, and the enum guarantees the value is one of the two and never NULL. The filter sits in `WHERE` rather than in the join condition because it depends on `Users` alone.

**Is `Role` reliable?** Reliable as a column, unreliable as a fact. The column cannot hold a value outside the enum, so there is no third state and no NULL. The value is entered by the academic office, so it can still be wrong:

- A student who also teaches has `Role = 'instructor'` and will not appear, even though they are studying. The query answers "accounts whose role is `student`", not "people who are studying".
- Case does not matter here. MySQL compares strings with the column's collation, and `utf8mb4_unicode_ci` is case-insensitive, so `'Student'` would also match. That is a property of the collation, not a guarantee in the schema.

The likelier failure is not a wrong case but an account that was never classified, and `Role NOT NULL` prevents that: every account has to be created as one role or the other, which is a decision someone can still get wrong.

---

### Task 1.2 — Courses with their department

**Business question.** Produce a report showing each course title, its credit count and the name of its department. Include all courses, even if something about the department data is unusual.

```sql
SELECT c.Title    AS CourseTitle,
       c.Credits  AS Credits,
       d.DeptName AS DepartmentName
FROM Courses c
LEFT JOIN Departments d ON c.DeptID = d.DeptID
ORDER BY c.Title;
```

**Table 4 — Result**

| CourseTitle | Credits | DepartmentName |
|---|---|---|
| Calculus I | 4 | Mathematics |
| Data Structures | 3 | Computer Science |
| Database Management | 3 | Computer Science |
| Introduction to Programming | 3 | Computer Science |
| Linear Algebra | 3 | Mathematics |

**Which JOIN type, and why.** `LEFT JOIN`, because the requirement is to include every course. A `LEFT JOIN` keeps a course row when the department side has no match, so a course cannot disappear because of its department.

**What happens with the other JOIN type.** Both versions were run and both return **5 rows** here:

- `Courses.DeptID` is `NOT NULL`.
- `fk_course_dept` uses `ON DELETE RESTRICT`, so a department cannot be deleted while a course still points at it.

A course therefore cannot have a missing department in this schema, and the two queries are equivalent on this data. `LEFT JOIN` states the intent and keeps working if the constraint is relaxed, if a course is loaded from outside the schema, or if the report is reused on a table where the relationship is not guaranteed. It costs nothing here.

**The "unusual department data".** The column in `Departments` that can be unusual is `ManagerID`, nullable for the bootstrapping reason in section 2.3. It does not affect this query, because the manager is not selected. The column that could produce a NULL here is `DeptName`, and `LEFT JOIN` protects the course row if that happens.

---

### Task 1.3 — Recent enrollments

**Business question.** Show the 5 most recent enrollment records, including the student's name, the course title and the enrolment date.

```sql
SELECT u.FullName AS StudentName,
       c.Title    AS CourseTitle,
       e.EnrollDate
FROM Enrollments e
JOIN Users u   ON u.UserID   = e.UserID
JOIN Courses c ON c.CourseID = e.CourseID
ORDER BY e.EnrollDate DESC, e.EnrollID DESC
LIMIT 5;
```

**Table 5 — Result**

| StudentName | CourseTitle | EnrollDate |
|---|---|---|
| Hoang Van Em | Data Structures | 2024-09-09 |
| Hoang Van Em | Introduction to Programming | 2024-09-09 |
| Pham Thi Dung | Calculus I | 2024-09-08 |
| Pham Thi Dung | Database Management | 2024-09-08 |
| Le Van Cuong | Data Structures | 2024-09-07 |

**What "most recent" means technically.** `ORDER BY e.EnrollDate DESC` sorts on `EnrollDate` alone. `EnrollDate` is a `DATE`, so its resolution is one day, and two enrolments made on the same day have the same sort value.

**Is the tie broken deterministically?** Not with the date alone. Three dates carry two rows each and one date carries four rows:

**Table 6 — Rows per enrolment date**

| EnrollDate | RowsOnThatDate |
|---|---|
| 2024-09-09 | 2 |
| 2024-09-08 | 2 |
| 2024-09-07 | 2 |
| 2024-09-06 | 1 |
| 2024-09-05 | 4 |

The five rows returned take two from 09-09, two from 09-08, then one of the two rows from 09-07. The cut falls **inside** a tie, so the fifth row is decided by the tie rather than by the dates. MySQL is free to return tied rows in any order, and the order it picks is an implementation detail that can change between versions, between machines, and between runs after a data change.

**The fix.** `e.EnrollID DESC` is added as a second sort key. `EnrollID` is `AUTO_INCREMENT`, so a larger value means the row was inserted later, and within one day the later insertion is the more recent enrolment. The sort is now total, because `EnrollID` is unique. The tie at 2024-09-07 resolves to EnrollID 7 (*Data Structures*) before EnrollID 6 (*Introduction to Programming*).

Any report that takes the "top N by date" has a boundary problem, and the boundary is where the reader looks.

---

### Task 2.1 — Enrolment count per course

**Business question.** The head of department wants to know how many students are enrolled in each course. The report must include courses with zero enrolments, because those are flagged for review.

```sql
SELECT c.Title           AS CourseTitle,
       COUNT(e.EnrollID) AS EnrollmentCount
FROM Courses c
LEFT JOIN Enrollments e ON c.CourseID = e.CourseID
GROUP BY c.CourseID, c.Title
ORDER BY EnrollmentCount DESC, c.Title;
```

**Table 7 — Result with LEFT JOIN**

| CourseTitle | EnrollmentCount |
|---|---|
| Introduction to Programming | 4 |
| Database Management | 3 |
| Calculus I | 2 |
| Data Structures | 2 |
| Linear Algebra | 0 |

**Table 8 — The same query with INNER JOIN**

| CourseTitle | EnrollmentCount |
|---|---|
| Introduction to Programming | 4 |
| Database Management | 3 |
| Calculus I | 2 |
| Data Structures | 2 |

**Which JOIN type.** `LEFT JOIN`. The question is about every course, and the courses with no students are the reason the report exists. An `INNER JOIN` builds its result from the courses that have at least one enrolment, so Linear Algebra is not in the output at all, and the query answers a different question: how many students are in the courses that have students. The 4 rows against 5 rows is the whole difference.

**What `COUNT` returns on the unmatched side.** `COUNT(e.EnrollID)` returns **0** for a course with no enrolments. The `LEFT JOIN` still produces one row for that course, and every column of the right-hand side in that row is NULL. `COUNT` ignores NULL, so the count is 0 and not NULL.

`COUNT(*)` would return **1** for the same course, because it counts rows and the padded row is a row. After a `LEFT JOIN`, `COUNT(*)` counts the padding, not the matches. This is the mistake in Part 8 question 7.

**Sorting.** `ORDER BY EnrollmentCount DESC` uses the select alias, which MySQL allows. `c.Title` is the second key so that the two courses with a count of 2 do not swap places between runs.

---

### Task 2.2 — Average grade by course

**Business question.** Calculate the average grade for each course. Only include courses where at least 2 grades have been recorded, not merely enrolled.

```sql
SELECT c.Title                AS CourseTitle,
       ROUND(AVG(e.Grade), 1) AS AverageGrade,
       COUNT(e.Grade)         AS GradedStudentCount
FROM Courses c
JOIN Enrollments e ON c.CourseID = e.CourseID
WHERE e.Grade IS NOT NULL
GROUP BY c.CourseID, c.Title
HAVING COUNT(e.Grade) >= 2
ORDER BY AverageGrade DESC, c.Title;
```

**Table 9 — Result**

| CourseTitle | AverageGrade | GradedStudentCount |
|---|---|---|
| Introduction to Programming | 7.5 | 3 |
| Database Management | 7.2 | 3 |

**Two filters, two different jobs.** `WHERE e.Grade IS NOT NULL` removes the ungraded rows before the rows are grouped, so NULL grades never enter the average or the count. `HAVING COUNT(e.Grade) >= 2` keeps only the groups holding at least two real grades. That second condition cannot be written in `WHERE`: when `WHERE` runs, the groups do not exist and the aggregate has not been computed.

The handout offers a second route: drop the `WHERE` and use `HAVING` alone with a conditional count, because `AVG` already ignores NULL. That route was run as well and returns the same two rows. The `WHERE` route is kept because it removes the ungraded rows before the aggregation instead of after it, so the aggregate works on less data.

**Is `AVG(Grade)` the same as `SUM(Grade) / COUNT(*)`?**

- `AVG(Grade)` ignores NULL and divides by the number of **non-NULL** grades.
- `SUM(Grade) / COUNT(*)` divides by the number of **rows**, including the rows where the grade is NULL.

With the `WHERE` filter in place the two agree, because the filter has removed the NULL rows and `COUNT(*)` equals `COUNT(e.Grade)`. Remove the filter and they part company:

**Table 10 — The three averages for the same course**

| CourseTitle | Enrolled | Graded | `AVG(Grade)` | `SUM(Grade)/COUNT(*)` | `AVG(COALESCE(Grade,0))` |
|---|---|---|---|---|---|
| Introduction to Programming | 4 | 3 | 7.5000 | 5.6250 | 5.6250 |
| Database Management | 3 | 3 | 7.1667 | 7.1667 | 7.1667 |
| Calculus I | 2 | 1 | 7.5000 | 3.7500 | 3.7500 |
| Data Structures | 2 | 1 | 6.0000 | 3.0000 | 3.0000 |

For Introduction to Programming the enrolled sum is 22.5 across 4 students, but only 3 of them have a grade. `AVG(Grade)` gives 22.5 / 3 = **7.5**. `SUM/COUNT(*)` gives 22.5 / 4 = **5.625**, because the ungraded student is counted in the denominator and contributes nothing to the sum. The second number treats an ungraded student as a zero; the first ignores the student. On one course the gap between 7.5 and 5.625 is the difference between a student who has not been assessed yet and a student who has been failed, and a report producing the wrong one does not crash or look wrong. It just misleads.

**`ROUND` and `COUNT(e.Grade)`.** `ROUND` is applied to the average, not to the sum, so the rounding happens last. `COUNT(e.Grade)` counts the non-NULL grades, so it is the number of students who were actually graded. `COUNT(*)` gives the same number here because the `WHERE` filter removed the ungraded rows, but `COUNT(e.Grade)` stays correct if the filter is dropped.

---

### Task 2.3 — Students with multiple absences

**Business question.** Flag students who have been recorded as absent more than once across any lesson. Show their name and absence count.

```sql
SELECT u.FullName AS StudentName,
       COUNT(*)   AS AbsenceCount
FROM Attendance a
JOIN Users u ON u.UserID = a.UserID
WHERE a.Status = 'absent'
GROUP BY u.UserID, u.FullName
HAVING COUNT(*) > 1
ORDER BY AbsenceCount DESC, u.FullName;
```

**Table 11 — Result: no rows**

**Table 12 — The absence count per student**

| StudentName | AttendanceRecords | Absences | LateArrivals |
|---|---|---|---|
| Hoang Van Em | 0 | 0 | 0 |
| Le Van Cuong | 1 | 1 | 0 |
| Nguyen Van An | 4 | 0 | 1 |
| Pham Thi Dung | 2 | 0 | 1 |
| Tran Thi Bich | 2 | 1 | 0 |

**`WHERE` versus `HAVING` placement.** `WHERE a.Status = 'absent'` filters individual attendance rows before the grouping, so the groups are built from absences alone and the count in `HAVING` counts absences. With the status test in `HAVING` instead, `COUNT(*)` would count every attendance row of the student and the threshold would mean "attended more than one lesson" rather than "was absent more than once". Late arrivals are removed by the same `WHERE` clause, since the test is an equality test on `'absent'`.

**The result is empty, and the reason is in the data.** The seed contains exactly two rows with `Status = 'absent'`: AttID 3 (Le Van Cuong, lesson 1) and AttID 6 (Tran Thi Bich, lesson 2). Each student has one absence, so nobody reaches the threshold of two. The query is correct; the data contains no case that satisfies it.

To show the threshold works, a probe was run: one extra `'absent'` row was inserted for Le Van Cuong inside a transaction, the query was re-run, and the transaction rolled back.

**Table 13 — The probe result**

| StudentName | AbsenceCount |
|---|---|
| Le Van Cuong | 2 |

The attendance table was verified to hold 9 rows again after the rollback, so the seed data is unchanged. One detail: the `AUTO_INCREMENT` counter is not transactional in InnoDB, so the counter advanced even though the row did not. That is normal InnoDB behaviour and it changes no data.

**Does User 5 (Hoang Van Em) appear, and should he?** He does not appear, which is correct: he has zero absences, so he fails a "more than one absence" test. His absence from the result does **not** mean perfect attendance. It means there is no data about his attendance.

Those two states are different and one report cannot tell them apart, because both produce zero rows:

- absent from the result with absences on record: a real pattern worth a look;
- absent from the result with no records at all: an unknown, which for an academic office is usually the more urgent of the two.

A production report has to separate them, by reporting the number of attendance records next to the number of absences, as Table 12 does. That uses `COUNT(CASE WHEN a.Status = 'absent' THEN 1 END)` rather than `SUM(a.Status = 'absent')`, because `SUM` over an empty set of non-NULL values returns NULL rather than 0, and Hoang Van Em's padded row would publish a NULL.

---

### Task 3.1 — Students at risk

**Business question.** Identify students who are enrolled in at least 3 courses but have not received a grade in **any** of those courses. If a student has even one graded course, exclude them.

```sql
SELECT u.FullName                        AS StudentName,
       COUNT(e.EnrollID)                  AS EnrolledCourseCount,
       COUNT(e.EnrollID) - COUNT(e.Grade) AS UngradedCourseCount
FROM Users u
JOIN Enrollments e ON u.UserID = e.UserID
WHERE u.Role = 'student'
GROUP BY u.UserID, u.FullName
HAVING COUNT(e.EnrollID) >= 3
   AND COUNT(e.Grade) = 0
ORDER BY u.FullName;
```

**Table 14 — Result: no rows**

**Why no subquery is needed.** The handout asks for a solution with joins and `HAVING` only, and both halves of the rule are conditions on a group:

- "at least 3 courses" is the number of enrolment rows in the group, `COUNT(e.EnrollID) >= 3`;
- "no grade in any course" is the number of non-NULL grades in the group being zero, `COUNT(e.Grade) = 0`.

A group is what `GROUP BY` produces and a condition on a group is what `HAVING` is for. The aggregate does not exist before the rows are grouped, so neither condition can be written in `WHERE`.

**The two counts.** `COUNT(e.EnrollID)` counts the enrolment rows; every joined row has a non-NULL `EnrollID`, so it is the number of courses the student is enrolled in. `COUNT(e.Grade)` counts the rows where `Grade` is not NULL, so it is the number of courses that were graded. `COUNT(e.Grade) = 0` is the rule "not a single grade exists", expressed as one number.

**The output column name.** `COUNT(e.Grade)` is the graded count, so it cannot be published under the name `UngradedCourseCount`. The ungraded count is the enrolled count minus the graded count, which is why the query selects `COUNT(e.EnrollID) - COUNT(e.Grade)`.

**The trap, walked through.** A student enrolled in 3 courses, 2 graded and 1 not:

| Test | Value | Result |
|---|---|---|
| `COUNT(e.EnrollID) >= 3` | 3 | passes |
| `COUNT(e.Grade) = 0` | 2 | **fails** |

The student is excluded, as the requirement asks: if a student has even one graded course, exclude them.

The trap is to write the condition as `COUNT(e.Grade) = COUNT(e.EnrollID)`, or to filter the ungraded rows with `WHERE e.Grade IS NULL` and count the survivors. That answers a different question, "students whose most recent row happens to be ungraded", and a student with 3 courses of which 2 are graded would pass it. The report would then flag a student who is being assessed normally, which is the silently wrong report Part 3.6 warns about.

**Why the seed data cannot show this rule working.** The enrolment and grading counts per student are:

**Table 15 — Enrolled and graded per student**

| StudentName | Enrolled | Graded | Ungraded |
|---|---|---|---|
| Nguyen Van An | 3 | 2 | 1 |
| Tran Thi Bich | 2 | 2 | 0 |
| Le Van Cuong | 2 | 1 | 1 |
| Pham Thi Dung | 2 | 2 | 0 |
| Hoang Van Em | 2 | 1 | 1 |

Only one student has 3 or more courses, and that student has 2 grades, so the first test passes and the second fails. No student in the seed data has every enrolment ungraded, so the rule matches nobody at any threshold.

A probe was run to prove the logic: a student with 3 ungraded enrolments was inserted inside a transaction.

**Table 16 — The probe result**

| StudentName | EnrolledCourseCount | UngradedCourseCount |
|---|---|---|
| PROBE Student | 3 | 3 |

The probe then gave that student 2 grades out of 3, which is the trap case, and the query returned no rows, so the student was excluded as required. The transaction was rolled back and the counts of `Users` (8) and `Enrollments` (11) were verified unchanged.

---

### Task 3.2 — The missing attendance problem

**Business question.** Find students who are enrolled in a course but have **no attendance records for any lesson in that course**.

**What the requirement means.** The scope is the pair (student, course). The test is not "the student has no record for some lesson" but "the student has no record for **any** of the lessons of this course". A student marked absent for lesson 1 with no row for lesson 2 does have attendance records for that course, so that pair must not be reported. Courses with no lessons scheduled are excluded, as the handout requires and because "no attendance for any lesson of this course" is not a meaningful statement about a course with no lessons.

**Version A — LEFT JOIN with a NULL check**

```sql
SELECT u.FullName AS StudentName,
       c.Title    AS CourseTitle
FROM Enrollments e
JOIN Users u   ON u.UserID   = e.UserID
JOIN Courses c ON c.CourseID = e.CourseID
JOIN Lessons l ON l.CourseID = c.CourseID
LEFT JOIN Attendance a ON a.UserID = e.UserID AND a.LessonID = l.LessonID
GROUP BY u.UserID, c.CourseID
HAVING COUNT(a.AttID) = 0
ORDER BY u.FullName, c.Title;
```

The join fans the rows out to one row per (student, course, lesson). Attendance is joined with **both** conditions, `a.UserID = e.UserID` and `a.LessonID = l.LessonID`, so the attendance row must belong to this student and to this lesson; without the `UserID` condition the query would match any student's record for the lesson. The rows are then grouped by student and course, and `HAVING COUNT(a.AttID) = 0` asks how many attendance records this student has across all the lessons of this course. Zero means the pair is reported.

**Version B — NOT EXISTS**

```sql
SELECT u.FullName AS StudentName,
       c.Title    AS CourseTitle
FROM Enrollments e
JOIN Users u   ON u.UserID   = e.UserID
JOIN Courses c ON c.CourseID = e.CourseID
WHERE EXISTS (SELECT 1 FROM Lessons l WHERE l.CourseID = c.CourseID)
  AND NOT EXISTS (
        SELECT 1
        FROM Lessons l
        JOIN Attendance a ON a.LessonID = l.LessonID AND a.UserID = e.UserID
        WHERE l.CourseID = c.CourseID)
GROUP BY u.UserID, c.CourseID
ORDER BY u.FullName, c.Title;
```

The correlated subquery looks for any attendance row of this student in any lesson of this course. The `EXISTS` clause on `Lessons` keeps the courses that have no lessons out.

**Table 17 — Versions A and B: the same 4 pairs**

| StudentName | CourseTitle |
|---|---|
| Hoang Van Em | Introduction to Programming |
| Nguyen Van An | Calculus I |
| Pham Thi Dung | Calculus I |
| Tran Thi Bich | Database Management |

Both return the same 4 pairs, because both scope the attendance check to the whole course.

**The trap.** The naïve forms do not. A `LEFT JOIN` with a bare `WHERE a.AttID IS NULL` and no `GROUP BY` tests each lesson row on its own and reports a pair as soon as **one** lesson has no record. A `NOT EXISTS` correlated on the single lesson row does the same.

**Table 18 — The naïve version returns 6 pairs**

| StudentName | CourseTitle |
|---|---|
| Hoang Van Em | Introduction to Programming |
| Le Van Cuong | Introduction to Programming |
| Nguyen Van An | Calculus I |
| Pham Thi Dung | Calculus I |
| Pham Thi Dung | Database Management |
| Tran Thi Bich | Database Management |

The two extra pairs are Le Van Cuong and Pham Thi Dung. The reasoning table shows why they must not be there:

**Table 19 — Attendance records per enrolled student-course pair**

| StudentName | CourseTitle | LessonsInCourse | AttendanceRecords |
|---|---|---|---|
| Hoang Van Em | Introduction to Programming | 2 | 0 |
| Le Van Cuong | Introduction to Programming | 2 | 1 |
| Nguyen Van An | Calculus I | 1 | 0 |
| Nguyen Van An | Database Management | 2 | 2 |
| Nguyen Van An | Introduction to Programming | 2 | 2 |
| Pham Thi Dung | Calculus I | 1 | 0 |
| Pham Thi Dung | Database Management | 2 | 1 |
| Tran Thi Bich | Database Management | 2 | 0 |
| Tran Thi Bich | Introduction to Programming | 2 | 2 |

Le Van Cuong was marked absent for lesson 1 of Introduction to Programming and has no row for lesson 2, so he has 1 attendance record for that course and does not belong in the report. The naïve query reports him because it found the missing lesson 2 row and stopped there. The difference between 4 and 6 rows is a report telling the academic office that two students have vanished from a class, when their attendance record is merely incomplete.

**Which performs better on a table with 1,000,000 rows?** This was measured, not asserted. A second dataset was built with 100,000 users, 4,999 courses, 1,000,000 enrolments, 9,998 lessons and **1,000,000 attendance rows**, and both versions were run under `EXPLAIN ANALYZE`.

**Table 20 — Task 3.2 at scale**

| Version | Median of 3 runs | Plan |
|---|---|---|
| A, LEFT JOIN | **9,309 ms** | nested loop left join producing 2,000,000 rows, then `Aggregate using temporary table` over 1,000,000 groups, then `Table scan on <temporary>` |
| B, NOT EXISTS | **3,655 ms** | `Nested loop antijoin`, 1,000,000 probes into a materialised, de-duplicated subquery |

`NOT EXISTS` is about **2.5 times faster**. The `LEFT JOIN` version has to build the join before it can answer the question: every (student, course, lesson) combination is produced, an attendance row is matched or not matched for each one, and the groups are counted. With two lessons per course that is 2,000,000 rows and 2,000,000 attendance lookups, and the groups land in a temporary table that is scanned again.

The `NOT EXISTS` version asks a question that one lookup per student-course pair can answer. MySQL rewrote it into an **antijoin** with a materialised, de-duplicated subquery, so it performs about 1,000,000 probes and never builds the 2,000,000-row intermediate result.

Two caveats. The `NOT EXISTS` version still has to be written correctly: the naive per-lesson form in Table 18 is also a `NOT EXISTS`, and it is wrong. The speed advantage comes from scoping the subquery to the whole course, not from the keyword. And on a well-indexed table the planner can make the two plans converge, so the gap can be smaller in practice than 2.5 times. What does not change is that the `LEFT JOIN` version does strictly more work, because it materialises the pairs it is going to discard.

---

### Task 3.3 — EXPLAIN analysis

**The query under analysis.**

```sql
SELECT u.FullName, COUNT(e.EnrollID) AS EnrolledCourses
FROM Users u
LEFT JOIN Enrollments e ON u.UserID = e.UserID
WHERE u.Role = 'student'
GROUP BY u.UserID, u.FullName
HAVING COUNT(e.EnrollID) > 0
ORDER BY EnrolledCourses DESC;
```

**Table 21 — EXPLAIN on the seed data**

| id | select_type | table | type | possible_keys | key | key_len | ref | rows | filtered | Extra |
|---|---|---|---|---|---|---|---|---|---|---|
| 1 | SIMPLE | u | **ALL** | NULL | **NULL** | NULL | NULL | 9 | 50.00 | Using where; Using temporary; Using filesort |
| 1 | SIMPLE | e | **ref** | uq_enrollment | **uq_enrollment** | 4 | educonnect.u.UserID | 2 | 100.00 | Using index |

**What MySQL is doing, in plain language.**

- **`Users` (u), type = `ALL`, key = `NULL`.** A full table scan. MySQL reads every row of `Users` and tests the `Role` column on each one, because no index on `Role` exists. `filtered = 50.00` is the planner's estimate that half the rows are students.
- **`Enrollments` (e), type = `ref`, key = `uq_enrollment`.** For each user row, MySQL looks up that user's enrolments through the unique key `(UserID, CourseID)`. The `ref` value `educonnect.u.UserID` shows the lookup is driven by the user id from the outer table. `Using index` means the index alone supplies every column needed, so the table rows are never touched. This part of the plan is already good: the schema's own unique key supports the join and no new index is needed for it.
- **`Extra` on `Users`: `Using temporary; Using filesort`.** MySQL builds a temporary table to hold the groups, then sorts the result again, because the `ORDER BY` is on an aggregate value that no index can supply. On 8 rows this costs nothing. On 100,000 users it is the dominant cost.

One note on `rows`: the classic `EXPLAIN` reports 9 rows for `Users` while the table holds 8. `EXPLAIN ANALYZE` on the same query reports the true figure, `Table scan on u (rows=8)`, because it executes the query. `rows` in a classic `EXPLAIN` is an estimate from the storage engine's statistics, not a measurement, and it drifts after inserts and rollbacks. Any conclusion that depends on the real row count has to come from `EXPLAIN ANALYZE`.

**Would this query be slow with 100,000 users?** Yes, and the bottleneck is not the join. It is the scan of `Users` plus the temporary table for the `GROUP BY`. The measurement was made on a scale database with 100,000 users, 4,999 courses and 1,000,000 enrolments.

**Table 22 — Task 3.3 at scale, 3 runs each**

| Configuration | Runs (ms) | Median | Plan on `Users` |
|---|---|---|---|
| No index on `Role` | 821, 1177, 777 | **821 ms** | `type=ALL`, `key=NULL`, `Table scan on u`, `Aggregate using temporary table` |
| `+ idx_users_role (Role)` | 743, 752, 736 | **743 ms** | `type=ref`, `key=idx_users_role`, `Using temporary; Using filesort` |
| `+ idx_users_role_id_name (Role, UserID, FullName)` | 358, 423, 360 | **360 ms** | `type=ref`, `key=idx_users_role_id_name`, `Using index`, a streaming `Group aggregate` |
| `+` same index, `GROUP BY u.UserID` only | 340, 299, 304 | **304 ms** | `Covering index lookup on u`, `Group aggregate`, `Stream results` |

The obvious index, on the column in the `WHERE` clause, barely moves the time: 821 ms becomes 743 ms, a difference smaller than the run-to-run spread within the no-index configuration (777-1,177 ms). The `Users` table is small enough to sit in the buffer pool, so the sequential scan is already cheap, and the index lookup replaces it with random access. The index is also not covering, so MySQL still visits the table row for every student it finds. It changes the plan but not the cost.

The **composite** index is the one that pays. `Role, UserID, FullName` covers every column the query reads, so the table is never touched, and the rows arrive from the index already grouped by `UserID`. That lets the plan change from `Aggregate using temporary table` to a streaming `Group aggregate` that never builds the temporary table: **821 ms → 360 ms**, a factor of 2.3.

Dropping `FullName` from the `GROUP BY` is legal, since `FullName` is functionally dependent on the primary key `UserID` and MySQL's functional-dependency detection allows it. That takes the query to **304 ms**.

`Using filesort` remains in every plan and always will. The `ORDER BY` sorts on an aggregate result, and no index can provide an aggregate result in sorted order. That sort is over the number of groups, not the number of rows, so it is not the bottleneck.

**Which index would you add?**

```sql
CREATE INDEX idx_users_role_id_name ON Users (Role, UserID, FullName);
```

It is the index the measurements support, not the obvious one. "Add an index on the column in the `WHERE` clause" is a rule of thumb, and here it was wrong by a factor of two.

---

## Discussion — Part 8 thinking questions

### Q1 — The NULL semantics trap

*Suppose you want the average grade among all enrolled students, treating ungraded students as 0. How would you rewrite the query? Is that fair?*

The rewrite uses `COALESCE` and divides by the number of enrolled students:

```sql
SELECT c.Title,
       ROUND(AVG(COALESCE(e.Grade, 0)), 4) AS AvgUngradedAsZero,
       ROUND(AVG(e.Grade), 4)              AS AvgIgnoringUngraded
FROM Courses c
JOIN Enrollments e ON c.CourseID = e.CourseID
GROUP BY c.CourseID, c.Title;
```

`AVG(e.Grade)` cannot be used, because it ignores NULL and divides by the non-NULL count, which is the opposite of what is asked. `SUM(COALESCE(e.Grade, 0)) / COUNT(e.EnrollID)` is the long form of the same thing. Table 10 shows all three averages side by side; for Introduction to Programming they are 7.5000, 5.6250 and 5.6250.

**Is treating ungraded students as 0 fair?** Not as a description of academic performance. A grade of 0 means the work was submitted and failed. A missing grade means the work has not been assessed yet, or the assessment has not been recorded. The query converts the second into the first.

**When would a teacher legitimately want that number?** When the question is about workload rather than performance: how many students are outstanding, what share of a cohort still needs a mark, whether a course is keeping up with its marking schedule. In that frame "0" is a legitimate encoding of "nothing recorded yet", because the measure is the gap, not the achievement.

**When would it be misleading?** Whenever the number is read as performance. A course where 30 students are ungraded and 5 scored 9.0 averages 7.5 under the fair rule and 4.5 under the zero rule. The zero rule makes a marking backlog look like a failing course, and makes the department act on a data-entry problem as if it were a teaching problem. The number is defensible only if it is published next to the number of ungraded students, because the two together say what either one alone hides.

### Q2 — JOIN order and performance

*If you had to explain to the query planner why joining Courses before Enrollments might be faster than the reverse, what would you say? What database property determines which table should be the "outer" table in a nested loop join?*

The property is the estimated number of rows, and the outer table should be the larger one, with the smaller table on the inside of the nested loop.

The loop runs the inner lookup once for every row of the outer table, so the total cost is roughly `outer rows × cost of one inner lookup`. If the outer table is small, the inner table is scanned repeatedly. If the outer table is large, the inner table is probed many times, but each probe is a cheap index lookup. The small table goes inside, where a single scan is reused, and the large table goes outside, where each row triggers one indexed probe.

The `EXPLAIN` output shows this directly: `rows` estimates how many times the inner table is probed, and `key` says whether the probe is an index lookup or a full scan. In the Task 3.3 plan, `Users` has `rows = 9` and drives the join, while `Enrollments` is entered with `type = ref`, the cheap case.

Joining `Courses` before `Enrollments` would be faster when `Courses` is much smaller than `Enrollments`, here 5 rows against 1,000,000 at scale. Starting from `Courses`, MySQL reads the 5 courses and looks up the enrolments for each through the index on `CourseID`, instead of walking a million enrolment rows and testing each against the course list. The join order the planner picks is visible in the `EXPLAIN` output, and the rule behind it is: the smallest table the join can start from, with the other tables entered through indexes.

### Q3 — HAVING versus a subquery

*Task 2.2 can be solved using HAVING, or using a subquery in the FROM clause. Which is more readable? Does MySQL execute them differently?*

Both were written and both were run. The `HAVING` version:

```sql
SELECT c.Title, ROUND(AVG(e.Grade), 1) AS AverageGrade, COUNT(e.Grade) AS GradedStudentCount
FROM Courses c
JOIN Enrollments e ON c.CourseID = e.CourseID
WHERE e.Grade IS NOT NULL
GROUP BY c.CourseID, c.Title
HAVING COUNT(e.Grade) >= 2
ORDER BY AverageGrade DESC;
```

The derived-table version:

```sql
SELECT d.CourseTitle, d.AverageGrade, d.GradedStudentCount
FROM (
    SELECT c.Title AS CourseTitle,
           ROUND(AVG(e.Grade), 1) AS AverageGrade,
           COUNT(e.Grade) AS GradedStudentCount
    FROM Courses c
    JOIN Enrollments e ON c.CourseID = e.CourseID
    WHERE e.Grade IS NOT NULL
    GROUP BY c.CourseID, c.Title
) d
WHERE d.GradedStudentCount >= 2
ORDER BY d.AverageGrade DESC;
```

Both return the same two rows: Introduction to Programming (7.5, 3) and Database Management (7.2, 3).

**Which is more readable?** The `HAVING` version. It states the whole question in one place, in the order the question is asked: filter, group, aggregate, keep the groups that qualify. The derived-table version spreads the same logic across two levels and renames every column on the way out, so the reader has to hold the inner query in their head while reading the outer one.

**Does MySQL execute them differently?** Yes, the plans differ although the results are the same:

| Route | Plan |
|---|---|
| `HAVING` | `Courses` scanned (`type=ALL`), `Enrollments` joined on `fk_enroll_course`, then `Using temporary; Using filesort` |
| Derived table | `<derived2>` scanned (`type=ALL`) with `Using filesort`, and the derived table itself built from `Enrollments` joined on `fk_enroll_course` |

The derived-table plan adds a level: the inner query is materialised and the outer query reads it as a table and sorts it again. On this data the cost is trivial, but the extra level is structural and does not go away with more data.

**How would you check?** `EXPLAIN` on both statements, and `EXPLAIN ANALYZE` for real timings. The `select_type` column shows what happened: `SIMPLE` for the `HAVING` route, `PRIMARY` plus `DERIVED` for the subquery route.

### Q4 — The "no attendance" problem

*Is the absence of an attendance record the same as being absent? What is the difference between "we recorded that this student was absent" and "we have no record for this student at this lesson"? How should a production EduConnect system handle this distinction?*

They are not the same.

- "We recorded that this student was absent" is a **positive observation**. A row exists in `Attendance` with `Status = 'absent'`. The system knows, with a date and a lesson, that the student was not there.
- "We have no record for this student at this lesson" is an **absence of evidence**. The student is enrolled, the course had a lesson, and the attendance table has nothing for that pair.

The first is a fact about the student; the second is a fact about the recording process. The second can arise from at least four situations that look identical in the database: the student was there and nobody marked it; the student was not there and nobody marked it; the lesson did not happen; or the enrolment happened after the lesson. Only the first is a student behaviour.

Task 3.2 is a query about the second kind, so its output is a list of gaps in the data, not a list of students who skipped class. That is why the query in 3.8 scopes the check to the whole course: a student with one attendance record for a course has been recorded, and reporting them would mix a data-quality problem into a student-behaviour report.

**How a production system should handle it.**

1. **Separate the two in the schema.** Record every expected pair. If the system writes a row for every enrolled student at every lesson and marks the status `absent` or `unknown` rather than leaving the row out, "no record" stops being possible. A status enum with an explicit `unrecorded` value, or a `NOT NULL` guarantee backed by a nightly reconciliation job, does it.
2. **Never let a query treat missing data as a negative observation.** Task 2.3 is the example: Hoang Van Em has 0 absences and 0 attendance records. Reporting him as "no absences" reads as praise; the truth is "no information". A production report should publish the denominator, attendance records or expected lessons, next to the numerator.
3. **Measure the gap.** The number of missing attendance rows is itself a KPI, the quality of the recording process, and it is measured by exactly the query in Task 3.2. Run daily it produces a list of lessons whose attendance was never taken, which is actionable in a way that "student X has no attendance" is not.

### Q5 — Scalability of GROUP BY

*If EduConnect grows to 200,000 users and 1,000,000 enrolments, which part of this query becomes the bottleneck first? What does MySQL do internally when it executes a GROUP BY on a large dataset with no index? What index would eliminate that cost?*

**The bottleneck.** The `GROUP BY`, and specifically the temporary table behind it. The join is already indexed and stays cheap: `Enrollments` is entered through `uq_enrollment`, so each user row costs one index probe. The expensive part is what happens to the rows afterwards.

**What MySQL does internally with no suitable index.** It builds the groups from scratch:

1. Read the rows, filtered by `Role = 'student'`.
2. Write each row into an **internal temporary table** whose key is the grouping expression (`UserID, FullName`).
3. Look up the group's current aggregate in that table and update it, or insert a new group.
4. Read the finished groups back out of the temporary table.
5. Sort the groups again for the `ORDER BY`.

That is what `Extra: Using temporary; Using filesort` means, and the `EXPLAIN ANALYZE` tree in `evidence/task3_3_scale_test.txt` shows it literally: `Aggregate using temporary table`, then `Table scan on <temporary>` over 95,000 groups. In the measurement in section 3.9 that temporary-table work was the single largest item in the plan.

**The index that eliminates it.** An index whose leading column is the grouping expression, so the rows arrive already grouped and MySQL can aggregate them as a stream instead of building a table:

```sql
CREATE INDEX idx_users_role_id_name ON Users (Role, UserID, FullName);
```

With that index the plan changes from `Aggregate using temporary table` to a streaming `Group aggregate` and `Stream results`, and the temporary table disappears. The measured effect on 100,000 users and 1,000,000 enrolments is **821 ms → 360 ms**. Adding `FullName` makes the index covering, which removes the table lookups too.

Two notes. `Role` must lead the index, because the `WHERE` clause has to use it as a range; with the grouping columns behind it, the index serves the filter and the grouping at once. And `ORDER BY EnrolledCourses DESC` will still show `Using filesort` and always will, because it sorts an aggregate result. That sort is over the number of groups, not the number of rows, so at 200,000 users it is a sort of 200,000 values rather than a scan of a million rows.

### Q6 — Business question versus SQL question

*Task 3.1 asks for "students at risk". You interpreted that as students with no grades. A product manager might mean something different. How does the ambiguity in a business question lead to a technically correct but useless query? What should a developer do before writing a query for a vague requirement?*

A vague business question produces a query that is correct with respect to *some* interpretation and useless with respect to the question actually asked. Task 3.1 is the clean example: it correctly implements "students with 3 or more courses and no grades", and on the seed data it returns nothing at all. If the product manager meant "average grade below 5.0", or "missed more than 50% of lessons", or "submitted no assignments", the query answers a question nobody asked, and it does so silently: it returns a well-formed table with headers and no rows, which reads as "no students are at risk".

The chain of failure is the same each time. An ambiguity in the requirement is resolved by an unstated assumption in the code, the assumption is invisible in the output, and the output is trusted. The dangerous part is not that the assumption is wrong but that the report is empty, and an empty report looks like good news.

**What a developer should do before writing the query:**

1. **Write the interpretation down, in the business's words, before writing any SQL.** The handout asks for exactly this: "If you are unsure what the question means, state your interpretation explicitly before writing the query." The interpretation is a deliverable other people can correct.
2. **Go back to the person who asked, with the data attached.** Not an abstract question, but the consequence: "the three readings return 0, 3 and 11 students on the current data". A business question with numbers attached gets a decision; the same question without them gets a shrug.
3. **Ask what the report is for, and what happens on an empty result.** "Students at risk" is a trigger for intervention. An empty trigger list means either no intervention or a broken query, and the requester has to say which. The number of students is part of the requirement, not an output of it.
4. **Check the assumption against the data before building on it.** The check is cheap: count the students per interpretation. The moment Task 3.1's result came back empty, the question "is the rule right, or is the data just like this?" had to be answered first.
5. **Make the chosen definition visible in the output.** The column names in Task 3.1, `EnrolledCourseCount` and `UngradedCourseCount`, state the rule that produced the row. A reader who disagrees can see what they disagree with.

### Q7 — When LEFT JOIN breaks GROUP BY

*A student writes `SELECT c.Title, COUNT(*) AS EnrollmentCount FROM Courses c LEFT JOIN Enrollments e ON c.CourseID = e.CourseID GROUP BY c.CourseID, c.Title;`. For a course with zero enrolments, what does COUNT(*) return? Is that correct? What should the student use instead, and why?*

**What `COUNT(*)` returns: 1.** The `LEFT JOIN` still produces one row for Linear Algebra, the course row padded with NULLs on the right, and `COUNT(*)` counts rows rather than values, so it counts that padded row as one.

**Table 23 — `COUNT(*)` against `COUNT(e.EnrollID)`**

| CourseTitle | `COUNT(*)` | `COUNT(e.EnrollID)` |
|---|---|---|
| Introduction to Programming | 4 | 4 |
| Database Management | 3 | 3 |
| Calculus I | 2 | 2 |
| Data Structures | 2 | 2 |
| Linear Algebra | **1** | **0** |

**Is that correct? No.** The report would say one student is enrolled in Linear Algebra when nobody is. It is worse than an obvious error, because 1 is plausible: a course with a single student is something a real report sometimes shows, so the wrong number does not look wrong.

**What to use instead, and why.** `COUNT(e.EnrollID)`, or `COUNT(e.CourseID)`, or `COUNT(e.<any non-NULL column from the right table>)`. `COUNT(column)` counts the non-NULL values in that column, so on the padded row the expression evaluates to NULL and is not counted. The count is then 0, the correct answer for a course with no enrolments.

The general rule: after a `LEFT JOIN`, `COUNT(*)` counts the padding while every other aggregate is computed over the values. `SUM` and `AVG` ignore NULL and are correct on the padded row; `COUNT(*)` is the one that is not. The family of errors in this lab comes from the same place, a query that looks like it is counting relationships but is counting rows.

---

## Common mistakes

| Mistake | Why it is wrong | Do this instead |
|---|---|---|
| `WHERE` on an aggregate | The aggregate does not exist yet when `WHERE` runs | `HAVING` for conditions on groups |
| `COUNT(*)` after a `LEFT JOIN` | It counts the padded row, so a course with no enrolments reports 1 | `COUNT(e.EnrollID)`, which ignores NULL |
| `INNER JOIN` where `LEFT JOIN` is needed | Silently drops the rows with no match | Ask: do I want rows with no match? |
| `SUM(e.Grade) / COUNT(*)` | Divides by all rows, including the ungraded ones | `AVG(e.Grade)`, or `SUM(COALESCE(e.Grade,0)) / COUNT(*)` if the zeros are intended |
| `ORDER BY date LIMIT n` with no tie-break | The row at the boundary is not defined | Add the unique key: `ORDER BY e.EnrollDate DESC, e.EnrollID DESC` |
| Forgetting `u.Role = 'student'` | Instructors appear in student reports | Filter on `Role` whenever the report is about students |
| A `NOT EXISTS` correlated on the wrong grain | It answers a different question from the one asked | Scope the correlation to the whole course, and verify the row count against a second formulation |

---

## Part 7 checklist

| Item | Status |
|---|---|
| 1.1 Roster query written, correct `Role` filter applied | done, section 3.1 |
| 1.2 Both JOIN types tested, difference explained | done, section 3.2 — both return 5 rows, and why |
| 1.3 Correct `ORDER BY` and `LIMIT`, determinism discussed | done, section 3.3 — tie at the boundary found and fixed |
| 2.1 `LEFT JOIN` used, zero-enrolment courses visible | done, section 3.4 — Linear Algebra shows 0 |
| 2.1 Compared with the `INNER JOIN` version | done — 4 rows against 5 rows |
| 2.2 NULL grades excluded from average and count | done, section 3.5 |
| 2.2 `ROUND()` applied, `HAVING` used correctly | done — two courses, both with 3 graded students |
| 2.3 Absence count correct (`late` is not `absent`), `HAVING` applied | done, section 3.6 |
| 2.3 User 5's absence discussed | done — no data is not perfect attendance |
| 3.1 "ALL enrolments ungraded" logic correct | done, section 3.7 — `COUNT(e.Grade) = 0` |
| 3.1 Edge case (2 graded + 1 ungraded) walked through | done — Table 16, the probe student is excluded |
| 3.2 Two versions written (LEFT JOIN + NOT EXISTS) | done, section 3.8 |
| 3.2 Performance comparison discussed | done — measured at 1,000,000 rows, Table 20 |
| 3.3 `EXPLAIN` output reported with `type`, `key`, `rows` | done, section 3.9 — Table 21 |
| 3.3 Plain-language description of the plan | done — and measured at scale, Table 22 |
| Every query has a written explanation | done — one section per task |
| No query justified by an output hint | done — every result was inspected, including the empty ones |
| All queries tested against the seed data | done — all 14 files in `src/`, outputs in `evidence/` |

---

## Reflection

This lab was about the gap between a query that runs and a query that answers.

The three tasks that returned no rows taught me more than the ones that returned rows, because an empty result is the one that hides a mistake. There is nothing in the output to say the query was wrong. The three probes I ran inside rolled-back transactions turned rules I was asserting into rules I had watched work.

The trap in Task 3.2 was the sharpest lesson. The query was textbook `LEFT JOIN` with a NULL check, it ran cleanly, it returned six plausible rows, and it was still wrong, because the check has to be scoped to the whole course rather than to one lesson at a time.

I also stopped trusting the obvious answer about indexes. The index everyone would suggest for Task 3.3 barely moved the time, and the one that halved it was a wider index I would not have reached for on my own.

---

## Appendix A — Contents of the submission bundle {- .unnumbered}

| Path | Contents |
|---|---|
| `lab4_report/PDMLab4_sources_ITCSIU25055.zip` | the submission bundle: this report as a PDF, all the SQL, the evidence and the README |
| `lab4_report/src/00_schema.sql` | the six tables, exactly as the handout defines them |
| `lab4_report/src/01_seed.sql` | the seed data, exactly as the handout defines it |
| `lab4_report/src/02_task1_1_student_roster.sql` … `10_task3_3_explain.sql` | one file per task, each with the question, the query and the explanation |
| `lab4_report/src/11_scale_test_schema.sql`, `12_scale_test_data.sql` | the scale database: 100,000 users, 1,000,000 enrolments |
| `lab4_report/src/13_thinking_question_queries.sql` | the queries used to answer Part 8 |
| `lab4_report/src/14_scale_test_lessons_attendance.sql` | the scale database's lessons and 1,000,000 attendance rows |
| `lab4_report/evidence/*.txt` | the captured output of every query in this report |
| `lab4_report/PDMLab4_ITCSIU25055.docx` | the same report, editable |

AI use: Claude/OpenCode assisted with SQL authoring, testing against a live
MySQL 8.4 instance, performance measurement, and documentation.
