# Amazon Product Data Cleaning Using SQL

## Project Overview

This is an independent data analytics portfolio project focused on cleaning and standardizing an Amazon product dataset using Microsoft SQL Server. The project demonstrates practical SQL skills in identifying and resolving data quality issues to prepare data for further analysis.

## Project Objectives

- Identify and remove duplicate records.
- Correct inconsistent data formats.
- Handle missing and invalid values.
- Standardize column names and data types.
- Validate the quality and consistency of the cleaned dataset.

## Tools Used

- Microsoft SQL Server
- SQL Server Management Studio (SSMS)
- Microsoft Excel

## Dataset Overview

The original dataset contained 42,675 records and 16 columns, including product titles, ratings, review counts, reported monthly purchases, prices, promotional information, delivery details and collection timestamps.

## Data Cleaning Process

### 1. Data Import and Staging
Imported the original CSV dataset into SQL Server and created a staging table to preserve the original data.

### 2. Duplicate Removal
Identified and removed duplicate records using Common Table Expressions (CTEs) and the ROW_NUMBER() window function.

### 3. Data Cleaning and Standardization
- Removed unnecessary text from product ratings.
- Removed commas from numerical values.
- Standardized reported monthly purchase quantities.
- Removed currency symbols and commas from prices.
- Extracted valid monetary variant prices into a separate column.
- Preserved meaningful categorical and descriptive information.

### 4. Handling Missing Values
Identified invalid entries and missing-value placeholders and replaced them with NULL where appropriate. Missing values were retained rather than replaced with inaccurate assumptions.

### 5. Data Type Standardization
Converted relevant columns from NVARCHAR to appropriate data types, including INT, DECIMAL and DATETIME2.

### 6. Column Renaming
Standardized column names using the snake_case naming convention and assigned descriptive names where necessary.

### 7. Data Quality Validation
Performed validation checks to identify remaining duplicates, missing values, negative numerical values and ratings outside the expected range.

## SQL Skills Demonstrated

- Common Table Expressions (CTEs)
- Window functions
- Aggregate functions
- GROUP BY and HAVING
- CASE statements
- String manipulation
- CAST and TRY_CAST
- UPDATE and DELETE statements
- ALTER TABLE
- Column renaming
- Missing value assessment
- Data quality validation

## Project Results

| Metric | Result |
|---|---:|
| Original records | 42,675 |
| Duplicate records removed | 962 |
| Final records | 41,713 |
| Original columns | 16 |
| Final columns | 17 |
| Remaining full-row duplicates | 0 |
| Invalid numerical ranges detected | 0 |
| Variant placeholders converted to NULL | 20,626 |

## Project Files

- [Amazon_Data_Cleaning.sql](Amazon_Data_Cleaning.sql) — SQL script containing the data cleaning, standardization and validation queries.

## Dataset Limitations

- The dataset contains product listing information rather than individual sales transactions.
- Reported monthly purchase quantities represent minimum reported quantities, not exact sales figures.
- Missing information was retained as NULL to maintain data integrity.
- Dataset redistribution permissions have not yet been confirmed.

## Conclusion

This project demonstrates my practical understanding of SQL-based data cleaning, data transformation and data quality validation. The resulting dataset is more consistent, structured and prepared for further exploratory data analysis.
