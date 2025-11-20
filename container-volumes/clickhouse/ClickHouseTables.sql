CREATE DATABASE IF NOT EXISTS classicmodels;

USE classicmodels;

-- classicmodels.customers definition (the dimension table in the star schema)

CREATE TABLE IF NOT EXISTS classicmodels.customers
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

CREATE TABLE IF NOT EXISTS classicmodels.payments
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

CREATE TABLE IF NOT EXISTS classicmodels.products
(
  productCode String,
  productName Nullable(String),
  productLine Nullable(String),
  productScale Nullable(String),
  productVendor Nullable(String),
  productDescription Nullable(String),
  quantityInStock Int32,
  buyPrice Float64,
  MSRP Float64,
  op_ts DateTime64(3)
)
ENGINE = ReplacingMergeTree(op_ts)
PRIMARY KEY (productCode);

CREATE TABLE IF NOT EXISTS classicmodels.orderdetails
(
  orderNumber Int32,
  productCode String,
  orderLineNumber Int32,
  quantityOrdered Int32,
  priceEach Float64,
  op_ts DateTime64(3)
)
ENGINE = ReplacingMergeTree(op_ts)
PRIMARY KEY (orderNumber, productCode, orderLineNumber);


-- *****lab_submission answer:*****

-- Type your lab submission answer here

-- *****lab_submission answer:*****
