-- Lab 4 - Task 2.2: Average Grade by Course
--
-- Business question: the average grade per course, only for courses with at
-- least 2 grades actually recorded, not merely enrolled.
--
-- WHERE e.Grade IS NOT NULL removes the ungraded rows before the grouping, so
-- NULL grades enter neither the average nor the count. HAVING COUNT(e.Grade)
-- >= 2 keeps the groups with at least two real grades; it cannot go in WHERE,
-- because the groups do not exist when WHERE runs.
--
-- The handout also allows HAVING alone with a conditional count, since AVG
-- already ignores NULL. That returns the same rows. WHERE is kept because it
-- aggregates less data.
--
-- AVG(Grade) is not SUM(Grade)/COUNT(*): AVG divides by the non-NULL count,
-- SUM/COUNT(*) divides by all rows. The third query below shows all three
-- averages side by side.
--
-- Result: 2 courses, 3 graded students each.

USE educonnect;

-- Chosen version
SELECT c.Title                  AS CourseTitle,
       ROUND(AVG(e.Grade), 1)   AS AverageGrade,
       COUNT(e.Grade)           AS GradedStudentCount
FROM Courses c
JOIN Enrollments e ON c.CourseID = e.CourseID
WHERE e.Grade IS NOT NULL
GROUP BY c.CourseID, c.Title
HAVING COUNT(e.Grade) >= 2
ORDER BY AverageGrade DESC, c.Title;

-- Route B: HAVING alone, no WHERE (same rows, different plan)
SELECT c.Title                  AS CourseTitle,
       ROUND(AVG(e.Grade), 1)   AS AverageGrade,
       COUNT(e.Grade)           AS GradedStudentCount
FROM Courses c
JOIN Enrollments e ON c.CourseID = e.CourseID
GROUP BY c.CourseID, c.Title
HAVING COUNT(e.Grade) >= 2
ORDER BY AverageGrade DESC, c.Title;

-- AVG(Grade) compared with SUM(Grade) / COUNT(*), per course, no WHERE filter.
-- This is where the two expressions part company.
SELECT c.Title                       AS CourseTitle,
       COUNT(e.EnrollID)             AS EnrolledStudents,
       COUNT(e.Grade)                AS GradedStudents,
       ROUND(AVG(e.Grade), 4)        AS AvgIgnoringUngraded,
       ROUND(SUM(e.Grade) / COUNT(e.EnrollID), 4) AS SumDividedByEnrolled,
       ROUND(SUM(COALESCE(e.Grade, 0)) / COUNT(e.EnrollID), 4) AS AvgUngradedAsZero
FROM Courses c
JOIN Enrollments e ON c.CourseID = e.CourseID
GROUP BY c.CourseID, c.Title
ORDER BY c.CourseID;
