-- Lab 4 - Task 3.1: Students at Risk
--
-- Business question: students enrolled in at least 3 courses who have not
-- received a grade in ANY of those courses. A student with even one graded
-- course is excluded.
--
-- JOIN + HAVING, no subquery. Both halves of the rule are conditions on a
-- group: COUNT(e.EnrollID) >= 3 is the number of courses, COUNT(e.Grade) = 0
-- is the number of graded courses. Neither can go in WHERE, because the
-- aggregate does not exist before the rows are grouped.
--
-- COUNT(e.Grade) is the graded count, so the ungraded count is published as
-- COUNT(e.EnrollID) - COUNT(e.Grade).
--
-- The trap: writing COUNT(e.Grade) = COUNT(e.EnrollID), or filtering with
-- WHERE e.Grade IS NULL and counting the survivors. That answers "students
-- whose most recent row happens to be ungraded" and would pass a student with
-- 3 courses of which 2 are graded. The probe below runs that case.
--
-- Result on the seed data: no rows. Only one student has 3 or more courses,
-- and that student has 2 grades, so the first test passes and the second
-- fails. No student has every enrollment ungraded, so the rule matches nobody
-- at any threshold. The probe below inserts a student with 3 ungraded
-- enrollments to show the logic works.

USE educonnect;

-- Chosen version (JOIN + HAVING, no subquery)
SELECT u.FullName                         AS StudentName,
       COUNT(e.EnrollID)                   AS EnrolledCourseCount,
       COUNT(e.EnrollID) - COUNT(e.Grade)  AS UngradedCourseCount
FROM Users u
JOIN Enrollments e ON u.UserID = e.UserID
WHERE u.Role = 'student'
GROUP BY u.UserID, u.FullName
HAVING COUNT(e.EnrollID) >= 3
   AND COUNT(e.Grade) = 0
ORDER BY u.FullName;

-- The query above returns no rows, and mysql prints nothing at all for an
-- empty result set, so the row count is shown separately to make the
-- evidence readable.
SELECT COUNT(*) AS RowsReturnedByTheQueryAbove FROM (
  SELECT u.FullName                         AS StudentName,
         COUNT(e.EnrollID)                   AS EnrolledCourseCount,
         COUNT(e.EnrollID) - COUNT(e.Grade)  AS UngradedCourseCount
  FROM Users u
  JOIN Enrollments e ON u.UserID = e.UserID
  WHERE u.Role = 'student'
  GROUP BY u.UserID, u.FullName
  HAVING COUNT(e.EnrollID) >= 3
     AND COUNT(e.Grade) = 0
) t;

-- The numbers behind the result: enrolled and graded per student
SELECT u.FullName       AS StudentName,
       COUNT(e.EnrollID) AS Enrolled,
       COUNT(e.Grade)    AS Graded,
       COUNT(e.EnrollID) - COUNT(e.Grade) AS Ungraded
FROM Users u
JOIN Enrollments e ON u.UserID = e.UserID
WHERE u.Role = 'student'
GROUP BY u.UserID, u.FullName
ORDER BY u.UserID;

-- Probe: a student with 3 courses and no grades at all, then rollback.
START TRANSACTION;
INSERT INTO Users (UserID, FullName, Email, Role, CreatedAt)
VALUES (99, 'PROBE Student', 'probe.student@edu.vn', 'student', '2024-09-10');
INSERT INTO Enrollments (EnrollID, UserID, CourseID, EnrollDate, Grade)
VALUES (901, 99, 1, '2024-09-10', NULL),
       (902, 99, 2, '2024-09-10', NULL),
       (903, 99, 3, '2024-09-10', NULL);
SELECT u.FullName                         AS StudentName,
       COUNT(e.EnrollID)                   AS EnrolledCourseCount,
       COUNT(e.EnrollID) - COUNT(e.Grade)  AS UngradedCourseCount
FROM Users u
JOIN Enrollments e ON u.UserID = e.UserID
WHERE u.Role = 'student'
GROUP BY u.UserID, u.FullName
HAVING COUNT(e.EnrollID) >= 3
   AND COUNT(e.Grade) = 0
ORDER BY u.FullName;

-- The trap case from the explanation: 3 courses, 2 graded, 1 not.
UPDATE Enrollments SET Grade = 8.0 WHERE EnrollID = 901;
UPDATE Enrollments SET Grade = 9.0 WHERE EnrollID = 902;
SELECT u.FullName                         AS StudentName,
       COUNT(e.EnrollID)                   AS EnrolledCourseCount,
       COUNT(e.EnrollID) - COUNT(e.Grade)  AS UngradedCourseCount
FROM Users u
JOIN Enrollments e ON u.UserID = e.UserID
WHERE u.Role = 'student'
GROUP BY u.UserID, u.FullName
HAVING COUNT(e.EnrollID) >= 3
   AND COUNT(e.Grade) = 0
ORDER BY u.FullName;
ROLLBACK;

-- Proof that the probe did not change the seed data
SELECT (SELECT COUNT(*) FROM Users)       AS UsersAfterRollback,
       (SELECT COUNT(*) FROM Enrollments) AS EnrollmentsAfterRollback;
