-- Lab 4 - Task 1.2: Courses With Their Department
--
-- Business question: each course title, its credit count and the name of its
-- department. Include all courses, even if something about the department data
-- is unusual.
--
-- LEFT JOIN, because the requirement is to include every course.
--
-- Both versions return 5 rows here, and that is not an accident: DeptID is
-- NOT NULL and fk_course_dept uses ON DELETE RESTRICT, so a course can never
-- have a missing department in this schema. LEFT JOIN states the intent and
-- stays correct if the constraint is relaxed or the data is loaded from
-- outside the schema.
--
-- Result: 5 courses, with either JOIN type.

USE educonnect;

-- Chosen version
SELECT c.Title   AS CourseTitle,
       c.Credits AS Credits,
       d.DeptName AS DepartmentName
FROM Courses c
LEFT JOIN Departments d ON c.DeptID = d.DeptID
ORDER BY c.Title;

-- Comparison version (run to show the difference)
SELECT c.Title   AS CourseTitle,
       c.Credits AS Credits,
       d.DeptName AS DepartmentName
FROM Courses c
INNER JOIN Departments d ON c.DeptID = d.DeptID
ORDER BY c.Title;
