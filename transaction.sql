BEGIN;

-- Điểm lưu trữ đầu tiên
SAVEPOINT initial_state;

# Thêm tài khoản mới
INSERT INTO accounts (accountNumber, accountName, balance, customerID, productCode, openingBranch, openingDate)
VALUES ('12345678', 'NONG TRUONG AN', 500000, '110004', 'CD-101', 'HN002', NOW());

-- Tạo điểm lưu trữ sau khi chèn
SAVEPOINT after_insert;

# Cập nhật số dư cho tài khoản
UPDATE accounts
SET balance = balance + 100000
WHERE accountNumber = '12345678';

-- Điểm lưu trữ trước khi xóa tài khoản
SAVEPOINT before_delete;

# Xóa tài khoản
DELETE FROM accounts
WHERE accountNumber = '12345678';

ROLLBACK TO before_delete; -- Quay lại trạng thái trước khi xóa tài khoản
ROLLBACK TO after_insert; -- Quay lại trạng thái trước khi cập nhật số dư tài khoản
ROLLBACK TO initial_state; -- Quay lại trạng thái ban đầu
