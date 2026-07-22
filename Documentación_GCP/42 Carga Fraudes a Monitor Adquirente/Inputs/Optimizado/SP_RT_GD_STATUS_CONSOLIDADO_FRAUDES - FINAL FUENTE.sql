USE [BDRIESGO]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ============================================================
-- SP: SP_RT_GD_STATUS_CONSOLIDADO_FRAUDES  (v3)
-- Descripción : Genera los estados de fraude para ADQ y EMISOR
--               e inserta en RT_GD_STATUS_CONSOLIDADO_FRAUDES.
--
-- OPTIMIZACIONES v3:
--   1. Fuente única (Fuentes_ALL): lee Asbanc + TC40 + Contracargos
--      una sola vez con el rango más amplio (14 días).
--      Trae ambos campos de monto (Monto_Soles e importe_dolares).
--      ADQ y EMISOR filtran su rango propio en sus CTEs descendientes.
--   2. Sin tabla staging física: RT_GD_REPORTE_CONSOLIDADO_FRAUDES_FINAL
--      reemplazada por CTEs en memoria.
--   3. Un solo INSERT al final con UNION ALL de los 8 estados.
--   4. Sin CTEs duplicados: Fuentes, Alertas e Investigadores
--      se definen una única vez cada uno.
--   5. Filtro de BINs emisor aplicado en Dedup_EMI, no en la fuente.
--   6. Reproceso ADQ derivado directamente del CTE Filtro_ADQ,
--      sin releer RT_GD_STATUS_CONSOLIDADO_FRAUDES.
--
-- Columnas transaccionales en CONSOLIDADO (solo para 'Enviado'
-- y 'Segundo_Reproceso_Enviado', NULL para el resto):
--   tarjeta_sha256_trx, hora_trx, mto_trx,
--   codigo_cio_trx, nom_cio_trx, cod_giro_comercio_trx, bin_trx,
--   id_cliente_trx, entry_mode_trx, ucaf_trx, canal_trx,
--   id_comercio_trx, tarjetaregistro750_trx
--
-- Ejecución   : Debe ejecutarse ANTES que SP_PFYCC_CARGA_FRAUDES_EXTERNOS.
-- Periodicidad:
--   Adquirente (ADQ)  -> últimos 3 días hábiles (respeta fin de semana)
--   Emisor     (EMI)  -> últimos 14 días
-- ============================================================

ALTER PROCEDURE [dbo].[SP_RT_GD_STATUS_CONSOLIDADO_FRAUDES]
AS
BEGIN
    SET NOCOUNT ON;

    -- ===========================================================
    -- SECCIÓN 0 : VARIABLES DE FECHA
    -- ===========================================================

    SET DATEFIRST 1;  -- Lunes = primer día de la semana

    -- Fechas ADQ: ayer como tope; si hoy es lunes, inicio = viernes
    DECLARE @adq_fecha1 DATE = CAST(DATEADD(DAY, -1, GETDATE()) AS DATE);
    DECLARE @adq_fecha2 DATE;
    IF DATEPART(WEEKDAY, GETDATE()) = 1
        SET @adq_fecha2 = CAST(DATEADD(DAY, -3, GETDATE()) AS DATE);
    ELSE
        SET @adq_fecha2 = @adq_fecha1;

    -- Fechas EMISOR: hoy como tope, 14 días atrás como inicio
    -- Este rango es el más amplio y es el que usa Fuentes_ALL
    DECLARE @emi_fecha1 DATE = CAST(GETDATE() AS DATE);
    DECLARE @emi_fecha2 DATE = CAST(DATEADD(DAY, -14, GETDATE()) AS DATE);

    -- Fecha de hoy para etiquetar los registros del día
    DECLARE @hoy VARCHAR(10) = CONVERT(VARCHAR(10), GETDATE(), 120);

    -- ===========================================================
    -- ÚNICO BLOQUE CTE + INSERT
    -- Todos los estados se calculan aquí y se insertan en un solo
    -- statement al final con UNION ALL.
    -- ===========================================================

    ;WITH

    -- -----------------------------------------------------------
    -- FUENTE ÚNICA: Asbanc + TC40 + Contracargos
    -- Rango: últimos 14 días (el más amplio, cubre ADQ y EMISOR).
    -- Se traen ambos campos de monto de Asbanc:
    --   Monto_Soles     → ADQ usa este
    --   importe_dolares → EMISOR usa este
    -- Para TC40 y Contracargos el monto es el mismo para ambos roles.
    -- ADQ y EMISOR filtran su ventana de fecha en sus propios CTEs.
    -- -----------------------------------------------------------
    Fuentes_ALL AS (

        -- ASBANC (trae ambos campos de monto)
        SELECT DISTINCT
            Fecha               = CAST(fecha_trx AS DATE),
            Tarjeta_Encriptada  = CONCAT(LEFT(Tarjeta_Encriptada,6),'XXXXXX',RIGHT(Tarjeta_Encriptada,4)),
            sufix               = RIGHT(Tarjeta_Encriptada,4),
            CodComercio         = CASE
                                    WHEN LEFT(Cod_comercio,2)='00'      THEN SUBSTRING(Cod_comercio,3,7)
                                    WHEN RIGHT(Cod_comercio,5)='00000'  THEN LEFT(Cod_comercio,7)
                                    ELSE RIGHT(Cod_comercio,7) END,
            bin,
            cod_autorizacion        = CASE
                                    WHEN Cod_RPTA <> '00' THEN ''
                                    WHEN NOT (Importe_dolares <> '' AND RTRIM(Autorizacion) <> ''
                                         AND CONCAT(REPLICATE('0',6-LEN(RTRIM(Autorizacion))),Autorizacion)
                                             NOT LIKE '%000000%') THEN ''
                                    ELSE CONCAT(REPLICATE('0',6-LEN(RTRIM(Autorizacion))),Autorizacion) END,
            -- ADQ usa Monto_Soles, EMISOR usa importe_dolares
            Monto_ADQ           = REPLACE(Monto_Soles,' ','.'),
            Monto_EMI           = REPLACE(importe_dolares,' ','.'),
            nom_comercio       = nombre_del_comercio,
            Accion_Tomada       = 'F:Asbanc',
            Tipo_Fraude_Marcado = 'Reportado x Asbanc',
            Fecha_Carga         = CASE WHEN Fecha_Carga='0' THEN '1900-01-01' ELSE CAST(Fecha_Carga AS DATE) END,
            Fuente              = 'ASBANC'
        FROM DBO.PFYCC_GI_CARGA_ASBANC_TANSFORMADA_2 WITH(NOLOCK)
        WHERE Fecha_Carga <> '0'
          AND ISDATE(Fecha_Carga) = 1
          AND CAST(Fecha_Carga AS DATE) BETWEEN @emi_fecha2 AND @emi_fecha1  -- rango máximo

        UNION ALL

        -- VISA / MASTERCARD (TC40) — monto igual para ADQ y EMISOR
        SELECT DISTINCT
            Fecha               = CONVERT(DATE,[Fecha transacción],103),
            Tarjeta_Encriptada  = CONCAT(LEFT(Tarjeta_Encriptada,6),'XXXXXX',RIGHT(Tarjeta_Encriptada,4)),
            sufix,
            CodComercio         = Establecimiento,
            bin,
            cod_autorizacion        = CONCAT(REPLICATE('0',6-LEN(RTRIM(Autorizacion))),Autorizacion),
            Monto_ADQ           = Importe_soles,
            Monto_EMI           = Importe_soles,
            nom_comercio       = [nombre comer],
            Accion_Tomada       = Fuente,
            Tipo_Fraude_Marcado = CASE Tipo_Fraude
                WHEN '6' THEN 'F: Tarjeta no Presente  MOTO-Internet'
                WHEN '4' THEN 'F: Falsificacion/ Clonacion'
                WHEN '1' THEN 'F: Tarjeta Robada'
                WHEN '5' THEN 'MISCELLANEOUS'
                WHEN '0' THEN 'F: Tarjeta Perdida'
                WHEN '2' THEN 'F: Tarjeta nunca recibida del Emisor'
                WHEN '3' THEN 'F: Fraud App'
                WHEN 'D' THEN 'MANIPULATION OF ACCOUNT HOLDER-MANIPULACIÓN DEL TITULAR DE LA CUENTA'
                WHEN 'A' THEN 'INCORRECT PROCESSING -PROCESAMIENTO INCORRECTO'
                WHEN 'B' THEN 'ACCOUNT OR CREDENTIALS TAKEOVER -ADQUISICIÓN DE CUENTAS O CREDENCIALES'
                END,
            Fecha_Carga         = CONVERT(DATE,Fecha_Carga,103),
            Fuente              = 'TC40'
        FROM DBO.PFYCC_GI_CARGA_TC40_TANSFORMADA WITH(NOLOCK)
        WHERE CONVERT(DATE,Fecha_Carga,103) BETWEEN @emi_fecha2 AND @emi_fecha1  -- rango máximo

        UNION ALL

        -- CONTRACARGOS — monto igual para ADQ y EMISOR
        SELECT DISTINCT
            Fecha               = FechaTrx,
            Tarjeta_Encriptada  = CONCAT(LEFT(Tarjeta,6),'XXXXXX',RIGHT(Tarjeta,4)),
            sufix               = RIGHT(Tarjeta,4),
            CodComercio         = RIGHT(CodComercio,7),
            bin                 = BIN,
            cod_autorizacion        = CONCAT(REPLICATE('0',6-LEN(RTRIM(CodAutorizacion))),CodAutorizacion),
            Monto_ADQ           = ImporteSoles,
            Monto_EMI           = ImporteSoles,
            nom_comercio       = NomComercio,
            Accion_Tomada       = 'F:Contracargos',
            Tipo_Fraude_Marcado = 'Reportado x Contracargos',
            Fecha_Carga         = FechaCC,
            Fuente              = 'CONTRACARGOS'
        FROM DBO.RT_GD_REPORTE_CONTRACARGOS_RPA WITH(NOLOCK)
        WHERE FechaCC BETWEEN @emi_fecha2 AND @emi_fecha1
          AND CategoriaCC = 'Fraude'
    ),

    -- -----------------------------------------------------------
    -- ALERTAS ADQ (definición única)
    -- -----------------------------------------------------------
    Alertas_ADQ AS (
        SELECT *
        FROM (
            SELECT
                FechaTrx        = CAST(FechaTRX_ACF AS DATE),
                BIN             = Bin_ACF,
                CodComercio     = RIGHT(CodigoCIO_ACF,7),
                CodAutorizacion = CONCAT(REPLICATE('0',6-LEN(RTRIM(Autorizacion_ACF))),Autorizacion_ACF),
                Tarjetaregistro750_ACF,
                ACF_SubtipoResultadoCasodeInvestigacion,
                ACF_TextoSubTipodeResultado,
                FechaRecepcion  = CAST(FechaRecepcion AS DATE),
                ACF_UsuarioInvestigador,
                ACF_TextoAccionTomada,
                rn = ROW_NUMBER() OVER (
                    PARTITION BY FechaTRX_ACF, HoraTRX_ACF, NumeroTrx_ACF, Autorizacion_ACF, MONTOSOLES_ACF
                    ORDER BY FechaRecepcion ASC, ACF_FechaCierreCaso ASC, ACF_HoraFinCaso ASC)
            FROM DBO.PFYCC_GI_CARGA_CIERRE_ALERTAS_ROL_ADQ WITH(NOLOCK)
            WHERE ACF_TipodeResultadoCasodeInvestigacion = '1'
              AND IndicadordeCorreccion_ACF IN ('0','2')
              AND CodRpta_ACF = '000'
              AND Reverso_ACF = 'N'
              AND FechaTRX_ACF <> '####/##/##'
        ) x
        WHERE rn = 1
          AND FechaTrx >= '2022-01-01'
    ),

    -- -----------------------------------------------------------
    -- ALERTAS EMISOR (definición única)
    -- -----------------------------------------------------------
    Alertas_EMI AS (
        SELECT *
        FROM (
            SELECT
                FechaTrx        = CAST(FechaTRX_ACF AS DATE),
                BIN             = Bin_ACF,
                CodComercio     = RIGHT(CodigoCIO_ACF,7),
                CodAutorizacion = CONCAT(REPLICATE('0',6-LEN(RTRIM(Autorizacion_ACF))),Autorizacion_ACF),
                Tarjetaregistro750_ACF,
                ACF_SubtipoResultadoCasodeInvestigacion,
                ACF_TextoSubTipodeResultado,
                FechaRecepcion  = CAST(FechaRecepcion AS DATE),
                ACF_UsuarioInvestigador,
                ACF_TextoAccionTomada,
                rn = ROW_NUMBER() OVER (
                    PARTITION BY FechaTRX_ACF, HoraTRX_ACF, NumeroTrx_ACF,
                                 Tarjeta_SHA256_ACF, CodigoCIO_ACF, Autorizacion_ACF, MONTOSOLES_ACF
                    ORDER BY FechaRecepcion ASC, ACF_FechaCierreCaso ASC, ACF_HoraFinCaso ASC)
            FROM DBO.PFYCC_GI_CARGA_CIERRE_ALERTAS_ROL_EMISOR WITH(NOLOCK)
            WHERE ACF_TipodeResultadoCasodeInvestigacion = '1'
              AND IndicadordeCorreccion_ACF IN ('0','2')
              AND CodRpta_ACF = '000'
              AND Reverso_ACF = 'N'
        ) x
        WHERE rn = 1
          AND FechaTrx >= '2021-01-01'
    ),

    -- -----------------------------------------------------------
    -- INVESTIGADORES (definición única, compartida ADQ y EMISOR)
    -- -----------------------------------------------------------
    Investigadores AS (
        SELECT C.Grupo, C.INVESTIGADOR, B.ACF_UsuarioInvestigador
        FROM (
            SELECT ACF_UsuarioInvestigador
            FROM (
                SELECT ACF_UsuarioInvestigador FROM DBO.PFYCC_GI_CARGA_CIERRE_ALERTAS_ROL_ADQ  WITH(NOLOCK) GROUP BY ACF_UsuarioInvestigador
                UNION ALL
                SELECT ACF_UsuarioInvestigador FROM DBO.PFYCC_GI_CARGA_CIERRE_ALERTAS_ROL_EMISOR WITH(NOLOCK) GROUP BY ACF_UsuarioInvestigador
            ) A
            GROUP BY ACF_UsuarioInvestigador
        ) B
        LEFT JOIN DBO.PFYCC_GI_CARGA_MONITOR_DIM_INVESTIGADOR C WITH(NOLOCK)
            ON B.ACF_UsuarioInvestigador = C.ACF_UsuarioInvestigador
    ),

    -- -----------------------------------------------------------
    -- TRANSACCIONAL ADQ (definición única)
    -- -----------------------------------------------------------
    Transaccional_ADQ AS (
        SELECT
            a.Tarjeta_SHA256_ACF, a.FechaTRX_ACF, a.HoraTRX_ACF,
            a.MontoLocalsoles_ACF,
            a.Autorizacion_ACF, a.CodigoCIO_ACF, a.Tarjetaregistro750_ACF,
            a.NombreCIO_ACF, MCC_ACF = LEFT(a.MCC_ACF,4),
            a.Bin_ACF, a.IDCliente_ACF, a.EntryMode_ACF,
            a.UCAF_ACF, a.Canal_ACF, a.IDComercio_ACF
        FROM DBO.TRX_YYYY_MM a  -- << reemplazar con mes(es) vigente(s)
            LEFT JOIN DBO.PFYCC_GI_DIM_MCC b ON a.MCC_ACF = b.mcc
        WHERE a.Reverso_ACF = 'N'
    ),

    -- -----------------------------------------------------------
    -- TRANSACCIONAL EMISOR (definición única)
    -- -----------------------------------------------------------
    Transaccional_EMI AS (
        SELECT
            a.Tarjeta_SHA256_ACF, a.FechaTRX_ACF, a.HoraTRX_ACF,
            a.MontoOrigTRX_ACF,
            a.Autorizacion_ACF, a.CodigoCIO_ACF, a.Tarjetaregistro750_ACF,
            a.NombreCIO_ACF, MCC_ACF = LEFT(a.MCC_ACF,4),
            a.Bin_ACF, a.IDCliente_ACF, a.EntryMode_ACF,
            a.UCAF_ACF, a.Canal_ACF, a.IDComercio_ACF
        FROM DBO.ROL_EMISOR_YYYY a  -- << reemplazar con tabla emisor vigente
            LEFT JOIN DBO.PFYCC_GI_DIM_MCC b ON a.MCC_ACF = b.mcc
        WHERE a.Reverso_ACF = 'N'
          AND a.Autorizacion_ACF <> ''
          AND a.CodRpta_ACF = '000'
    ),

    -- ===========================================================
    -- BLOQUE ADQ
    -- ===========================================================

    -- Deduplicación ADQ: filtra ventana de fecha ADQ y elige monto ADQ
    Dedup_ADQ AS (
        SELECT *,
               ROW_NUMBER() OVER (
                   PARTITION BY Fecha, Tarjeta_Encriptada, CodComercio, cod_autorizacion
                   ORDER BY CASE Accion_Tomada
                       WHEN 'F:TC40'         THEN 1
                       WHEN 'F:Safe'         THEN 2
                       WHEN 'F:Asbanc'       THEN 3
                       WHEN 'F:Contracargos' THEN 4
                       ELSE 5 END) AS rn
        FROM Fuentes_ALL
        WHERE Fecha_Carga BETWEEN @adq_fecha2 AND @adq_fecha1
    ),

    -- Cruce ADQ vs alertas → determina RESULTADOFINAL
    Cruce_ADQ AS (
        SELECT
            f.Tarjeta_Encriptada, f.sufix, f.Fecha, f.CodComercio, f.bin,
            f.cod_autorizacion, f.Accion_Tomada, f.Tipo_Fraude_Marcado,
            Importe_Fraude_Soles    = f.Monto_ADQ,
            f.Fecha_Carga,
            RESULTADOFINAL          = CASE WHEN a.CodAutorizacion IS NULL THEN 0 ELSE 1 END,
            a.ACF_SubtipoResultadoCasodeInvestigacion,
            a.ACF_TextoSubTipodeResultado,
            a.FechaRecepcion,
            a.ACF_UsuarioInvestigador,
            a.ACF_TextoAccionTomada
        FROM Dedup_ADQ f
        LEFT JOIN Alertas_ADQ a
            ON  f.bin         = a.BIN
            AND f.CodComercio = a.CodComercio
            AND f.cod_autorizacion = a.CodAutorizacion
            AND (
                (LEFT(f.Tarjeta_Encriptada,2)='37' AND RIGHT(f.sufix,3)=RIGHT(a.Tarjetaregistro750_ACF,3))
                OR (LEFT(f.Tarjeta_Encriptada,2)='36' AND RIGHT(f.sufix,2)=RIGHT(a.Tarjetaregistro750_ACF,2))
                OR (LEFT(f.Tarjeta_Encriptada,2) NOT IN ('37','36') AND RIGHT(f.sufix,4)=RIGHT(a.Tarjetaregistro750_ACF,4))
            )
        WHERE f.rn = 1
    ),

    -- estado_fraude A: Marcado Alerta ADQ
    Alerta_ADQ AS (
        SELECT DISTINCT
            Fecha = Fecha,
            Tarjeta_Encriptada = CASE
                WHEN LEFT(Tarjeta_Encriptada,2)='37' THEN LEFT(Tarjeta_Encriptada,6)+'XXXXXX'+RIGHT(Tarjeta_Encriptada,3)
                WHEN LEFT(Tarjeta_Encriptada,2)='36' THEN LEFT(Tarjeta_Encriptada,6)+'XXXXXX'+RIGHT(Tarjeta_Encriptada,2)
                ELSE LEFT(Tarjeta_Encriptada,6)+'XXXXXX'+RIGHT(Tarjeta_Encriptada,4) END,
            CodComercio, cod_autorizacion,
            mto_fraude_soles  = CONVERT(DECIMAL(18,2), Importe_Fraude_Soles),
            nom_comercio       = NULL,  -- no viene de fuente en este estado
            Accion_Tomada, Tipo_Fraude_Marcado, Fecha_Carga,
            estado_fraude              = 'Filtro: Marcado Alerta',
            Entidad             = 'ADQ'
        FROM Cruce_ADQ
        WHERE RESULTADOFINAL = 1
    ),

    -- Staging ADQ: fraudes sin alerta, con enriquecimiento de segmento e investigador
    Staging_ADQ AS (
        SELECT DISTINCT
            f.Tarjeta_Encriptada, f.sufix, f.Fecha, f.CodComercio, f.bin,
            f.cod_autorizacion, f.Accion_Tomada, f.Tipo_Fraude_Marcado,
            mto_fraude_soles  = CONVERT(DECIMAL(18,2), f.Importe_Fraude_Soles),
            f.Fecha_Carga,
            inv.INVESTIGADOR, inv.Grupo,
            seg.SEGMENTO,
            flag_carga = CASE
                WHEN f.Fecha_Carga >= '2022-05-25' AND seg.segmento IN ('Empresa','Negocio') THEN 1
                WHEN f.Fecha_Carga >= '2022-05-25' AND seg.segmento NOT IN ('Empresa','Negocio')
                     AND CONVERT(DECIMAL(18,2), f.Importe_Fraude_Soles) >= 150 THEN 1
                WHEN f.Fecha_Carga < '2022-05-25' THEN 1
                ELSE 0 END
        FROM Cruce_ADQ f
        LEFT JOIN Investigadores inv  ON f.ACF_UsuarioInvestigador = inv.ACF_UsuarioInvestigador
        LEFT JOIN DBO.PFYCC_GI_TRANS_MCESTAB seg WITH(NOLOCK) ON f.CodComercio = seg.codigo
        WHERE f.RESULTADOFINAL = 0
          AND f.cod_autorizacion   <> '000000'
          AND f.nom_comercio  NOT LIKE '%iata%'
          AND f.nom_comercio  NOT LIKE '%tc33%'
    ),

    -- estado_fraude B: Enviado ADQ (cruce exitoso con transaccional)
    Enviado_ADQ AS (
        SELECT DISTINCT
            Fecha               = t.FechaTRX_ACF,
            Tarjeta_Encriptada  = t.Tarjetaregistro750_ACF,
            CodComercio         = RIGHT(t.CodigoCIO_ACF,7),
            cod_autorizacion        = t.Autorizacion_ACF,
            mto_fraude_soles  = CONVERT(NUMERIC(14,2), t.MontoLocalsoles_ACF),
            nom_comercio       = f.nom_comercio,  -- viene del join, campo no existe en Staging; ver nota (*)
            Accion_Tomada       = f.Accion_Tomada,
            Tipo_Fraude_Marcado = f.Tipo_Fraude_Marcado,
            Fecha_Carga         = f.Fecha_Carga,
            estado_fraude              = 'Enviado',
            Entidad             = 'ADQ',
            -- Columnas transaccionales para EXTERNOS
            tarjeta_sha256_trx      = t.Tarjeta_SHA256_ACF,
            hora_trx             = t.HoraTRX_ACF,
            mto_trx            = CONVERT(NUMERIC(14,2), t.MontoLocalsoles_ACF),
            codigo_cio_trx           = t.CodigoCIO_ACF,
            nom_cio_trx           = t.NombreCIO_ACF,
            cod_giro_comercio_trx                 = t.MCC_ACF,
            bin_trx                 = t.Bin_ACF,
            id_cliente_trx           = t.IDCliente_ACF,
            entry_mode_trx           = t.EntryMode_ACF,
            ucaf_trx                = t.UCAF_ACF,
            canal_trx               = t.Canal_ACF,
            id_comercio_trx          = t.IDComercio_ACF,
            tarjetaregistro750_trx  = t.Tarjetaregistro750_ACF
        FROM Staging_ADQ f
        INNER JOIN Transaccional_ADQ t
            ON  f.Fecha        = t.FechaTRX_ACF
            AND f.CodComercio  = RIGHT(t.CodigoCIO_ACF,7)
            AND f.cod_autorizacion = t.Autorizacion_ACF
            AND f.bin          = t.Bin_ACF
            AND (
                (LEFT(f.Tarjeta_Encriptada,2)='37' AND LEFT(f.Tarjeta_Encriptada,6)+'XXXXXX'+RIGHT(f.Tarjeta_Encriptada,3) = t.Tarjetaregistro750_ACF)
                OR (LEFT(f.Tarjeta_Encriptada,2)='36' AND LEFT(f.Tarjeta_Encriptada,6)+'XXXXXX'+RIGHT(f.Tarjeta_Encriptada,2) = t.Tarjetaregistro750_ACF)
                OR (LEFT(f.Tarjeta_Encriptada,2) NOT IN ('37','36') AND LEFT(f.Tarjeta_Encriptada,6)+'XXXXXX'+RIGHT(f.Tarjeta_Encriptada,4) = t.Tarjetaregistro750_ACF)
            )
    ),

    -- estado_fraude C: Filtro Cruce Transaccional ADQ (sin match transaccional)
    Filtro_ADQ AS (
        SELECT DISTINCT
            f.Fecha,
            Tarjeta_Encriptada = CASE
                WHEN LEFT(f.Tarjeta_Encriptada,2)='37' THEN LEFT(f.Tarjeta_Encriptada,6)+'XXXXXX'+RIGHT(f.Tarjeta_Encriptada,3)
                WHEN LEFT(f.Tarjeta_Encriptada,2)='36' THEN LEFT(f.Tarjeta_Encriptada,6)+'XXXXXX'+RIGHT(f.Tarjeta_Encriptada,2)
                ELSE LEFT(f.Tarjeta_Encriptada,6)+'XXXXXX'+RIGHT(f.Tarjeta_Encriptada,4) END,
            f.CodComercio, f.cod_autorizacion, f.mto_fraude_soles,
            nom_comercio       = f.nom_comercio,
            f.Accion_Tomada, f.Tipo_Fraude_Marcado, f.Fecha_Carga,
            estado_fraude              = 'Filtro: Cruce Transaccional',
            Entidad             = 'ADQ'
        FROM Staging_ADQ f
        LEFT JOIN Transaccional_ADQ t
            ON  f.Fecha        = t.FechaTRX_ACF
            AND f.CodComercio  = RIGHT(t.CodigoCIO_ACF,7)
            AND f.cod_autorizacion = t.Autorizacion_ACF
            AND f.bin          = t.Bin_ACF
            AND (
                (LEFT(f.Tarjeta_Encriptada,2)='37' AND LEFT(f.Tarjeta_Encriptada,6)+'XXXXXX'+RIGHT(f.Tarjeta_Encriptada,3) = t.Tarjetaregistro750_ACF)
                OR (LEFT(f.Tarjeta_Encriptada,2)='36' AND LEFT(f.Tarjeta_Encriptada,6)+'XXXXXX'+RIGHT(f.Tarjeta_Encriptada,2) = t.Tarjetaregistro750_ACF)
                OR (LEFT(f.Tarjeta_Encriptada,2) NOT IN ('37','36') AND LEFT(f.Tarjeta_Encriptada,6)+'XXXXXX'+RIGHT(f.Tarjeta_Encriptada,4) = t.Tarjetaregistro750_ACF)
            )
        WHERE t.Autorizacion_ACF IS NULL
          AND f.cod_autorizacion <> ''
    ),

    -- estado_fraude D: Segundo Reproceso Enviado ADQ (derivado de Filtro_ADQ, sin releer la tabla)
    Reproceso_Enviado_ADQ AS (
        SELECT DISTINCT
            Fecha               = t.FechaTRX_ACF,
            Tarjeta_Encriptada  = t.Tarjetaregistro750_ACF,
            CodComercio         = RIGHT(t.CodigoCIO_ACF,7),
            cod_autorizacion        = f.cod_autorizacion,
            mto_fraude_soles  = CONVERT(NUMERIC(14,2), t.MontoLocalsoles_ACF),
            nom_comercio       = f.nom_comercio,
            Accion_Tomada       = f.Accion_Tomada,
            Tipo_Fraude_Marcado = f.Tipo_Fraude_Marcado,
            Fecha_Carga         = f.Fecha_Carga,
            estado_fraude              = 'Segundo_Reproceso_Enviado',
            Entidad             = 'ADQ',
            tarjeta_sha256_trx      = t.Tarjeta_SHA256_ACF,
            hora_trx             = t.HoraTRX_ACF,
            mto_trx            = CONVERT(NUMERIC(14,2), t.MontoLocalsoles_ACF),
            codigo_cio_trx           = t.CodigoCIO_ACF,
            nom_cio_trx           = t.NombreCIO_ACF,
            cod_giro_comercio_trx                 = t.MCC_ACF,
            bin_trx                 = t.Bin_ACF,
            id_cliente_trx           = t.IDCliente_ACF,
            entry_mode_trx           = t.EntryMode_ACF,
            ucaf_trx                = t.UCAF_ACF,
            canal_trx               = t.Canal_ACF,
            id_comercio_trx          = t.IDComercio_ACF,
            tarjetaregistro750_trx  = t.Tarjetaregistro750_ACF
        FROM Filtro_ADQ f
        INNER JOIN Transaccional_ADQ t
            ON  f.Fecha        = t.FechaTRX_ACF
            AND f.CodComercio  = RIGHT(t.CodigoCIO_ACF,7)
            AND f.cod_autorizacion = t.Autorizacion_ACF
    ),

    -- estado_fraude E: Segundo Reproceso Filtro ADQ (sigue sin cruzar)
    Reproceso_Filtro_ADQ AS (
        SELECT DISTINCT
            f.Fecha, f.Tarjeta_Encriptada, f.CodComercio, f.cod_autorizacion,
            f.mto_fraude_soles, f.nom_comercio,
            f.Accion_Tomada, f.Tipo_Fraude_Marcado, f.Fecha_Carga,
            estado_fraude  = 'Segundo_Reproceso_Filtro: Cruce Transaccional',
            Entidad = 'ADQ'
        FROM Filtro_ADQ f
        WHERE NOT EXISTS (
            SELECT 1
            FROM Transaccional_ADQ t
            WHERE f.Fecha        = t.FechaTRX_ACF
              AND f.CodComercio  = RIGHT(t.CodigoCIO_ACF,7)
              AND f.cod_autorizacion = t.Autorizacion_ACF
        )
    ),

    -- ===========================================================
    -- BLOQUE EMISOR
    -- ===========================================================

    -- Deduplicación EMISOR: filtra ventana 14 días, monto EMI y BINs propios
    Dedup_EMI AS (
        SELECT *,
               ROW_NUMBER() OVER (
                   PARTITION BY Fecha, Tarjeta_Encriptada, CodComercio, cod_autorizacion
                   ORDER BY CASE Accion_Tomada
                       WHEN 'F:TC40'         THEN 1
                       WHEN 'F:Safe'         THEN 2
                       WHEN 'F:Asbanc'       THEN 3
                       WHEN 'F:Contracargos' THEN 4
                       ELSE 5 END) AS rn
        FROM Fuentes_ALL
        WHERE Fecha_Carga BETWEEN @emi_fecha2 AND @emi_fecha1
          AND bin IN (
              '521628','522772','545028','449577','475796','477151','489068',
              '512533','529206','550218','905050','546342','231000','231020',
              '233063','234057','234058','400657','486352','486353','483105'
          )
    ),

    -- Cruce EMISOR vs alertas → determina RESULTADOFINAL
    Cruce_EMI AS (
        SELECT
            f.Tarjeta_Encriptada, f.sufix, f.Fecha, f.CodComercio, f.bin,
            f.cod_autorizacion, f.Accion_Tomada, f.Tipo_Fraude_Marcado,
            Importe_Fraude_Soles    = f.Monto_EMI,
            f.Fecha_Carga,
            RESULTADOFINAL          = CASE WHEN a.CodAutorizacion IS NULL THEN 0 ELSE 1 END,
            a.ACF_SubtipoResultadoCasodeInvestigacion,
            a.ACF_TextoSubTipodeResultado,
            a.FechaRecepcion,
            a.ACF_UsuarioInvestigador,
            a.ACF_TextoAccionTomada
        FROM Dedup_EMI f
        LEFT JOIN Alertas_EMI a
            ON  f.bin         = a.BIN
            AND f.CodComercio = a.CodComercio
            AND RIGHT(f.sufix,4) = RIGHT(a.Tarjetaregistro750_ACF,4)
            AND f.cod_autorizacion = a.CodAutorizacion
        WHERE f.rn = 1
    ),

    -- estado_fraude F: Marcado Alerta EMISOR
    Alerta_EMI AS (
        SELECT DISTINCT
            Fecha               = Fecha,
            Tarjeta_Encriptada  = LEFT(Tarjeta_Encriptada,6)+'XXXXXX'+RIGHT(Tarjeta_Encriptada,4),
            CodComercio, cod_autorizacion,
            mto_fraude_soles  = CONVERT(DECIMAL(18,2), Importe_Fraude_Soles),
            nom_comercio       = NULL,
            Accion_Tomada, Tipo_Fraude_Marcado, Fecha_Carga,
            estado_fraude              = 'Filtro: Marcado Alerta',
            Entidad             = 'EMISOR'
        FROM Cruce_EMI
        WHERE RESULTADOFINAL = 1
    ),

    -- Staging EMISOR: fraudes sin alerta con enriquecimiento
    Staging_EMI AS (
        SELECT DISTINCT
            f.Tarjeta_Encriptada, f.sufix, f.Fecha, f.CodComercio, f.bin,
            f.cod_autorizacion, f.Accion_Tomada, f.Tipo_Fraude_Marcado,
            mto_fraude_soles  = CONVERT(DECIMAL(18,2), f.Importe_Fraude_Soles),
            f.Fecha_Carga,
            inv.INVESTIGADOR, inv.Grupo,
            seg.SEGMENTO,
            flag_carga = CASE
                WHEN f.Fecha_Carga >= '2022-05-25' AND seg.segmento IN ('Empresa','Negocio') THEN 1
                WHEN f.Fecha_Carga >= '2022-05-25' AND seg.segmento NOT IN ('Empresa','Negocio')
                     AND CONVERT(DECIMAL(18,2), f.Importe_Fraude_Soles) >= 150 THEN 1
                WHEN f.Fecha_Carga < '2022-05-25' THEN 1
                ELSE 0 END
        FROM Cruce_EMI f
        LEFT JOIN Investigadores inv  ON f.ACF_UsuarioInvestigador = inv.ACF_UsuarioInvestigador
        LEFT JOIN DBO.PFYCC_GI_TRANS_MCESTAB seg WITH(NOLOCK) ON f.CodComercio = seg.codigo
        WHERE f.RESULTADOFINAL = 0
          AND f.cod_autorizacion   <> '000000'
          AND f.nom_comercio  NOT LIKE '%iata%'
          AND f.nom_comercio  NOT LIKE '%tc33%'
          AND f.Fecha_Carga    >= '2023-07-01'
    ),

    -- estado_fraude G: Enviado EMISOR (cruce exitoso con transaccional emisor)
    Enviado_EMI AS (
        SELECT DISTINCT
            Fecha               = t.FechaTRX_ACF,
            Tarjeta_Encriptada  = t.Tarjetaregistro750_ACF,
            CodComercio         = RIGHT(t.CodigoCIO_ACF,7),
            cod_autorizacion        = t.Autorizacion_ACF,
            mto_fraude_soles  = CONVERT(NUMERIC(14,2), t.MontoOrigTRX_ACF),
            nom_comercio       = f.nom_comercio,
            Accion_Tomada       = NULL,   -- Emisor no devuelve acción tomada
            Tipo_Fraude_Marcado = f.Tipo_Fraude_Marcado,
            Fecha_Carga         = f.Fecha_Carga,
            estado_fraude              = 'Enviado',
            Entidad             = 'EMISOR',
            tarjeta_sha256_trx      = t.Tarjeta_SHA256_ACF,
            hora_trx             = t.HoraTRX_ACF,
            mto_trx            = CONVERT(NUMERIC(14,2), t.MontoOrigTRX_ACF),
            codigo_cio_trx           = t.CodigoCIO_ACF,
            nom_cio_trx           = t.NombreCIO_ACF,
            cod_giro_comercio_trx                 = t.MCC_ACF,
            bin_trx                 = t.Bin_ACF,
            id_cliente_trx           = t.IDCliente_ACF,
            entry_mode_trx           = t.EntryMode_ACF,
            ucaf_trx                = t.UCAF_ACF,
            canal_trx               = t.Canal_ACF,
            id_comercio_trx          = t.IDComercio_ACF,
            tarjetaregistro750_trx  = t.Tarjetaregistro750_ACF
        FROM Staging_EMI f
        INNER JOIN Transaccional_EMI t
            ON  f.Fecha        = t.FechaTRX_ACF
            AND f.CodComercio  = RIGHT(t.CodigoCIO_ACF,7)
            AND f.cod_autorizacion = t.Autorizacion_ACF
            AND f.bin          = t.Bin_ACF
            AND LEFT(f.Tarjeta_Encriptada,6)+'XXXXXX'+RIGHT(f.Tarjeta_Encriptada,4) = t.Tarjetaregistro750_ACF
    ),

    -- estado_fraude H: Filtro Cruce Transaccional EMISOR
    Filtro_EMI AS (
        SELECT DISTINCT
            f.Fecha,
            Tarjeta_Encriptada  = LEFT(f.Tarjeta_Encriptada,6)+'XXXXXX'+RIGHT(f.Tarjeta_Encriptada,4),
            f.CodComercio, f.cod_autorizacion, f.mto_fraude_soles,
            nom_comercio       = f.nom_comercio,
            f.Accion_Tomada, f.Tipo_Fraude_Marcado, f.Fecha_Carga,
            estado_fraude              = 'Filtro: Cruce Transaccional',
            Entidad             = 'EMISOR'
        FROM Staging_EMI f
        LEFT JOIN Transaccional_EMI t
            ON  f.Fecha        = t.FechaTRX_ACF
            AND f.CodComercio  = RIGHT(t.CodigoCIO_ACF,7)
            AND f.cod_autorizacion = t.Autorizacion_ACF
            AND f.bin          = t.Bin_ACF
            AND LEFT(f.Tarjeta_Encriptada,6)+'XXXXXX'+RIGHT(f.Tarjeta_Encriptada,4) = t.Tarjetaregistro750_ACF
        WHERE t.Autorizacion_ACF IS NULL
    )

    -- ===========================================================
    -- ÚNICO INSERT: todos los estados con UNION ALL
    -- Columnas transaccionales en NULL para estados sin transacción
    -- ===========================================================
    INSERT INTO DBO.RT_GD_STATUS_CONSOLIDADO_FRAUDES
        (Fecha, Tarjeta_Encriptada, CodComercio, cod_autorizacion, mto_fraude_soles,
         nom_comercio, Accion_Tomada, Tipo_Fraude_Marcado, Fecha_Carga,
         estado_fraude, Fecha_Envio, Entidad,
         tarjeta_sha256_trx, hora_trx, mto_trx, codigo_cio_trx, nom_cio_trx,
         cod_giro_comercio_trx, bin_trx, id_cliente_trx, entry_mode_trx, ucaf_trx, canal_trx,
         id_comercio_trx, tarjetaregistro750_trx)

    -- A: Filtro: Marcado Alerta — ADQ
    SELECT Fecha, Tarjeta_Encriptada, CodComercio, cod_autorizacion, mto_fraude_soles,
           nom_comercio, Accion_Tomada, Tipo_Fraude_Marcado, Fecha_Carga,
           estado_fraude, @hoy, Entidad,
           NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL
    FROM Alerta_ADQ

    UNION ALL

    -- B: Enviado — ADQ (con columnas transaccionales)
    SELECT Fecha, Tarjeta_Encriptada, CodComercio, cod_autorizacion, mto_fraude_soles,
           nom_comercio, Accion_Tomada, Tipo_Fraude_Marcado, Fecha_Carga,
           estado_fraude, @hoy, Entidad,
           tarjeta_sha256_trx, hora_trx, mto_trx, codigo_cio_trx, nom_cio_trx,
           cod_giro_comercio_trx, bin_trx, id_cliente_trx, entry_mode_trx, ucaf_trx, canal_trx,
           id_comercio_trx, tarjetaregistro750_trx
    FROM Enviado_ADQ

    UNION ALL

    -- C: Filtro: Cruce Transaccional — ADQ
    SELECT Fecha, Tarjeta_Encriptada, CodComercio, cod_autorizacion, mto_fraude_soles,
           nom_comercio, Accion_Tomada, Tipo_Fraude_Marcado, Fecha_Carga,
           estado_fraude, @hoy, Entidad,
           NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL
    FROM Filtro_ADQ

    UNION ALL

    -- D: Segundo_Reproceso_Enviado — ADQ (con columnas transaccionales)
    SELECT Fecha, Tarjeta_Encriptada, CodComercio, cod_autorizacion, mto_fraude_soles,
           nom_comercio, Accion_Tomada, Tipo_Fraude_Marcado, Fecha_Carga,
           estado_fraude, @hoy, Entidad,
           tarjeta_sha256_trx, hora_trx, mto_trx, codigo_cio_trx, nom_cio_trx,
           cod_giro_comercio_trx, bin_trx, id_cliente_trx, entry_mode_trx, ucaf_trx, canal_trx,
           id_comercio_trx, tarjetaregistro750_trx
    FROM Reproceso_Enviado_ADQ

    UNION ALL

    -- E: Segundo_Reproceso_Filtro — ADQ
    SELECT Fecha, Tarjeta_Encriptada, CodComercio, cod_autorizacion, mto_fraude_soles,
           nom_comercio, Accion_Tomada, Tipo_Fraude_Marcado, Fecha_Carga,
           estado_fraude, @hoy, Entidad,
           NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL
    FROM Reproceso_Filtro_ADQ

    UNION ALL

    -- F: Filtro: Marcado Alerta — EMISOR
    SELECT Fecha, Tarjeta_Encriptada, CodComercio, cod_autorizacion, mto_fraude_soles,
           nom_comercio, Accion_Tomada, Tipo_Fraude_Marcado, Fecha_Carga,
           estado_fraude, @hoy, Entidad,
           NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL
    FROM Alerta_EMI

    UNION ALL

    -- G: Enviado — EMISOR (con columnas transaccionales)
    SELECT Fecha, Tarjeta_Encriptada, CodComercio, cod_autorizacion, mto_fraude_soles,
           nom_comercio, Accion_Tomada, Tipo_Fraude_Marcado, Fecha_Carga,
           estado_fraude, @hoy, Entidad,
           tarjeta_sha256_trx, hora_trx, mto_trx, codigo_cio_trx, nom_cio_trx,
           cod_giro_comercio_trx, bin_trx, id_cliente_trx, entry_mode_trx, ucaf_trx, canal_trx,
           id_comercio_trx, tarjetaregistro750_trx
    FROM Enviado_EMI

    UNION ALL

    -- H: Filtro: Cruce Transaccional — EMISOR
    SELECT Fecha, Tarjeta_Encriptada, CodComercio, cod_autorizacion, mto_fraude_soles,
           nom_comercio, Accion_Tomada, Tipo_Fraude_Marcado, Fecha_Carga,
           estado_fraude, @hoy, Entidad,
           NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL
    FROM Filtro_EMI;

END
GO
