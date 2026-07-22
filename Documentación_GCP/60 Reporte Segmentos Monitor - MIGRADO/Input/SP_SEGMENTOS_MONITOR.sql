USE [BDRIESGO]
GO
/****** Object:  StoredProcedure [dbo].[SP_SEGMENTOS_MONITOR]    Script Date: 12/01/2026 18:04:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[SP_SEGMENTOS_MONITOR]
AS
BEGIN
    SET NOCOUNT ON;

    -- Definir fechas
    DECLARE @FechaHoy DATE = CAST(GETDATE() AS DATE);
    DECLARE @FechaCorteAnterior DATE = EOMONTH(DATEADD(MONTH, -1, @FechaHoy));
    DECLARE @FechaCorteActual DATE = EOMONTH(@FechaHoy);

    /*Insertar del mes actual en respaldo */
    INSERT INTO SEGMENTOS_MES_RESPALDO (nroruc, cta_esp_anterior, situac_anterior, fecha_corte)
    SELECT 
        nroruc,
        cta_esp,
        situac,
        @FechaCorteActual
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (
                   PARTITION BY nroruc
                   ORDER BY fecmod DESC
               ) AS rn
        FROM PFYCC_GI_TRANS_MCESTAB
        WHERE 
            situac NOT IN (2, 3, 4, 6)
            AND cta_esp IN ('C', 'E')
			AND facili_pago <> 'INTEROPERABILIDAD' 
			AND facili_pago NOT LIKE 'FP-VD%'
			AND CONTRA <> 'NIUBIZ-AX'
            --AND facili_pago NOT IN ('INTEROPERABILIDAD', 'NIUBIZ', 'FP-VD+')
    ) AS sub
    WHERE rn = 1;

    /*Comparar mes anterior vs mes actual y guardar en SEGMENTOS_MONITOR */
    WITH HISTORICO AS (
        SELECT 
            nroruc,
            cta_esp_anterior,
            situac_anterior
        FROM SEGMENTOS_MES_RESPALDO
        WHERE fecha_corte = @FechaCorteAnterior
    ),
    ACTUAL_VALIDO AS (
        SELECT t.nroruc,
               t.cta_esp AS cta_esp_actual,
               t.situac AS situac_actual
        FROM (
            SELECT 
                nroruc,
                cta_esp,
                situac,
                fecmod,
                ROW_NUMBER() OVER (PARTITION BY nroruc ORDER BY fecmod DESC) AS rn
            FROM PFYCC_GI_TRANS_MCESTAB
            WHERE situac NOT IN (2,3,4,6)
              AND cta_esp IN ('C','E')
			  AND facili_pago <> 'INTEROPERABILIDAD' 
			  AND facili_pago NOT LIKE 'FP-VD%'
			  AND CONTRA <> 'NIUBIZ-AX'
              --AND facili_pago NOT IN ('INTEROPERABILIDAD','NIUBIZ','FP-VD+')
        ) t
        WHERE t.rn = 1
    ),
    ACTUAL_TODOS AS (   -- siempre el último valor del mes sin filtros
        SELECT t.nroruc,
               t.cta_esp,
               t.situac
        FROM (
            SELECT 
                nroruc,
                cta_esp,
                situac,
                fecmod,
                ROW_NUMBER() OVER (PARTITION BY nroruc ORDER BY fecmod DESC) AS rn
            FROM PFYCC_GI_TRANS_MCESTAB
        ) t
        WHERE t.rn = 1
    )
    INSERT INTO dbo.SEGMENTOS_MONITOR (
        nroruc,
        cta_esp_anterior,
        cta_esp_actual,
        situac_anterior,
        situac_actual,
        tipo_cambio,
        accion,
        fecha_ejecucion
    )
    SELECT 
        COALESCE(H.nroruc, F.nroruc) AS nroruc,
        H.cta_esp_anterior,
        COALESCE(F.cta_esp_actual, FT.cta_esp) AS cta_esp_actual,
        H.situac_anterior,
        COALESCE(F.situac_actual, FT.situac) AS situac_actual,
        CASE 
            WHEN H.nroruc IS NULL AND F.nroruc IS NOT NULL THEN 'NUEVO'
            WHEN H.nroruc IS NOT NULL AND F.nroruc IS NULL THEN 'INACTIVO'
            WHEN H.nroruc IS NOT NULL AND F.nroruc IS NOT NULL 
                 AND H.cta_esp_anterior <> F.cta_esp_actual 
                 AND F.cta_esp_actual IN ('C','E') THEN 'CAMBIO_SEGMENTO'
            WHEN H.nroruc IS NOT NULL AND F.nroruc IS NOT NULL 
                 AND H.cta_esp_anterior <> FT.cta_esp_actual 
                 AND FT.cta_esp_actual NOT IN ('C','E') THEN 'CAMBIO_SEGMENTO_NO_VALIDO'
            WHEN H.nroruc IS NOT NULL AND F.nroruc IS NOT NULL 
                 AND H.cta_esp_anterior = F.cta_esp_actual THEN 'SIN_CAMBIO'
        END AS tipo_cambio,
        CASE 
            WHEN H.nroruc IS NULL AND F.nroruc IS NOT NULL THEN 'CARGAR'
            WHEN H.nroruc IS NOT NULL AND F.nroruc IS NULL THEN 'EXTRAER'
            WHEN H.nroruc IS NOT NULL AND F.nroruc IS NOT NULL 
                 AND H.cta_esp_anterior <> F.cta_esp_actual 
                 AND F.cta_esp_actual IN ('C','E') THEN 'EXTRAER Y CARGAR'
            WHEN H.nroruc IS NOT NULL AND F.nroruc IS NOT NULL 
                 AND H.cta_esp_anterior <> FT.cta_esp_actual 
                 AND FT.cta_esp_actual NOT IN ('C','E') THEN 'EXTRAER'
            WHEN H.nroruc IS NOT NULL AND F.nroruc IS NOT NULL 
                 AND H.cta_esp_anterior = F.cta_esp_actual THEN 'MANTENER'
        END AS accion,
        @FechaHoy AS fecha_ejecucion
    FROM HISTORICO H
    FULL OUTER JOIN ACTUAL_VALIDO F
        ON H.nroruc = F.nroruc
    LEFT JOIN ACTUAL_TODOS FT
        ON H.nroruc = FT.nroruc;

END
