### TRUY VẤN KHÁCH HÀNG
-- 1. Truy vấn xem mỗi khách hàng có bao nhiêu tài khoản (group by + left join + aggregate functions)
SELECT
    c.customerID,
    CONCAT(c.lastName, ' ', c.firstName) AS customerName,
    COUNT(a.accountNumber) AS totalAccounts
FROM
    bank_db.customers c
        LEFT JOIN bank_db.accounts a ON c.customerID = a.customerID
GROUP BY
    c.customerID;

-- 2. Truy vấn tính tổng số tiền trong tất cả tài khoản của mỗi khách hàng (group by + left join + aggregate functions)
SELECT
    c.customerID,
    CONCAT(c.lastName, ' ', c.firstName) AS customerName,
    COALESCE(SUM(a.balance), 0) AS totalBalance
FROM
    bank_db.customers c
        LEFT JOIN bank_db.accounts a ON c.customerID = a.customerID
GROUP BY
    c.customerID;

-- 3. Truy vấn tìm khách hàng có sinh nhật vào quý 4
SELECT
    customerID,
    CONCAT(lastName, ' ', firstName) AS customerName,
    birthDate
FROM
    bank_db.customers
WHERE
    MONTH(birthDate) IN (10, 11, 12);

-- 4. Truy vấn số lượng khách hàng ở mỗi thang điểm tín dụng (group by + aggregate functions)
SELECT
    creditScore,
    COUNT(customerID) AS customerCount
FROM
    bank_db.customers
GROUP BY
    creditScore
ORDER BY
    creditScore;

-- 5. Truy vấn mỗi khách hàng đã thực hiện bao nhiêu giao dịch (left join + group by + aggregate functions)
SELECT
    c.customerID,
    CONCAT(c.lastName, ' ', c.firstName) AS customerName,
    COUNT(t.transactionNumber) AS totalTransactions
FROM
    bank_db.customers c
        LEFT JOIN bank_db.accounts a ON c.customerID = a.customerID
        LEFT JOIN bank_db.transactions t ON a.accountNumber = t.sourceAccount
GROUP BY
    c.customerID
ORDER BY
    totalTransactions DESC;

-- 6. Truy vẫn tất cả tài khoản và số dư trong đó của mỗi khách hàng (outer join + aggregate functions)
SELECT
    c.customerID,
    CONCAT(c.lastName, ' ', c.firstName) AS customerName,
    a.accountNumber,
    a.balance
FROM
    bank_db.customers c
        LEFT JOIN bank_db.accounts a ON c.customerID = a.customerID

UNION

SELECT
    c.customerID,
    CONCAT(c.lastName, ' ', c.firstName) AS customerName,
    a.accountNumber,
    a.balance
FROM
    bank_db.customers c
        RIGHT JOIN bank_db.accounts a ON c.customerID = a.customerID;

-- 7. Truy vấn mỗi khách hàng đã được phục vụ bởi bao nhiêu nhân viên (left join + group by + aggregate functions)
SELECT
    c.customerID,
    CONCAT(c.lastName, ' ', c.firstName) AS customerName,
    COUNT(DISTINCT t.employeeCode) AS totalEmployees
FROM
    bank_db.customers c
        LEFT JOIN bank_db.accounts a ON c.customerID = a.customerID
        LEFT JOIN bank_db.transactions t ON a.accountNumber = t.sourceAccount
GROUP BY
    c.customerID;


### TRUY VẤN TÀI KHOẢN
-- 8. Truy vấn mỗi tài khoản đã thực hiện bao nhiêu giao dịch chuyển tiền (group by + left join + aggregate functions)
SELECT
    a1.accountNumber,
    a1.accountName,
    COUNT(t1.transactionNumber) AS totalTransactions
FROM
    bank_db.accounts a1
        LEFT JOIN bank_db.transactions t1 ON a1.accountNumber = t1.sourceAccount
GROUP BY
    a1.accountNumber;

-- 9. Truy vấn mỗi tài khoản đã thực hiện chuyển hay rút bao nhiêu tiền (group by + left join + aggregate functions)
SELECT
    a1.accountNumber,
    a1.accountName,
    SUM(t1.amount) AS totalTransactionsAmount
FROM
    bank_db.accounts a1
        LEFT JOIN bank_db.transactions t1 ON a1.accountNumber = t1.sourceAccount
GROUP BY
    a1.accountNumber;

-- 10. Truy vấn mỗi tài khoản đã chuyển nhiều tiền nhất cho tài khoản nào khác (subquery trong from và where + aggregate functions + group by)
SELECT
    t1.sourceAccount,
    t1.targetAccount,
    t1.totalAmount
FROM (
         SELECT
             sourceAccount,
             targetAccount,
             SUM(amount) AS totalAmount
         FROM
             bank_db.transactions
         WHERE
             sourceAccount IS NOT NULL
           AND targetAccount IS NOT NULL
           AND amount IS NOT NULL
         GROUP BY
             sourceAccount, targetAccount
     ) t1
WHERE
    t1.totalAmount = (
        SELECT
            MAX(t2.totalAmount)
        FROM (
                 SELECT
                     sourceAccount,
                     targetAccount,
                     SUM(amount) AS totalAmount
                 FROM
                     bank_db.transactions
                 WHERE
                     sourceAccount IS NOT NULL
                   AND targetAccount IS NOT NULL
                   AND amount IS NOT NULL
                 GROUP BY
                     sourceAccount, targetAccount
             ) t2
        WHERE
            t2.sourceAccount = t1.sourceAccount
    );

-- 11. Truy vẫn mỗi tài khoản đã thực hiện nhiều giao dịch chuyển tiền nhất cho tài khoản nào khác null(subquery trong from và where + aggregate functions + group by)
SELECT
    t1.sourceAccount,
    t1.targetAccount,
    t1.transactionCount
FROM (
         SELECT
             sourceAccount,
             targetAccount,
             COUNT(*) AS transactionCount
         FROM
             bank_db.transactions
         WHERE
             sourceAccount IS NOT NULL
           AND targetAccount IS NOT NULL
         GROUP BY
             sourceAccount, targetAccount
     ) t1
WHERE
    t1.transactionCount = (
        SELECT
            MAX(t2.transactionCount)
        FROM (
                 SELECT
                     sourceAccount,
                     targetAccount,
                     COUNT(*) AS transactionCount
                 FROM
                     bank_db.transactions
                 WHERE
                     sourceAccount IS NOT NULL
                   AND targetAccount IS NOT NULL
                 GROUP BY
                     sourceAccount, targetAccount
             ) t2
        WHERE
            t2.sourceAccount = t1.sourceAccount
    );

-- 12. Truy vấn số lượng tài khoản được mở mỗi năm (group by + aggregate functions)
SELECT
    YEAR(openingDate) AS openingYear,
    COUNT(*) AS accountCount
FROM
    bank_db.accounts
WHERE
    openingDate IS NOT NULL
GROUP BY
    YEAR(openingDate)
ORDER BY
    openingYear;

### TRUY VẤN NHÂN VIÊN
-- 13. Truy vấn nhân viên và tất cả người quản lý của họ (self join + aggregate functions)
SELECT
    e.employeeCode,
    CONCAT(e.lastName, ' ', e.firstName) AS employeeName,
    m.employeeCode AS managerCode,
    CONCAT(m.lastName, ' ', m.firstName) AS managerName
FROM
    bank_db.employees e
        LEFT JOIN bank_db.employees m ON e.managerCode = m.employeeCode;

-- 14. Truy vấn nhân viên và số cấp dưới họ quản lý (self join + group by + aggregate functions)
SELECT
    e1.employeeCode AS managerCode,
    CONCAT(e1.lastName, ' ', e1.firstName) AS managerName,
    COUNT(e2.employeeCode) AS subordinateCount
FROM
    bank_db.employees e1
        LEFT JOIN bank_db.employees e2 ON e1.employeeCode = e2.managerCode
GROUP BY
    e1.employeeCode
ORDER BY
    subordinateCount DESC;

-- 15. Truy vấn nhân viên và tổng số tiền giao dịch họ đã xử lý (inner join + group by + aggregate functions)
SELECT
    e.employeeCode,
    CONCAT(e.lastName, ' ', e.firstName) AS employeeName,
    COALESCE(SUM(t.amount), 0) AS totalRevenue
FROM
    bank_db.employees e
        LEFT JOIN bank_db.transactions t ON t.employeeCode = e.employeeCode
GROUP BY
    e.employeeCode
ORDER BY
    totalRevenue DESC;

-- 16. Truy vấn mỗi nhân viên đã từng phục vụ bao nhiêu khách hàng (left join + group by + aggregate functions)
SELECT
    e.employeeCode,
    CONCAT(e.lastName, ' ', e.firstName) AS employeeName,
    COUNT(c.customerID) AS totalCustomers
FROM
    bank_db.employees e
        LEFT JOIN bank_db.transactions t ON e.employeeCode = t.employeeCode
        LEFT JOIN bank_db.accounts a ON a.accountNumber = t.sourceAccount
        LEFT JOIN bank_db.customers c on c.customerID = a.customerID
GROUP BY
    e.employeeCode;

### TRUY VẤN GIAO DỊCH
-- 17. Truy vấn tính số lượng giao dịch trong mỗi năm (group by + aggregate functions)
SELECT
    YEAR(time) AS Year,
    COUNT(*) AS transactionCount
FROM
    bank_db.transactions
GROUP BY
    Year
ORDER BY
    Year;

-- 18. Truy vấn số lượng tiền vào mỗi tháng (group by + aggregate functions)
SELECT
    DATE_FORMAT(time, '%Y-%m') AS month,
    SUM(amount) AS totalAmount
FROM
    bank_db.transactions
WHERE
    amount IS NOT NULL
  AND transactionType IN ('DEPOSIT')
GROUP BY
    month
ORDER BY
    totalAmount;

-- 19. Truy vấn số lượng tiền ra mỗi tháng (group by + aggregate functions)
SELECT
    DATE_FORMAT(time, '%Y-%m') AS month,
    SUM(amount) AS totalAmount
FROM
    bank_db.transactions
WHERE
    amount IS NOT NULL
  AND transactionType = 'WITHDRAW'
GROUP BY
    month
ORDER BY
    totalAmount;

-- 20. Truy vấn tổng số tiền của mỗi loại giao dịch (group by + aggregate functions)
SELECT
    transactionType,
    SUM(amount) AS totalAmount
FROM
    bank_db.transactions
WHERE
    amount IS NOT NULL
GROUP BY
    transactionType
ORDER BY
    totalAmount DESC;

### TRUY VẤN CHI NHÁNH
-- 21. Truy vấn mỗi chi nhánh có tất cả bao nhiêu nhân viên (left join + group by + aggregate functions)
SELECT
    b1.branchCode,
    b1.branchName,
    COUNT(e1.employeeCode) AS totalEmployee
FROM
    bank_db.branches b1
        LEFT JOIN bank_db.employees e1 ON b1.branchCode = e1.branchCode
GROUP BY
    b1.branchCode;

-- 22. Truy vấn tổng số tiền các giao dịch rút tiền, chuyển tiền, nạp tiền đã thực hiện tại mỗi chi nhánh (left join + group by + aggregate functions)
SELECT
    b.branchName AS branchName,
    t.transactionType,
    COALESCE(SUM(t.amount),0) AS totalAmount
FROM
    bank_db.transactions t
    LEFT JOIN bank_db.employees e ON t.employeeCode = e.employeeCode
    LEFT JOIN bank_db.branches b ON e.branchCode = b.branchCode
WHERE
    t.transactionType IN ('WITHDRAW', 'TRANSFER', 'DEPOSIT')
GROUP BY
    b.branchName, t.transactionType
ORDER BY
    b.branchName, t.transactionType;

-- 23. Truy vấn số tài khoản được mở tại mỗi chi nhánh (left join + group by + aggregate functions)
SELECT
    a.openingBranch,
    b.branchName,
    COUNT(*) AS totalAccounts
FROM
    bank_db.accounts a
        LEFT JOIN bank_db.branches b ON a.openingBranch = b.branchCode
GROUP BY
    openingBranch;

-- 24. Truy vấn số nhân viên trong từng chức vụ tại mỗi chi nhánh (inner join + group by + aggregate functions)
SELECT
    b.branchCode,
    b.branchName,
    e.position,
    COUNT(*) AS totalEmployees
FROM
    bank_db.employees e
        JOIN bank_db.branches b ON e.branchCode = b.branchCode
GROUP BY
    b.branchCode, e.position;

-- 25. Truy vấn các chi nhánh và tên đầy đủ của giám đốc chi nhánh đó (inner join + aggregate functions)
SELECT
    b.branchCode,
    b.branchName,
    CONCAT(e.lastName, ' ', e.firstName) as directorName
FROM
    bank_db.employees e
        JOIN bank_db.branches b ON e.branchCode = b.branchCode
WHERE
    e.position = 'Giám đốc chi nhánh';

-- 26. Truy vấn số lượng chi nhánh tại mỗi tỉnh thành (group by + aggregate functions)
SELECT
    province,
    COUNT(branchCode) AS totalBranches
FROM
    bank_db.branches
GROUP BY
    province;

### TRUY VẤN SẢN PHẨM
-- 27. Truy vấn mỗi sản phẩm có bao nhiêu tài khoản (left join + group by + aggregate functions)
SELECT
    p.productCode,
    p.productType,
    COUNT(*) AS totalAccounts
FROM
    bank_db.products p
        LEFT JOIN bank_db.accounts a ON a.productCode = p.productCode
GROUP BY
    p.productCode;

-- 28. Truy vấn mỗi khách hàng yêu thích sản phẩm nào nhất (giả sử sản phẩm nào khách hàng có nhiều tài khoản nhất thì là yêu thích nhất)(inner join + subquery trong from + group by + aggregate functions)
SELECT
    c.customerID,
    CONCAT(c.lastName, ' ', c.firstName) AS customerName,
    p.productCode,
    p.productType,
    COUNT(*) AS totalAccounts
FROM
    bank_db.customers c
        JOIN bank_db.accounts a ON c.customerID = a.customerID
        JOIN bank_db.products p ON a.productCode = p.productCode
GROUP BY
    c.customerID,
    p.productCode,
    p.productType
HAVING
    COUNT(*) = (
        SELECT
            MAX(account_count)
        FROM (
                 SELECT
                     c2.customerID,
                     p2.productCode,
                     COUNT(*) AS account_count
                 FROM
                     bank_db.customers c2
                         JOIN
                     bank_db.accounts a2 ON c2.customerID = a2.customerID
                         JOIN
                     bank_db.products p2 ON a2.productCode = p2.productCode
                 GROUP BY
                     c2.customerID,
                     p2.productCode
             ) AS subquery_max
        WHERE subquery_max.customerID = c.customerID
    );