-- 1. Lấy thông tin tài khoản bằng mã khách hàng
DELIMITER $$
CREATE PROCEDURE GetAccountsByCustomerID(
    IN p_customerID VARCHAR(50)
)
BEGIN
    SELECT accountNumber, accountName, balance, productCode, openingBranch, openingDate
    FROM accounts
    WHERE customerID = p_customerID;
END $$
DELIMITER ;


-- 2. Lấy lịch sử giao dịch của một tài khoản
DELIMITER $$
CREATE PROCEDURE GetTransactionHistory(
    IN p_accountNumber VARCHAR(50)
)
BEGIN
    SELECT transactionNumber, sourceAccount, targetAccount, transactionType, amount, time, description
    FROM transactions
    WHERE sourceAccount = p_accountNumber OR targetAccount = p_accountNumber
    ORDER BY time DESC;
END $$
DELIMITER ;


-- 3. Đưa ra danh sách nhân viên của một chi nhánh
DELIMITER $$
CREATE PROCEDURE GetEmployeesByBranch(
    IN p_branchCode VARCHAR(50)
)
BEGIN
    SELECT employeeCode, CONCAT(lastName, ' ', firstName) as FullName, position, department, managerCode
    FROM employees
    WHERE branchCode = p_branchCode;
END $$
DELIMITER ;


-- 4. Đưa ra danh sách các giao dịch trong 1 năm hoặc 1 tháng hoặc 1 ngày cụ thể nào đó
DELIMITER $$
CREATE PROCEDURE GetTransactionsBySpecificDate(
    IN p_year INT,      -- Có thể NULL
    IN p_month INT,     -- Có thể NULL
    IN p_day INT        -- Có thể NULL
)
BEGIN
    SELECT transactionNumber, sourceAccount, targetAccount, transactionType, amount, time, description, employeeCode
    FROM transactions
    WHERE
        (p_year IS NULL OR YEAR(time) = p_year) AND
        (p_month IS NULL OR MONTH(time) = p_month) AND
        (p_day IS NULL OR DAY(time) = p_day)
    ORDER BY time;
END $$
DELIMITER ;


-- 5. Tính tổng số tiền trong tất cả tài khoản của 1 khách hàng
DELIMITER $$
CREATE PROCEDURE GetTotalBalanceByCustomer(
    IN p_customerID VARCHAR(50)
)
BEGIN
    SELECT SUM(balance) AS totalBalance
    FROM accounts
    WHERE customerID = p_customerID;
END $$
DELIMITER ;


-- 6. Đưa ra danh sách các nhân viên và số lượng giao dịch đã thực hiện theo thứ tự giảm dần
DELIMITER $$
CREATE PROCEDURE GetEmployeeTransactionStats()
BEGIN
    SELECT
        e.employeeCode AS EmployeeCode,
        CONCAT(e.lastName, ' ', e.firstName) AS EmployeeName,
        b.branchName AS BranchName,
        e.position AS Position,
        e.department AS Department,
        (SELECT CONCAT(m.lastName, ' ', m.firstName)
         FROM employees m
         WHERE m.employeeCode = e.managerCode) AS ManagerName,
        COUNT(t.transactionNumber) AS TransactionCount
    FROM
        employees e
            LEFT JOIN
        branches b ON e.branchCode = b.branchCode
            LEFT JOIN
        transactions t ON e.employeeCode = t.employeeCode
    GROUP BY
        e.employeeCode, e.lastName, e.firstName, b.branchName, e.position, e.department, e.managerCode
    ORDER BY
        TransactionCount DESC;
END $$
DELIMITER ;


-- 7. Thêm một khách hàng mới tại ngân hàng
DELIMITER $$
CREATE PROCEDURE AddNewCustomer(
    IN p_customerID VARCHAR(50),
    IN p_lastName VARCHAR(50),
    IN p_firstName VARCHAR(50),
    IN p_birthDate DATE,
    IN p_phoneNumber VARCHAR(15),
    IN p_address VARCHAR(256),
    IN p_creditScore INT
)
BEGIN
    # Kiểm tra nếu khách hàng đã tồn tại
    IF EXISTS (SELECT 1 FROM customers WHERE customerID = p_customerID) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Khách hàng đã tồn tại trên hệ thống';
    ELSE
        INSERT INTO customers (customerID, lastName, firstName, birthDate, phoneNumber, address, creditScore)
        VALUES (p_customerID, p_lastName, p_firstName, p_birthDate, p_phoneNumber, p_address, p_creditScore);
    END IF;
END$$
DELIMITER ;


-- 8. Mở một tài khoản mới tại ngân hàng (mở tài khoản + nạp tiền)
DELIMITER $$
CREATE PROCEDURE OpenNewAccount(
    IN p_accountNumber VARCHAR(256),
    IN p_accountName VARCHAR(256),
    IN p_balance BIGINT,
    IN p_customerID VARCHAR(50),
    IN p_productCode VARCHAR(50),
    IN p_openingBranch VARCHAR(50),
    IN p_openingDate DATETIME
)
BEGIN
    # Thêm tài khoản mới
    INSERT INTO accounts (accountNumber, accountName, balance, customerID, productCode, openingBranch, openingDate)
    VALUES (p_accountNumber, p_accountName, p_balance, p_customerID, p_productCode, p_openingBranch, p_openingDate);

    # Thêm giao dịch nạp tiền khi mở tài khoản
    INSERT INTO transactions (sourceAccount, targetAccount, transactionType, amount, time, description, employeeCode)
    VALUES (NULL, p_accountNumber, 'OPENING', p_balance, p_openingDate, 'Mo tai khoan', NULL);
END$$
DELIMITER ;


-- 9. Lấy danh sách nhân viên theo chức vụ
DELIMITER $$
CREATE PROCEDURE GetEmployeesByPosition(
    IN p_position VARCHAR(256)
)
BEGIN
    SELECT employeeCode, lastName, firstName, branchCode, department
    FROM employees
    WHERE position = p_position;
END$$
DELIMITER ;


-- 10. Tính lãi suất của một tài khoản
DELIMITER $$
CREATE PROCEDURE CalculateInterestForAccount(
    IN p_accountNumber VARCHAR(256)
)
BEGIN
    DECLARE p_balance BIGINT;               # Số dư tài khoản
    DECLARE p_interestRate FLOAT;           # Lãi suất (%)
    DECLARE p_term INT;                     # Kỳ hạn (tháng)
    DECLARE last_interest_date DATETIME;    # Ngày trả lãi gần nhất
    DECLARE interest_amount BIGINT;         # Số tiền lãi
    DECLARE next_interest_date DATETIME;    # Ngày trả lãi kế tiếp
    DECLARE product_type VARCHAR(50);       # Loại tài khoản
    DECLARE count_withdrawal INT;           # Biến đếm giao dịch rút tiền
    DECLARE amount_withdrawal BIGINT;       # Số tiền đã rút hoặc chuyển đi

    # Bước 1: Lấy thông tin tài khoản
    SELECT a.balance, p.interestRate, p.term, p.productType
    INTO p_balance, p_interestRate, p_term, product_type
    FROM accounts a
             JOIN products p ON a.productCode = p.productCode
    WHERE a.accountNumber = p_accountNumber;

    # Bước 2: Xác định ngày trả lãi gần nhất
    SELECT MAX(t.time)
    INTO last_interest_date
    FROM transactions t
    WHERE (t.sourceAccount = p_accountNumber OR t.targetAccount = p_accountNumber)
      AND t.transactionType IN ('INTEREST', 'OPENING');

    # Bước 3: Tính ngày trả lãi kế tiếp
    SET next_interest_date = DATE_ADD(last_interest_date, INTERVAL p_term MONTH);

    # Bước 4: Tính lãi suất và kiểm tra giao dịch rút tiền
    WHILE next_interest_date <= CURDATE() DO
            # Kiểm tra giao dịch rút tiền trong khoảng thời gian này
            SELECT COUNT(*)
            INTO count_withdrawal
            FROM transactions t
            WHERE t.transactionType IN ('WITHDRAW', 'TRANSFER')
              AND t.time BETWEEN last_interest_date AND next_interest_date
              AND (t.sourceAccount = p_accountNumber);

            # Nếu có giao dịch rút tiền, cập nhật số dư sau khi rút tiền và không tính lãi cho kỳ hạn này
            IF count_withdrawal > 0 THEN
                # Cập nhật số dư sau khi rút tiền (sử dụng giao dịch rút tiền trong kỳ hạn)
                SELECT SUM(t.amount)
                INTO amount_withdrawal
                FROM transactions t
                WHERE t.transactionType IN ('WITHDRAW', 'TRANSFER')
                  AND t.time BETWEEN last_interest_date AND next_interest_date
                  AND t.sourceAccount = p_accountNumber;

                # Cập nhật số dư sau mỗi lần rút tiền
                SET p_balance = p_balance - amount_withdrawal;
            ELSE
                # Nếu không có giao dịch rút tiền, tính lãi cho kỳ hạn này
                # Tính tiền lãi = Số dư * Lãi suất * Thời gian gửi (tháng) / 12
                SET interest_amount = ROUND(p_balance * p_interestRate * p_term / 12);

                # Kiểm tra loại tài khoản
                IF product_type = 'Credit' OR product_type = 'Checking' THEN
                    # Thu lãi
                    INSERT INTO transactions (sourceAccount, targetAccount, transactionType, amount, time, description, employeeCode)
                    VALUES (p_accountNumber, NULL, 'INTEREST', ABS(interest_amount), next_interest_date, 'Ngan hang thu lai', NULL);
                ELSE
                    # Trả lãi
                    INSERT INTO transactions (sourceAccount, targetAccount, transactionType, amount, time, description, employeeCode)
                    VALUES (NULL, p_accountNumber, 'INTEREST', interest_amount, next_interest_date, 'Ngan hang tra lai', NULL);
                END IF;
                # Cập nhật số dư tài khoản
                SET p_balance = p_balance + interest_amount;
            END IF;
            # Cập nhật ngày trả lãi kế tiếp
            SET next_interest_date = DATE_ADD(next_interest_date, INTERVAL p_term MONTH);
        END WHILE;

    # Bước 5: Cập nhật số dư tài khoản cuối cùng
    UPDATE accounts
    SET balance = p_balance
    WHERE accountNumber = p_accountNumber;
END$$
DELIMITER ;












