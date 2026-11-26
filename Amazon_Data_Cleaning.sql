/*
Project: Amazon Product Data Cleaning
Project Type: Independent Data Analytics Portfolio Project
Tool: Microsoft SQL Server (SSMS)

Objective:
Clean and standardize the Amazon product dataset by removing
duplicates, handling missing values, correcting inconsistencies,
standardizing data types and validating data quality.
*/

USE AmazonSales;
GO

--1. Initial Data Exploration
SELECT TOP (100) *
FROM dbo.amazon_sales_data_uncleaned;

--Counting The Total Number of Records Before Cleaning
SELECT COUNT (*) AS Total_Raw_Records
FROM dbo.amazon_sales_data_uncleaned;

--2. Data Preparation
--Creating a Staging Table 
SELECT TOP(0) *
INTO dbo.amazon_sales_data_uncleaned_staging
FROM dbo.amazon_sales_data_uncleaned;
GO

--Inserting Data Into the Staging Table
INSERT INTO dbo.amazon_sales_data_uncleaned_staging
SELECT *
FROM dbo.amazon_sales_data_uncleaned;

--Validating the Data In the Staging Table
SELECT COUNT(*) AS Total_Staging_Records
FROM dbo.amazon_sales_data_uncleaned_staging;

--3.Data Cleaning
--Identify and Remove Duplicates

WITH amazon_duplicate_records AS
	(SELECT *,
	ROW_NUMBER () OVER (PARTITION BY Title,Rating,Number_of_reviews,
	bought_in_last_month,Current_discounted_price,Price_on_variant,
	Listed_price,is_best_seller,is_sponsored,is_couponed,buy_box_availability,
	delivery_details,sustainability_badges, image_url,product_url,
	collected_at ORDER BY Number_of_reviews) AS row_num
	FROM dbo.amazon_sales_data_uncleaned_staging)
SELECT *
FROM amazon_duplicate_records
WHERE row_num > 1;

WITH amazon_duplicate_records AS
	(SELECT *,
	ROW_NUMBER () OVER (PARTITION BY Title,Rating,Number_of_reviews,
	bought_in_last_month,Current_discounted_price,Price_on_variant,
	Listed_price,is_best_seller,is_sponsored,is_couponed,buy_box_availability,
	delivery_details,sustainability_badges, image_url,product_url,
	collected_at ORDER BY Number_of_reviews) AS row_num
	FROM dbo.amazon_sales_data_uncleaned_staging)
DELETE 
FROM amazon_duplicate_records
WHERE row_num > 1;

--Validating Duplicates Removal
SELECT COUNT(*) AS Records_After_Duplicate_Removal
FROM dbo.amazon_sales_data_uncleaned_staging;

--Confirming any Remaining Duplicate Records
WITH amazon_duplicate_records AS
	(SELECT *,
	ROW_NUMBER () OVER (PARTITION BY Title,Rating,Number_of_reviews,
	bought_in_last_month,Current_discounted_price,Price_on_variant,
	Listed_price,is_best_seller,is_sponsored,is_couponed,buy_box_availability,
	delivery_details,sustainability_badges, image_url,product_url,
	collected_at ORDER BY Number_of_reviews) AS row_num
	FROM dbo.amazon_sales_data_uncleaned_staging)
SELECT COUNT (*)
FROM amazon_duplicate_records
WHERE row_num > 1;

-- Data Standardization
-- Standardizing the Rating column

SELECT DISTINCT Rating 
FROM dbo.amazon_sales_data_uncleaned_staging
ORDER BY Rating;

SELECT Rating,
	TRIM(REPLACE (Rating,' out of 5 stars','')) AS New_Rating
FROM dbo.amazon_sales_data_uncleaned_staging;

--Updating The Rating Column
UPDATE dbo.amazon_sales_data_uncleaned_staging
SET Rating = TRIM(REPLACE (Rating,' out of 5 stars',''))
WHERE Rating LIKE '%out of 5 stars%';

-- Standardizing the Number_of_reviews column
SELECT DISTINCT Number_of_reviews
FROM dbo.amazon_sales_data_uncleaned_staging
ORDER BY Number_of_reviews;

SELECT Number_of_reviews,
	TRIM(REPLACE (Number_of_reviews,',','')) AS New_Number_of_reviews
FROM dbo.amazon_sales_data_uncleaned_staging;

--Updating The Number_of_reviews Column
UPDATE dbo.amazon_sales_data_uncleaned_staging
SET Number_of_reviews = TRIM(REPLACE (Number_of_reviews,',',''))
WHERE Number_of_reviews LIKE '%,%';

-- Standardizing the bought_in_last_month column
SELECT DISTINCT bought_in_last_month
FROM dbo.amazon_sales_data_uncleaned_staging
ORDER BY bought_in_last_month;

SELECT DISTINCT bought_in_last_month
FROM dbo.amazon_sales_data_uncleaned_staging
WHERE bought_in_last_month NOT LIKE '%bought in past month%'
AND bought_in_last_month IS NOT NULL;

-- Count records containing invalid purchase information
SELECT COUNT(bought_in_last_month) AS Invalid_Purchase_Records
FROM dbo.amazon_sales_data_uncleaned_staging
WHERE bought_in_last_month NOT LIKE '%bought in past month%'
AND bought_in_last_month IS NOT NULL;

-- Replacing invalid purchase information with NULL
UPDATE dbo.amazon_sales_data_uncleaned_staging
SET bought_in_last_month = NULL
WHERE bought_in_last_month NOT LIKE '%bought in past month%';

SELECT DISTINCT bought_in_last_month,
	REPLACE (bought_in_last_month,'+ bought in past month', '') AS New_Purchase_Quantity
FROM dbo.amazon_sales_data_uncleaned_staging
WHERE bought_in_last_month IS NOT NULL;

-- Convert abbreviated purchase quantities into whole numbers
SELECT bought_in_last_month,
    CASE
        WHEN bought_in_last_month LIKE '%K+ bought in past month'
        THEN TRY_CAST(REPLACE(bought_in_last_month,
            'K+ bought in past month', '') AS INT) * 1000
        ELSE TRY_CAST(REPLACE(bought_in_last_month,
            '+ bought in past month', '') AS INT)
    END AS Minimum_Purchase_Quantity
FROM dbo.amazon_sales_data_uncleaned_staging;

-- Identify failed purchase quantity conversions

WITH Purchase_Conversion AS (
    SELECT bought_in_last_month,
        CASE
            WHEN bought_in_last_month LIKE '%K+ bought in past month'
            THEN TRY_CAST(REPLACE(bought_in_last_month,
                'K+ bought in past month', '') AS INT) * 1000
            ELSE TRY_CAST(REPLACE(bought_in_last_month,
                '+ bought in past month', '') AS INT)
        END AS Minimum_Purchase_Quantity
    FROM dbo.amazon_sales_data_uncleaned_staging
  WHERE bought_in_last_month IS NOT NULL
)
SELECT *
FROM Purchase_Conversion
WHERE Minimum_Purchase_Quantity IS NULL;

UPDATE dbo.amazon_sales_data_uncleaned_staging
SET bought_in_last_month = CASE
            WHEN bought_in_last_month LIKE '%K+ bought in past month'
            THEN CAST(REPLACE(bought_in_last_month,
                'K+ bought in past month', '') AS INT) * 1000
            ELSE TRY_CAST(REPLACE(bought_in_last_month,
                '+ bought in past month', '') AS INT)
        END
WHERE bought_in_last_month LIKE '%bought in past month%';

-- Standardizing the Current_discounted_price column
SELECT DISTINCT Current_discounted_price
FROM dbo.amazon_sales_data_uncleaned_staging
ORDER BY Current_discounted_price;

SELECT DISTINCT Current_discounted_price
FROM dbo.amazon_sales_data_uncleaned_staging
WHERE Current_discounted_price IS NOT NULL
AND TRY_CAST(Current_discounted_price AS DECIMAL(10,2)) IS NULL;

SELECT Current_discounted_price,
	REPLACE (Current_discounted_price,',','') AS New_Discounted_Price
	FROM dbo.amazon_sales_data_uncleaned_staging
WHERE Current_discounted_price LIKE '%,%';

UPDATE dbo.amazon_sales_data_uncleaned_staging
SET Current_discounted_price = REPLACE (Current_discounted_price,',','')
WHERE Current_discounted_price LIKE '%,%';


SELECT DISTINCT Current_discounted_price
FROM dbo.amazon_sales_data_uncleaned_staging
WHERE Current_discounted_price IS NOT NULL
    AND TRY_CAST(Current_discounted_price AS DECIMAL(10,2)) IS NULL;

SELECT
    MIN(CAST(Current_discounted_price AS DECIMAL(10,2))) AS Minimum_Price,
    MAX(CAST(Current_discounted_price AS DECIMAL(10,2))) AS Maximum_Price
FROM dbo.amazon_sales_data_uncleaned_staging;

SELECT DISTINCT Current_discounted_price
FROM dbo.amazon_sales_data_uncleaned_staging
WHERE Current_discounted_price LIKE '%.___%';

-- Inspect variant price values
SELECT DISTINCT Price_on_variant
FROM dbo.amazon_sales_data_uncleaned_staging
ORDER BY Price_on_variant;

SELECT Price_on_variant
FROM dbo.amazon_sales_data_uncleaned_staging
WHERE Price_on_variant LIKE '%$%';

SELECT Price_on_variant,
REPLACE (Price_on_variant,'basic variant price: ','')
FROM dbo.amazon_sales_data_uncleaned_staging
WHERE Price_on_variant LIKE '%basic variant price%';

UPDATE dbo.amazon_sales_data_uncleaned_staging
SET Price_on_variant = REPLACE (Price_on_variant,'basic variant price: ','')
WHERE Price_on_variant LIKE '%basic variant price%';

SELECT Price_on_variant,
REPLACE(REPLACE (Price_on_variant,'$',''),',','') 
FROM dbo.amazon_sales_data_uncleaned_staging
WHERE Price_on_variant LIKE '%$%';

-- Identify invalid monetary variant prices
SELECT DISTINCT Price_on_variant
FROM dbo.amazon_sales_data_uncleaned_staging
WHERE Price_on_variant LIKE '%$%'
    AND TRY_CAST(REPLACE(REPLACE(Price_on_variant, '$', ''), ',', '') AS DECIMAL(10,2)) IS NULL;

SELECT DISTINCT Price_on_variant, is_couponed
FROM dbo.amazon_sales_data_uncleaned_staging
WHERE Price_on_variant LIKE '%off coupon applied%';

ALTER TABLE dbo.amazon_sales_data_uncleaned_staging
ADD Variant_Price DECIMAL(10,2) NULL;
GO

-- Populate the numeric variant price column
UPDATE dbo.amazon_sales_data_uncleaned_staging
SET Variant_Price = TRY_CAST(REPLACE(REPLACE(Price_on_variant, '$', ''), ',', '') AS DECIMAL(10,2))
WHERE Price_on_variant LIKE '$%'
    AND Price_on_variant NOT LIKE '%off coupon applied%';

-- Inspect remaining columns for data quality issues

SELECT DISTINCT Listed_price
FROM dbo.amazon_sales_data_uncleaned_staging;

SELECT DISTINCT Listed_price
FROM dbo.amazon_sales_data_uncleaned_staging
WHERE Listed_price IS NOT NULL
    AND TRY_CAST(REPLACE(REPLACE(Listed_price, '$', ''), ',', '') AS DECIMAL(10,2)) IS NULL;

-- Remove currency symbols and commas from listed prices
UPDATE dbo.amazon_sales_data_uncleaned_staging
SET Listed_price = REPLACE(REPLACE(Listed_price, '$', ''), ',', '')
WHERE Listed_price LIKE '%$%'
    OR Listed_price LIKE '%,%';

SELECT DISTINCT is_best_seller
FROM dbo.amazon_sales_data_uncleaned_staging;

SELECT DISTINCT is_sponsored
FROM dbo.amazon_sales_data_uncleaned_staging;

SELECT DISTINCT is_couponed
FROM dbo.amazon_sales_data_uncleaned_staging;

SELECT DISTINCT buy_box_availability
FROM dbo.amazon_sales_data_uncleaned_staging;

SELECT DISTINCT delivery_details
FROM dbo.amazon_sales_data_uncleaned_staging;

SELECT DISTINCT sustainability_badges
FROM dbo.amazon_sales_data_uncleaned_staging;

SELECT DISTINCT image_url
FROM dbo.amazon_sales_data_uncleaned_staging;

SELECT DISTINCT product_url
FROM dbo.amazon_sales_data_uncleaned_staging;

SELECT DISTINCT collected_at
FROM dbo.amazon_sales_data_uncleaned_staging;

-- Standardize numerical data types
GO

ALTER TABLE dbo.amazon_sales_data_uncleaned_staging
ALTER COLUMN Rating DECIMAL(2,1) NULL;

ALTER TABLE dbo.amazon_sales_data_uncleaned_staging
ALTER COLUMN Number_of_reviews INT NULL;

ALTER TABLE dbo.amazon_sales_data_uncleaned_staging
ALTER COLUMN bought_in_last_month INT NULL;

ALTER TABLE dbo.amazon_sales_data_uncleaned_staging
ALTER COLUMN Current_discounted_price DECIMAL(10,2) NULL;

SELECT DISTINCT Listed_price
FROM dbo.amazon_sales_data_uncleaned_staging
WHERE Listed_price IS NOT NULL
    AND TRY_CAST(Listed_price AS DECIMAL(10,2)) IS NULL;

-- Replace non-numeric listed prices with NULL
UPDATE dbo.amazon_sales_data_uncleaned_staging
SET Listed_price = NULL
WHERE Listed_price = 'No Discount';

ALTER TABLE dbo.amazon_sales_data_uncleaned_staging
ALTER COLUMN Listed_price DECIMAL(10,2) NULL;

-- Standardize the date and time data type
SET DATEFORMAT dmy;

ALTER TABLE dbo.amazon_sales_data_uncleaned_staging
ALTER COLUMN collected_at DATETIME2(0) NULL;

GO

-- Standardize column names

EXEC sp_rename
    'dbo.amazon_sales_data_uncleaned_staging.Title',
    'product_title',
    'COLUMN';

EXEC sp_rename
    'dbo.amazon_sales_data_uncleaned_staging.Rating',
    'rating', 'COLUMN';

EXEC sp_rename
    'dbo.amazon_sales_data_uncleaned_staging.Number_of_reviews',
    'review_count', 'COLUMN';

EXEC sp_rename
    'dbo.amazon_sales_data_uncleaned_staging.bought_in_last_month',
    'minimum_monthly_purchases', 'COLUMN';

EXEC sp_rename
    'dbo.amazon_sales_data_uncleaned_staging.Current_discounted_price',
    'discounted_price', 'COLUMN';

EXEC sp_rename
    'dbo.amazon_sales_data_uncleaned_staging.Price_on_variant',
    'variant_details', 'COLUMN';

EXEC sp_rename
    'dbo.amazon_sales_data_uncleaned_staging.Variant_Price',
    'variant_price', 'COLUMN';

EXEC sp_rename
    'dbo.amazon_sales_data_uncleaned_staging.Listed_price',
    'listed_price', 'COLUMN';

EXEC sp_rename
    'dbo.amazon_sales_data_uncleaned_staging.is_best_seller',
    'product_badge', 'COLUMN';

EXEC sp_rename
    'dbo.amazon_sales_data_uncleaned_staging.is_sponsored',
    'sponsorship_status', 'COLUMN';

EXEC sp_rename
    'dbo.amazon_sales_data_uncleaned_staging.is_couponed',
    'coupon_details', 'COLUMN';

EXEC sp_rename
    'dbo.amazon_sales_data_uncleaned_staging.sustainability_badges',
    'additional_product_badges', 'COLUMN';
GO

SELECT DISTINCT variant_details
FROM dbo.amazon_sales_data_uncleaned_staging
WHERE variant_details IN ('nan', 'N/A', 'NULL', '');

-- Replace missing variant details with NULL
UPDATE dbo.amazon_sales_data_uncleaned_staging
SET variant_details = NULL
WHERE variant_details = 'nan';

-- Assess missing values across all columns
SELECT
    COUNT(*) AS total_records,
    COUNT(*) - COUNT(product_title) AS missing_title,
    COUNT(*) - COUNT(rating) AS missing_rating,
    COUNT(*) - COUNT(review_count) AS missing_reviews,
    COUNT(*) - COUNT(minimum_monthly_purchases) AS missing_purchases,
    COUNT(*) - COUNT(discounted_price) AS missing_discounted_price,
    COUNT(*) - COUNT(variant_details) AS missing_variant_details,
    COUNT(*) - COUNT(variant_price) AS missing_variant_price,
    COUNT(*) - COUNT(listed_price) AS missing_listed_price,
    COUNT(*) - COUNT(product_badge) AS missing_product_badge,
    COUNT(*) - COUNT(sponsorship_status) AS missing_sponsorship,
    COUNT(*) - COUNT(coupon_details) AS missing_coupon,
    COUNT(*) - COUNT(buy_box_availability) AS missing_availability,
    COUNT(*) - COUNT(delivery_details) AS missing_delivery,
    COUNT(*) - COUNT(additional_product_badges) AS missing_badges,
    COUNT(*) - COUNT(image_url) AS missing_image_url,
    COUNT(*) - COUNT(product_url) AS missing_product_url,
    COUNT(*) - COUNT(collected_at) AS missing_collection_date
FROM dbo.amazon_sales_data_uncleaned_staging;

-- Check for invalid numerical values
SELECT *
FROM dbo.amazon_sales_data_uncleaned_staging
WHERE rating < 0
    OR rating > 5
    OR review_count < 0
    OR minimum_monthly_purchases < 0
    OR discounted_price < 0
    OR listed_price < 0
    OR variant_price < 0;

-- Check for duplicates after data cleaning
SELECT
    product_title,
    rating,
    review_count,
    minimum_monthly_purchases,
    discounted_price,
    variant_details,
    variant_price,
    listed_price,
    product_badge,
    sponsorship_status,
    coupon_details,
    buy_box_availability,
    delivery_details,
    additional_product_badges,
    image_url,
    product_url,
    collected_at,
    COUNT(*) AS duplicate_count
FROM dbo.amazon_sales_data_uncleaned_staging
GROUP BY
    product_title,
    rating,
    review_count,
    minimum_monthly_purchases,
    discounted_price,
    variant_details,
    variant_price,
    listed_price,
    product_badge,
    sponsorship_status,
    coupon_details,
    buy_box_availability,
    delivery_details,
    additional_product_badges,
    image_url,
    product_url,
    collected_at
HAVING COUNT(*) > 1;
