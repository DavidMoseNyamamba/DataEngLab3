CREATE DATABASE classicmodels;

USE classicmodels;

-- classicmodels.customers definition (the dimension table in the star schema)

CREATE TABLE customers
(
    `customerNumber` Int32,
    `customerName` Nullable(String),
    `contactLastName` Nullable(String),
    `contactFirstName` Nullable(String),
    `phone` Nullable(String),
    `addressLine1` Nullable(String),
    `addressLine2` Nullable(String),
    `city` Nullable(String),
    `state` Nullable(String),
    `postalCode` Nullable(String),
    `country` Nullable(String),
    `salesRepEmployeeNumber` Nullable(Int32),
    `creditLimit` Nullable(Float64)
)
ENGINE = ReplacingMergeTree
PRIMARY KEY customerNumber
ORDER BY customerNumber
SETTINGS index_granularity = 50;

-- classicmodels.payments definition (the fact table in the star schema)

CREATE TABLE payments
(
    `customerNumber` Int32, -- Foreign key referencing customers
    `checkNumber` String,
    `paymentDate` Date,
    `amount` Nullable(Float64)
)
ENGINE = ReplacingMergeTree
PARTITION BY customerNumber
PRIMARY KEY (customerNumber,
 checkNumber)
ORDER BY (customerNumber,
 checkNumber)
SETTINGS index_granularity = 50;



-- *****lab_submission answer:*****

-- Type your lab submission answer here

-- *****lab_submission answer:*****
