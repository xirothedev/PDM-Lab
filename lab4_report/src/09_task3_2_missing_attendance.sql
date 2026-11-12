-- Lab 4 - Task 3.2: The Missing Attendance Problem
--
-- Business question: students enrolled in a course who have NO attendance
-- records for any lesson in that course. Courses with no lessons are
-- excluded.
--
-- The scope is the pair (student, course). A student marked absent for
-- lesson 1 with no row for lesson 2 does have attendance records for the
-- course, so that pair must not be reported.
--
-- Version A joins Attendance with BOTH a.UserID = e.UserID and
-- a.LessonID = l.LessonID, groups by student and course, and keeps the groups
-- with COUNT(a.AttID) = 0. Version B asks the same question with NOT EXISTS.
--
-- The naive forms, a bare WHERE a.AttID IS NULL with no GROUP BY and a
-- NOT EXISTS correlated on the single lesson row, test one lesson at a time
-- and return 6 pairs instead of 4. The third query below keeps that
-- counter-example so the difference is visible.
--
-- Result: both correct versions return the same 4 pairs.
--
-- At 1,000,000 attendance rows (scripts/run_scale32_evidence.sh) the NOT
-- EXISTS version is about 2.5 times faster, because MySQL rewrites it into an
-- antijoin with a materialised subquery, while the LEFT JOIN version builds
-- 2,000,000 joined rows and a temporary table.

USE educonnect;

-- Version A: LEFT JOIN + NULL check, grouped at the student-course level
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

-- Version B: NOT EXISTS, scoped to the whole course
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

-- The naive LEFT JOIN, kept only as a counter-example. It reports 6 pairs
-- instead of 4 because it tests one lesson row at a time.
SELECT DISTINCT u.FullName AS StudentName,
                c.Title    AS CourseTitle
FROM Enrollments e
JOIN Users u   ON u.UserID   = e.UserID
JOIN Courses c ON c.CourseID = e.CourseID
JOIN Lessons l ON l.CourseID = c.CourseID
LEFT JOIN Attendance a ON a.UserID = e.UserID AND a.LessonID = l.LessonID
WHERE a.AttID IS NULL
ORDER BY u.FullName, c.Title;

-- The reasoning table behind the answer: attendance records per enrolled
-- student-course pair, out of the lessons that the course actually has.
SELECT u.FullName                          AS StudentName,
       c.Title                             AS CourseTitle,
       COUNT(DISTINCT l.LessonID)          AS LessonsInCourse,
       COUNT(a.AttID)                      AS AttendanceRecords,
       COUNT(e.EnrollID)                   AS Enrolled
FROM Enrollments e
JOIN Users u   ON u.UserID   = e.UserID
JOIN Courses c ON c.CourseID = e.CourseID
JOIN Lessons l ON l.CourseID = c.CourseID
LEFT JOIN Attendance a ON a.UserID = e.UserID AND a.LessonID = l.LessonID
GROUP BY u.UserID, c.CourseID
ORDER BY u.FullName, c.Title;

-- Courses with no lessons are excluded, and this shows which ones they are
SELECT c.CourseID, c.Title, COUNT(l.LessonID) AS Lessons
FROM Courses c
LEFT JOIN Lessons l ON l.CourseID = c.CourseID
GROUP BY c.CourseID, c.Title
HAVING COUNT(l.LessonID) = 0;
