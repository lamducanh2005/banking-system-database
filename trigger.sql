-- 1. Kiểm tra các tài khoản có tồn tại trên hệ thống
DELIMITER $$
CREATE TRIGGER before_transaction_validation
    BEFORE INSERT ON transactions
    FOR EACH ROW
BEGIN
    # Kiểm tra nếu là giao dịch gửi tiền
    IF NEW.transactionType = 'DEPOSIT' THEN
        IF NOT EXISTS (
            SELECT 1 FROM accounts WHERE accountNumber = NEW.targetAccount
        ) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Giao dịch thất bại: Tài khoản đích không tồn tại.';
        END IF;
    END IF;

    # Kiểm tra nếu là giao dịch rút tiền
    IF NEW.transactionType = 'WITHDRAW' THEN
        IF NOT EXISTS (
            SELECT 1 FROM accounts WHERE accountNumber = NEW.sourceAccount
        ) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Giao dịch thất bại: Tài khoản nguồn không tồn tại.';
        END IF;
    END IF;

    # Kiểm tra nếu là giao dịch chuyển tiền
    IF NEW.transactionType = 'TRANSFER' THEN
        # Kiểm tra tài khoản nguồn
        IF NOT EXISTS (
            SELECT 1 FROM accounts WHERE accountNumber = NEW.sourceAccount
        ) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Giao dịch thất bại: Tài khoản nguồn không tồn tại.';
        END IF;

        # Kiểm tra tài khoản đích
        IF NOT EXISTS (
            SELECT 1 FROM accounts WHERE accountNumber = NEW.targetAccount
        ) THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Giao dịch thất bại: Tài khoản đích không tồn tại.';
        END IF;
    END IF;
END$$
DELIMITER ;


-- 2. Kiểm tra số dư tài khoản nguồn trước khi thực hiện giao dịch (WITHDRAW, TRANSFER)
DELIMITER $$
CREATE TRIGGER before_withdraw_or_transfer
    BEFORE INSERT ON transactions
    FOR EACH ROW
BEGIN
    DECLARE current_balance BIGINT;

    # Kiểm tra nếu là giao dịch chuyển khoản
    IF NEW.transactionType IN ('WITHDRAW', 'TRANSFER') THEN
        # Lấy số dư hiện tại của tài khoản nguồn
        SELECT balance INTO current_balance
        FROM accounts
        WHERE accountNumber = NEW.sourceAccount;

        # Nếu số dư không đủ thì chặn giao dịch
        IF current_balance < NEW.amount THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Giao dịch thất bại: Số dư không đủ.';
        END IF;
    END IF;
END$$
DELIMITER ;


-- 3. Tự động xử lý giao dịch nạp tiền - DEPOSIT
DELIMITER $$
CREATE TRIGGER after_deposit
    AFTER INSERT ON transactions
    FOR EACH ROW
BEGIN
    IF NEW.transactionType = 'DEPOSIT' THEN
        # Cập nhật số dư của tài khoản khi có giao dịch gửi tiền
        UPDATE accounts
        SET balance = balance + NEW.amount
        WHERE accountNumber = NEW.targetAccount;
    END IF;
END$$
DELIMITER ;


-- 4. Cập nhật số dư tài khoản nguồn sau khi rút tiền
DELIMITER $$
CREATE TRIGGER after_withdraw
    AFTER INSERT ON transactions
    FOR EACH ROW
BEGIN
    IF NEW.transactionType = 'WITHDRAW' THEN
        # Trừ tiền từ tài khoản nguồn
        UPDATE accounts
        SET balance = balance - NEW.amount
        WHERE accountNumber = NEW.sourceAccount;
    END IF;
END$$
DELIMITER ;


-- 5. Cập nhật số dư 2 tài khoản sau khi chuyển tiền
DELIMITER $$
CREATE TRIGGER after_transfer
    AFTER INSERT ON transactions
    FOR EACH ROW
BEGIN
    IF NEW.transactionType = 'TRANSFER' THEN
        # Trừ tiền từ tài khoản nguồn
        UPDATE accounts
        SET balance = balance - NEW.amount
        WHERE accountNumber = NEW.sourceAccount;

        # Cộng tiền vào tài khoản đích
        UPDATE accounts
        SET balance = balance + NEW.amount
        WHERE accountNumber = NEW.targetAccount;
    END IF;
END$$
DELIMITER ;


-- 6. Kiểm tra điểm tín dụng có đủ để mở tài khoản
DELIMITER $$
CREATE TRIGGER before_account_creation
    BEFORE INSERT ON accounts
    FOR EACH ROW
BEGIN
    DECLARE credit_score INT;

    # Kiểm tra xem customerID có tồn tại trong bảng customers không
    IF NOT EXISTS (
        SELECT 1 FROM customers WHERE customerID = NEW.customerID
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Khách hàng không tồn tại trong hệ thống.';
    ELSE
        # Lấy điểm tín dụng của khách hàng
        SELECT creditScore INTO credit_score
        FROM customers
        WHERE customerID = NEW.customerID;

        # Kiểm tra điểm tín dụng
        IF credit_score < 300 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Điểm tín dụng không đủ để mở tài khoản.';
        END IF;
    END IF;
END$$
DELIMITER ;



-- 7. Kiểm tra số tiền giao dịch tối thiểu
DELIMITER $$
CREATE TRIGGER before_transaction_check
    BEFORE INSERT ON transactions
    FOR EACH ROW
BEGIN
    # Kiểm tra nếu là giao dịch rút tiền hoặc chuyển khoản
    IF NEW.transactionType IN ('WITHDRAW', 'TRANSFER') THEN
        # Đảm bảo số tiền rút hoặc chuyển đi là ít nhất 10,000
        IF NEW.amount < 10000 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Giao dịch thất bại: Số tiền trong một giao dịch chuyển tiền/rút tiền tối thiểu 10,000 VND.';
        END IF;
    END IF;

    # Kiểm tra nếu là gửi tiền thì số tiền phải ít nhất là 50,000
    IF NEW.transactionType = 'DEPOSIT' THEN
        IF NEW.amount < 50000 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Giao dịch thất bại: Số tiền trong một giao dịch gửi tiền tối thiểu 50,000 VND.';
        END IF;
    END IF;
END$$
DELIMITER ;







