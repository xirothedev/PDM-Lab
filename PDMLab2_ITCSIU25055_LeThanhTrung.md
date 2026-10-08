Le Thanh Trung — ITCSIU25055 — Lab 2 (Relational Algebra / RelaX)

DB: Employee (Franklin University) in RelaX.
Schema: EMPLOYEE{Fname,Minit,Lname,Ssn,Bdate,Address,Sex,Salary,Super_ssn,Dno}
DEPARTMENT{Dname,Dnumber,Mgr_ssn,Mgr_start_date} DEPT_LOCATIONS{Dnumber,Dlocation}
PROJECT{Pname,Pnumber,Plocation,Dnum} WORKS_ON{Essn,Pno,Hours}
DEPENDENT{Essn,Dependent_name,Sex,Bdate,Relationship}
Note: Dno/Dnumber/Dnum, Ssn/Essn/Mgr_ssn/Super_ssn, Pnumber/Pno differ, so every
join below is a theta join with an explicit condition (natural join would miss).

Copy-paste RelaX block (execute line by line in RA mode):

```text
pi Fname, Lname (EMPLOYEE)
pi Fname, Lname (sigma Sex='F' (EMPLOYEE))
pi Fname, Lname, Dname (EMPLOYEE join EMPLOYEE.Dno = DEPARTMENT.Dnumber (DEPARTMENT))
pi Dname, Mgr_ssn (DEPARTMENT)
gamma Dno; AVG(Salary)->AvgSalary (EMPLOYEE)
gamma Dname; AVG(Salary)->AvgSalary (EMPLOYEE join EMPLOYEE.Dno = DEPARTMENT.Dnumber (DEPARTMENT))
pi Fname, Lname (EMPLOYEE join EMPLOYEE.Ssn = Nowork.Ssn (rho Nowork (pi Ssn (EMPLOYEE) - pi Essn -> Ssn (WORKS_ON))))
pi Fname, Lname, Dependent_name (EMPLOYEE join EMPLOYEE.Ssn = DEPENDENT.Essn (DEPENDENT))
pi Fname, Lname (EMPLOYEE join EMPLOYEE.Ssn = DEPARTMENT.Mgr_ssn (DEPARTMENT))
pi Fname, Lname (EMPLOYEE join EMPLOYEE.Ssn = WorkAll.Essn (rho WorkAll ((pi Essn, Pno (WORKS_ON)) / (rho Pnumber -> Pno (pi Pnumber (PROJECT))))))
S = pi Super_ssn -> Sup (sigma Ssn=123456789 (EMPLOYEE))
pi Fname, Lname (sigma Super_ssn = Sup AND Ssn != 123456789 (EMPLOYEE cross join S))
```
Renaming is written old -> new throughout. String literals use single quotes
as in the RelaX help (`sigma firstname = 'Bob' (Customer)`); numeric attributes
(Ssn, Salary, Dno, ...) take unquoted literals — quoting a number raises
a type error. AND is written uppercase.

Per-query math reference:

1. All employees: π Fname,Lname(EMPLOYEE)
2. Female: π Fname,Lname(σ Sex='F'(EMPLOYEE))
3. Employee + dept: π Fname,Lname,Dname(EMPLOYEE ⋈ EMPLOYEE.Dno=DEPARTMENT.Dnumber DEPARTMENT)
4. Dept + manager SSN: π Dname,Mgr_ssn(DEPARTMENT)
5. Avg salary per dept (extended RA γ): γ Dno; AVG(Salary)→AvgSalary(EMPLOYEE).
   With names: γ Dname; AVG(Salary)→AvgSalary(EMPLOYEE ⋈ EMPLOYEE.Dno=DEPARTMENT.Dnumber DEPARTMENT)
6. No projects: π Fname,Lname(EMPLOYEE ⋈ EMPLOYEE.Ssn=Nowork.Ssn ρNowork(π Ssn(EMPLOYEE) − π Essn→Ssn(WORKS_ON)))
   Live result: empty — every employee in this dataset works on at least one project.
7. Employees + dependents (inner): π Fname,Lname,Dependent_name(EMPLOYEE ⋈ EMPLOYEE.Ssn=DEPENDENT.Essn DEPENDENT).
   To include employees without dependents: replace `join` with `left outer join`.
8. Employee-managers: π Fname,Lname(EMPLOYEE ⋈ EMPLOYEE.Ssn=DEPARTMENT.Mgr_ssn DEPARTMENT)
9. Every project (division): π Fname,Lname(EMPLOYEE ⋈ EMPLOYEE.Ssn=WorkAll.Essn ρWorkAll(π Essn,Pno(WORKS_ON) ÷ ρPnumber→Pno(π Pnumber(PROJECT))))
   Live result: empty — no one works on all 6 projects (max is 4, by 333445555).
10. Same supervisor as 123456789: π Fname,Lname(σ Super_ssn=Sup ∧ Ssn≠123456789(EMPLOYEE × ρS(π Super_ssn→Sup(σ Ssn=123456789(EMPLOYEE)))).
    Drop the `Ssn !=` clause to include 123456789 itself.
    Live result: Ramesh Narayan, Joyce English (supervisor 333445555).

Appendix — Lab2_Data.txt worked examples, corrected (guide omits join conditions;
example c is union-incompatible as written):
a. pi CourseName (Course join Course.CourseId = Register.CourseID (Register))
b. pi StudentName (sigma CourseID='IT162IU' (Student join Student.StudentID = Register.StudentID (Register)))
c. pi StudentName (Student join Student.StudentID = Nowork.StudentID (rho Nowork (pi StudentID (Student) - pi StudentID (Register))))
Live results on the pasted group: a → all 3 courses; b → B, C, D; c → A only.
