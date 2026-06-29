CREATE DATABASE student_db;
USE student_db;

CREATE TABLE students (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(20),
    place VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);