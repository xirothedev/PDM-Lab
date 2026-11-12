-- Lab 4 - Task 1.1: Student Roster
--
-- Business question: all students on the platform, sorted alphabetically by
-- name, showing name and email. Instructors must not appear.
--
-- Role is the only column that separates students from instructors, and the
-- ENUM guarantees the value is one of the two and never NULL. The filter is in
-- WHERE rather than in a join condition, because it depends on Users alone.
--
-- Role is reliable as a column but not as a fact: an instructor who is also
-- studying will not appear, so this answers "accounts whose role is student",
-- not "people who are studying".
--
-- Result: 5 students.

USE educonnect;

SELECT u.FullName,
       u.Email
FROM Users u
WHERE u.Role = 'student'
ORDER BY u.FullName;
