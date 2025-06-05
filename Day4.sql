
--DROP DATABASE sqlday4; --xóa thẳng
--DROP DATABASE IF EXISTS sqlday4; -- xóa nếu tồn tại

--CREATE DATABASE sqlday4;

USE sqlday4;

--DROP TABLE Enrollments; -- xóa bảng (note: phải xóa bảng liên kết khóa ngoại trước thì mới xóa được các bảng được liên kết)
--DROP TABLE Students;
--DROP TABLE Courses;

/*
CREATE TABLE Students (
    student_id INT IDENTITY(1,1) PRIMARY KEY,
    full_name NVARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL, -- UNIQUE: Đảm bảo rằng giá trị trong cột đó là duy nhất, không được trùng lặp giữa các hàng
    join_date DATE DEFAULT GETDATE()    -- DEFAULT: Gán giá trị mặc định (GETDATE) nếu không được nhập thủ công (vào trường join_date)
);

CREATE TABLE Courses (
    course_id INT IDENTITY(1,1) PRIMARY KEY,
    title NVARCHAR(100) NOT NULL,
    description NVARCHAR(255),
    price INT CHECK (price >= 0) -- CHECK: Đảm bảo dữ liệu trong cột phải thỏa mãn điều kiện nhất định (ở đây là price >=0)
);

CREATE TABLE Enrollments (
    enrollment_id INT IDENTITY(1,1) PRIMARY KEY,
    student_id INT FOREIGN KEY REFERENCES Students(student_id),
    course_id INT FOREIGN KEY REFERENCES Courses(course_id),
    enroll_date DATE DEFAULT GETDATE()
);



INSERT INTO Students (full_name, email)
VALUES 
(N'Nguyễn Văn A', 'a@gmail.com'),
(N'Trần Thị B', 'b@gmail.com'),
(N'Lê Văn C', 'c@gmail.com');

INSERT INTO Courses (title, description, price)
VALUES 
(N'Lập trình PHP', N'Khóa học PHP cơ bản đến nâng cao', 500000),
(N'SQL Server', N'Học thiết kế cơ sở dữ liệu với SQL Server', 700000),
(N'HTML & CSS', N'Khóa học thiết kế web cơ bản', 300000);

INSERT INTO Enrollments (student_id, course_id)
VALUES 
(1, 1),
(1, 2),
(2, 2),
(3, 3);
*/

SELECT * FROM Students;
SELECT * FROM Courses;
SELECT * FROM Enrollments;

/*Thêm cột status vào bảng Enrollments với giá trị mặc định là 'active'.
 (Sử dụng ALTER TABLE + DEFAULT)
 */

 /*
ALTER TABLE Enrollments
ADD status VARCHAR(20) DEFAULT 'active';
*/

-- test xem status có tự động là 'active' không
--INSERT INTO Enrollments (student_id, course_id) VALUES (3, 2);

/*
Tạo một VIEW tên là StudentCourseView hiển thị danh sách sinh viên và tên khóa học họ đã đăng ký
 (Sử dụng CREATE VIEW)
*/
/*
GO
CREATE VIEW StudentCourseView AS
SELECT 
    s.full_name AS student_name,
    c.title AS course_title,
    e.enroll_date,
    e.status
FROM Enrollments e
JOIN Students s ON e.student_id = s.student_id
JOIN Courses c ON e.course_id = c.course_id;
*/

--xem view
--SELECT * FROM StudentCourseView;

-- nếu có lỗi hoặc muốn sửa thì có thể drop view và create view lại như bth
--DROP VIEW IF EXISTS StudentCourseView;


/* Tạo một chỉ mục (INDEX) trên cột title của bảng Courses để tối ưu tìm kiếm.
 (Sử dụng CREATE INDEX)
 */
 /*
 CREATE INDEX idx_course_title
ON Courses (title);
*/

--test tìm kiếm
--SELECT * FROM Courses WHERE title LIKE '%s%';


