"""Generate Part D database diagram PNG from the live schema definition.

Source of truth: create_coursemanagement.sql (verified running on MySQL 8.4.11
and TiDB 8.5.3) + INFORMATION_SCHEMA.TABLE_CONSTRAINTS output (fig_B_constraints).
Tables, columns, PKs and FKs below match the database itself exactly.
"""

from PIL import Image, ImageDraw

W, H = 1600, 1150
img = Image.new("RGB", (W, H), "white")
d = ImageDraw.Draw(img)

tables = [
    (
        "Department",
        60,
        80,
        [
            "DeptNo CHAR(4)  PK",
            "DeptName VARCHAR(60)",
        ],
    ),
    (
        "Lecturer",
        600,
        80,
        [
            "LecturerID CHAR(6)  PK",
            "LecturerName VARCHAR(60)",
            "DeptNo CHAR(4)  FK -> Department",
        ],
    ),
    (
        "Student",
        1140,
        80,
        [
            "StudentID CHAR(10)  PK",
            "StudentName VARCHAR(60)",
            "DoB DATE  CK_Student_DoB",
            "Major VARCHAR(40)",
            "Email VARCHAR(80)  UQ",
        ],
    ),
    (
        "Course",
        60,
        470,
        [
            "CourseID CHAR(8)  PK",
            "CourseName VARCHAR(60)",
            "Credits TINYINT  (ALTER)",
        ],
    ),
    (
        "Register",
        600,
        470,
        [
            "StudentID CHAR(10)  PK,FK -> Student",
            "CourseID CHAR(8)  PK,FK -> Course",
            "Grade DECIMAL(5,2)  CK_Register_Grade",
        ],
    ),
    (
        "Teach",
        1140,
        470,
        [
            "CourseID CHAR(8)  PK,FK -> Course",
            "LecturerID CHAR(6)  PK,FK -> Lecturer",
        ],
    ),
    (
        "LecturerPhone",
        600,
        830,
        [
            "LecturerID CHAR(6)  PK,FK -> Lecturer",
            "Phone VARCHAR(15)  PK, CK_Phone_Length",
        ],
    ),
]

boxes = {}
for name, x, y, cols in tables:
    w, row = 400, 30
    h = 44 + len(cols) * row + 8
    boxes[name] = (x, y, x + w, y + h)
    d.rectangle([x, y, x + w, y + h], outline="black", width=2)
    d.rectangle([x, y, x + w, y + 36], fill="#1f3a5f")
    d.text((x + 12, y + 10), name, fill="white")
    for i, c in enumerate(cols):
        d.text((x + 12, y + 44 + i * row), c, fill="black")


def arrow(x1, y1, x2, y2, label):
    d.line([x1, y1, x2, y2], fill="#b00020", width=2)
    d.text(((x1 + x2) // 2 - 40, (y1 + y2) // 2 - 22), label, fill="#b00020")


# FK edges (parent -> child), red
arrow(460, 180, 600, 180, "FK_Lecturer_Dept")  # Dept -> Lecturer
arrow(600, 640, 460, 560, "FK_Reg_Course")  # Course -> Register
arrow(1140, 200, 1000, 520, "FK_Reg_Stu")  # Student -> Register
arrow(460, 520, 600, 560, "FK_Teach_Course")  # Course -> Teach
arrow(800, 250, 1200, 470, "FK_Teach_Lect")  # Lecturer -> Teach
arrow(700, 250, 700, 830, "FK_Phone_Lect")  # Lecturer -> Phone

d.text(
    (60, H - 90),
    "CourseManagement on MySQL 8.4.11  |  7 tables, InnoDB  |  StudentWithAge is a VIEW (not a table).",
    fill="black",
)
d.text(
    (60, H - 60),
    "Generated from the live schema (CREATE TABLE + INFORMATION_SCHEMA), not hand-drawn. PK underlined in schema comment.",
    fill="black",
)

img.save("/Users/xirothedev/workspace/PDM-Lab/lab3_report/fig_D_eer.png")
print("saved fig_D_eer.png")
