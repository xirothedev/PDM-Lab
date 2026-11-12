-- Lab 4 - Part 4.1: EduConnect seed data (verbatim from the handout)
USE educonnect;

-- Seed: Users
INSERT INTO Users (UserID, FullName, Email, Role, CreatedAt) VALUES
(1, 'Nguyen Van An',    'an.nguyen@edu.vn',   'student',    '2024-09-01'),
(2, 'Tran Thi Bich',    'bich.tran@edu.vn',    'student',    '2024-09-01'),
(3, 'Le Van Cuong',     'cuong.le@edu.vn',     'student',    '2024-09-02'),
(4, 'Pham Thi Dung',    'dung.pham@edu.vn',   'student',    '2024-09-02'),
(5, 'Hoang Van Em',     'em.hoang@edu.vn',     'student',    '2024-09-03'),
(6, 'Dr. Minh Tuan',    'tuan.minh@edu.vn',   'instructor', '2024-08-01'),
(7, 'Dr. Lan Anh',      'lan.anh@edu.vn',     'instructor', '2024-08-01'),
(8, 'Dr. Thanh Hung',   'hung.thanh@edu.vn',  'instructor', '2024-08-15');

-- Seed: Departments
INSERT INTO Departments (DeptID, DeptName, ManagerID) VALUES
(1, 'Computer Science', 6),
(2, 'Mathematics',      7);

-- Seed: Courses
INSERT INTO Courses (CourseID, Title, Credits, DeptID, InstructorID) VALUES
(1, 'Introduction to Programming', 3, 1, 6),
(2, 'Database Management',         3, 1, 6),
(3, 'Calculus I',                  4, 2, 7),
(4, 'Data Structures',             3, 1, 8),
(5, 'Linear Algebra',              3, 2, 7);

-- Seed: Enrollments (CourseID 5 has NO enrollments - intentional)
INSERT INTO Enrollments (EnrollID, UserID, CourseID, EnrollDate, Grade) VALUES
(1, 1, 1, '2024-09-05', 8.5),
(2, 1, 2, '2024-09-05', 7.0),
(3, 1, 3, '2024-09-06', NULL),
(4, 2, 1, '2024-09-05', 9.0),
(5, 2, 2, '2024-09-05', 6.5),
(6, 3, 1, '2024-09-07', 5.0),
(7, 3, 4, '2024-09-07', NULL),
(8, 4, 2, '2024-09-08', 8.0),
(9, 4, 3, '2024-09-08', 7.5),
(10, 5, 1, '2024-09-09', NULL),
(11, 5, 4, '2024-09-09', 6.0);

-- Seed: Lessons
INSERT INTO Lessons (LessonID, CourseID, Title, ScheduledDate, DurationMins) VALUES
(1, 1, 'Variables and Types',    '2024-09-10', 90),
(2, 1, 'Control Flow',           '2024-09-17', 90),
(3, 2, 'ER Diagrams',            '2024-09-11', 90),
(4, 2, 'Relational Algebra',     '2024-09-18', 90),
(5, 3, 'Limits and Continuity', '2024-09-12', 90);

-- Seed: Attendance (User 5 has no attendance records - intentional)
INSERT INTO Attendance (AttID, LessonID, UserID, Status, Note) VALUES
(1, 1, 1, 'present', NULL),
(2, 1, 2, 'present', NULL),
(3, 1, 3, 'absent', 'Sick'),
(4, 1, 4, 'late',    'Traffic'),
(5, 2, 1, 'present', NULL),
(6, 2, 2, 'absent',  NULL),
(7, 3, 1, 'present', NULL),
(8, 3, 4, 'present', NULL),
(9, 4, 1, 'late',    'Connection issues');
