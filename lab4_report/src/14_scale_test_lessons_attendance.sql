-- Lab 4 - Task 3.2 scale test data: Lessons and Attendance at 1,000,000 rows
--
-- The Task 3.3 scale database has 100,000 users, 4,999 courses and 1,000,000
-- enrollments. The two remaining tables are filled here so that the Task 3.2
-- query can be measured on a 1,000,000-row Attendance table.
--
-- Lessons: two per course, 9,998 rows. Lessons 1..4999 are the first lesson
-- of each course, lessons 5000..9998 the second.
--
-- Attendance: one row per enrollment, on the FIRST lesson of the course, so
-- the table holds exactly 1,000,000 rows.
--
-- With this construction every student has a record for the first lesson of
-- the course, so the "no attendance for any lesson" result set is empty by
-- construction. The workload is still real: the query has to look up the
-- attendance record for every one of the 1,000,000 enrollment rows, and the
-- two formulations differ in how many lookups they perform.
--   LEFT JOIN    joins every enrollment to both lessons of its course, so it
--                performs 2,000,000 attendance lookups.
--   NOT EXISTS   asks whether any lesson of the course has a record for this
--                student and stops at the first match, so it performs about
--                1,000,000 lookups.

USE educonnect_scale;

SET SESSION cte_max_recursion_depth = 1000000;

-- Lessons: two per course
INSERT INTO Lessons (LessonID, CourseID, Title, ScheduledDate, DurationMins)
WITH RECURSIVE seq(n) AS (
  SELECT 1 UNION ALL SELECT n + 1 FROM seq WHERE n < 9998
)
SELECT n, ((n - 1) % 4999) + 1, CONCAT('Lesson ', n), '2024-09-01', 90
FROM seq;

-- Attendance: one row per enrollment, on the first lesson of the course
INSERT INTO Attendance (LessonID, UserID, Status, Note)
SELECT l.LessonID, e.UserID, 'present', NULL
FROM Enrollments e
JOIN Lessons l ON l.CourseID = e.CourseID AND l.LessonID <= 4999;

SELECT (SELECT COUNT(*) FROM Lessons)     AS lessons,
       (SELECT COUNT(*) FROM Attendance) AS attendance;
