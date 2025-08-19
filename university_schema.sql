-- =========================================================
-- UNIVERSITY Transcript Database - Unified SQL Schema
-- Engine: MySQL/MariaDB (adjust types/syntax for other RDBMS)
-- =========================================================

-- Safety: adjust database name as needed
-- CREATE DATABASE university_transcripts DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- USE university_transcripts;

-- =========================================================
-- Optional controlled vocabularies (comment out if not needed)
-- =========================================================
CREATE TABLE degree_program (
  code VARCHAR(10) PRIMARY KEY  -- e.g., 'BA','BS','MS','PhD'
) ENGINE=InnoDB;

CREATE TABLE class_level (
  code VARCHAR(15) PRIMARY KEY  -- e.g., 'freshman','sophomore','junior','senior','graduate'
) ENGINE=InnoDB;

CREATE TABLE semester (
  code VARCHAR(10) PRIMARY KEY  -- e.g., 'Spring','Summer','Fall'
) ENGINE=InnoDB;

-- Optionally seed common values
-- INSERT INTO degree_program(code) VALUES ('BA'),('BS'),('MS'),('PhD');
-- INSERT INTO class_level(code) VALUES ('freshman'),('sophomore'),('junior'),('senior'),('graduate');
-- INSERT INTO semester(code) VALUES ('Spring'),('Summer'),('Fall');

-- =========================================================
-- Core entities
-- =========================================================

CREATE TABLE department (
  dept_code VARCHAR(10) PRIMARY KEY,
  dept_name VARCHAR(100) NOT NULL UNIQUE,
  office_number VARCHAR(20),
  office_phone VARCHAR(20),
  college VARCHAR(100)
) ENGINE=InnoDB;

CREATE TABLE student (
  student_number BIGINT PRIMARY KEY,
  ssn VARCHAR(15) NOT NULL UNIQUE,
  first_name VARCHAR(50) NOT NULL,
  last_name VARCHAR(50) NOT NULL,
  birth_date DATE,
  sex CHAR(1),  -- policy-defined domain, e.g., 'M','F','O'
  class VARCHAR(15),  -- FK to class_level.code (optional)
  degree_program VARCHAR(10),  -- FK to degree_program.code (optional)

  current_address VARCHAR(200),
  current_phone VARCHAR(20),

  permanent_address VARCHAR(200),
  permanent_phone VARCHAR(20),
  perm_city VARCHAR(60),
  perm_state VARCHAR(60),
  perm_zip VARCHAR(15),

  major_dept_code VARCHAR(10) NOT NULL,
  minor_dept_code VARCHAR(10) NULL,

  CONSTRAINT fk_student_major_dept
    FOREIGN KEY (major_dept_code) REFERENCES department(dept_code)
      ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_student_minor_dept
    FOREIGN KEY (minor_dept_code) REFERENCES department(dept_code)
      ON UPDATE CASCADE ON DELETE SET NULL
  -- Optional domain enforcement:
  -- ,CONSTRAINT fk_student_degree_program FOREIGN KEY (degree_program) REFERENCES degree_program(code)
  -- ,CONSTRAINT fk_student_class FOREIGN KEY (class) REFERENCES class_level(code)
) ENGINE=InnoDB;

CREATE INDEX idx_student_last_name ON student(last_name);
CREATE INDEX idx_student_perm_city_state_zip ON student(perm_city, perm_state, perm_zip);

CREATE TABLE course (
  course_number VARCHAR(20) PRIMARY KEY,
  course_name VARCHAR(150) NOT NULL,
  description TEXT,
  semester_hours TINYINT UNSIGNED,
  level VARCHAR(20),  -- e.g., 'undergrad','grad' or numeric
  offering_dept_code VARCHAR(10) NOT NULL,
  CONSTRAINT fk_course_offering_dept
    FOREIGN KEY (offering_dept_code) REFERENCES department(dept_code)
      ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- =========================================================
-- Optional instructor entity (comment out if not needed)
-- =========================================================
CREATE TABLE instructor (
  instructor_id BIGINT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(120) UNIQUE,
  office VARCHAR(50),
  dept_code VARCHAR(10),
  CONSTRAINT fk_instructor_dept
    FOREIGN KEY (dept_code) REFERENCES department(dept_code)
      ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- =========================================================
-- Section (composite key per business rule)
-- =========================================================
CREATE TABLE section (
  course_number VARCHAR(20) NOT NULL,
  semester VARCHAR(10) NOT NULL,  -- FK to semester.code if using the reference table
  year SMALLINT NOT NULL,
  section_number SMALLINT NOT NULL,  -- 1..N within (course, semester, year)

  -- Use one of the following:
  instructor VARCHAR(100),           -- simple attribute
  instructor_id BIGINT NULL,         -- or FK to instructor if using the entity

  PRIMARY KEY (course_number, semester, year, section_number),

  CONSTRAINT fk_section_course
    FOREIGN KEY (course_number) REFERENCES course(course_number)
      ON UPDATE CASCADE ON DELETE RESTRICT,

  CONSTRAINT fk_section_instructor
    FOREIGN KEY (instructor_id) REFERENCES instructor(instructor_id)
      ON UPDATE CASCADE ON DELETE SET NULL

  -- Optional: enforce semester domain via FK
  -- ,CONSTRAINT fk_section_semester FOREIGN KEY (semester) REFERENCES semester(code)
) ENGINE=InnoDB;

-- Optional check constraints (MySQL 8.0+ supports CHECK)
-- ALTER TABLE section ADD CONSTRAINT chk_section_number CHECK (section_number >= 1);

-- =========================================================
-- Grade report (associative entity: enrollment + outcome)
-- =========================================================
CREATE TABLE grade_report (
  student_number BIGINT NOT NULL,
  course_number VARCHAR(20) NOT NULL,
  semester VARCHAR(10) NOT NULL,
  year SMALLINT NOT NULL,
  section_number SMALLINT NOT NULL,

  letter_grade VARCHAR(2),   -- e.g., 'A','A-','B+'
  numeric_grade TINYINT,     -- 0..4

  PRIMARY KEY (student_number, course_number, semester, year, section_number),

  CONSTRAINT fk_gr_student
    FOREIGN KEY (student_number) REFERENCES student(student_number)
      ON UPDATE CASCADE ON DELETE CASCADE,

  CONSTRAINT fk_gr_section
    FOREIGN KEY (course_number, semester, year, section_number)
      REFERENCES section(course_number, semester, year, section_number)
      ON UPDATE CASCADE ON DELETE RESTRICT,

  CONSTRAINT chk_numeric_grade CHECK (numeric_grade IN (0,1,2,3,4))
) ENGINE=InnoDB;

CREATE INDEX idx_grade_report_by_section ON grade_report(course_number, semester, year, section_number);

-- =========================================================
-- Optional: multiple minors (use instead of student.minor_dept_code)
-- =========================================================
-- CREATE TABLE student_minor (
--   student_number BIGINT NOT NULL,
--   dept_code VARCHAR(10) NOT NULL,
--   PRIMARY KEY (student_number, dept_code),
--   CONSTRAINT fk_student_minor_student
--     FOREIGN KEY (student_number) REFERENCES student(student_number)
--       ON UPDATE CASCADE ON DELETE CASCADE,
--   CONSTRAINT fk_student_minor_dept
--     FOREIGN KEY (dept_code) REFERENCES department(dept_code)
--       ON UPDATE CASCADE ON DELETE RESTRICT
-- ) ENGINE=InnoDB;

-- If using student_minor, drop minor_dept_code from student and rely on the bridge.

-- =========================================================
-- Helpful views (optional)
-- =========================================================
-- CREATE VIEW v_transcript AS
-- SELECT gr.student_number,
--        s.first_name, s.last_name,
--        gr.course_number, c.course_name,
--        gr.semester, gr.year, gr.section_number,
--        gr.letter_grade, gr.numeric_grade
-- FROM grade_report gr
-- JOIN student s ON s.student_number = gr.student_number
-- JOIN course c  ON c.course_number = gr.course_number;

-- =========================================================
-- End of unified schema
-- =========================================================
