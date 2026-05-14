-- Para definir una estrategia de mejora competitiva 
-- Implementaremos tener el producto correcto en el momento exacto


WITH Metricas_BG3 AS (
    -- Traemos los resultados del modelo Pull (BG3)
    SELECT 'CDMX' as ciudad, 40.37 as v_diaria, 17.02 as precio_base UNION ALL
    SELECT 'Guadalajara', 37.67, 17.02 UNION ALL
    SELECT 'Hermosillo', 32.53, 17.02 UNION ALL
    SELECT 'Monterrey', 31.82, 17.02 UNION ALL
    SELECT 'Mexicali', 23.98, 17.02
),
Analisis_Elasticidad AS (
    -- Aplicamos el Key Lever: Blindaje de Margen (+/- 10% según velocidad)
    SELECT 
        ciudad,
        v_diaria,
        precio_base,
        CASE 
            WHEN v_diaria >= 35 THEN ROUND(precio_base * 1.10, 2) -- CDMX/GDL: Precio Premium (+10%)
            WHEN v_diaria BETWEEN 30 AND 34.99 THEN ROUND(precio_base * 1.05, 2) -- HER/MTY: Ajuste de Margen (+5%)
            ELSE ROUND(precio_base * 0.95, 2) -- MEX: Penetración de mercado (-5%)
        END as precio_dinamico,
        (v_diaria * 365) as ventas_unidades_anuales
    FROM Metricas_BG3
)
SELECT 
    ciudad,
    v_diaria as velocidad_venta,
    precio_base,
    precio_dinamico,
    -- EFECTO 1: Ingreso Anual Proyectado con modelo anterior
    ROUND(ventas_unidades_anuales * precio_base, 2) as ingreso_anual_plano,
    -- EFECTO 2: Ingreso Anual Proyectado con BG4 (Blindaje de Margen)
    ROUND(ventas_unidades_anuales * precio_dinamico, 2) as ingreso_anual_estrategico,
    -- CONSECUENCIA: Captura de Valor Extra
    ROUND((ventas_unidades_anuales * precio_dinamico) - (ventas_unidades_anuales * precio_base), 2) as captura_valor_extra,
    -- KPI de FEEDBACK: Margen de Posicionamiento
    ROUND(((precio_dinamico - precio_base) / precio_base) * 100, 2) as pct_blindaje_margen
FROM Analisis_Elasticidad
ORDER BY captura_valor_extra DESC;

--si optamos por  "Estrategia de Dominio por Disponibilidad Ubicua y Blindaje de Margen (Elasticity-Based Positioning)"

-- las consecuencias son sacrificar un poco de margen en una ciudad para "comprar" el mercado, mientras se cosecha el valor en las plazas dominantes, genera una rentabilidad neta superior.

-- La decisión que se tomará es Modelo de Precios Dinámicos de Precisión Logística

WITH Resumen_Operativo AS (
    -- Datos reales de tu operación BG3 + BG4
    SELECT 'CDMX' as ciudad, 40.37 as v_diaria, 17.02 as p_base, 3633 as stock_piso UNION ALL
    SELECT 'Guadalajara', 37.67, 17.02, 3390 UNION ALL
    SELECT 'Hermosillo', 32.53, 17.02, 2928 UNION ALL
    SELECT 'Monterrey', 31.82, 17.02, 2864 UNION ALL
    SELECT 'Mexicali', 23.98, 17.02, 2158
),
Calculo_Estrategico AS (
    SELECT 
        *,
        -- Aplicación de la Decisión Executive: Precios Dinámicos
        CASE 
            WHEN v_diaria >= 35 THEN ROUND(p_base * 1.10, 2) -- Premium
            WHEN v_diaria >= 30 THEN ROUND(p_base * 1.05, 2) -- Ajuste
            ELSE ROUND(p_base * 0.95, 2) -- Penetración
        END as p_dinamico,
        (v_diaria * 365) as unidades_anuales
    FROM Resumen_Operativo
)
SELECT 
    ciudad,
    v_diaria as velocidad,
    -- Comparativa de Ingresos
    ROUND(unidades_anuales * p_base, 2) as ingreso_teorico,
    ROUND(unidades_anuales * p_dinamico, 2) as ingreso_con_decision,
    
    -- KPI 1: CAPTURA DE VALOR EXTRA (Dinero "nuevo" sin vender más piezas)
    ROUND((unidades_anuales * p_dinamico) - (unidades_anuales * p_base), 2) as valor_extra,

    -- KPI 2: MARGIN YIELD (El indicador de excelencia)
    -- Si es > 1.00, la decisión está extrayendo valor del mercado eficientemente
    ROUND((unidades_anuales * p_dinamico) / (unidades_anuales * p_base), 3) as margin_yield,

    -- FEEDBACK DEL KPI
    CASE 
        WHEN (unidades_anuales * p_dinamico) / (unidades_anuales * p_base) > 1.05 
            THEN 'EXCELENTE: Captura de Valor Premium'
        WHEN (unidades_anuales * p_dinamico) / (unidades_anuales * p_base) BETWEEN 1.00 AND 1.05 
            THEN 'POSITIVO: Optimización de Margen'
        ELSE 'TÁCTICO: Inversión en Cuota de Mercado'
    END as veredicto_ejecutivo
FROM Calculo_Estrategico
ORDER BY margin_yield DESC;
