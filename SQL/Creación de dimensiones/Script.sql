-- 1. Dimensión Productos

DROP TABLE IF EXISTS dim_product;
CREATE TABLE dim_product (
    Product_ID INT PRIMARY KEY,
    Product_Name VARCHAR(255),
    Product_Category VARCHAR(100),
    Product_Cost TEXT,   -- Aquí entrará el "$9.99"
    Product_Price TEXT   -- Aquí entrará el "$15.99"
);

-- 2. Dimensión de tiendas 
CREATE TABLE dim_stores (
    Store_ID INT PRIMARY KEY,
    Store_Name VARCHAR(255),
    Store_City VARCHAR(100),
    Store_Location VARCHAR(100),
    Store_Open_Date TEXT,    -- Usamos TEXT por el formato "18-Sep-92"
    Store_years_age INT      -- El ejemplo dice "1992", lo ponemos como INT
);

-- 3. Dimensión Fecha
CREATE TABLE dim_date (
    Date_Value TEXT,             -- Para "2-Jan-22"
    Date_Key INT PRIMARY KEY,    -- 20220102
    Year INT,
    Month_Number INT,
    Month_Name VARCHAR(20),
    Quarter VARCHAR(2),
    Day_of_Week INT,
    Is_Weekend INT
);
