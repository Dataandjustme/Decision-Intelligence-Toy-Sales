-- Donde esta el capital?--

SELECT 
    product_category, 
    SUM(stock_on_hand) as unidades_totales,
    SUM(valor_inventario) as capital_total
FROM view_inventario_disponible
GROUP BY product_category
ORDER BY capital_total DESC;
ORDER BY capital_total DESC;

-- Cuáles productos no se estan vendiendo?--

SELECT 
    v.product_name,
    v.stock_on_hand,
    v.valor_inventario,
    COALESCE(SUM(s.units::INT), 0) as unidades_vendidas
FROM view_inventario_disponible v
LEFT JOIN fact_sales s ON v.product_id = s.product_id::INT
WHERE v.product_category = 'Toys'
GROUP BY v.product_name, v.stock_on_hand, v.valor_inventario
ORDER BY v.valor_inventario DESC
LIMIT 10;

-- tomoar la decision de realocación de capital a electornics--

SELECT 
    p.product_name,
    p.product_category,
    SUM(i.stock_on_hand::INT) as stock_actual,
    (REPLACE(p.product_cost, '$', '')::DECIMAL * SUM(i.stock_on_hand::INT)) as valor_total,
    COALESCE(SUM(s.units::INT), 0) as unidades_vendidas_historicas
FROM dim_product p
JOIN fact_inventory i ON p.product_id = i.product_id
LEFT JOIN fact_sales s ON p.product_id = s.product_id::INT
WHERE p.product_name IN ('Dinosaur Figures', 'Lego Bricks')
GROUP BY p.product_name, p.product_category, p.product_cost;

-- Cómo estamos seguros?--
SELECT 
    p.product_category,
    SUM(s.units::INT) as unidades_vendidas,
    COUNT(DISTINCT p.product_id) as variedad_productos,
    -- Calculamos cuántas unidades se venden en promedio por cada modelo de producto
    ROUND(SUM(s.units::INT) / NULLIF(COUNT(DISTINCT p.product_id), 0), 2) as ventas_por_modelo
FROM fact_sales s
JOIN dim_product p ON s.product_id::INT = p.product_id  -- Aquí aplicamos el ajuste de tipo
WHERE p.product_category IN ('Toys', 'Electronics')
GROUP BY p.product_category;


--Entonces si ya sabemos que categoria realocarte, pero preguntarte --

SELECT 
    st.store_city,
    SUM(s.units::INT) as ventas_electronics
FROM fact_sales s
JOIN dim_product p ON s.product_id::INT = p.product_id
JOIN dim_stores st ON s.store_id::INT = st.store_id
WHERE p.product_category = 'Electronics'
GROUP BY st.store_city
ORDER BY ventas_electronics DESC
LIMIT 5;


-- Ya sabemos que ciudades podemos invgertir eso 180k usd pero como sabemos si estamos correctos?--

SELECT 
    p.product_name,
    p.product_category,
    -- 1. ROTACIÓN (Inventory Turnover)
    -- Fórmula: Ventas Totales / Stock Actual
    ROUND(SUM(s.units::INT) / NULLIF(SUM(i.stock_on_hand::INT), 0), 4) AS inventory_turnover,

    -- 2. GMROI
    -- Fórmula: Utilidad Bruta Total / Inversión en Stock Actual
    ROUND(
        SUM((REPLACE(p.product_price, '$', '')::DECIMAL - REPLACE(p.product_cost, '$', '')::DECIMAL) * s.units::INT) 
        / 
        NULLIF(SUM(REPLACE(p.product_cost, '$', '')::DECIMAL * i.stock_on_hand::INT), 0)
    , 4) AS gmroi,

    -- 3. DSI (Days Sales of Inventory)
    -- Fórmula: (Stock Actual / Ventas Diarias Promedio) 
    -- Asumiendo un histórico de 365 días
    ROUND(
        SUM(i.stock_on_hand::INT) / NULLIF(SUM(s.units::INT) / 365.0, 0)
    , 0) AS dsi_dias

FROM dim_product p
JOIN fact_inventory i ON p.product_id = i.product_id
LEFT JOIN fact_sales s ON p.product_id = s.product_id::INT
WHERE p.product_name IN ('Dinosaur Figures', 'Lego Bricks') 
   OR p.product_category = 'Electronics'
GROUP BY p.product_name, p.product_category
ORDER BY gmroi DESC
limit 5;
