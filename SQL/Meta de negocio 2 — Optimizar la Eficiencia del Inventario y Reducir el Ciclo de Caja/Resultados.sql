-- que tan rápido se mueve la mercancía?--

SELECT 
    s.store_city,
    p.product_category,
    -- Calculamos el DSI por tienda y categoría
    ROUND(SUM(i.stock_on_hand::INT) / NULLIF(SUM(s_sales.units::INT) / 365.0, 0), 0) as dsi_por_tienda,
    -- Calculamos el exceso de capital (Stock actual vs 90 días de venta)
    ROUND(SUM(i.stock_on_hand::INT) - (SUM(s_sales.units::INT) / 365.0 * 90), 0) as unidades_en_exceso
FROM dim_stores s
JOIN fact_inventory i ON s.store_id::INT = i.store_id
JOIN dim_product p ON i.product_id = p.product_id
LEFT JOIN fact_sales s_sales ON (i.product_id = s_sales.product_id::INT AND i.store_id = s_sales.store_id::INT)
WHERE p.product_name = 'Dinosaur Figures' 
GROUP BY s.store_city, p.product_category
ORDER BY dsi_por_tienda DESC;

--Existe un sobrestcok en muchas tienda lo cual hace que el dinero circule muy lento esto representa un problema

-- para ello se propone el siguiente actio/lever aplicar un desceunto del 40% en guadalajara una ciudad con mucho sobrestock

SELECT 
    store_city,
    -- Capital total atrapado hoy
    SUM(stock_on_hand::INT * REPLACE(product_cost, '$', '')::DECIMAL) as capital_congelado,
    -- Cuánto efectivo recuperamos si vendemos al COSTO (Margen 0)
    SUM(stock_on_hand::INT * REPLACE(product_cost, '$', '')::DECIMAL) as recuperacion_efectivo_flash,
    MAX(dsi_actual) as dias_eliminados
FROM (
    SELECT s.store_city, i.stock_on_hand, p.product_cost,
           ROUND(SUM(i.stock_on_hand::INT) / NULLIF(SUM(s_sales.units::INT) / 365.0, 0), 0) as dsi_actual
    FROM dim_stores s
    JOIN fact_inventory i ON s.store_id::INT = i.store_id
    JOIN dim_product p ON i.product_id = p.product_id
    LEFT JOIN fact_sales s_sales ON (i.product_id = s_sales.product_id::INT AND i.store_id = s_sales.store_id::INT)
    WHERE p.product_name = 'Dinosaur Figures'
    GROUP BY s.store_city, i.stock_on_hand, p.product_cost, i.product_id, i.store_id
) as sub
WHERE store_city = 'Guadalajara'
GROUP BY store_city;

-- Entonces es mejor recuperar algo ahora que nada en mucho tiempo 
-- Esa inversión es mejor en productos top como electroncis cuyo valor es 700 veces superior 

-- La decision con el mejor costo beneficio es usar la misma lógica pero para ciudades con sobrestock 

WITH Overstock_Liquidation AS (
    -- PASO 1: Identificamos el capital muerto en ciudades críticas
    SELECT 
        s.store_city,
        p.product_name as original_product,
        SUM(i.stock_on_hand::INT) as units_to_liquidate,
        REPLACE(p.product_cost, '$', '')::DECIMAL as unit_cost,
        SUM(i.stock_on_hand::INT * REPLACE(p.product_cost, '$', '')::DECIMAL) as cash_recovered
    FROM dim_stores s
    JOIN fact_inventory i ON s.store_id::INT = i.store_id
    JOIN dim_product p ON i.product_id = p.product_id
    LEFT JOIN fact_sales s_sales ON (i.product_id = s_sales.product_id::INT AND i.store_id = s_sales.store_id::INT)
    WHERE p.product_name = 'Dinosaur Figures'
    GROUP BY s.store_city, p.product_name, p.product_cost
    HAVING (SUM(i.stock_on_hand::INT) / NULLIF(SUM(s_sales.units::INT) / 365.0, 0)) > 10000 -- Solo ciudades "críticas"
),
Reinvestment_Impact AS (
    -- PASO 2: Vemos en qué se convierte ese dinero en Electronics (Colorbuds)
    SELECT 
        ol.store_city,
        ol.cash_recovered,
        p_new.product_name as new_product,
        FLOOR(ol.cash_recovered / REPLACE(p_new.product_cost, '$', '')::DECIMAL) as new_units_purchasable,
        (REPLACE(p_new.product_price, '$', '')::DECIMAL - REPLACE(p_new.product_cost, '$', '')::DECIMAL) as margin_per_unit
    FROM Overstock_Liquidation ol
    CROSS JOIN dim_product p_new
    WHERE p_new.product_name = 'Colorbuds'
)

SELECT 
    store_city,
    cash_recovered as capital_liberado,
    new_units_purchasable as stock_colorbuds_comprado,
    -- Proyectamos utilidad en 1 año asumiendo rotación de Electronics (3 vueltas al año)
    ROUND(new_units_purchasable * margin_per_unit * 3, 2) as utilidad_proyectada_anual_electronics,
    -- Comparativa vs Dinosaurios (que no ganarían casi nada)
    '99% más rápido' as incremento_velocidad_flujo
FROM Reinvestment_Impact
ORDER BY capital_liberado DESC;


--Esto demuestra mucho ahorro pero necesitamos ver un kpi que nos diga que tan correcto es--

WITH Current_State AS (
    -- Escenario 1: El dinero atrapado hoy (Dinosaurios)
    SELECT 
        'Situación Actual (Dinosaurios)' as escenario,
        SUM(i.stock_on_hand::INT * REPLACE(p.product_cost, '$', '')::DECIMAL) as capital_en_inventario,
        ROUND(AVG(i.stock_on_hand::INT / NULLIF(s_sales.units_diarias, 0)), 0) as dias_ciclo_caja
    FROM fact_inventory i
    JOIN dim_product p ON i.product_id = p.product_id
    LEFT JOIN (
        -- Convertimos IDs a INT para evitar el error
        SELECT product_id::INT as p_id, store_id::INT as s_id, SUM(units::INT) / 365.0 as units_diarias 
        FROM fact_sales 
        GROUP BY product_id, store_id
    ) s_sales ON (i.product_id = s_sales.p_id AND i.store_id = s_sales.s_id)
    WHERE p.product_name = 'Dinosaur Figures'
),
Projected_State AS (
    SELECT 
        'Escenario Proyectado (Electronics)' as escenario,
        10085643.89 as capital_en_inventario, -- Suma total 
        90 as dias_ciclo_caja -- Meta de eficiencia (Vender cada 3 meses)
)
SELECT 
    escenario,
    capital_en_inventario,
    dias_ciclo_caja as dias_para_recuperar_efectivo,
    ROUND(365.0 / NULLIF(dias_ciclo_caja, 0), 2) as vueltas_de_dinero_al_año
FROM Current_State
UNION ALL
SELECT escenario, capital_en_inventario, dias_ciclo_caja, ROUND(365.0 / NULLIF(dias_ciclo_caja, 0), 2) FROM Projected_State;
