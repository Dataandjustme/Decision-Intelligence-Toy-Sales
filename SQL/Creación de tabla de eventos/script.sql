-- 4. Hechos: Inventario
CREATE TABLE fact_inventory (
    Store_ID INT,
    Product_ID INT,
    Stock_On_Hand INT,
    Date_Text TEXT,              -- Para "31-Dec-23"
    Date_Key INT
);


-- 5. Hechos: Ventas
DROP TABLE IF EXISTS fact_sales;
CREATE TABLE fact_sales (
    Product_ID TEXT,     -- Usamos TEXT temporalmente por si hay caracteres raros
    Store_ID TEXT,       -- El error dice que aquí está entrando la fecha
    Date_Text TEXT,      
    Sale_ID TEXT,        
    Units TEXT,          
    Date_Key TEXT        
);
