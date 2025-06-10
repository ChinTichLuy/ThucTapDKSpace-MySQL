--CREATE DATABASE sqlday7;

--USE sqlday7;

/*
CREATE TABLE Categories (
    category_id INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(100)
);

CREATE TABLE Products (
    product_id INT PRIMARY KEY IDENTITY(1,1),
    name VARCHAR(255),
    category_id INT FOREIGN KEY REFERENCES Categories(category_id),
    price DECIMAL(10, 2),
    stock_quantity INT,
    created_at DATETIME
);

CREATE TABLE Orders (
    order_id INT PRIMARY KEY IDENTITY(1,1),
    user_id INT,
    order_date DATETIME,
    status VARCHAR(20) CHECK (status IN ('Pending', 'Shipped', 'Cancelled'))
);

CREATE TABLE OrderItems (
    order_item_id INT PRIMARY KEY IDENTITY(1,1),
    order_id INT FOREIGN KEY REFERENCES Orders(order_id),
    product_id INT FOREIGN KEY REFERENCES Products(product_id),
    quantity INT,
    unit_price DECIMAL(10, 2)
);


INSERT INTO Categories (name)
VALUES 
    ('Điện thoại'),
    ('Laptop'),
    ('Phụ kiện'),
    ('Máy tính bảng');

INSERT INTO Products (name, category_id, price, stock_quantity, created_at)
VALUES 
    ('iPhone 14 Pro Max', 1, 29990000, 25, GETDATE()),
    ('Samsung Galaxy Z Fold5', 1, 40990000, 10, GETDATE()),
    ('MacBook Air M2', 2, 28990000, 15, GETDATE()),
    ('Dell Inspiron 15', 2, 18990000, 20, GETDATE()),
    ('Cáp sạc nhanh USB-C', 3, 250000, 100, GETDATE()),
    ('iPad Air 2024', 4, 22990000, 12, GETDATE());

INSERT INTO Orders (user_id, order_date, status)
VALUES 
    (101, '2024-06-01 09:00:00', 'Pending'),
    (102, '2024-06-02 10:15:00', 'Shipped'),
    (103, '2024-06-03 14:30:00', 'Cancelled'),
	(103, '2024-07-01 09:00:00', 'Shipped'),
    (102, '2024-08-02 10:15:00', 'Shipped'),
    (101, '2024-09-03 14:30:00', 'Shipped'),
	(104, '2025-05-15 09:00:00', 'Shipped'),
    (105, '2025-06-01 10:00:00', 'Shipped'),
    (106, '2025-06-05 11:30:00', 'Shipped');

INSERT INTO OrderItems (order_id, product_id, quantity, unit_price)
VALUES 
    (1, 1, 1, 29990000),
    (1, 5, 2, 250000),
    (2, 3, 1, 28990000),
    (3, 2, 1, 40990000),
    (3, 6, 1, 22990000),
	(4, 1, 5, 2888800),
    (5, 5, 2, 29999000),
    (5, 3, 4, 2923000),
    (6, 2, 8, 85744100),
    (6, 6, 1, 26574500),
	(7, 1, 5, 29990000),  
    (7, 2, 2, 40990000),  
    (8, 1, 3, 29990000),  
    (9, 5, 10, 250000), 
    (9, 1, 2, 29990000); 
*/


/*
Phân tích truy vấn sau bằng EXPLAIN và đề xuất cải tiến:
SELECT * 
FROM Orders 
JOIN OrderItems ON Orders.order_id = OrderItems.order_id
WHERE status = 'Shipped'
ORDER BY order_date DESC;
*/
--phân tích
/*
SET SHOWPLAN_ALL ON;
GO
SELECT * 
FROM Orders 
JOIN OrderItems ON Orders.order_id = OrderItems.order_id
WHERE status = 'Shipped'
ORDER BY order_date DESC;
GO
SET SHOWPLAN_ALL OFF;
GO
*/

/*
- vấn đề: 
	SELECT * lấy tất cả cột -> tốn tài nguyên không cần thiết
	status = 'Shipped' cần chỉ mục để lọc nhanh
	ORDER BY order_date DESC cần chỉ mục hỗ trợ sắp xếp
	JOIN cần tối ưu khóa ngoại order_id

- đề xuất cải tiến:
	### thêm chỉ mục
	-- Chỉ mục lọc nhanh theo status và sắp xếp theo order_date
	CREATE NONCLUSTERED INDEX idx_orders_status_date
	ON Orders (status, order_date DESC);

	-- Chỉ mục JOIN nhanh giữa OrderItems và Orders
	CREATE NONCLUSTERED INDEX idx_orderitems_orderid_productid
	ON OrderItems (order_id, product_id);

	### tối ưu truy vấn, dùng các trường cần thiết
	SELECT 
    o.order_id, o.order_date, o.status, 
    oi.product_id, oi.quantity, oi.unit_price
	FROM Orders o
	JOIN OrderItems oi ON o.order_id = oi.order_id
	WHERE o.status = 'Shipped'
	ORDER BY o.order_date DESC;
*/
/*
- các cột cần lưu ý:
PhysicalOp (thao tác vật lý):
	Index Seek -> rất tối ưu -> dùng chỉ mục
	Index Scan / Table Scan -> không tối ưu (đọc toàn bảng)
	Hash Match Join -> có thể tốn tài nguyên nếu bảng lớn

EstimateRows (ước lượng số dòng):
	Nếu con số quá lớn (>100K) -> SQL cần tối ưu lại chỉ mục
	Nếu thấy Index Seek mà EstimateRows nhỏ là OK

TotalSubtreeCost:
	Tổng chi phí tính toán (số càng thấp càng tốt)
	Khi so sánh 2 truy vấn thì đây cũng là 1 chỉ số để biết truy vấn nào tối ưu hơn

OutputList và DefinedValues:
	cho biết các cột được chọn -> dùng để biết truy vấn có SELECT * không
	Giúp thấy việc chỉ chọn cột cần thiết là hiệu quả

 - các dấu hiệu của 1 truy vấn được xem là tối ưu khi:
Index Seek xuất hiện ở JOIN hoặc WHERE:		SQL tìm đúng dữ liệu
Không có Table Scan:						để tránh quét toàn bộ bảng
TotalSubtreeCost nhỏ:						chi phí thấp, hiệu suất cao ( cột này càng thấp càng tốt)
EstimateRows hợp lý (không cực lớn): 		Tránh tình trạng đọc thừa
JOIN kiểu Nested Loop (với index) 
hoặc Merge Join nếu dữ liệu lớn:			Tránh Hash Join nếu không cần thiết
*/

/*  
Tạo chỉ mục phù hợp để tăng tốc truy vấn theo status, order_date
Tạo composite index cho bảng OrderItems theo order_id, product_id để hỗ trợ JOIN hiệu quả
*/
/*
-- Chỉ mục lọc nhanh theo status và sắp xếp theo order_date
	CREATE NONCLUSTERED INDEX idx_orders_status_date
	ON Orders (status, order_date DESC);

-- Chỉ mục JOIN nhanh giữa OrderItems và Orders
	CREATE NONCLUSTERED INDEX idx_orderitems_orderid_productid
	ON OrderItems (order_id, product_id);
*/

--Sửa truy vấn SELECT * thành chỉ chọn cột cần thiết
/*
SELECT 
    o.order_id, o.order_date, o.status, 
    oi.product_id, oi.quantity, oi.unit_price
	FROM Orders o
	JOIN OrderItems oi ON o.order_id = oi.order_id
	WHERE o.status = 'Shipped'
	ORDER BY o.order_date DESC;
*/

--So sánh hiệu suất: JOIN vs Subquery
/*
-- JOIN giữa bảng Products và Categories
SELECT p.product_id, p.name, c.name AS category_name
FROM Products p
JOIN Categories c ON p.category_id = c.category_id;

-- Subquery lấy tên danh mục
SELECT product_id, name,
    (SELECT name FROM Categories WHERE category_id = p.category_id) AS category_name
FROM Products p;
*/

/*
- đối với quy mô nhỏ (trường hợp này) thì 2 cái chênh lệch không đáng kể, và có thể Subquery sẽ chậm hơn 1 chút về hiệu suất
- đối với quy mô lớn thì JOIN nhanh hơn đáng kể nhờ tối ưu hóa join và chỉ mục, Subquery sẽ chậm hơn vì nó phải thực hiện nhiều lần

- JOIN thì sẽ tạo ra 1 đường nối giữa 2 bảng, tạo ra bảng tạm nối
- Subquery thì sẽ chạy truy vấn  cho con "mỗi dòng" trong bảng cha

  (tôi ưu hóa SQL Engine)
- JOIN thì dễ tối ưu hơn, hỗ trợ index join, hash join, merge join
- Subquery thì có thể gây lỗi

- JOIN đọc code dễ dàng hơn nếu làm việc nhiều bảng
- Subquery đọc code dễ hơn nếu truy vấn đơn giản, nhưng sẽ rất rối khi làm việc với nhiều cấp, nhiều bảng

- JOIN khả năng mở rộng rất dễ dàng, tốt hơn rất nhiều
- Subquery thì kém hơn khi mở rộng

=> JOIN luôn tối ưu hơn Subquery
*/

/* Viết truy vấn để lấy 10 sản phẩm mới nhất trong danh mục “Electronics”, có stock_quantity > 0.
	(Áp dụng: WHERE, LIMIT, ORDER BY, JOIN, tránh dùng hàm trong WHERE)
*/
/*
SELECT TOP 10 p.product_id, p.name, p.created_at
FROM Products p
JOIN Categories c ON p.category_id = c.category_id
WHERE c.name = 'Điện thoại' AND p.stock_quantity > 0
ORDER BY p.created_at DESC;
*/

/*
Tạo một Covering Index cho truy vấn thường xuyên:
SELECT product_id, name, price 
FROM Products 
WHERE category_id = 3 
ORDER BY price ASC 
LIMIT 20;
-- trong SQL SERVER không hỗ trợ LIMIT, dùng TOP hoặc OFFSET...FETCH
--SELECT product_id, name, price->> SELECT TOP 20 product_id, name, price
--LIMIT 20; ->> OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY; dùng nếu cần phân trang (ví dụ trang 2 sẽ là OFFSET 20 ROWS FETCH NEXT 20 ROWS)
*/

/*
CREATE NONCLUSTERED INDEX idx_products_covering
ON Products (category_id, price ASC)
INCLUDE (product_id, name);
*/

/*
Tối ưu truy vấn tính doanh thu theo tháng, dùng GROUP BY:
Áp dụng DATE_FORMAT(order_date, '%Y-%m')
Tránh dùng hàm trong WHERE, thay bằng điều kiện thời gian chuẩn
*/
--SELECT * FROM Orders;
--SELECT * FROM OrderItems;
/*
SELECT 
    FORMAT(o.order_date, 'yyyy-MM') AS order_month,
    SUM(oi.quantity * oi.unit_price) AS total_revenue
FROM Orders o
JOIN OrderItems oi ON o.order_id = oi.order_id
WHERE o.order_date >= '2024-01-01' AND o.order_date < '2025-01-01'
GROUP BY FORMAT(o.order_date, 'yyyy-MM')
ORDER BY order_month;
*/

/*
Tách truy vấn lớn thành nhiều bước nhỏ:
Ví dụ: Lọc đơn hàng có nhiều sản phẩm đắt tiền (>1M), sau đó tính tổng số lượng bán ra.
*/

/*
-- Bước 1: Lọc đơn hàng có ít nhất 1 sản phẩm giá > 1M
WITH ExpensiveOrders AS (
    SELECT DISTINCT order_id
    FROM OrderItems
    WHERE unit_price > 1000000
)

-- Bước 2: Tính tổng số lượng sản phẩm đã bán trong các đơn hàng đó

SELECT p.product_id, p.name, SUM(oi.quantity) AS total_sold
FROM OrderItems oi
JOIN Products p ON oi.product_id = p.product_id
JOIN ExpensiveOrders eo ON oi.order_id = eo.order_id
GROUP BY p.product_id, p.name
ORDER BY total_sold DESC;
*/

/*
Viết truy vấn liệt kê top 5 sản phẩm bán chạy nhất trong 30 ngày gần nhất.
Gợi ý: Dùng JOIN, WHERE, GROUP BY, ORDER BY, LIMIT
*/
/*
SELECT TOP 5 p.product_id, p.name, SUM(oi.quantity) AS total_quantity
FROM OrderItems oi
JOIN Orders o ON oi.order_id = o.order_id
JOIN Products p ON oi.product_id = p.product_id
WHERE o.order_date >= DATEADD(DAY, -30, GETDATE())
  AND o.status = 'Shipped'
GROUP BY p.product_id, p.name
ORDER BY total_quantity DESC;
*/
