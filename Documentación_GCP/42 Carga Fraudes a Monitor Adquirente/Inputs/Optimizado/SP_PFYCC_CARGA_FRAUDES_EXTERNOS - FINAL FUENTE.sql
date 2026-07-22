USE [BDRIESGO]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================================
-- SP: SP_PFYCC_CARGA_FRAUDES_EXTERNOS  (v2)
-- Descripción : Genera la tabla PFYCC_CARGA_FRAUDES_EXTERNOS
--               leyendo directamente desde RT_GD_STATUS_CONSOLIDADO_FRAUDES,
--               filtrando los estados:
--                 - 'Enviado'
--                 - 'Segundo_Reproceso_Enviado'
--               para ADQ (C87882='8751') y EMISOR (C87882='8750').
--
-- PREREQUISITO: SP_RT_GD_STATUS_CONSOLIDADO_FRAUDES debe haberse
--               ejecutado previamente en el mismo día.
--
-- Tablas destino : DBO.PFYCC_CARGA_FRAUDES_EXTERNOS
--                  DBO.PFYCC_CARGA_FRAUDES_EXTERNOS_BACKUP (solo backup)
-- ============================================================

ALTER PROCEDURE [dbo].[SP_PFYCC_CARGA_FRAUDES_EXTERNOS]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @hoy VARCHAR(10) = CONVERT(VARCHAR(10), GETDATE(), 120);

    -- ===========================================================
    -- SECCIÓN 1 : BACKUP + TRUNCATE
    -- ===========================================================

    -- Guardar snapshot previo antes de recargar
    INSERT INTO DBO.PFYCC_CARGA_FRAUDES_EXTERNOS_BACKUP
    SELECT * FROM DBO.PFYCC_CARGA_FRAUDES_EXTERNOS;

    -- Limpiar destino para carga fresca
    TRUNCATE TABLE DBO.PFYCC_CARGA_FRAUDES_EXTERNOS;


    -- ===========================================================
    -- SECCIÓN 2 : CARGA ROL ADQUIRENTE (C87882 = '8751')
    -- Fuente   : RT_GD_STATUS_CONSOLIDADO_FRAUDES
    -- Filtro   : estado_fraude IN ('Enviado','Segundo_Reproceso_Enviado')
    --            AND Entidad = 'ADQ'
    --            AND Fecha_Envio = hoy
    -- El correlativo C87873 se genera aquí: YYMMDD + secuencia 4 dígitos
    -- ===========================================================

    ;WITH

    -- Universo ADQ enviados del día (deduplicado por clave transaccional)
    Enviados_ADQ AS (
        SELECT
            tarjeta_sha256_trx, hora_trx, mto_trx,
            codigo_cio_trx, nom_cio_trx, cod_giro_comercio_trx,
            bin_trx, id_cliente_trx, entry_mode_trx,
            ucaf_trx, canal_trx, id_comercio_trx,
            tarjetaregistro750_trx,
            Fecha, CodComercio, Autorizacion,
            Accion_Tomada, Tipo_Fraude_Marcado, Fecha_Carga,
            MONTO_FRAUDE_SOLES,
            rn_dup = ROW_NUMBER() OVER (
                PARTITION BY CONVERT(VARCHAR, Fecha, 112),
                             Autorizacion,
                             codigo_cio_trx,
                             tarjetaregistro750_trx
                ORDER BY (SELECT NULL))
        FROM DBO.RT_GD_STATUS_CONSOLIDADO_FRAUDES WITH(NOLOCK)
        WHERE Fecha_Envio = @hoy
          AND estado_fraude IN ('Enviado', 'Segundo_Reproceso_Enviado')
          AND Entidad = 'ADQ'
          AND tarjeta_sha256_trx IS NOT NULL   -- garantiza que tiene datos transaccionales
    )

    INSERT INTO DBO.PFYCC_CARGA_FRAUDES_EXTERNOS
    SELECT
        C87872 = 1,
        C87873 = CAST(
                    CONCAT(
                        CONVERT(VARCHAR, GETDATE(), 12),
                        REPLICATE('0', 4 - LEN(CAST(ROW_NUMBER() OVER (ORDER BY Fecha ASC, hora_trx ASC) AS VARCHAR))),
                        ROW_NUMBER() OVER (ORDER BY Fecha ASC, hora_trx ASC)
                    ) AS BIGINT),
        C87874 = 'IZIPAY',
        C87875 = 'PERU',
        C87876 = Fecha_Carga,
        C87877 = '00:00:01',
        C87878 = CASE Accion_Tomada WHEN 'F:TC40' THEN '1' WHEN 'F:Safe' THEN '2' ELSE '3' END,
        C87879 = 0,
        C87880 = CASE Accion_Tomada WHEN 'F:TC40' THEN '1' WHEN 'F:Safe' THEN '2' ELSE '3' END,
        C87881 = 'REP',
        C87882 = '8751',    -- Identificador Adquirente
        C87883 = id_cliente_trx,
        C87884 = tarjeta_sha256_trx,
        C87885 = CONVERT(VARCHAR, Fecha, 112),
        C87886 = REPLACE(hora_trx, ':', ''),
        C87887 = CONVERT(NUMERIC(14,2), mto_trx),
        C87888 = Autorizacion,
        C87889 = '000',
        C87890 = 1,
        C87531 = codigo_cio_trx,
        C87545 = tarjetaregistro750_trx,
        C87418 = nom_cio_trx,
        C87510 = cod_giro_comercio_trx,
        C87536 = bin_trx,
        C87511 = entry_mode_trx,
        C87599 = ucaf_trx,
        C87532 = canal_trx,
        C87530 = id_comercio_trx,
        C90066 = 0, C90067 = 0, C90068 = 0, C90069 = 0, C90070 = 0, C90071 = 0,
        C87891 = CASE Accion_Tomada WHEN 'F:TC40' THEN '210' WHEN 'F:Safe' THEN '211'
                                    WHEN 'F:Asbanc' THEN '212' WHEN 'F:Contracargos' THEN '213'
                                    ELSE '210' END,
        C87892 = Tipo_Fraude_Marcado,
        C87893 = 0,
        C87894 = '001',
        C87895 = CAST(GETDATE() AS DATE),
        C87896 = CAST(GETDATE() AS TIME),
        C87897 = 0
    FROM Enviados_ADQ
    WHERE rn_dup = 1
      AND LEN(
            CAST(
                CONCAT(
                    CONVERT(VARCHAR, GETDATE(), 12),
                    REPLICATE('0', 4 - LEN(CAST(ROW_NUMBER() OVER (ORDER BY Fecha ASC, hora_trx ASC) AS VARCHAR))),
                    ROW_NUMBER() OVER (ORDER BY Fecha ASC, hora_trx ASC)
                ) AS BIGINT)
          ) = 10;  -- Filtro de correlativo válido (10 dígitos)


    -- ===========================================================
    -- SECCIÓN 3 : CARGA ROL EMISOR (C87882 = '8750')
    -- Misma lógica, desde estados Enviado/Segundo_Reproceso_Enviado
    -- de Entidad = 'EMISOR'
    -- El correlativo continúa la secuencia del día (no hay colisión
    -- porque ADQ y EMISOR se diferencian por C87882)
    -- ===========================================================

    ;WITH

    Enviados_EMI AS (
        SELECT
            tarjeta_sha256_trx, hora_trx, mto_trx,
            codigo_cio_trx, nom_cio_trx, cod_giro_comercio_trx,
            bin_trx, id_cliente_trx, entry_mode_trx,
            ucaf_trx, canal_trx, id_comercio_trx,
            tarjetaregistro750_trx,
            Fecha, CodComercio, Autorizacion,
            Accion_Tomada, Tipo_Fraude_Marcado, Fecha_Carga,
            MONTO_FRAUDE_SOLES,
            rn_dup = ROW_NUMBER() OVER (
                PARTITION BY CONVERT(VARCHAR, Fecha, 112),
                             Autorizacion,
                             codigo_cio_trx,
                             tarjetaregistro750_trx
                ORDER BY (SELECT NULL))
        FROM DBO.RT_GD_STATUS_CONSOLIDADO_FRAUDES WITH(NOLOCK)
        WHERE Fecha_Envio = @hoy
          AND estado_fraude IN ('Enviado', 'Segundo_Reproceso_Enviado')
          AND Entidad = 'EMISOR'
          AND tarjeta_sha256_trx IS NOT NULL
    )

    INSERT INTO DBO.PFYCC_CARGA_FRAUDES_EXTERNOS
    SELECT
        C87872 = 1,
        C87873 = CAST(
                    CONCAT(
                        CONVERT(VARCHAR, GETDATE(), 12),
                        REPLICATE('0', 4 - LEN(CAST(ROW_NUMBER() OVER (ORDER BY Fecha ASC, hora_trx ASC) AS VARCHAR))),
                        ROW_NUMBER() OVER (ORDER BY Fecha ASC, hora_trx ASC)
                    ) AS BIGINT),
        C87874 = 'IZIPAY',
        C87875 = 'PERU',
        C87876 = Fecha_Carga,
        C87877 = '00:00:01',
        C87878 = CASE Accion_Tomada WHEN 'F:TC40' THEN '1' WHEN 'F:Safe' THEN '2' ELSE '3' END,
        C87879 = 0,
        C87880 = CASE Accion_Tomada WHEN 'F:TC40' THEN '1' WHEN 'F:Safe' THEN '2' ELSE '3' END,
        C87881 = 'REP',
        C87882 = '8750',    -- Identificador Emisor
        C87883 = id_cliente_trx,
        C87884 = tarjeta_sha256_trx,
        C87885 = CONVERT(VARCHAR, Fecha, 112),
        C87886 = REPLACE(hora_trx, ':', ''),
        C87887 = CONVERT(NUMERIC(14,2), mto_trx),
        C87888 = Autorizacion,
        C87889 = '000',
        C87890 = 1,
        C87531 = codigo_cio_trx,
        C87545 = tarjetaregistro750_trx,
        C87418 = nom_cio_trx,
        C87510 = cod_giro_comercio_trx,
        C87536 = bin_trx,
        C87511 = entry_mode_trx,
        C87599 = ucaf_trx,
        C87532 = canal_trx,
        C87530 = id_comercio_trx,
        C90066 = 0, C90067 = 0, C90068 = 0, C90069 = 0, C90070 = 0, C90071 = 0,
        C87891 = '800',     -- Código acción Emisor
        C87892 = Tipo_Fraude_Marcado,
        C87893 = 0,
        C87894 = '001',
        C87895 = CAST(GETDATE() AS DATE),
        C87896 = CAST(GETDATE() AS TIME),
        C87897 = 0
    FROM Enviados_EMI
    WHERE rn_dup = 1
      AND LEN(
            CAST(
                CONCAT(
                    CONVERT(VARCHAR, GETDATE(), 12),
                    REPLICATE('0', 4 - LEN(CAST(ROW_NUMBER() OVER (ORDER BY Fecha ASC, hora_trx ASC) AS VARCHAR))),
                    ROW_NUMBER() OVER (ORDER BY Fecha ASC, hora_trx ASC)
                ) AS BIGINT)
          ) = 10;  -- Filtro de correlativo válido (10 dígitos)

END
GO
