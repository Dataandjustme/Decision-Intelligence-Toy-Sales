-- Sabemos que ese dinero recuperado $10,085,643.89 USD se necesitan realocar perfectamente en reinversión --

WITH Metricas_Electronics AS (
    -- Calculamos el comportamiento real de la electrónica por ciudad
    SELECT 
        s.store_city,
        ROUND(SUM(s_sales.units::INT) / 365.0, 2) as velocidad_venta_diaria,
        AVG(REPLACE(p.product_price, '$', '')::DECIMAL) as precio_promedio_ticket,
        SUM(i.stock_on_hand::INT) as stock_actual
    FROM dim_stores s
    JOIN fact_inventory i ON s.store_id::INT = i.store_id
    JOIN dim_product p ON i.product_id = p.product_id
    LEFT JOIN fact_sales s_sales ON (i.product_id = s_sales.product_id::INT AND i.store_id = s_sales.store_id::INT)
    WHERE p.product_category = 'Electronics'
    GROUP BY s.store_city
)
SELECT 
    store_city,
    velocidad_venta_diaria,
    precio_promedio_ticket,
    stock_actual,
    -- REGLA PRESCRIPTIVA DE CLUSTERIZACIÓN
    CASE 
        WHEN velocidad_venta_diaria >= 5.0 THEN 'Clúster 1: Motores de Volumen'
        WHEN precio_promedio_ticket >= 40.0 AND velocidad_venta_diaria BETWEEN 1.5 AND 4.99 THEN 'Clúster 2: Hubs Premium'
        ELSE 'Clúster 3: Rotación Just-In-Time'
    END as cluster_estrategico,
    -- ACCIÓN DIRECTA PARA EL SURTIDO
    CASE 
        WHEN velocidad_venta_diaria >= 5.0 THEN 'Surtido Masivo (Densidad Alta)'
        WHEN precio_promedio_ticket >= 40.0 AND velocidad_venta_diaria BETWEEN 1.5 AND 4.99 THEN 'Surtido High-Ticket (Audífonos Pro & Gamer)'
        ELSE 'Surtido Ágil (Máximo 45 días de Stock)'
    END as directriz_surtido
FROM Metricas_Electronics
ORDER BY velocidad_venta_diaria DESC
LIMIT 10;


--El DSI es muy alto para estas ciudades --

--Guadalajara: 290,387 unidades / 37.67 ventas diarias = ¡7,708 días de stock (21 años)!

--Hermosillo: 242,460 unidades / 32.53 ventas diarias = ¡7,453 días de stock (20 años)!

--CDMX: 264,525 unidades / 40.37 ventas diarias = ¡6,552 días de stock (18 años)!

--Mexicali: 118,571 unidades / 23.98 ventas diarias = ¡4,944 días de stock (13 años)!

--Monterrey: 75,694 unidades / 31.82 ventas diarias = ¡2,378 días de stock (6.5 años)!

--Estas serían las consecuencias de dejar el stock así--

-- Monterrey. Con solo 75,694 unidades de stock, vende prácticamente lo mismo que Hermosillo (31.82 vs 32.53), que tiene el triple de inventario (242k).

--Las tiendas solo tienen en piso lo que van a vender en los próximos 3 meses. El espacio liberado se usa para otros SKUs o se reduce el costo de renta de almacén local.

--Si una campaña en CDMX eleva la velocidad de 40 a 80 unidades por día, el Hub Central reasigna automáticamente el flujo hacia allá.

-- Nuestra decision es "La Decisión Executive: > Transicionar de un modelo de empuje de inventario ("Push") a un modelo centralizado de demanda activa ("Pull"), decretando un techo estricto de 90 días de stock en piso de venta y centralizando los $10.08M USD en un Hub Regional Líquido."

WITH Metricas_Base_Electronics AS (
    -- 1. Simulamos el comportamiento real que se midió  de la electrónica por ciudad
    SELECT 'CDMX' as store_city, 40.37 as velocidad_venta_diaria, 264525 as stock_actual_en_tienda UNION ALL
    SELECT 'Guadalajara', 37.67, 290387 UNION ALL
    SELECT 'Hermosillo', 32.53, 242460 UNION ALL
    SELECT 'Monterrey', 31.82, 75694 UNION ALL
    SELECT 'Mexicali', 23.98, 118571
),
Simulacion_Decision_Pull AS (
    -- 2. Aplicamos techo de 90 días en tienda y el resto al Hub Líquido
    SELECT 
        store_city,
        velocidad_venta_diaria,
        stock_actual_en_tienda as stock_total_comprado,
        -- El techo impuesto por tu decisión
        ROUND(velocidad_venta_diaria * 90, 0) as max_stock_permitido_en_tienda,
        -- Lo que se queda protegido y líquido en el Hub
        GREATEST(0, stock_actual_en_tienda - ROUND(velocidad_venta_diaria * 90, 0)) as stock_retenido_hub_liquido
    FROM Metricas_Base_Electronics
)
-- 3. Evaluamos el KPI de Feedback de la decisión
SELECT 
    store_city,
    velocidad_venta_diaria,
    stock_total_comprado,
    max_stock_permitido_en_tienda as inventario_en_piso_de_venta,
    stock_retenido_hub_liquido as inventario_en_hub_regional,
    
    -- KPI 1: DSI resultante en piso de venta tras la decisión
    ROUND(max_stock_permitido_en_tienda / NULLIF(velocidad_venta_diaria, 0), 0) as dsi_real_en_piso,
    
    -- KPI 2: % de Capital  salvado de quedarse congelado en la tienda
    ROUND((stock_retenido_hub_liquido::DECIMAL / NULLIF(stock_total_comprado, 0)) * 100, 2) as pct_capital_mantenido_liquido,
    

    'ÉXITO: Modelo Pull Eficiente (Techo 90 días)' as feedback_de_la_decision
FROM Simulacion_Decision_Pull
ORDER BY velocidad_venta_diaria DESC;
