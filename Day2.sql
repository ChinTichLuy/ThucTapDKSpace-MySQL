
--CREATE DATABASE sqlday2;

USE sqlday2;

/*
CREATE TABLE Users (
    user_id INT PRIMARY KEY,
    full_name NVARCHAR(100), --NVARCHAR để viết tiếng việt có dấu (ngoài ra nó còn hỗ trợ các ngôn ngữ khác, vì nó thay đổi độ dài của chuỗi kí tự khi unicode)
    city NVARCHAR(50),
    referrer_id INT NULL, --người giới thiệu (referrer)
    created_at DATE,
    FOREIGN KEY (referrer_id) REFERENCES Users(user_id) --Self-Join hoặc Self-referencing foreign key 
	--vì người giới thiệu cũng là một user, nên khóa ngoại trỏ về chính bảng Users
);


CREATE TABLE Products (
    product_id INT PRIMARY KEY,
    product_name NVARCHAR(100),
    category NVARCHAR(50),
    price INT,
    is_active BIT  -- BIT là kiểu boolean (kiểu giống vậy) 0: False, 1: True, NULL: không xác định (nếu không gán)
);


CREATE TABLE Orders (
    order_id INT PRIMARY KEY,
    user_id INT,
    order_date DATE,
    status NVARCHAR(20),
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

CREATE TABLE OrderItems (
    order_id INT,
    product_id INT,
    quantity INT,
    PRIMARY KEY (order_id, product_id),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);
*/

/*
INSERT INTO Users (user_id, full_name, city, referrer_id, created_at) VALUES
(1, N'Nguyen Van A', N'Hanoi', NULL, '2023-01-01'),
(2, N'Tran Thi B', N'HCM', 1, '2023-01-10'),
(3, N'Le Van C', N'Hanoi', 1, '2023-01-12'),
(4, N'Do Thi D', N'Da Nang', 2, '2023-02-05'),
(5, N'Hoang E', N'Can Tho', NULL, '2023-02-10');

INSERT INTO Products (product_id, product_name, category, price, is_active) VALUES
(1, N'iPhone 13', N'Electronics', 20000000, 1),
(2, N'MacBook Air', N'Electronics', 28000000, 1),
(3, N'Coffee Beans', N'Grocery', 250000, 1),
(4, N'Book: SQL Basics', N'Books', 150000, 1),
(5, N'Xbox Controller', N'Gaming', 1200000, 0);

INSERT INTO Orders (order_id, user_id, order_date, status) VALUES
(1001, 1, '2023-02-01', N'completed'),
(1002, 2, '2023-02-10', N'cancelled'),
(1003, 3, '2023-02-12', N'completed'),
(1004, 4, '2023-02-15', N'completed'),
(1005, 1, '2023-03-01', N'pending');

INSERT INTO OrderItems (order_id, product_id, quantity) VALUES
(1001, 1, 1),
(1001, 3, 3),
(1003, 2, 1),
(1003, 4, 2),
(1004, 3, 5),
(1005, 2, 1);
*/

/*
--insert thêm dữ liệu để test
INSERT INTO Products (product_id, product_name, category, price, is_active) VALUES
(6, N'Taly Controller', N'Gaming', 1200000, 0);
INSERT INTO Orders (order_id, user_id, order_date, status) VALUES
(1088, 2, '2023-02-15', N'completed');
INSERT INTO OrderItems (order_id, product_id, quantity) VALUES
(1088, 6, 5);
*/


SELECT * FROM Users;
SELECT * FROM Products;
SELECT * FROM Orders;
SELECT * FROM OrderItems;


--Tính tổng doanh thu từ các đơn hàng completed, nhóm theo danh mục sản phẩm
/*
SELECT p.category, SUM(oi.quantity * p.price) AS total_revenue
FROM Orders o --alias: dạng kiểu viết tắt, biệt danh
JOIN OrderItems oi ON o.order_id = oi.order_id -- ON: điều kiện nối khi join các bảng, xác định các cột chung khi liên kết bảng
JOIN Products p ON oi.product_id = p.product_id
WHERE o.status = 'completed'
GROUP BY p.category; --nhóm các dòng (bản ghi) lại dựa trên giá trị của một hoặc nhiều cột
-- ở đây thì là nhóm tất cả các bản ghi theo từng giá trị category
*/

--Tạo danh sách các người dùng kèm theo tên người giới thiệu (dùng self join)
/*
SELECT 
    u.user_id,
    u.full_name AS user_name,
    r.full_name AS referrer_name
FROM Users u
LEFT JOIN Users r ON u.referrer_id = r.user_id; 
--Giữ lại tất cả người dùng(u) dù họ có người giới thiệu (referrer_id) hay không
--Nếu không có người giới thiệu thì (r.full_name) sẽ là NULL
*/

--Tìm các sản phẩm đã từng được đặt mua nhưng hiện tại không còn active
/*
SELECT DISTINCT p.product_id, p.product_name --DISTINCT để loại trùng nếu sản phẩm được mua nhiều lần
FROM Products p
JOIN OrderItems oi ON p.product_id = oi.product_id
WHERE p.is_active = 0;
*/

--Lấy danh sách người dùng không có bất kỳ đơn hàng nào
/*
SELECT u.user_id, u.full_name
FROM Users u
LEFT JOIN Orders o ON u.user_id = o.user_id
WHERE o.order_id IS NULL; --bị NULL sau khi JOIN thì lấy-> ng đó ko có đơn hàng
*/

--Đơn hàng đầu tiên của từng người dùng: Với mỗi user, tìm order_id tương ứng với đơn hàng đầu tiên của họ
/*
SELECT o.user_id, o.order_id, o.order_date
FROM Orders o
JOIN (
    SELECT user_id, MIN(order_date) AS first_order_date
    FROM Orders
    GROUP BY user_id
) first_orders ON o.user_id = first_orders.user_id AND o.order_date = first_orders.first_order_date;
*/

--Tổng chi tiêu của mỗi người dùng: Viết truy vấn lấy tổng tiền mà từng người dùng đã chi tiêu (chỉ tính đơn hàng completed)
/*
SELECT 
    o.user_id,
    SUM(oi.quantity * p.price) AS total_spent
FROM Orders o
JOIN OrderItems oi ON o.order_id = oi.order_id
JOIN Products p ON oi.product_id = p.product_id
WHERE o.status = 'completed'
GROUP BY o.user_id;
--Lọc người dùng tiêu nhiều: Từ kết quả trên, chỉ lấy các user có tổng chi tiêu > 25 triệu
--HAVING SUM(oi.quantity * p.price) > 25000000;
--HAVING để lọc sau khi GROUP BY và tính toán xong, còn WHERE là lọc trước
*/

--So sánh các thành phố: Tính tổng số đơn hàng và tổng doanh thu của từng thành phố
/*
SELECT 
    u.city,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(
	CASE 
		WHEN o.status = 'completed'
		THEN oi.quantity * p.price 
		ELSE 0 
	END
	) AS total_revenue
FROM Users u
LEFT JOIN Orders o ON u.user_id = o.user_id
LEFT JOIN OrderItems oi ON o.order_id = oi.order_id
LEFT JOIN Products p ON oi.product_id = p.product_id
GROUP BY u.city;
*/

--Người dùng có ít nhất 2 đơn hàng completed: Truy xuất danh sách người dùng thỏa điều kiện
/*
SELECT o.user_id, COUNT(*) AS completed_orders
FROM Orders o
WHERE o.status = 'completed'
GROUP BY o.user_id
HAVING COUNT(*) >= 2;
*/

--Tìm đơn hàng có sản phẩm thuộc nhiều hơn 1 danh mục: (gợi ý: JOIN OrderItems và Products rồi GROUP BY order_id + COUNT DISTINCT category > 1)
/*
SELECT oi.order_id
FROM OrderItems oi
JOIN Products p ON oi.product_id = p.product_id
GROUP BY oi.order_id
HAVING COUNT(DISTINCT p.category) > 1;
*/

--Kết hợp danh sách: Dùng UNION để kết hợp 2 danh sách:
/*
A: người dùng đã từng đặt hàng
B: người dùng được người khác giới thiệu
 (loại trùng lặp, lấy user_id, full_name, nguồn đến: “placed_order” hoặc “referred”)
*/
/*
-- A: người từng đặt hàng
SELECT DISTINCT u.user_id, u.full_name, 'placed_order' AS source --thêm cột mới tên source, luôn chứa giá trị 'placed_order'
FROM Users u
JOIN Orders o ON u.user_id = o.user_id

UNION --để kết hợp kết quả của hai truy vấn có cùng cấu trúc cột

-- B: người được người khác giới thiệu
SELECT DISTINCT u.user_id, u.full_name, 'referred' AS source
FROM Users u
WHERE u.referrer_id IS NOT NULL; --phải có ai đó đã giới thiệu ng này
*/