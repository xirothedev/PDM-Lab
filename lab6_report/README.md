# Lab 6 — Java + MySQL: Connect, Query & Stay Safe

Course **IT079IU** · Principles of Database Management · Lab 6
**Le Thanh Trung** · Student ID **ITCSIU25055**

Submission bundle for the EduConnect lab. The report is the PDF inside the
zip; everything else is the Java source it refers to and the captured output
of every demonstration.

---

## Contents

| File | What it is |
|---|---|
| `PDMLab6_ITCSIU25055_LeThanhTrung.pdf` (in zip) | the report, rendered from `report_source.md` |
| `PDMLab6_ITCSIU25055.docx` | the same report, editable |
| `project/` | Maven project (`educonnect` package) with all Java classes |
| `src/00_db_objects.sql` | view + stored procedures the Java code calls |
| `evidence/*.txt` | captured output of every demonstration |
| `README.md` | this file |

---

## Running it

Requires MySQL 8.x on port 33306 (see `lab4_report/docker-compose.yml`) and
JDK 17+.

```bash
# 1. create the supporting DB objects
docker exec -i lab4_report-mysql-1 mysql -uroot -proot educonnect \
    < lab6_report/src/00_db_objects.sql

# 2. build the Java project
cd lab6_report/project
export JAVA_HOME=/Library/Java/JavaVirtualMachines/temurin-25.jdk/Contents/Home
mvn compile

# 3. run a demo
CP="target/classes:/Users/.../.m2/repository/com/mysql/mysql-connector-j/8.4.0/mysql-connector-j-8.4.0.jar"
java -cp "$CP" educonnect.ConnectionTest
```

The seed data is reused from Lab 4 and was not modified (one extra
enrolment row added by the demo is removed afterwards).
