-- MySQL dump 10.13  Distrib 8.4.11, for Linux (aarch64)
--
-- Host: localhost    Database: CourseManagement
-- ------------------------------------------------------
-- Server version	8.4.11

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Current Database: `CourseManagement`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `CourseManagement` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;

USE `CourseManagement`;

--
-- Table structure for table `Course`
--

DROP TABLE IF EXISTS `Course`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Course` (
  `CourseID` char(8) NOT NULL,
  `CourseName` varchar(60) NOT NULL,
  `Credits` tinyint unsigned NOT NULL DEFAULT '3',
  PRIMARY KEY (`CourseID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Course`
--

LOCK TABLES `Course` WRITE;
/*!40000 ALTER TABLE `Course` DISABLE KEYS */;
INSERT INTO `Course` VALUES ('IT003IU','Data Structures and Algorithms',3),('IT005IU','Object-Oriented Programming',3),('IT012IU','Computer Networks',3),('IT045IU','Machine Learning Fundamentals',2),('IT079IU','Principles of Database Management',3);
/*!40000 ALTER TABLE `Course` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Department`
--

DROP TABLE IF EXISTS `Department`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Department` (
  `DeptNo` char(4) NOT NULL,
  `DeptName` varchar(60) NOT NULL,
  PRIMARY KEY (`DeptNo`),
  CONSTRAINT `CK_Department_DeptNo_Format` CHECK ((char_length(`DeptNo`) = 4))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Department`
--

LOCK TABLES `Department` WRITE;
/*!40000 ALTER TABLE `Department` DISABLE KEYS */;
INSERT INTO `Department` VALUES ('BIOT','Biotechnology'),('CSEN','Computer Science and Engineering'),('ISYS','Information Systems'),('MATH','Mathematics and Statistics');
/*!40000 ALTER TABLE `Department` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Lecturer`
--

DROP TABLE IF EXISTS `Lecturer`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Lecturer` (
  `LecturerID` char(6) NOT NULL,
  `LecturerName` varchar(60) NOT NULL,
  `DeptNo` char(4) NOT NULL,
  PRIMARY KEY (`LecturerID`),
  KEY `FK_Lecturer_Department` (`DeptNo`),
  CONSTRAINT `FK_Lecturer_Department` FOREIGN KEY (`DeptNo`) REFERENCES `Department` (`DeptNo`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Lecturer`
--

LOCK TABLES `Lecturer` WRITE;
/*!40000 ALTER TABLE `Lecturer` DISABLE KEYS */;
INSERT INTO `Lecturer` VALUES ('LE0001','Dr. Nguyen Van Hien','ISYS'),('LE0002','Dr. Tran Thi Lan','ISYS'),('LE0003','Dr. Le Hoang Nam','CSEN'),('LE0004','MSc. Pham Minh Tuan','CSEN'),('LE0005','Dr. Vo Thi Kim Ngan','MATH'),('LE0006','MSc. Doan Gia Khang','BIOT');
/*!40000 ALTER TABLE `Lecturer` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `LecturerPhone`
--

DROP TABLE IF EXISTS `LecturerPhone`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `LecturerPhone` (
  `LecturerID` char(6) NOT NULL,
  `Phone` varchar(15) NOT NULL,
  PRIMARY KEY (`LecturerID`,`Phone`),
  CONSTRAINT `FK_LecturerPhone_Lecturer` FOREIGN KEY (`LecturerID`) REFERENCES `Lecturer` (`LecturerID`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `CK_Phone_Length` CHECK ((char_length(`Phone`) between 7 and 15))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `LecturerPhone`
--

LOCK TABLES `LecturerPhone` WRITE;
/*!40000 ALTER TABLE `LecturerPhone` DISABLE KEYS */;
INSERT INTO `LecturerPhone` VALUES ('LE0001','02811335577'),('LE0001','0912345678'),('LE0002','0987654321'),('LE0003','0909123456'),('LE0004','0938112244'),('LE0005','0977333444');
/*!40000 ALTER TABLE `LecturerPhone` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Register`
--

DROP TABLE IF EXISTS `Register`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Register` (
  `StudentID` char(10) NOT NULL,
  `CourseID` char(8) NOT NULL,
  `Grade` decimal(5,2) DEFAULT NULL,
  PRIMARY KEY (`StudentID`,`CourseID`),
  KEY `FK_Register_Course` (`CourseID`),
  CONSTRAINT `FK_Register_Course` FOREIGN KEY (`CourseID`) REFERENCES `Course` (`CourseID`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `FK_Register_Student` FOREIGN KEY (`StudentID`) REFERENCES `Student` (`StudentID`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `CK_Register_Grade` CHECK ((`Grade` between 0 and 100))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Register`
--

LOCK TABLES `Register` WRITE;
/*!40000 ALTER TABLE `Register` DISABLE KEYS */;
INSERT INTO `Register` VALUES ('ITITIU1001','IT045IU',91.25),('ITITIU1001','IT079IU',85.50),('ITITIU1002','IT003IU',68.50),('ITITIU1002','IT079IU',72.00),('ITITIU1003','IT005IU',88.25),('ITITIU1003','IT079IU',90.00),('ITITIU1004','IT012IU',76.75),('ITITIU1004','IT079IU',NULL),('ITITIU1005','IT045IU',81.50),('ITITIU1005','IT079IU',64.00),('ITITIU1006','IT003IU',55.25),('ITITIU1006','IT079IU',93.00),('ITITIU1007','IT079IU',49.00),('ITITIU1008','IT079IU',78.00);
/*!40000 ALTER TABLE `Register` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `Student`
--

DROP TABLE IF EXISTS `Student`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Student` (
  `StudentID` char(10) NOT NULL,
  `StudentName` varchar(60) NOT NULL,
  `DoB` date NOT NULL,
  `Major` varchar(40) DEFAULT NULL,
  `Email` varchar(80) DEFAULT NULL,
  PRIMARY KEY (`StudentID`),
  UNIQUE KEY `UQ_Student_Email` (`Email`),
  CONSTRAINT `CK_Student_DoB` CHECK ((`DoB` between _latin1'1900-01-01' and _latin1'2026-10-15'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Student`
--

LOCK TABLES `Student` WRITE;
/*!40000 ALTER TABLE `Student` DISABLE KEYS */;
INSERT INTO `Student` VALUES ('ITITIU1001','Nguyen Minh Anh','2004-05-12','Information Systems','minhanh.nguyen@iu.edu.vn'),('ITITIU1002','Tran Quoc Bao','2003-11-02','Computer Science and Engineering','quocbao.tran@iu.edu.vn'),('ITITIU1003','Le Thi Hong Nhung','2004-03-25','Data Science','hongnhung.le@iu.edu.vn'),('ITITIU1004','Pham Duc Duy','2003-08-17','Information Systems','ducduy.pham@iu.edu.vn'),('ITITIU1005','Vo Thanh Truc','2004-12-09','Software Engineering','thanhtruc.vo@iu.edu.vn'),('ITITIU1006','Dang Ngoc Mai','2005-01-30','Computer Science and Engineering','ngocmai.dang@iu.edu.vn'),('ITITIU1007','Bui Tuan Kiet','2003-06-14','Information Systems','tuankiet.bui@iu.edu.vn'),('ITITIU1008','Hoang Thu Ha','2004-09-21','Data Science','thuha.hoang@iu.edu.vn');
/*!40000 ALTER TABLE `Student` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary view structure for view `StudentWithAge`
--

DROP TABLE IF EXISTS `StudentWithAge`;
/*!50001 DROP VIEW IF EXISTS `StudentWithAge`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `StudentWithAge` AS SELECT 
 1 AS `StudentID`,
 1 AS `StudentName`,
 1 AS `DoB`,
 1 AS `Major`,
 1 AS `Email`,
 1 AS `Age`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `Teach`
--

DROP TABLE IF EXISTS `Teach`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `Teach` (
  `CourseID` char(8) NOT NULL,
  `LecturerID` char(6) NOT NULL,
  PRIMARY KEY (`CourseID`,`LecturerID`),
  KEY `FK_Teach_Lecturer` (`LecturerID`),
  CONSTRAINT `FK_Teach_Course` FOREIGN KEY (`CourseID`) REFERENCES `Course` (`CourseID`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `FK_Teach_Lecturer` FOREIGN KEY (`LecturerID`) REFERENCES `Lecturer` (`LecturerID`) ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `Teach`
--

LOCK TABLES `Teach` WRITE;
/*!40000 ALTER TABLE `Teach` DISABLE KEYS */;
INSERT INTO `Teach` VALUES ('IT079IU','LE0001'),('IT079IU','LE0002'),('IT003IU','LE0003'),('IT005IU','LE0003'),('IT005IU','LE0004'),('IT012IU','LE0004'),('IT045IU','LE0005'),('IT045IU','LE0006');
/*!40000 ALTER TABLE `Teach` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'CourseManagement'
--

--
-- Current Database: `CourseManagement`
--

USE `CourseManagement`;

--
-- Final view structure for view `StudentWithAge`
--

/*!50001 DROP VIEW IF EXISTS `StudentWithAge`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = latin1 */;
/*!50001 SET character_set_results     = latin1 */;
/*!50001 SET collation_connection      = latin1_swedish_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `StudentWithAge` AS select `Student`.`StudentID` AS `StudentID`,`Student`.`StudentName` AS `StudentName`,`Student`.`DoB` AS `DoB`,`Student`.`Major` AS `Major`,`Student`.`Email` AS `Email`,timestampdiff(YEAR,`Student`.`DoB`,curdate()) AS `Age` from `Student` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-10-15  4:45:47
