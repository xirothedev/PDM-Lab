-- Lab 6 supporting DB objects: view + stored procedures referenced by the Java code.
-- Run once against educonnect.

USE educonnect;

-- StudentProgressReport view: per-student enrolment count and average grade.
DROP VIEW IF EXISTS StudentProgressReport;
CREATE VIEW StudentProgressReport AS
SELECT u.UserID,
       u.FullName AS StudentName,
       COUNT(e.EnrollID) AS TotalEnrolled,
       AVG(e.Grade) AS AverageGrade
FROM Users u
LEFT JOIN Enrollments e ON u.UserID = e.UserID
WHERE u.Role = 'student'
GROUP BY u.UserID, u.FullName;

-- EnrollStudent: validates and inserts an enrolment, returns a message via OUT param.
DROP PROCEDURE IF EXISTS EnrollStudent;
DELIMITER $$
CREATE PROCEDURE EnrollStudent(IN pUserID INT, IN pCourseID INT, OUT pMessage VARCHAR(255))
BEGIN
    DECLARE vRole VARCHAR(20);
    SELECT Role INTO vRole FROM Users WHERE UserID = pUserID;
    IF vRole IS NULL THEN
        SET pMessage = 'ERROR: user not found';
    ELSEIF vRole = 'instructor' THEN
        SET pMessage = 'ERROR: instructors cannot enroll in courses';
    ELSEIF NOT EXISTS (SELECT 1 FROM Courses WHERE CourseID = pCourseID) THEN
        SET pMessage = 'ERROR: course not found';
    ELSEIF EXISTS (SELECT 1 FROM Enrollments WHERE UserID = pUserID AND CourseID = pCourseID) THEN
        SET pMessage = 'ERROR: already enrolled in this course';
    ELSE
        INSERT INTO Enrollments (UserID, CourseID, EnrollDate) VALUES (pUserID, pCourseID, CURDATE());
        SET pMessage = CONCAT('Enrolled successfully (EnrollID=', LAST_INSERT_ID(), ')');
    END IF;
END$$
DELIMITER ;

-- GetCourseReport: returns enrolment report rows for a course.
DROP PROCEDURE IF EXISTS GetCourseReport;
DELIMITER $$
CREATE PROCEDURE GetCourseReport(IN pCourseID INT)
BEGIN
    SELECT u.FullName,
           e.EnrollDate,
           COALESCE(CAST(e.Grade AS CHAR), 'N/A') AS GradeDisplay
    FROM Enrollments e
    JOIN Users u ON e.UserID = u.UserID
    WHERE e.CourseID = pCourseID
    ORDER BY u.FullName;
END$$
DELIMITER ;
