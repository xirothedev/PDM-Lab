-- Lab 4 - Task 2.1: Enrollment Count Per Course
--
-- Business question: how many students are enrolled in each course, including
-- the courses with zero enrolments, which are flagged for review.
--
-- LEFT JOIN, because INNER JOIN leaves the zero-enrolment courses out of the
-- report entirely.
--
-- COUNT(e.EnrollID) returns 0 for a course with no enrolments: the LEFT JOIN
-- still produces one row, every right-side column in it is NULL, and COUNT
-- ignores NULL. COUNT(*) would return 1, because it counts the padded row.
--
-- Result: LEFT JOIN 5 rows (Linear Algebra 0), INNER JOIN 4 rows.

USE educonnect;

-- Chosen version
SELECT c.Title                AS CourseTitle,
       COUNT(e.EnrollID)      AS EnrollmentCount
FROM Courses c
LEFT JOIN Enrollments e ON c.CourseID = e.CourseID
GROUP BY c.CourseID, c.Title
ORDER BY EnrollmentCount DESC, c.Title;

-- Comparison version (run to show the difference)
SELECT c.Title                AS CourseTitle,
       COUNT(e.EnrollID)      AS EnrollmentCount
FROM Courses c
INNER JOIN Enrollments e ON c.CourseID = e.CourseID
GROUP BY c.CourseID, c.Title
ORDER BY EnrollmentCount DESC, c.Title;
