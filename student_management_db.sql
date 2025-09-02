DROP SCHEMA IF EXISTS student_mgmt CASCADE;
CREATE SCHEMA student_mgmt;

-- ==== Students ====
CREATE TABLE student_mgmt.students (
    student_id   SERIAL PRIMARY KEY,
    full_name    VARCHAR(100) NOT NULL,
    email        VARCHAR(120) UNIQUE NOT NULL,
    phone        VARCHAR(20) UNIQUE,
    created_at   TIMESTAMP DEFAULT NOW(),
    CHECK (position('@' IN email) > 1)
);

-- ==== Courses ====
CREATE TABLE student_mgmt.courses (
    course_id     SERIAL PRIMARY KEY,
    course_name   VARCHAR(100) UNIQUE NOT NULL,
    credit_hours  INT NOT NULL,
    CHECK (credit_hours BETWEEN 1 AND 6)
);

-- ==== Instructors (Bonus used later) ====
CREATE TABLE student_mgmt.instructors (
    instructor_id SERIAL PRIMARY KEY,
    full_name     VARCHAR(100) NOT NULL,
    email         VARCHAR(120) UNIQUE NOT NULL
);

-- ==== Enrollments ====
-- composite PK يسمح بنفس الطالب ياخد نفس الكورس في تيرم مختلف
CREATE TABLE student_mgmt.enrollments (
    student_id     INT NOT NULL REFERENCES student_mgmt.students(student_id) ON DELETE CASCADE,
    course_id      INT NOT NULL REFERENCES student_mgmt.courses(course_id)  ON DELETE CASCADE,
    instructor_id  INT     REFERENCES student_mgmt.instructors(instructor_id),
    term           VARCHAR(20) NOT NULL,   -- e.g., 'Fall 2024'
    grade          VARCHAR(2),             -- A, A-, B+, ...
    enrolled_at    TIMESTAMP DEFAULT NOW(),
    PRIMARY KEY (student_id, course_id, term),
    CHECK (grade IS NULL OR grade IN ('A','A-','B+','B','B-','C+','C','D','F'))
);

-- ==== Helpful Indexes ====
CREATE INDEX idx_enr_course ON student_mgmt.enrollments(course_id);
CREATE INDEX idx_enr_student ON student_mgmt.enrollments(student_id);
CREATE INDEX idx_enr_instructor ON student_mgmt.enrollments(instructor_id);


-- ==== Students ====
INSERT INTO student_mgmt.students (full_name, email, phone) VALUES
('Shahinda Mostafa', 'shahinda@example.com', '+20-100-111-2222'),
('Omar Elbaz',       'omar.elbaz@example.com', '+20-100-333-4444'),
('Mariam Adel',      'mariam.adel@example.com', '+20-100-555-6666'),
('Kareem Hany',      'kareem.hany@example.com', '+20-100-777-8888'),
('Salma Tarek',      'salma.tarek@example.com', '+20-100-999-0000');

-- ==== Courses ====
INSERT INTO student_mgmt.courses (course_name, credit_hours) VALUES
('Database Systems', 3),
('Data Analysis with Python', 4),
('Algorithms', 3),
('Operating Systems', 3),
('Business Intelligence', 3);

-- ==== Instructors ====
INSERT INTO student_mgmt.instructors (full_name, email) VALUES
('Dr. Ahmed Samir',   'ahmed.samir@uni.edu'),
('Dr. Nour El-Din',   'nour.eldin@uni.edu'),
('Eng. Hala Mansour', 'hala.mansour@uni.edu');

-- ==== Enrollments ====
INSERT INTO student_mgmt.enrollments (student_id, course_id, instructor_id, term, grade) VALUES
(1, 1, 1, 'Spring 2025', 'A'),
(1, 2, 3, 'Spring 2025', 'B+'),
(1, 5, 2, 'Spring 2025', 'A-'),

(2, 1, 1, 'Spring 2025', 'B'),
(2, 3, 2, 'Spring 2025', 'A'),
(2, 4, 2, 'Spring 2025', 'B-'),

(3, 2, 3, 'Spring 2025', 'A'),
(3, 3, 2, 'Spring 2025', 'B+'),

(4, 1, 1, 'Spring 2025', 'C+'),
(4, 5, 2, 'Spring 2025', 'B'),

(5, 2, 3, 'Spring 2025', 'A-'),
(5, 4, 2, 'Spring 2025', 'B+');


-- ==== List all students ====
SELECT student_id, full_name, email, phone, created_at
FROM student_mgmt.students
ORDER BY student_id;


-- ==== Find students who have a grade of 'A' ====
SELECT DISTINCT s.student_id, s.full_name, e.course_id, e.term, e.grade
FROM student_mgmt.students s
JOIN student_mgmt.enrollments e ON e.student_id = s.student_id
WHERE e.grade = 'A'
ORDER BY s.full_name, e.term;


-- ==== Show all courses with their credit hours ====
SELECT course_id, course_name, credit_hours
FROM student_mgmt.courses
ORDER BY course_name;


-- ==== Find the courses a specific student ====
SELECT s.full_name, c.course_name, e.term, e.grade
FROM student_mgmt.enrollments e
JOIN student_mgmt.students s  ON s.student_id  = e.student_id
JOIN student_mgmt.courses  c  ON c.course_id   = e.course_id
WHERE c.course_name = 'Database Systems'
ORDER BY s.full_name;


-- ==== List each student along with the number of courses they enrolled in ====
SELECT c.course_name, COUNT(*) AS enroll_count
FROM student_mgmt.enrollments e
JOIN student_mgmt.courses c ON c.course_id = e.course_id
GROUP BY c.course_name
ORDER BY enroll_count DESC, c.course_name;


-- ==== Find students who are not enrolled in any course ====
SELECT s.student_id, s.full_name, s.email
FROM student_mgmt.students s
LEFT JOIN student_mgmt.enrollments e ON e.student_id = s.student_id
WHERE e.student_id IS NULL
ORDER BY s.student_id;


-- ==== Show all enrollments sorted by grade ==== 
SELECT s.full_name, c.course_name, e.term, e.grade
FROM student_mgmt.enrollments e
JOIN student_mgmt.students s ON s.student_id = e.student_id
JOIN student_mgmt.courses  c ON c.course_id  = e.course_id
ORDER BY e.grade ASC, s.full_name;  -- 'A' < 'B' < ...


-- ==== Full Transcript ====
SELECT 
  s.full_name      AS student,
  c.course_name    AS course,
  c.credit_hours   AS credits,
  i.full_name      AS instructor,
  e.term,
  e.grade
FROM student_mgmt.enrollments e
JOIN student_mgmt.students    s ON s.student_id = e.student_id
JOIN student_mgmt.courses     c ON c.course_id  = e.course_id
LEFT JOIN student_mgmt.instructors i ON i.instructor_id = e.instructor_id
ORDER BY s.full_name, e.term, c.course_name;


-- Bonus: Average Grade Per Course ====
WITH grade_points AS (
  SELECT
    e.*,
    CASE e.grade
      WHEN 'A'  THEN 4.0
      WHEN 'A-' THEN 3.7
      WHEN 'B+' THEN 3.3
      WHEN 'B'  THEN 3.0
      WHEN 'B-' THEN 2.7
      WHEN 'C+' THEN 2.3
      WHEN 'C'  THEN 2.0
      WHEN 'D'  THEN 1.0
      WHEN 'F'  THEN 0.0
      ELSE NULL
    END AS points
  FROM student_mgmt.enrollments e
)
SELECT 
  c.course_name,
  ROUND(AVG(g.points)::numeric, 2) AS avg_points
FROM grade_points g
JOIN student_mgmt.courses c ON c.course_id = g.course_id
GROUP BY c.course_name
ORDER BY avg_points DESC;

-- ==== GPA In Weighted Credits ==== 
WITH gp AS (
  SELECT
    e.student_id, e.course_id, c.credit_hours,
    CASE e.grade
      WHEN 'A'  THEN 4.0
      WHEN 'A-' THEN 3.7
      WHEN 'B+' THEN 3.3
      WHEN 'B'  THEN 3.0
      WHEN 'B-' THEN 2.7
      WHEN 'C+' THEN 2.3
      WHEN 'C'  THEN 2.0
      WHEN 'D'  THEN 1.0
      WHEN 'F'  THEN 0.0
      ELSE NULL
    END AS points
  FROM student_mgmt.enrollments e
  JOIN student_mgmt.courses c ON c.course_id = e.course_id
)
SELECT 
  s.full_name,
  ROUND(SUM(points * credit_hours) / NULLIF(SUM(credit_hours),0), 2) AS gpa
FROM gp
JOIN student_mgmt.students s ON s.student_id = gp.student_id
GROUP BY s.full_name
ORDER BY gpa DESC;


-- ==== View Transcript ==== 
CREATE OR REPLACE VIEW student_mgmt.v_transcript AS
SELECT 
  s.student_id,
  s.full_name      AS student,
  c.course_name    AS course,
  c.credit_hours   AS credits,
  COALESCE(i.full_name, 'N/A') AS instructor,
  e.term,
  e.grade
FROM student_mgmt.enrollments e
JOIN student_mgmt.students s ON s.student_id = e.student_id
JOIN student_mgmt.courses  c ON c.course_id  = e.course_id
LEFT JOIN student_mgmt.instructors i ON i.instructor_id = e.instructor_id;