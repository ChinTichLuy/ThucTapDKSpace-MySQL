--CREATE DATABASE sqlday5;

USE sqlday5;
/*
CREATE TABLE Rooms (
    room_id INT IDENTITY(1,1) PRIMARY KEY,
    room_number VARCHAR(10) UNIQUE NOT NULL,
    type VARCHAR(20) CHECK (type IN ('Standard', 'VIP', 'Suite')),
    status VARCHAR(20) CHECK (status IN ('Available', 'Occupied', 'Maintenance')),
    price INT CHECK (price >= 0)
);

CREATE TABLE Guests (
    guest_id INT IDENTITY(1,1) PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    phone VARCHAR(20)
);

CREATE TABLE Bookings (
    booking_id INT IDENTITY(1,1) PRIMARY KEY,
    guest_id INT NOT NULL,
    room_id INT NOT NULL,
    check_in DATE NOT NULL,
    check_out DATE NOT NULL,
    status VARCHAR(20) CHECK (status IN ('Pending', 'Confirmed', 'Cancelled')),

    FOREIGN KEY (guest_id) REFERENCES Guests(guest_id),
    FOREIGN KEY (room_id) REFERENCES Rooms(room_id)
);

CREATE TABLE Invoices (
    invoice_id INT IDENTITY(1,1) PRIMARY KEY,
    booking_id INT FOREIGN KEY REFERENCES Bookings(booking_id),
    total_amount INT NOT NULL,
    generated_date DATETIME DEFAULT GETDATE()
);
*/

--phần fake dữ liệu
/*
INSERT INTO Rooms (room_number, type, status, price)
VALUES 
('103', 'Standard', 'Available', 500),
('105', 'VIP', 'Available', 999),
('202', 'Suite', 'Available', 1500);

INSERT INTO Guests (full_name, phone)
VALUES 
('Taly Nguyen', '0494857499'),
('Tran Ngoc Hong', '0923473445');
*/


--Stored Procedure: MakeBooking
/*
CREATE PROCEDURE MakeBooking
    @p_guest_id INT, -- @p_* là biến tham số đầu vào
    @p_room_id INT,
    @p_check_in DATE,
    @p_check_out DATE
AS		-- AS ở đây nghĩa là bắt đầu định nghĩa thân của thủ tục
BEGIN  --BEGIN ... END dùng để bao các lệnh SQL lại thành một khối, giúp rõ ràng và tránh lỗi
    SET NOCOUNT ON; 
	/* SET NOCOUNT ON: dùng để bỏ thông báo về số lượng dòng bị ảnh hưởng sau khi thực hiện một câu lệnh SQL như INSERT, UPDATE, DELETE, v.v.  vd: (6 rows affected)
	giúp:
	- Tăng hiệu suất trong các stored procedure hoặc script lớn
	- Giảm lưu lượng mạng giữa SQL Server và client
	- Tránh lỗi không mong muốn trong một số ứng dụng xử lý kết quả trả về
	*/

	-- Kiểm tra logic ngày
    IF @p_check_in >= @p_check_out
    BEGIN
        THROW 50000, 'Ngày check-out phải sau ngày check-in!', 1;
		--THROW dùng để trả lỗi thủ công với (mã lỗi tự custom, thông báo lỗi cụ thể, và trạng thái (state) thường = 1)
    END

    -- Kiểm tra trạng thái phòng
    IF NOT EXISTS (
        SELECT 1 FROM Rooms WHERE room_id = @p_room_id AND status = 'Available'
    )
    BEGIN
        THROW 50001, 'Phòng này không có sẵn!', 1; --(đã có người ở hoặc đang bảo trì)
    END

    -- Kiểm tra xung đột thời gian
    IF EXISTS (
        SELECT 1 FROM Bookings
        WHERE room_id = @p_room_id AND status = 'Confirmed'
        AND (
            (@p_check_in < check_out AND @p_check_out > check_in)  -- Trùng thời gian
        )
    )
    BEGIN
        THROW 50002, 'Thời gian đặt phòng đã bị trùng với đơn đặt khác!', 1;
    END

    -- Tạo bản ghi Booking mới
    INSERT INTO Bookings (guest_id, room_id, check_in, check_out, status)
    VALUES (@p_guest_id, @p_room_id, @p_check_in, @p_check_out, 'Confirmed');

    -- Cập nhật trạng thái phòng
    UPDATE Rooms
    SET status = 'Occupied'
    WHERE room_id = @p_room_id;
END;
*/

--test đặt phòng
--EXEC MakeBooking @p_guest_id = 2, @p_room_id = 6, @p_check_in = '2025-06-03', @p_check_out = '2025-06-09';


--Tạo trigger sau khi update Booking
/*
CREATE TRIGGER after_booking_cancel
ON Bookings
AFTER UPDATE --AFTER: chỉ kích hoạt khi có (UPDATE) cập nhật trong Bookings 
AS
BEGIN
    SET NOCOUNT ON;

    -- Xử lý chỉ với các bản ghi vừa bị chuyển sang 'Cancelled'
    UPDATE Rooms
    SET status = 'Available'
    WHERE room_id IN (
        SELECT DISTINCT i.room_id
        FROM inserted i					--inserted: dữ liệu mới sau update (inserted và deleted là hai bảng tạm trong Trigger)
        JOIN deleted d ON i.booking_id = d.booking_id	--deleted: dữ liệu cũ trước update
       
	   -- Chỉ lấy các dòng có trạng thái mới là 'Cancelled', nghĩa là vừa mới bị hủy (không phải đã hủy từ trước)
	    WHERE i.status = 'Cancelled' AND d.status != 'Cancelled' 

        AND NOT EXISTS (
            SELECT 1 FROM Bookings b
            WHERE b.room_id = i.room_id
              AND b.status = 'Confirmed'
              AND b.check_out > GETDATE()  -- vẫn còn đơn đặt trong tương lai
        )
		-- tức là chỉ khi không còn ai đặt phòng này trong tương lai nữa, thì mới đổi phòng đó thành Available
    );
END;
*/

--UPDATE Bookings SET status = 'Cancelled' WHERE booking_id = 4;


--bonus phần tạo hóa đơn
/*
CREATE PROCEDURE GenerateInvoice
    @p_booking_id INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Kiểm tra booking tồn tại và đã xác nhận chưa
    IF NOT EXISTS (
        SELECT 1 FROM Bookings
        WHERE booking_id = @p_booking_id AND status = 'Confirmed'
    )
    BEGIN
        THROW 50003, 'Booking không tồn tại hoặc chưa được xác nhận!', 1;
    END

    -- Tính toán và lấy dữ liệu
    DECLARE @check_in DATE, @check_out DATE, @price INT, @nights INT, @total INT; 
	--Tạo ra biến tạm trong procedure để lưu dữ liệu--

    SELECT 
        @check_in = b.check_in,
        @check_out = b.check_out,
        @price = r.price
    FROM Bookings b
    JOIN Rooms r ON b.room_id = r.room_id
    WHERE b.booking_id = @p_booking_id;

    -- Tính số đêm
    SET @nights = DATEDIFF(DAY, @check_in, @check_out); --DATEDIFF:dùng để tính khoảng cách thời gian giữa 2 ngày (checkin và checkout)

    IF @nights <= 0
    BEGIN
        THROW 50004, 'Thời gian lưu trú không hợp lệ!', 1;
    END

    SET @total = @nights * @price;

    -- Insert vào bảng Invoices
    INSERT INTO Invoices (booking_id, total_amount)
    VALUES (@p_booking_id, @total);
END;
*/

--test xuất hóa đơn
EXEC GenerateInvoice @p_booking_id = 5;



-- fix lại bảng để fix logic trong quá trình test
--DROP PROCEDURE IF EXISTS MakeBooking;
--DROP TABLE IF EXISTS Bookings;
--UPDATE Rooms SET status = 'Available' WHERE room_id = 1;
--DROP TRIGGER IF EXISTS after_booking_cancel;

-- phần xem các bảng
SELECT * FROM Rooms;
SELECT * FROM Guests;
SELECT * FROM Bookings;
SELECT * FROM Invoices;