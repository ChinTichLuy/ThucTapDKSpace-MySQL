
--CREATE DATABASE sqlday1;

USE sqlday1;

/*
CREATE TABLE customers (
    customer_id INT IDENTITY(1,1) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    city VARCHAR(50) NOT NULL,
    email VARCHAR(100) DEFAULT NULL
);

CREATE TABLE orders (
    order_id INT IDENTITY(1,1) PRIMARY KEY,
    customer_id INT NOT NULL,
    order_date DATE NOT NULL,
    total_amount INT NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE products (
    product_id INT IDENTITY(1,1) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price INT NOT NULL
);

*/

/*
INSERT INTO customers (name, city, email) VALUES
('Nguyen An', 'Hanoi', 'an.nguyen@email.com'),
('Tran Binh', 'Ho Chi Minh', NULL),
('Le Cuong', 'Da Nang', 'cuong.le@email.com'),
('Hoang Duong', 'Hanoi', 'duong.hoang@email.com');


INSERT INTO orders (customer_id, order_date, total_amount) VALUES
(1, '2023-01-15', 500000),
(3, '2023-02-10', 800000),
(2, '2023-03-05', 300000),
(1, '2023-04-01', 450000);

INSERT INTO products (name, price) VALUES
('Laptop Dell', 15000000),
('Mouse Logitech', 300000),
('Keyboard Razer', 1200000),
('Laptop HP', 14000000);
*/


--SELECT * FROM customers;

--SELECT * FROM orders;

SELECT * FROM products;


--SELECT * FROM customers WHERE city = 'Hanoi';

--SELECT * FROM orders WHERE total_amount > 400000 AND order_date > '2023-02-20';

--SELECT * FROM customers WHERE email IS NULL;

--SELECT * FROM orders ORDER BY total_amount DESC;

--INSERT INTO customers (name, city, email) VALUES ('HoangTaly', 'Hanoi', NULL); 

--UPDATE customers SET email = 'hoangtaly@email.com' WHERE customer_id = 6;

--DELETE FROM orders WHERE order_id = 2;

--SELECT TOP 5 * FROM customers;

--SELECT MAX(total_amount) AS max_amount, MIN(total_amount) AS min_amount FROM orders;

/*
SELECT 
    COUNT(*) AS total_orders, 
    SUM(total_amount) AS total_sales, 
    AVG(total_amount) AS avg_order_value 
FROM orders;
*/

SELECT * FROM products WHERE name LIKE 'Laptop%';

/*
RDBMS (Relational Database Management System) là hệ quản trị cơ sở dữ liệu quan hệ,
nơi dữ liệu được lưu trong các bảng và các bảng có thể liên kết với nhau thông qua các khóa (khóa chính, khóa ngoại)

Vai trò của mối quan hệ giữa các bảng
- Giúp liên kết dữ liệu giữa các bảng có liên quan (ví dụ: khách hàng và đơn hàng)
- Tránh trùng lặp dữ liệu (nhờ tách thành nhiều bảng chuẩn hóa và liên kết với nhau)
- Dễ truy vấn tổng hợp hoặc phân tích dữ liệu nhiều bảng cùng 1 lúc
*/



