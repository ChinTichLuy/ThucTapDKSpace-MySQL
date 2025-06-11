--CREATE DATABASE sqlday8;

--USE sqlday8;
/*
CREATE TABLE Users (
    user_id INT PRIMARY KEY IDENTITY(1,1),
    username NVARCHAR(50) NOT NULL,
    created_at DATETIME DEFAULT GETDATE()
);

CREATE TABLE Posts (
    post_id INT PRIMARY KEY IDENTITY(1,1),
    user_id INT NOT NULL,
    content NVARCHAR(500),
    created_at DATETIME DEFAULT GETDATE(),
    likes INT DEFAULT 0,
    hashtags VARCHAR(255),
    FOREIGN KEY (user_id) REFERENCES Users(user_id)
);

CREATE TABLE Follows (
    follower_id INT,
    followee_id INT,
    PRIMARY KEY (follower_id, followee_id),
    FOREIGN KEY (follower_id) REFERENCES Users(user_id),
    FOREIGN KEY (followee_id) REFERENCES Users(user_id)
);

CREATE TABLE PostViews (
    view_id BIGINT PRIMARY KEY IDENTITY(1,1),
    post_id INT NOT NULL,
    viewer_id INT NOT NULL,
    view_time DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (post_id) REFERENCES Posts(post_id),
    FOREIGN KEY (viewer_id) REFERENCES Users(user_id)
);

CREATE TABLE Hashtags (
    hashtag_id INT IDENTITY PRIMARY KEY,
    tag VARCHAR(50) UNIQUE NOT NULL
);

CREATE TABLE PostHashtags (
    post_id INT FOREIGN KEY REFERENCES Posts(post_id),
    hashtag_id INT FOREIGN KEY REFERENCES Hashtags(hashtag_id),
    PRIMARY KEY (post_id, hashtag_id)
);

CREATE TABLE PostLikes (
    post_id INT FOREIGN KEY REFERENCES Posts(post_id),
    user_id INT FOREIGN KEY REFERENCES Users(user_id),
    liked_at DATETIME DEFAULT GETDATE(),
    PRIMARY KEY (post_id, user_id) -- tránh trùng like
);
*/

/*
INSERT INTO Users (username) VALUES 
('HoangTaly'), 
('VitaminChin'), 
('Chinesu'), 
('Nguyễn Dương'), 
('Hoàng Tú');

INSERT INTO Posts (user_id, content, hashtags, created_at, likes) VALUES
(1, N'Chạy bộ buổi sáng thật tuyệt vời!', 'fitness,morning', GETDATE(), 5),
(2, N'Chuyến tham quan Hà Nội!', 'travel,vietnam', GETDATE(), 10),
(3, N'Đồ ăn healthy là 1 ý tưởng tuyệt vời!', 'fitness,food', DATEADD(DAY, -1, GETDATE()), 3),
(4, N'Khám phá hang động ở Hạ long!', 'travel,sea', DATEADD(DAY, -1, GETDATE()), 8),
(5, N'Đồ ăn tại Đà Lạt có lạnh không?', 'travel,food', DATEADD(DAY, -1, GETDATE()), 7),
(1, N'Lượn lờ Nha trang', 'travel,food', DATEADD(DAY, -1, GETDATE()), 6);


INSERT INTO Follows (follower_id, followee_id) VALUES
(1, 2),
(2, 1),
(3, 2),
(3, 5),
(5, 1),
(1, 5),
(4, 1);

INSERT INTO PostViews (post_id, viewer_id, view_time) VALUES
(1, 2, GETDATE()),
(1, 3, GETDATE()),
(2, 1, GETDATE()),
(2, 3, DATEADD(DAY, -2, GETDATE())),
(3, 4, DATEADD(DAY, -1, GETDATE())),
(4, 2, GETDATE()),
(4, 1, DATEADD(DAY, -1, GETDATE())),
(2, 4, DATEADD(HOUR, -5, GETDATE())),           
(5, 1, DATEADD(DAY, -3, GETDATE())),            
(3, 2, DATEADD(MINUTE, -30, GETDATE())),       
(4, 5, DATEADD(DAY, -1, GETDATE())),           
(6, 4, DATEADD(SECOND, -20, GETDATE()));   
*/

--Viết truy vấn trả về danh sách 10 bài viết được "thích" nhiều nhất hôm nay
/*
SELECT TOP 10
    P.post_id,
    P.content,
    P.likes,
    P.created_at,
    U.username
--INTO #TopLikedToday --để dùng bảng tạm sau này
FROM Posts P
JOIN Users U ON P.user_id = U.user_id
WHERE CAST(P.created_at AS DATE) = CAST(GETDATE() AS DATE)--CAST(... AS DATE) chỉ lấy phần ngày, bỏ qua phần thời gian(giờ phút giây), vì hiện tại cần so sánh lọc dữ liệu theo ngày
ORDER BY P.likes DESC;
*/

/*SQL Server không có MEMORY TABLE giống MySQL, 
 nhưng vẫn có thể dùng table variable hoặc temporary table nếu cần cache tạm trong session
	#TênBảng là Temporary Table (bảng tạm, lưu trong tempdb)
	@TênBiến là Table Variable
*/
-- dùng Temporary Table #TopLikedToday(bảng tạm)
--SELECT * FROM #TopLikedToday;

/*
 Sử dụng EXPLAIN ANALYZE (MySQL 8.0+):
Phân tích chi tiết truy vấn sau và chỉ ra bottlenecks:
SELECT * FROM Posts 
WHERE hashtags LIKE '%fitness%' 
ORDER BY created_at DESC 
LIMIT 20;
*/
/*
SET SHOWPLAN_ALL ON;
GO
SELECT TOP 20 *
FROM Posts
WHERE hashtags LIKE '%fitness%'
ORDER BY created_at DESC;
GO
SET SHOWPLAN_ALL OFF;
GO
*/
/*
- Bottlenecks (điểm nghẽn)
	LIKE '%fitness%'        :  Không dùng được index -> Table Scan toàn bộ bảng (Full Scan)             
	ORDER BY created_at DESC:  Nếu không có index 'created_at DESC' -> phải sort toàn bảng              
	TOP 20                  :  Giới hạn kết quả, nhưng không giúp giảm lượng dữ liệu cần quét trước đó 
*/


--Viết truy vấn thống kê số lượt xem mỗi tháng trong 6 tháng gần nhất
/*
SELECT 
  FORMAT(view_time, 'yyyy-MM') AS Month,
  COUNT(*) AS ViewCount
FROM PostViews
WHERE view_time >= DATEADD(MONTH, -6, GETDATE())
GROUP BY FORMAT(view_time, 'yyyy-MM')
ORDER BY Month DESC;
*/


/*
 Sử dụng Window Functions thay vòng lặp thủ công:
Viết truy vấn:
Tính tổng số view mỗi bài viết và xếp hạng (RANK) theo số view mỗi ngày (view_time).
Truy vấn top 3 bài viết mỗi ngày
*/
/*
WITH ViewRank AS (
  SELECT 
    post_id,
    CAST(view_time AS DATE) AS view_date,
    COUNT(*) AS view_count,
    RANK() OVER (PARTITION BY CAST(view_time AS DATE) ORDER BY COUNT(*) DESC) AS rank
  FROM PostViews
  GROUP BY post_id, CAST(view_time AS DATE)
)
SELECT *
FROM ViewRank
WHERE rank <= 3
ORDER BY view_date DESC, rank;
*/

/*
Tối ưu transaction ngắn gọn:
Viết stored procedure cập nhật lượt thích (likes) của một bài viết khi người dùng click like.
Đảm bảo:
Transaction tối thiểu các bước.
Tránh cập nhật không cần thiết nếu người dùng đã like rồi
*/
/*
CREATE PROCEDURE LikePost
  @user_id INT,
  @post_id INT
AS
BEGIN
  SET NOCOUNT ON;

  IF EXISTS (
    SELECT 1 FROM PostLikes
    WHERE user_id = @user_id AND post_id = @post_id
  )
    RETURN; -- đã like rồi sẽ trả về luôn ko chạy + like nữa

  BEGIN TRANSACTION;
    INSERT INTO PostLikes(user_id, post_id) VALUES (@user_id, @post_id);
    UPDATE Posts SET likes = likes + 1 WHERE post_id = @post_id;
  COMMIT;
END
*/

--test LikePost
--EXEC LikePost @post_id = 3, @user_id = 5;
-- DROP PROCEDURE LikePost;
--SELECT * FROM PostLikes;

/*
Kiểm tra Slow Query Log:
Mô tả cách bật slow_query_log, phân tích log để tìm truy vấn chậm.
Đưa ra ví dụ với một truy vấn chậm và cách cải thiện (thêm index, viết lại, limit...)
*/


/*
Sử dụng OPTIMIZER_TRACE để debug sâu:
Kích hoạt optimizer_trace trong MySQL.
Chạy một truy vấn phức tạp có JOIN, WHERE, ORDER BY.
Phân tích tệp JSON trả về để hiểu vì sao MySQL chọn kế hoạch truy vấn đó
*/
