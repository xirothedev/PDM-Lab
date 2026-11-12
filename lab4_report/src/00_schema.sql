-- Lab 4 - Part 4.0: EduConnect schema
DROP DATABASE IF EXISTS educonnect;
CREATE DATABASE educonnect
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE educonnect;

-- 1. Users (no FK dependencies)
CREATE TABLE Users (
  UserID     INT          NOT NULL AUTO_INCREMENT,
  FullName   VARCHAR(100) NOT NULL,
  Email      VARCHAR(150) NOT NULL,
  Role       ENUM('student', 'instructor') NOT NULL,
  CreatedAt  DATE         NOT NULL DEFAULT (CURRENT_DATE),
  PRIMARY KEY (UserID),
  UNIQUE KEY uq_email (Email)
);

-- 2. Departments (FK -> Users for ManagerID)
CREATE TABLE Departments (
  DeptID     INT          NOT NULL AUTO_INCREMENT,
  DeptName   VARCHAR(100) NOT NULL,
  ManagerID  INT          NULL,
  PRIMARY KEY (DeptID),
  CONSTRAINT fk_dept_manager
    FOREIGN KEY (ManagerID) REFERENCES Users(UserID)
    ON DELETE SET NULL
    ON UPDATE CASCADE
);

-- 3. Courses (FK -> Departments, Users)
CREATE TABLE Courses (
  CourseID     INT          NOT NULL AUTO_INCREMENT,
  Title        VARCHAR(150) NOT NULL,
  Credits      TINYINT      NOT NULL CHECK (Credits BETWEEN 1 AND 6),
  DeptID       INT          NOT NULL,
  InstructorID INT          NOT NULL,
  PRIMARY KEY (CourseID),
  CONSTRAINT fk_course_dept
    FOREIGN KEY (DeptID) REFERENCES Departments(DeptID)
    ON DELETE RESTRICT,
  CONSTRAINT fk_course_instructor
    FOREIGN KEY (InstructorID) REFERENCES Users(UserID)
    ON DELETE RESTRICT
);

-- 4. Enrollments (FK -> Users, Courses)
CREATE TABLE Enrollments (
  EnrollID   INT NOT NULL AUTO_INCREMENT,
  UserID     INT NOT NULL,
  CourseID   INT NOT NULL,
  EnrollDate DATE NOT NULL DEFAULT (CURRENT_DATE),
  Grade      DECIMAL(4,1) NULL,
  PRIMARY KEY (EnrollID),
  UNIQUE KEY uq_enrollment (UserID, CourseID),
  CONSTRAINT fk_enroll_user
    FOREIGN KEY (UserID) REFERENCES Users(UserID)
    ON DELETE CASCADE,
  CONSTRAINT fk_enroll_course
    FOREIGN KEY (CourseID) REFERENCES Courses(CourseID)
    ON DELETE CASCADE
);

-- 5. Lessons (FK -> Courses)
CREATE TABLE Lessons (
  LessonID      INT           NOT NULL AUTO_INCREMENT,
  CourseID      INT           NOT NULL,
  Title         VARCHAR(150)  NOT NULL,
  ScheduledDate DATE          NOT NULL,
  DurationMins  SMALLINT      NOT NULL CHECK (DurationMins > 0),
  PRIMARY KEY (LessonID),
  CONSTRAINT fk_lesson_course
    FOREIGN KEY (CourseID) REFERENCES Courses(CourseID)
    ON DELETE CASCADE
);

-- 6. Attendance (FK -> Lessons, Users)
CREATE TABLE Attendance (
  AttID    INT NOT NULL AUTO_INCREMENT,
  LessonID INT NOT NULL,
  UserID   INT NOT NULL,
  Status   ENUM('present', 'absent', 'late') NOT NULL,
  Note     VARCHAR(255) NULL,
  PRIMARY KEY (AttID),
  UNIQUE KEY uq_attendance (LessonID, UserID),
  CONSTRAINT fk_att_lesson
    FOREIGN KEY (LessonID) REFERENCES Lessons(LessonID)
    ON DELETE CASCADE,
  CONSTRAINT fk_att_user
    FOREIGN KEY (UserID) REFERENCES Users(UserID)
    ON DELETE CASCADE
);
