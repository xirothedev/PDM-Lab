-- Lab 4 - Part 8: the queries used to answer the thinking questions.
--
-- Q1  the three averages for the same course
-- Q2  the join order MySQL chooses and the row estimates behind it
-- Q3  the two routes for Task 2.2, with their EXPLAIN
-- Q7  COUNT(*) against COUNT(e.EnrollID) after a LEFT JOIN
--
-- Q4 and Q6 are reasoning questions and need no new query.

USE educonnect;

-- Q1: three different averages for the same course, side by side.
--   AvgIgnoringUngraded  - AVG(Grade): the 20 students in the handout example
--   AvgUngradedAsZero    - SUM(COALESCE(Grade,0)) / COUNT(*): ungraded counts
--                          as a zero
--   AvgUngradedAsZeroN   - the same thing written as AVG(COALESCE(Grade,0)),
--                          which is the shortest correct form
SELECT c.Title                                     AS CourseTitle,
       COUNT(e.EnrollID)                           AS EnrolledStudents,
       COUNT(e.Grade)                              AS GradedStudents,
       ROUND(AVG(e.Grade), 4)                      AS AvgIgnoringUngraded,
       ROUND(SUM(e.Grade) / COUNT(e.EnrollID), 4)  AS AvgUngradedAsZero,
       ROUND(AVG(COALESCE(e.Grade, 0)), 4)         AS AvgUngradedAsZeroN
FROM Courses c
JOIN Enrollments e ON c.CourseID = e.CourseID
GROUP BY c.CourseID, c.Title
ORDER BY c.CourseID;

-- Q2: the join order MySQL chooses, and the row estimates that drive it
EXPLAIN SELECT u.FullName, c.Title, COUNT(e.EnrollID)
FROM Users u
JOIN Enrollments e ON u.UserID   = e.UserID
JOIN Courses c    ON c.CourseID = e.CourseID
WHERE u.Role = 'student'
GROUP BY u.UserID, c.CourseID;

-- Q3 route A: HAVING
EXPLAIN SELECT c.Title, ROUND(AVG(e.Grade), 1) AS AverageGrade, COUNT(e.Grade) AS GradedStudentCount
FROM Courses c
JOIN Enrollments e ON c.CourseID = e.CourseID
WHERE e.Grade IS NOT NULL
GROUP BY c.CourseID, c.Title
HAVING COUNT(e.Grade) >= 2
ORDER BY AverageGrade DESC;

-- Q3 route B: derived table in the FROM clause
EXPLAIN SELECT d.CourseTitle, d.AverageGrade, d.GradedStudentCount
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

-- Q3: both routes produce the same rows
SELECT c.Title                  AS CourseTitle,
       ROUND(AVG(e.Grade), 1)   AS AverageGrade,
       COUNT(e.Grade)           AS GradedStudentCount
FROM Courses c
JOIN Enrollments e ON c.CourseID = e.CourseID
WHERE e.Grade IS NOT NULL
GROUP BY c.CourseID, c.Title
HAVING COUNT(e.Grade) >= 2;

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
WHERE d.GradedStudentCount >= 2;

-- Q7: COUNT(*) against COUNT(e.EnrollID) after a LEFT JOIN.
--   COUNT(*) counts the padded row, so it reports 1 for a course with no
--   enrollments. COUNT(e.EnrollID) ignores the NULL and reports 0.
SELECT c.Title           AS CourseTitle,
       COUNT(*)          AS CountStar,
       COUNT(e.EnrollID) AS CountEnrollID
FROM Courses c
LEFT JOIN Enrollments e ON c.CourseID = e.CourseID
GROUP BY c.CourseID, c.Title
ORDER BY c.CourseID;
