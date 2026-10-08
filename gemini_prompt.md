# Prompt for Gemini — IT079IU Lab 1 written report (text only)

Copy everything inside the fenced block into Gemini.

---

```text
You are writing the written sections of a graded university lab report. Produce TEXT ONLY — do not
draw, render, or attempt to depict the ER diagram in any form (no ASCII art, no Mermaid, no PlantUML,
no code blocks that imitate a picture). The diagrams are drawn separately in ERDPlus; your job is the
prose that goes underneath and beside them.

## Context

Course: IT079IU — Principles of Database Management, International University – VNU-HCM.
Lab 1 — Introduction to the Entity–Relationship Diagram. Tool: ERDPlus (Chen notation, crow's-foot
cardinality marks). Two graded parts: Part B (4 marks) and Part C (6 marks). The author may be asked
to explain any design decision, so every claim must be traceable to the specification.

Student: Le Thanh Trung. Student ID: ITCSIU25055. Lab number: Lab 1.

## Marking criteria you are writing against

1. Entities, attributes and keys correctly identified.
2. Relationships: degree, cardinality ratio and participation constraint correct, each justified from
   the specification.
3. Correct use of weak entity, identifying relationship, composite, multivalued, derived and
   relationship attributes.
4. Written justification traceable to the specification.

Marks are deducted for a foreign key or a junction table drawn in a conceptual diagram, and for work
the student cannot explain when asked.

## Specification — Part B (a small library). Verbatim; do not paraphrase or add facts.

- The library holds titles. A title has an ISBN that identifies it, a name, a year of publication and
  one or more authors.
- The library owns several physical copies of a title. A copy is numbered 1, 2, 3 … within its title,
  so copy number 2 means nothing unless the title is known. Each copy has a shelf location.
- A member has a membership number, a full name made of a first and a last name, and one or more
  phone numbers.
- A member borrows a copy on a date and returns it on another date. The same copy may be borrowed by
  many members over time, and a member may borrow many copies.
- A member may exist without ever having borrowed anything, but every copy must belong to a title.

## Specification — Part C (a clinic). Verbatim; do not paraphrase or add facts.

- A patient has a patient number, a full name made of a first and a last name, a date of birth and
  one or more phone numbers. The clinic displays the patient's age but does not store it.
- A doctor has a doctor number, a name, and a specialty. Every doctor works in exactly one
  department; a department has a code, a name, and is headed by exactly one of its own doctors.
- A patient makes an appointment with one doctor for a date and a time. A patient may have many
  appointments over time, and a doctor sees many patients.
- Each appointment produces exactly one consultation record that contains the diagnosis and notes.
  A consultation record cannot exist without its appointment.
- A consultation may prescribe several treatments, and the same treatment may be prescribed in many
  consultations. The dose and the duration are recorded each time a treatment is prescribed.
- A treatment has a treatment code, a name, and a type.

## The model. These decisions are already fixed in the diagrams. Do not redesign or contradict them.

PART B
- Entities: Title (key ISBN; attributes TitleName, YearPublished, Authors multivalued);
  Copy (WEAK entity, partial key CopyNo; attribute ShelfLocation); Member (key MemberNo;
  Name composite with FirstName and LastName; Phone multivalued).
- HasCopy: Title 1:N Copy — identifying relationship, Mandatory (total) on Copy, Optional on Title.
- Borrows: Member M:N Copy — Optional on both sides; carries relationship attributes BorrowDate and
  ReturnDate.
- Full identifier of a Copy: ISBN + CopyNo.

PART C
- Entities: Patient (key PatientNo; Name composite -> FirstName, LastName; DateOfBirth; Phone
  multivalued; Age DERIVED); Doctor (key DoctorNo; Name; Specialty); Department (key DeptCode;
  DeptName); Appointment (key AppointmentNo; Date; Time); Consultation (WEAK entity, partial key
  ConsultationNo; Diagnosis; Notes); Treatment (key TreatmentCode; Name; Type).
- Books: Patient 1:N Appointment — Optional on Patient, Mandatory on Appointment.
- Attends: Appointment 1:N Doctor — Optional on Doctor, Mandatory on Appointment.
- Produces: Appointment 1:1 Consultation — identifying, Optional on Appointment, Mandatory on
  Consultation.
- WorksIn: Doctor N:1 Department — Mandatory on Doctor, Optional on Department.
- Heads: Department 1:1 Doctor — Mandatory on Department, Optional on Doctor.
- Prescribes: Consultation M:N Treatment — Optional both sides; carries Dose and Duration.
- Refers: Doctor M:N Doctor (self-relationship), roles "referring doctor" and "referred doctor",
  Optional on both sides.

Two decisions you must not soften or re-litigate:

(a) Appointment is a STRONG ENTITY with its own key AppointmentNo. Reason: the specification says a
consultation record "cannot exist without its appointment", so Appointment must be something that can
own a weak entity. The rejected alternative — treating Appointment as an associative entity keyed by
PatientNo + DoctorNo + Date + Time — would place the identifier of another entity inside an entity,
which the lab penalises.

(b) Refers does NOT appear anywhere in the Part C specification, but the task sheet requires "at least
one relationship of an entity set with itself". It was added deliberately and must be disclosed as an
addition, not presented as if the specification stated it.

## Hard constraints

- Never introduce a foreign key, a DepartmentID-style attribute, or a junction/link table. This is a
  conceptual model.
- Never place the identifier of one entity inside another entity.
- Every attribute that describes a PAIR of entities belongs on the relationship, not on either entity.
- Only use facts present in the specifications above. If something is not stated, say so explicitly
  rather than inventing it.
- The entity is named "Consultation", not "ConsultationRecord" (ERDPlus fixes entity box width and the
  longer name overflows the rectangle). Use "Consultation" consistently.
- Specialty and Type are plain attributes, not entity sets: the specifications give them only a word.
- Authors is a multivalued attribute of Title, not an entity: authors are given nothing but a name.

## Required output — produce exactly these sections, in this order, as Markdown

### SECTION 1 — Report header
Three lines: full name, student ID, lab number.

### SECTION 2 — Part B description
Use this form, filling it in accurately:

    Entities: <entity list, marking the weak one>
    Relationships: <for each relationship: name, the two entities, the ratio, the participation, and
      the reason>
    Key of the weak entity: <the composite identifier>

Then add two short paragraphs (2–4 sentences each), only if they add something the form does not
already say:
- why Copy is a weak entity rather than a regular one;
- why BorrowDate and ReturnDate sit on the Borrows diamond instead of on Member or Copy.

### SECTION 3 — Part C relationship table
A Markdown table with exactly these five columns:
Relationship | Entities joined | Ratio | Participation | Sentence from the specification that justifies it

- One row per relationship: Books, Attends, Produces, WorksIn, Heads, Prescribes, Refers. Seven rows.
- Ratio and Participation must state BOTH ends, e.g. "Optional on Patient / Mandatory on Appointment".
- The final column must quote or closely track a sentence from the Part C specification. For Refers,
  state plainly that no sentence in the specification supports it and that it was added to satisfy the
  task sheet's self-relationship requirement.
- Mark Produces as the identifying relationship.

### SECTION 4 — Part C supporting notes
Short labelled paragraphs or a tight bullet list covering:
- which attributes are composite, multivalued and derived, with the spec phrase that proves each;
- that Prescription-style relationship attributes (Dose, Duration) sit on the Prescribes diamond;
- the full identifier of the weak entity Consultation;
- that no foreign key and no junction table appear anywhere.

### SECTION 5 — Comment on the hardest design decision
One paragraph of 3–5 sentences on Appointment (point (a) above): why it was modelled as a strong entity
rather than an associative link, and what was gained and lost by that choice. Then one or two further
sentences disclosing that Refers was added although the specification does not state it (point (b)).

### SECTION 6 — AI use declaration
One line, factual, in the form the lab sheet gives as an example. State that an AI assistant drafted
this written text and that the diagrams were drawn with AI assistance, that the design decisions were
approved by the student, and that the student can justify every element. Do not overstate or understate.

## Style

- Plain academic prose. No bullet-point fragments where a sentence is expected.
- Aim for roughly 700–900 words in total. This report is 4 A4 pages and must not overflow.
- Keep table cells terse; long justification belongs in the table's final column, not in Section 4.
- British spelling ("recognised", "modelled") to match the lab sheet.
- Do not repeat the specification verbatim outside the table's justification column.

## Before you answer, self-check and silently fix

- Are all three Part B entities present, with Copy marked weak and CopyNo marked a partial key?
- Does every one of the seven Part C relationships have a ratio and BOTH participation ends?
- Is the identifying relationship flagged, and is the self-relationship disclosed as an addition?
- Does any sentence assert a fact that is not in the specifications? Remove it.
- Does any entity contain another entity's identifier? Remove it.
- Does the total fit the length limit?

Output only the six sections. No preamble, no closing remarks.
```

---

## Note on the declaration

The prompt asks Gemini to write the declaration line covering both the text **and** the diagrams. If
Gemini produces text you keep, that line is accurate — but read it before signing, and adjust the
wording to match what you actually did. Don't file a declaration you can't defend if asked directly.