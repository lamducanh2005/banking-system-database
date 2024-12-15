create database if not exists bank_db;

create table if not exists bank_db.branches
(
    branchCode varchar(50)  not null
        primary key,
    branchName varchar(256) not null,
    province   varchar(50)  null,
    district   varchar(50)  null,
    street     varchar(256) null
);

create table if not exists bank_db.customers
(
    customerID  varchar(50)  not null
        primary key,
    lastName    varchar(50)  not null,
    firstName   varchar(50)  not null,
    birthDate   date         not null,
    phoneNumber varchar(15)  null,
    address     varchar(256) null,
    creditScore int          null
);

create table if not exists bank_db.employees
(
    employeeCode varchar(50)  not null
        primary key,
    lastName     varchar(50)  not null,
    firstName    varchar(50)  not null,
    position     varchar(256) null,
    department   varchar(256) null,
    managerCode  varchar(50)  null,
    branchCode   varchar(50)  null
);

create table if not exists bank_db.products
(
    productCode  varchar(50)  not null
        primary key,
    productType  varchar(256) null,
    interestRate float        null,
    term         int          null,
    minAmount    bigint       null,
    maxAmount    bigint       null
);

create table if not exists bank_db.accounts
(
    accountNumber varchar(256)             not null
        primary key,
    accountName   varchar(256)             not null,
    balance       bigint                   not null,
    customerID    varchar(50)              null,
    productCode   varchar(256)             null,
    openingBranch varchar(50)              null,
    openingDate   datetime default (now()) null
);

create table if not exists bank_db.transactions
(
    transactionNumber int auto_increment
        primary key,
    sourceAccount     varchar(50)                        null,
    targetAccount     varchar(50)                        null,
    transactionType   varchar(50)                        null,
    amount            bigint                             not null,
    time              datetime default CURRENT_TIMESTAMP not null,
    description       varchar(256)                       null,
    employeeCode      varchar(50)                        null
);

