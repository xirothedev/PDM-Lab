-- Lab 4 - Task 1.3: Recent Enrollments
--
-- Business question: the 5 most recent enrollment records with the student's
-- name, the course title and the enrollment date.
--
-- "Most recent" means ORDER BY EnrollDate DESC, and EnrollDate is a DATE, so
-- its resolution is one day. The seed data has three dates with two rows each
-- and one date with four rows, so the LIMIT cut falls inside the 2024-09-07
-- tie. With the date alone the fifth row is not determined, because MySQL may
-- return tied rows in any order.
--
-- e.EnrollID DESC fixes it. EnrollID is AUTO_INCREMENT, so a larger value means
-- a later insertion, and the key is unique, so the sort becomes total.
--
-- Result: 5 rows.

USE educonnect;

-- Chosen version (deterministic)
SELECT u.FullName AS StudentName,
       c.Title    AS CourseTitle,
       e.EnrollDate
FROM Enrollments e
JOIN Users u   ON u.UserID   = e.UserID
JOIN Courses c ON c.CourseID = e.CourseID
ORDER BY e.EnrollDate DESC, e.EnrollID DESC
LIMIT 5;

-- Comparison version (non-deterministic tie at the LIMIT boundary)
SELECT u.FullName AS StudentName,
       c.Title    AS CourseTitle,
       e.EnrollDate,
       e.EnrollID
FROM Enrollments e
JOIN Users u   ON u.UserID   = e.UserID
JOIN Courses c ON c.CourseID = e.CourseID
ORDER BY e.EnrollDate DESC
LIMIT 5;

-- How many rows share each date (this is where the tie comes from)
SELECT e.EnrollDate, COUNT(*) AS RowsOnThatDate
FROM Enrollments e
GROUP BY e.EnrollDate
ORDER BY e.EnrollDate DESC;
