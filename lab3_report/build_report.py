"""Build Lab 3 submission HTML from verified artifacts, then render PDF via weasyprint CLI."""

import html

WS = "/Users/xirothedev/workspace/PDM-Lab"
R = WS + "/lab3_report"

sql = open(WS + "/create_coursemanagement.sql", encoding="utf-8").read()
sql_esc = html.escape(sql)

FIG = lambda f, cap: f'<figure><img src="{f}"/><figcaption>{cap}</figcaption></figure>'

body = f"""
<h1>IT079IU - Principles of Database Management - Lab 3</h1>
<p><b>Le Thanh Trung - ITCSIU25055 - Lab 3</b> (From ER Diagram to a Running Database: MySQL, CREATE and Constraints)</p>
<p>Engines: local MySQL 8.4.11 (Docker, marker parity) + TiDB Serverless 8.0.11-TiDB-v8.5.3 (assigned server). Script runs twice clean on both.</p>

<h2>0. Pre-lab evidence</h2>
{FIG("fig_A_version.png", "Fig A - TiDB version + engine: 8.0.11-TiDB-v8.5.3, InnoDB. Local MySQL 8.4.11 verified via CLI (SELECT VERSION, script re-run).")}
<p>Local MySQL 8.4 container <code>pdmlab-mysql84</code> on localhost:3306; Workbench connection PDM LAB targets TiDB. No passwords in screenshots.</p>

<h2>Part B.1 - Relation schema (comment block at top of script)</h2>
<p>Full schema with underlined PKs, *-marked FKs and separately stated referential constraints is the header comment of <code>create_coursemanagement.sql</code> (reproduced in the script listing below).</p>

<h2>Part B - Database build evidence</h2>
{FIG("fig_B_schema_tree.png", "Fig B - SCHEMAS panel: CourseManagement has 7 tables (Course, Department, Lecturer, LecturerPhone, Register, Student, Teach) + Views &gt; StudentWithAge.")}
{FIG("fig_B_course.png", "Fig B.7-1 - Course incl. Credits from ALTER (IT079IU uses DEFAULT 3). 5 rows.")}
{FIG("fig_B_join.png", "Fig B.7-2 - Student JOIN Register, 14 rows incl. one NULL grade (registered, not yet graded).")}
{FIG("fig_B_phones.png", "Fig B.7-3 - LecturerPhone, 6 rows for 5 lecturers.")}
{FIG("fig_B_view.png", "Fig B.4 - StudentWithAge view computes Age at query time (22). Age is never stored.")}
{FIG("fig_B_constraints.png", "Fig - INFORMATION_SCHEMA.TABLE_CONSTRAINTS for CourseManagement (PK/FK/UQ names; CHECKs enforced - see Part C).")}
<p>Counts exceed minima: 4 departments, 6 lecturers, 8 students, 5 courses, 14 registrations, phones for 5 lecturers. ALTERs: <code>Course ADD Credits</code> (column) + <code>LecturerPhone ADD CK_Phone_Length</code> (constraint). Third CHECK pair: CK_Student_DoB, CK_Register_Grade.</p>
<p>Precision note: Register.Grade is DECIMAL(5,2), not the snippet's 4,2 - with 4,2 a grade of 150 dies on the column range (ERROR 1264) and the named CHECK never fires. 5,2 lets the value exist so CK_Register_Grade is what rejects it.</p>

<h2>Part C - Constraint proofs (MySQL 8.4.11 exact errors; TiDB screenshots where provided)</h2>
<table border="1" cellpadding="4">
<tr><th>#</th><th>Statement</th><th>MySQL 8.4 result</th><th>Enforcer</th></tr>
<tr><td>1</td><td><code>INSERT INTO Register VALUES ('IT09999','IT079IU',50.00)</code></td><td>ERROR 1452 (23000): Cannot add or update a child row: a foreign key constraint fails (CONSTRAINT FK_Register_Student)</td><td>FK_Register_Student</td></tr>
<tr><td>2</td><td><code>INSERT INTO Student ... ('ITITIU1001',...)</code></td><td>ERROR 1062 (23000): Duplicate entry 'ITITIU1001' for key 'Student.PRIMARY'</td><td>PRIMARY</td></tr>
<tr><td>3</td><td><code>INSERT INTO Student ... ('ITITIU1009',...,'2150-01-01',...)</code></td><td>ERROR 3819 (HY000): Check constraint 'CK_Student_DoB' is violated.</td><td>CK_Student_DoB</td></tr>
<tr><td>4</td><td><code>INSERT INTO Register VALUES ('ITITIU1007','IT045IU',150.00)</code></td><td>ERROR 3819 (HY000): Check constraint 'CK_Register_Grade' is violated.</td><td>CK_Register_Grade</td></tr>
<tr><td>5</td><td><code>DELETE FROM Course WHERE CourseID='IT079IU'</code></td><td>ERROR 1451 (23000): Cannot delete or update a parent row: a foreign key constraint fails (CONSTRAINT FK_Register_Course)</td><td>FK_Register_Course</td></tr>
</table>
{FIG("fig_C1_fk.png", "Fig C1 - TiDB rejects case 1 with the same 1452 / FK_Register_Student.")}
{FIG("fig_C2_dup.png", "Fig C2 - TiDB rejects case 2 with 1062 for key Student.PRIMARY (value masked as '?' by this Workbench build; MySQL 8.4 names the value).")}
{FIG("fig_C3_tidb.png", "Fig C3 - HONEST DISCLOSURE: on TiDB Serverless this statement returned OK, 1 row affected - CK_Student_DoB did NOT fire there. On MySQL 8.4.11 the same statement is rejected with ERROR 3819 above. The stray TiDB row (ITITIU1009) is test pollution only; the submitted MySQL dump is unaffected. Cleanup: DELETE FROM Student WHERE StudentID='ITITIU1009'.")}
<p>Cases 4-5: no Workbench screenshots were provided; evidence is the CLI-captured MySQL 8.4 errors above (each statement run individually). Schema-vs-application (0.5): constraints live in the schema so every access path - any app, notebook, dump-restore, manual SQL - is checked by the engine. App-side checks only cover the paths the app implements; a second client, a forgotten form, or a raw INSERT bypasses them silently.</p>

<h2>Part D - Database diagram (generated from the live schema)</h2>
{FIG("fig_D_eer.png", "Fig D - Database diagram generated from the database itself (CREATE TABLE + INFORMATION_SCHEMA), not hand-drawn. Red edges are FKs. Workbench 26.7.0 (this install) has no Database &gt; Reverse Engineer - its Database menu is HeatWave-branded - so the EER was rendered from live schema metadata instead.")}
<p><b>D1 - two things from the ER diagram (sec 3) gone from the DB diagram:</b> (1) the derived attribute Age - never stored, computed at query time by the StudentWithAge view; (2) the relationship diamonds Belong/Register/Teach and the multivalued Phone - Belong became the FK column Lecturer.DeptNo, Register and Teach became tables with two FKs each, Phone became the LecturerPhone table. A relationship cannot hold rows; only an entity table can.<br/>
<b>D2 - Register as a table with two FKs:</b> produced by the M:N relationship Register (Student-Course) carrying Grade. It could not stay a relationship because the relational model has no relationship construct - to store one grade per (student, course) pair and enforce both referential lines, the M:N must be mapped to its own table with a composite PK and two FKs.</p>

<h2>Part E - Backup and restore</h2>
<p>Submission dump (MySQL 8.4): <code>mysqldump -uroot --databases CourseManagement --routines --triggers &gt; CourseManagement_backup.sql</code> (268 lines, 7 CREATE TABLE, Grade decimal(5,2)). Restore path: table-only dump into CM_Restored. TiDB pair used <code>--no-tablespaces</code>. No screenshots were provided for this step; counts below are CLI-verified on both engines.</p>
<table border="1" cellpadding="4">
<tr><th>db</th><th>regs</th><th>studs</th><th>courses</th></tr>
<tr><td>CourseManagement</td><td>14</td><td>8</td><td>5</td></tr>
<tr><td>CM_Restored</td><td>14</td><td>8</td><td>5</td></tr>
</table>
<p>Counts match on MySQL 8.4.11 and on TiDB (14/8/5 both databases).</p>

<h2>Attachments</h2>
<p><code>create_coursemanagement.sql</code> (runs twice clean on fresh MySQL 8.4 and on TiDB) and <code>CourseManagement_backup.sql</code> (MySQL 8.4 logical dump with CREATE DATABASE/USE).</p>

<h2>Script listing</h2>
<pre>{sql_esc}</pre>

<p>AI use: Claude/OpenCode assisted with script authoring, testing, and documentation.</p>
"""

html_doc = f"""<!DOCTYPE html><html><head><meta charset="utf-8">
<style>
body {{ font-family: Helvetica, Arial, sans-serif; font-size: 11px; margin: 40px; color: #111; }}
h1 {{ font-size: 20px; }} h2 {{ font-size: 15px; margin-top: 28px; border-bottom: 1px solid #999; padding-bottom: 4px; }}
figure {{ margin: 12px 0; }} img {{ max-width: 100%; border: 1px solid #ccc; }}
figcaption {{ font-size: 10px; color: #333; margin-top: 4px; }}
pre {{ font-size: 8.5px; background: #f6f6f6; padding: 10px; white-space: pre-wrap; border: 1px solid #ddd; }}
table {{ border-collapse: collapse; font-size: 10px; }} th, td {{ border: 1px solid #999; padding: 4px 6px; text-align: left; }}
code {{ font-size: 10px; }}
</style></head><body>{body}</body></html>"""

open(R + "/report.html", "w", encoding="utf-8").write(html_doc)
print("wrote report.html", len(html_doc))
