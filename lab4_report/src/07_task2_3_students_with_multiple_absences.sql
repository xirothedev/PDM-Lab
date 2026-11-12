-- Lab 4 - Task 2.3: Students With Multiple Absences
--
-- Business question: students recorded as absent more than once across any
-- lesson. Late arrivals do not count.
--
-- WHERE a.Status = 'absent' filters the rows before the grouping, so the
-- groups are built from absences alone and the count in HAVING counts
-- absences. With the status test in HAVING, COUNT(*) would count every
-- attendance row and the threshold would mean "attended more than one lesson"
-- instead of "was absent more than once".
--
-- Result on the seed data: no rows. The seed holds exactly two absent rows,
-- one per student, so nobody reaches the threshold of two. The probe below
-- adds one more inside a transaction to show the threshold works.
--
-- Hoang Van Em has no attendance rows at all, so he does not appear. That is
-- not perfect attendance, it is no data: a report has to publish the number of
-- attendance records next to the number of absences to tell the two apart.

USE educonnect;

-- Chosen version
SELECT u.FullName AS StudentName,
       COUNT(*)   AS AbsenceCount
FROM Attendance a
JOIN Users u ON u.UserID = a.UserID
WHERE a.Status = 'absent'
GROUP BY u.UserID, u.FullName
HAVING COUNT(*) > 1
ORDER BY AbsenceCount DESC, u.FullName;

-- The query above returns no rows, and mysql prints nothing at all for an
-- empty result set, so the row count is shown separately to make the
-- evidence readable.
SELECT COUNT(*) AS RowsReturnedByTheQueryAbove FROM (
  SELECT u.FullName AS StudentName,
         COUNT(*)   AS AbsenceCount
  FROM Attendance a
  JOIN Users u ON u.UserID = a.UserID
  WHERE a.Status = 'absent'
  GROUP BY u.UserID, u.FullName
  HAVING COUNT(*) > 1
) t;

-- Supporting counts: who has absences, and who has no attendance data at all
-- COUNT(CASE WHEN ...) is used instead of SUM(a.Status = 'absent') because
-- SUM over an empty set of non-NULL values returns NULL, not 0. For Hoang Van
-- Em the LEFT JOIN produces one padded row whose Status is NULL, and
-- NULL = 'absent' evaluates to NULL, so SUM would publish NULL for him.
SELECT u.FullName                            AS StudentName,
       COUNT(a.AttID)                       AS AttendanceRecords,
       COUNT(CASE WHEN a.Status = 'absent' THEN 1 END) AS Absences,
       COUNT(CASE WHEN a.Status = 'late'   THEN 1 END) AS LateArrivals
FROM Users u
LEFT JOIN Attendance a ON a.UserID = u.UserID
WHERE u.Role = 'student'
GROUP BY u.UserID, u.FullName
ORDER BY u.FullName;

-- Probe: add one more absence for Le Van Cuong, re-run the query, roll back.
START TRANSACTION;
INSERT INTO Attendance (LessonID, UserID, Status, Note)
VALUES (2, 3, 'absent', 'PROBE - rolled back');
SELECT u.FullName AS StudentName,
       COUNT(*)   AS AbsenceCount
FROM Attendance a
JOIN Users u ON u.UserID = a.UserID
WHERE a.Status = 'absent'
GROUP BY u.UserID, u.FullName
HAVING COUNT(*) > 1
ORDER BY AbsenceCount DESC, u.FullName;
ROLLBACK;

-- Proof that the probe did not change the seed data
SELECT COUNT(*) AS AttendanceRowsAfterRollback FROM Attendance;
