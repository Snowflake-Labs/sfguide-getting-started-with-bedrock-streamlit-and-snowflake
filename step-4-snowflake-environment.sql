--create database and warehouse
use role accountadmin;
CREATE OR REPLACE WAREHOUSE HOL_WH WITH WAREHOUSE_SIZE='X-SMALL';
CREATE OR REPLACE DATABASE CUSTOMER_WRAPPED;

--create stage
USE DATABASE CUSTOMER_WRAPPED;
CREATE OR REPLACE STAGE CUSTOMER_WRAPPED_STAGE
URL='s3://hol-qs-bucket/'
FILE_FORMAT = (TYPE = 'csv');
list @customer_wrapped_stage;

--create customer_wrapped table
CREATE OR REPLACE TABLE CUSTOMER_WRAPPED
  (CUSTOMERID STRING,
   PRODUCTS_PURCHASED STRING,
   CUSTOMER_TYPE_AND_RECOMMENDATION STRING);

COPY INTO CUSTOMER_WRAPPED FROM @CUSTOMER_WRAPPED_STAGE/customer_wrapped.csv
  FILE_FORMAT=(TYPE = 'csv' FIELD_DELIMITER = ',' SKIP_HEADER = 1);

select top 10 * from CUSTOMER_WRAPPED;

--Create customer_demographics table
CREATE OR REPLACE TABLE CUSTOMER_DEMOGRAPHICS
  (CUSTOMERID STRING,
   NAME STRING,
   AGE STRING,
   CITY STRING,
   COUNTRY STRING,
   GENDER STRING,
   YEARS_AS_CUSTOMER INT,
   PURCHASES_TWENTYTHREE INT,
   DOLLARS_SPENT_TWENTYTHREE INT);

COPY INTO CUSTOMER_DEMOGRAPHICS FROM @CUSTOMER_WRAPPED_STAGE/customer_demographics.csv
  FILE_FORMAT=(TYPE = 'csv' SKIP_HEADER = 1);

select top 10 * from CUSTOMER_DEMOGRAPHICS;

--Create products table
CREATE OR REPLACE TABLE PRODUCTS (
    product_id INT,
    product_name VARCHAR(255)
);

COPY INTO PRODUCTS FROM @CUSTOMER_WRAPPED_STAGE/products.csv
  FILE_FORMAT=(TYPE = 'csv' SKIP_HEADER = 1);

select top 10 * from PRODUCTS;

--Create product_category table
CREATE OR REPLACE TABLE PRODUCT_CATEGORY (
    product_id INT,
    product_category VARCHAR(255)
);

COPY INTO PRODUCT_CATEGORY FROM @CUSTOMER_WRAPPED_STAGE/product_category.csv
  FILE_FORMAT=(TYPE = 'csv' SKIP_HEADER = 1);

select top 10 * from PRODUCT_CATEGORY;

-- Create the customer_purchases table
CREATE OR REPLACE TABLE customer_purchases (
    customer_id INT,
    product_id INT
);

COPY INTO CUSTOMER_PURCHASES FROM @CUSTOMER_WRAPPED_STAGE/customer_purchases.csv
  FILE_FORMAT=(TYPE = 'csv' SKIP_HEADER = 1);

select top 10 * from CUSTOMER_PURCHASES;