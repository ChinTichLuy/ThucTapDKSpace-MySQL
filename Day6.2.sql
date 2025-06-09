USE sqlday6;
--Isolation Level: để kiểm soát mức độ khóa dữ liệu
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ; -- mặc định của InnoDB
BEGIN TRANSACTION;

-- Đọc số dư tài khoản 
SELECT balance FROM Accounts WHERE account_id = 5;

-- COMMIT hoặc ROLLBACK tùy ý
--COMMIT đến khi nào hết thì thôi

WHILE @@TRANCOUNT > 0
BEGIN
    COMMIT;-- xác nhận và ghi thay đổi vào CSDL
END

--ROLLBACK; -- hủy tất cả thay đổi trong giao dịch
--nếu không thay đổi dữ liệu thì ROLLBACK chỉ đơn giản là giải phóng lock

SELECT @@TRANCOUNT; --Kiểm tra lại COMMIT

/*
- InnoDB (bộ máy lưu trữ mặc định trong MySQL/MariaDB)
khi dùng REPEATABLE READ sẽ không dùng khóa vật lý để giữ dòng đã đọc,
mà tạo một "snapshot" (ảnh chụp) dữ liệu ở thời điểm bắt đầu transaction.

Gọi là MVCC – Multi-Version Concurrency Control, tức là:
Khi mà SELECT, thì sẽ không đọc dòng hiện tại trong bảng,
mà sẽ đọc lại phiên bản (cũ) "đúng với thời điểm transaction bắt đầu"

=> Đây là lý do mà không thấy dòng bị thay đổi dù giao dịch khác đã update 
– vì bản hiện tại đang đọc là bản snapshot cũ

Các mức độ đọc:
- READ UNCOMMITTED: Cho phép đọc dữ liệu chưa COMMIT từ giao dịch khác
- READ COMMITTED:	Chỉ đọc dữ liệu đã COMMIT
- REPEATABLE READ:	Khóa các dòng đã đọc -> không cho thay đổi, xóa
- SERIALIZABLE: 	Khóa toàn bộ phạm vi đọc (nghiêm ngặt nhất)
*/