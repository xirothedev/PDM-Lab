-- Lab 4 - Task 3.3: EXPLAIN Analysis
--
-- The query under analysis is the one from the handout. On the seed data:
--   Users       type=ALL, key=NULL           full table scan, no index on Role
--   Enrollments type=ref, key=uq_enrollment   lookup through the unique key,
--                                             index only, table rows never read
--   Extra on Users: Using temporary; Using filesort
--                                             the GROUP BY needs a temporary
--                                             table, then a sort
--
-- rows in a classic EXPLAIN is an estimate, not a measurement: it reports 9
-- rows for a table that holds 8, and it drifts after inserts and rollbacks.
-- EXPLAIN ANALYZE reports the true figure because it executes the query.
--
-- The scale test (scripts/run_scale_evidence.sh) measures four index
-- configurations on 100,000 users and 1,000,000 enrolments:
--   no index on Role                                821 ms
--   + idx_users_role (Role)                         743 ms
--   + idx_users_role_id_name (Role,UserID,FullName)  360 ms
--   + same index, GROUP BY u.UserID only            304 ms
--
-- The index on the WHERE column barely moves the time: the table is cached,
-- so the sequential scan is already cheap, and the index lookup is random
-- access on top of it. The composite index pays because it is covering and
-- lets the plan aggregate as a stream instead of building a temporary table.
--
-- The index to add:
--   CREATE INDEX idx_users_role_id_name ON Users (Role, UserID, FullName);

USE educonnect;

-- The query under analysis
SELECT u.FullName, COUNT(e.EnrollID) AS EnrolledCourses
FROM Users u
LEFT JOIN Enrollments e ON u.UserID = e.UserID
WHERE u.Role = 'student'
GROUP BY u.UserID, u.FullName
HAVING COUNT(e.EnrollID) > 0
ORDER BY EnrolledCourses DESC;

-- Classic EXPLAIN
EXPLAIN SELECT u.FullName, COUNT(e.EnrollID) AS EnrolledCourses
FROM Users u
LEFT JOIN Enrollments e ON u.UserID = e.UserID
WHERE u.Role = 'student'
GROUP BY u.UserID, u.FullName
HAVING COUNT(e.EnrollID) > 0
ORDER BY EnrolledCourses DESC;

-- EXPLAIN ANALYZE: the plan with the real row counts and the real timings
EXPLAIN ANALYZE SELECT u.FullName, COUNT(e.EnrollID) AS EnrolledCourses
FROM Users u
LEFT JOIN Enrollments e ON u.UserID = e.UserID
WHERE u.Role = 'student'
GROUP BY u.UserID, u.FullName
HAVING COUNT(e.EnrollID) > 0
ORDER BY EnrolledCourses DESC;

-- The index experiment on the seed data.
-- On 8 rows the planner keeps the full scan even with the index present,
-- because a full scan of 8 rows is cheaper than any index lookup. The index
-- experiment only shows something at scale, which is why 11_scale_test_*.sql
-- exist.
CREATE INDEX idx_users_role_id_name ON Users (Role, UserID, FullName);
EXPLAIN SELECT u.FullName, COUNT(e.EnrollID) AS EnrolledCourses
FROM Users u
LEFT JOIN Enrollments e ON u.UserID = e.UserID
WHERE u.Role = 'student'
GROUP BY u.UserID, u.FullName
HAVING COUNT(e.EnrollID) > 0
ORDER BY EnrolledCourses DESC;
DROP INDEX idx_users_role_id_name ON Users;

-- Confirm the schema is back to the state the handout defines
SHOW INDEX FROM Users;
