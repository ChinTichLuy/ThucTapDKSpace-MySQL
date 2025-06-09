--CREATE DATABASE sqlday6;

--USE sqlday6;

/*
CREATE TABLE Accounts (
    account_id INT PRIMARY KEY IDENTITY(1,1),
    full_name NVARCHAR(100),
    balance DECIMAL(18,2),
    status NVARCHAR(20) CHECK (status IN ('Active', 'Frozen', 'Closed'))
);


CREATE TABLE Transactions (
    txn_id INT PRIMARY KEY IDENTITY(1,1),
    from_account INT,
    to_account INT,
    amount DECIMAL(18,2),
    txn_date DATETIME DEFAULT GETDATE(),
    status NVARCHAR(20) CHECK (status IN ('Success', 'Failed', 'Pending')),
    FOREIGN KEY (from_account) REFERENCES Accounts(account_id),
    FOREIGN KEY (to_account) REFERENCES Accounts(account_id)
);


CREATE TABLE TxnAuditLogs (
    log_id INT PRIMARY KEY IDENTITY(1,1),
    txn_id INT,
    log_message NVARCHAR(MAX),
    log_date DATETIME DEFAULT GETDATE()
);
*/

/*Trong SQL Server, mọi bảng đều hỗ trợ transaction.
Nhưng vẫn có thể ghi log ngoài transaction bằng cách gọi thủ tục ghi log sau COMMIT
hoặc bằng cách dùng thủ tục riêng
*/
/*
INSERT INTO Accounts ( full_name, balance, status) VALUES
(N'Nguyễn Văn A', 5000.00, 'Active'),
(N'Trần Thị B', 3000.00, 'Active'),
(N'Lê Văn C', 2000.00, 'Frozen'),
(N'Hoàng Văn D', 6000.00, 'Active'),
(N'Vương Thị E', 9000.00, 'Active');
*/

--Stored Procedure TransferMoney với transaction + rollback + audit log + chống deadlock

/*
CREATE PROCEDURE TransferMoney
    @p_from_account INT,
    @p_to_account INT,
    @p_amount DECIMAL(18,2)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @current_balance DECIMAL(18,2);
    DECLARE @last_txn_id INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Kiểm tra trạng thái Active
        IF NOT EXISTS (
            SELECT 1 FROM Accounts
            WHERE account_id = @p_from_account AND status = 'Active'
        ) OR NOT EXISTS (
            SELECT 1 FROM Accounts
            WHERE account_id = @p_to_account AND status = 'Active'
        )
        BEGIN
            THROW 50001, 'Tài khoản gửi hoặc nhận không tồn tại hoặc không hoạt động!', 1;
        END

         -- Kiểm tra số dư (sử dụng lock)
         SET @current_balance = (SELECT balance 
        FROM Accounts WITH (UPDLOCK, ROWLOCK) 
        WHERE account_id = @p_from_account);
		--WITH (UPDLOCK, ROWLOCK): khóa hàng để tránh các giao dịch khác thay đổi số dư khi đang kiểm tra số dư

        IF @current_balance < @p_amount
        BEGIN
            THROW 50003, 'Tài khoản gửi không đủ số dư!', 1;
        END

        -- Trừ và cộng tiền
        UPDATE Accounts
        SET balance = balance - @p_amount
        WHERE account_id = @p_from_account;

        UPDATE Accounts
        SET balance = balance + @p_amount
        WHERE account_id = @p_to_account;

        -- Ghi vào bảng Transactions
        INSERT INTO Transactions (from_account, to_account, amount, status)
        VALUES (@p_from_account, @p_to_account, @p_amount, 'Success');

		--set id cho bảng log
        SET @last_txn_id = SCOPE_IDENTITY();
		--SCOPE_IDENTITY(): hàm trả về giá trị ID mới nhất được sinh ra bởi một cột có kiểu IDENTITY

        -- Ghi vào bảng log
        INSERT INTO TxnAuditLogs (txn_id, log_message)
        VALUES (
            @last_txn_id, 
            CONCAT(N'Số tiền ', @p_amount, N' từ account ', @p_from_account, N' đến account ', @p_to_account)
			--CONCAT() là hàm nối chuỗi - dùng để kết hợp nhiều giá trị (chuỗi, số, v.v.) thành một chuỗi duy nhất
        );

        COMMIT;
    END TRY
    BEGIN CATCH
        DECLARE @err_msg NVARCHAR(4000);
        IF XACT_STATE() <> 0
            ROLLBACK;

        SET @err_msg = ERROR_MESSAGE();

        -- Ghi log lỗi
        INSERT INTO TxnAuditLogs (txn_id, log_message)
        VALUES (NULL, 'Transaction failed: ' + @err_msg);

        -- Gửi lỗi về client
        THROW 50004, @err_msg, 1;
    END CATCH
END;
*/

--test giao dịch
EXEC TransferMoney @p_from_account =5, @p_to_account =4, @p_amount = 3000;

--DROP PROCEDURE TransferMoney;
--DROP TABLE TxnAuditLogs;
--ROLLBACK;
--SELECT @@TRANCOUNT; --Kiểm tra lại 

/*
--check session bị kẹt, chặn, chờ và kill nó
--KILL 52;
SELECT
    s.session_id,
    s.status,
    r.blocking_session_id,
    t.text AS last_sql,
    s.open_transaction_count,
    r.wait_type,
    r.wait_time,
    r.status AS request_status
FROM sys.dm_exec_sessions s
LEFT JOIN sys.dm_exec_requests r ON s.session_id = r.session_id
OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) t
WHERE s.is_user_process = 1
ORDER BY s.session_id;
*/


--SELECT * FROM Accounts;
--SELECT * FROM Transactions;
--SELECT * FROM TxnAuditLogs;

