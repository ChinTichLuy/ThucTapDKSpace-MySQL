--CREATE DATABASE sqlday3;

USE sqlday3;

/*
CREATE TABLE Candidates (
    candidate_id INT PRIMARY KEY,
    full_name VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(20),
    years_exp INT,
    expected_salary INT
);

CREATE TABLE Jobs (
    job_id INT PRIMARY KEY,
    title VARCHAR(100),
    department VARCHAR(100),
    min_salary INT,
    max_salary INT
);

CREATE TABLE Applications (
    app_id INT PRIMARY KEY,
    candidate_id INT,
    job_id INT,
    apply_date DATE,
    status VARCHAR(20),
    FOREIGN KEY (candidate_id) REFERENCES Candidates(candidate_id),
    FOREIGN KEY (job_id) REFERENCES Jobs(job_id)
);

CREATE TABLE ShortlistedCandidates (
    candidate_id INT,
    job_id INT,
    selection_date DATE
);
*/

/*
INSERT INTO Candidates (candidate_id, full_name, email, phone, years_exp, expected_salary) VALUES
(1, 'Nguyen Van A', 'a@gmail.com', '0912345678', 0, 500),
(2, 'Tran Thi B', 'b@gmail.com', NULL, 2, 700),
(3, 'Le Van C', 'c@gmail.com', '0987654321', 5, 1200),
(4, 'Pham Thi D', 'd@gmail.com', '0909090909', 7, 1500),
(5, 'Hoang Van E', 'e@gmail.com', NULL, 3, 1000);

INSERT INTO Jobs (job_id, title, department, min_salary, max_salary) VALUES
(101, 'Backend Developer', 'IT', 800, 1500),
(102, 'Frontend Developer', 'IT', 700, 1400),
(103, 'HR Executive', 'HR', 600, 900),
(104, 'Data Analyst', 'IT', 1000, 1600),
(105, 'Accountant', 'Finance', 500, 1000);

INSERT INTO Applications (app_id, candidate_id, job_id, apply_date, status) VALUES
(1001, 1, 101, '2025-05-01', 'Pending'),
(1002, 2, 102, '2025-05-02', 'Accepted'),
(1003, 3, 103, '2025-05-03', 'Rejected'),
(1004, 4, 104, '2025-05-04', 'Accepted'),
(1005, 5, 105, '2025-05-05', 'Pending'),
(1006, 1, 103, '2025-05-06', 'Rejected'),
(1007, 2, 105, '2025-05-07', 'Pending'),
(1008, 3, 101, '2025-05-08', 'Accepted');
*/

SELECT * FROM Candidates;
SELECT * FROM Jobs;
SELECT * FROM Applications;
SELECT * FROM ShortlistedCandidates;

/*
--phần insert thêm để test truy vấn
INSERT INTO Jobs (job_id, title, department, min_salary, max_salary) VALUES
(111, 'Staff', 'IT', 300, 450);
*/

--Tìm các ứng viên đã từng ứng tuyển vào ít nhất một công việc thuộc phòng ban "IT". (Sử dụng EXISTS)
/*
SELECT *
FROM Candidates c
WHERE EXISTS ( --check xem có tồn tại ng đáy trong application có job_id tương ứng với department = "IT" trong job hay ko-> nếu có bất kì 1 dòng nào sẽ trả về 
    SELECT 1
    FROM Applications a
    JOIN Jobs j ON a.job_id = j.job_id
    WHERE a.candidate_id = c.candidate_id
      AND j.department = 'IT'
);
*/

--Liệt kê các công việc mà mức lương tối đa lớn hơn mức lương mong đợi của bất kỳ ứng viên nào. (Sử dụng ANY)
/*
SELECT *
FROM Jobs
WHERE max_salary > ANY ( --chỉ cần điều kiện đúng với ít nhất MỘT phần tử trong tập con là đủ. Đây là so sánh với một tập hợp
    SELECT expected_salary
    FROM Candidates
);
*/

--Liệt kê các công việc mà mức lương tối thiểu lớn hơn mức lương mong đợi của tất cả ứng viên. (Sử dụng ALL)
/*
SELECT *
FROM Jobs
WHERE min_salary > ALL ( -- ngược lại với ANY chút là điều kiện phải đúng với TẤT CẢ phần tử trong tập con thay vì chỉ cần ĐÚNG 1
    SELECT expected_salary
    FROM Candidates
);
*/

/*
 Chèn vào một bảng ShortlistedCandidates những ứng viên có trạng thái ứng tuyển là 'Accepted'
 Bảng ShortlistedCandidates có các cột: candidate_id, job_id, selection_date (ngày hiện tại). (Sử dụng INSERT SELECT)
 */
 /*
INSERT INTO ShortlistedCandidates (candidate_id, job_id, selection_date)
SELECT  candidate_id, job_id, GETDATE()  
FROM Applications a
WHERE status = 'Accepted'
	AND NOT EXISTS ( -- áp dụng EXISTS để không bị lặp lại sau mỗi lần excute
		 SELECT 1
		 FROM ShortlistedCandidates sc
		 WHERE sc.candidate_id = a.candidate_id
		  AND sc.job_id = a.job_id
  );
  */

 /*
Hiển thị danh sách ứng viên, kèm theo đánh giá mức kinh nghiệm như sau:

	< 1 năm → “Fresher”

	1–3 năm → “Junior”

	4–6 năm → “Mid-level”

	> 6 năm → “Senior”
(Sử dụng CASE)
 */

 /*
 SELECT 
    full_name,
    years_exp,
    CASE
        WHEN years_exp < 1 THEN 'Fresher'
        WHEN years_exp BETWEEN 1 AND 3 THEN 'Junior'
        WHEN years_exp BETWEEN 4 AND 6 THEN 'Mid-level'
        ELSE 'Senior'
    END AS exp_level
FROM Candidates;
*/

 /*
 Liệt kê tất cả các ứng viên, trong đó nếu phone bị NULL thì thay bằng 'Chưa cung cấp'
 (Sử dụng hàm xử lý NULL như COALESCE hoặc IFNULL) tùy hệ quản trị
 */
 /*
 SELECT 
    full_name,
    COALESCE(phone, N'chưa cung cấp') AS phone -- COALESCE: nó giống như kiểu "nếu không có thì lấy cái khác thay thế"
FROM Candidates;
*/

 /*
 Tìm các công việc có mức lương tối đa không bằng mức lương tối thiểu và mức lương tối đa lớn hơn hoặc bằng 1000.
 (Sử dụng kết hợp các Operators như !=, >=, AND, OR)
 */
 
 /*
 SELECT *
FROM Jobs
WHERE max_salary != min_salary
  AND max_salary >= 1000;
 */