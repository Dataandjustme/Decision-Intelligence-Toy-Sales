-- 2. La creamos con la limpieza de "$" y los tipos de datos correctos
CREATE VIEW view_inventario_disponible AS
SELECT 
    i.product_id,
    p.product_name,
    p.product_category,
    -- Limpiamos el "$" y convertimos a número
    REPLACE(p.product_cost, '$', '')::DECIMAL AS product_cost,
    i.store_id,
    i.stock_on_hand::INT AS stock_on_hand,
    -- Calculamos el valor monetario del inventario
    (REPLACE(p.product_cost, '$', '')::DECIMAL * i.stock_on_hand::INT) AS valor_inventario
FROM fact_inventory i
JOIN dim_product p ON i.product_id = p.product_id;
