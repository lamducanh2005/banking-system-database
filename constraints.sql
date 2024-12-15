alter table bank_db.employees
    add constraint branch___fk
        foreign key (branchCode) references branches (branchCode),
    add constraint employees_managers__fk
        foreign key (managerCode) references employees (employeeCode);

alter table bank_db.accounts
    add constraint customerID___fk
        foreign key (customerID) references customers (customerID),
    add constraint openingBranch___fk
        foreign key (openingBranch) references branches (branchCode),
    add constraint productCode___fk
        foreign key (productCode) references products (productCode);

alter table bank_db.transactions
    add constraint sourceAccount___fk
        foreign key (sourceAccount) references accounts (accountNumber),
    add constraint targetAccount___fk
        foreign key (targetAccount) references accounts (accountNumber),
    add constraint transactions__fk
        foreign key (employeeCode) references employees (employeeCode);