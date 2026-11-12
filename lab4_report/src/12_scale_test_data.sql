-- Lab 4 - Task 3.3 evidence: bulk data for the scale test
-- 100,000 users, 4,999 courses, 1,000,000 enrollments.
-- Lessons and Attendance are not populated: the Task 3.3 plan only reads Users and Enrollments.
USE educonnect_scale;

SET SESSION cte_max_recursion_depth = 1000000;

-- Users: every 20th user is an instructor (5,000 instructors, 95,000 students)
INSERT INTO Users (UserID, FullName, Email, Role, CreatedAt)
WITH RECURSIVE seq(n) AS (
  SELECT 1 UNION ALL SELECT n + 1 FROM seq WHERE n < 100000
)
SELECT n,
       CONCAT('User ', n),
       CONCAT('user', n, '@scale.test'),
       IF(n % 20 = 0, 'instructor', 'student'),
       '2024-01-01'
FROM seq;

-- Departments: 10 departments, each managed by an instructor
INSERT INTO Departments (DeptID, DeptName, ManagerID)
WITH RECURSIVE seq(n) AS (
  SELECT 1 UNION ALL SELECT n + 1 FROM seq WHERE n < 10
)
SELECT n, CONCAT('Dept ', n), n * 20
FROM seq;

-- Courses: 4,999 courses, instructors taken from the multiples of 20 (all instructors)
INSERT INTO Courses (CourseID, Title, Credits, DeptID, InstructorID)
WITH RECURSIVE seq(n) AS (
  SELECT 1 UNION ALL SELECT n + 1 FROM seq WHERE n < 4999
)
SELECT n, CONCAT('Course ', n), 3, (n % 10) + 1, ((n % 4999) + 1) * 20
FROM seq;

-- Enrollments: 1,000,000 rows, 10 per user.
-- Course index uses 4999 (coprime with 100000) so the (UserID, CourseID) unique key never collides.
-- Every 7th row has a NULL grade.
INSERT INTO Enrollments (UserID, CourseID, EnrollDate, Grade)
WITH RECURSIVE seq(n) AS (
  SELECT 1 UNION ALL SELECT n + 1 FROM seq WHERE n < 1000000
)
SELECT (n % 100000) + 1,
       (n % 4999) + 1,
       DATE_ADD('2024-01-01', INTERVAL (n % 300) DAY),
       IF(n % 7 = 0, NULL, ((n % 100) / 10) + 1)
FROM seq;

SELECT (SELECT COUNT(*) FROM Users)        AS users,
       (SELECT COUNT(*) FROM Courses)      AS courses,
       (SELECT COUNT(*) FROM Enrollments)  AS enrollments,
       (SELECT COUNT(*) FROM Enrollments WHERE Grade IS NULL) AS null_grades;
