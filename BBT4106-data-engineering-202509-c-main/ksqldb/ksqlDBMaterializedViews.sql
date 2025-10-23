-- The materialized view of the orderdetails stream
CREATE TABLE orderdetails_stream_table AS
SELECT
  payload->`orderNumber` AS `orderNumber`,
  payload->`productCode` AS `productCode`,
  LATEST_BY_OFFSET(payload->`quantityOrdered`) AS `quantityOrdered`,
  LATEST_BY_OFFSET(payload->`priceEach`) AS `priceEach`,
  LATEST_BY_OFFSET(payload->`orderLineNumber`) AS `orderLineNumber`
FROM orderdetails_stream
GROUP BY payload->`orderNumber`, payload->`productCode` EMIT CHANGES;

-- The materialized view of the orders stream
CREATE TABLE orders_stream_table AS
SELECT
  payload->`orderNumber` AS `orderNumber`,
  LATEST_BY_OFFSET(payload->`orderDate`) AS `orderDate`,
  LATEST_BY_OFFSET(payload->`requiredDate`) AS `requiredDate`,
  LATEST_BY_OFFSET(payload->`shippedDate`) AS `shippedDate`,
  LATEST_BY_OFFSET(payload->`status`) AS `status`,
  LATEST_BY_OFFSET(payload->`comments`) AS `comments`,
  LATEST_BY_OFFSET(payload->`customerNumber`) AS `customerNumber`
FROM orders_stream
GROUP BY payload->`orderNumber` EMIT CHANGES;

-- The materialized view of the products stream
CREATE TABLE products_stream_table AS
SELECT
  payload->`productCode` AS `productCode`,
  LATEST_BY_OFFSET(payload->`productName`) AS `productName`,
  LATEST_BY_OFFSET(payload->`productLine`) AS `productLine`,
  LATEST_BY_OFFSET(payload->`productScale`) AS `productScale`,
  LATEST_BY_OFFSET(payload->`productVendor`) AS `productVendor`,
  LATEST_BY_OFFSET(payload->`productDescription`) AS `productDescription`,
  LATEST_BY_OFFSET(payload->`quantityInStock`) AS `quantityInStock`,
  LATEST_BY_OFFSET(payload->`buyPrice`) AS `buyPrice`,
  LATEST_BY_OFFSET(payload->`MSRP`) AS `MSRP`
FROM products_stream
GROUP BY payload->`productCode` EMIT CHANGES;

-- The materialized view of the customers stream
CREATE TABLE customers_stream_table AS
SELECT
  payload->`customerNumber` AS `customerNumber`,
  LATEST_BY_OFFSET(payload->`customerName`) AS `customerName`,
  LATEST_BY_OFFSET(payload->`contactLastName`) AS `contactLastName`,
  LATEST_BY_OFFSET(payload->`contactFirstName`) AS `contactFirstName`,
  LATEST_BY_OFFSET(payload->`phone`) AS `phone`,
  LATEST_BY_OFFSET(payload->`addressLine1`) AS `addressLine1`,
  LATEST_BY_OFFSET(payload->`addressLine2`) AS `addressLine2`,
  LATEST_BY_OFFSET(payload->`city`) AS `city`,
  LATEST_BY_OFFSET(payload->`state`) AS `state`,
  LATEST_BY_OFFSET(payload->`postalCode`) AS `postalCode`,
  LATEST_BY_OFFSET(payload->`country`) AS `country`,
  LATEST_BY_OFFSET(payload->`salesRepEmployeeNumber`) AS `salesRepEmployeeNumber`,
  LATEST_BY_OFFSET(payload->`creditLimit`) AS `creditLimit`
FROM customers_stream
GROUP BY payload->`customerNumber` EMIT CHANGES;

-- The materialized view of the productlines stream
CREATE TABLE productlines_stream_table AS
SELECT
  payload->`productLine` AS `productLine`,
  LATEST_BY_OFFSET(payload->`textDescription`) AS `textDescription`
FROM productlines_stream
GROUP BY payload->`productLine` EMIT CHANGES;
