-- ============================================================
-- PROCEDURE: master_risk.sp_carga_m_consolidacion_fraudes
--
-- Mapeo tablas SQL → BigQuery:
--   PFYCC_GI_CARGA_ASBANC_TANSFORMADA_2      → master_risk.t_alerta_fraude_asbanc
--   PFYCC_GI_CARGA_TC40_TANSFORMADA           → master_risk.m_fraude_liquidacion
--   PFYCC_GI_REPORTE_RPA_LINEA                → bi_riesgo.dv_consolidacion_contracargo
--   PFYCC_GI_CARGA_CIERRE_ALERTAS_ROL_ADQ     → master_risk.t_alerta_adq_monitor
--   PFYCC_GI_CARGA_CIERRE_ALERTAS_ROL_EMISOR  → master_risk.t_alerta_emisor_monitor
--   TRX_YYYY_MM                               → master_risk.t_monitor_adquirente
--   ROL_EMISOR_YYYY                           → master_risk.t_trx_emisor_monitor
--   PFYCC_GI_CARGA_MONITOR_DIM_INVESTIGADOR   → master_risk.t_fraude_dim_investigador
--   PFYCC_GI_TRANS_MCESTAB                    → master_party.m_comercio
--
-- Destino: master_risk.m_consolidacion_fraudes
--
-- Columnas de auditoría:
--   process_date  → CURRENT_DATE()
--   record_source → 'FRAUDES REPORTADOS+ALERTAS ADQ' | '...EMISOR'
--   load_date     → CURRENT_DATETIME('America/Lima')
--   creation_user → SESSION_USER()
--
-- Reglas transformación SELECT final:
--   STRING  → NULLIF(TRIM(UPPER(campo)), '')
--   fecha*  → CAST(... AS DATE)
--   mto*    → CAST(... AS FLOAT64)
-- ============================================================

CREATE OR REPLACE PROCEDURE `master_risk.sp_carga_m_consolidacion_fraudes`()
BEGIN

  -- ===========================================================
  -- VARIABLES DE FECHA
  -- ===========================================================
  DECLARE adq_fecha1 DATE DEFAULT DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY);
  DECLARE adq_fecha2 DATE;

  -- Si hoy es lunes (DAYOFWEEK=2) el rango retrocede al viernes
  IF EXTRACT(DAYOFWEEK FROM CURRENT_DATE()) = 2 THEN
    SET adq_fecha2 = DATE_SUB(CURRENT_DATE(), INTERVAL 3 DAY);
  ELSE
    SET adq_fecha2 = adq_fecha1;
  END IF;

  DECLARE emi_fecha1 DATE DEFAULT CURRENT_DATE();
  DECLARE emi_fecha2 DATE DEFAULT DATE_SUB(CURRENT_DATE(), INTERVAL 14 DAY);

  -- ===========================================================
  -- Trunca tabla de última foto
  -- ===========================================================
  truncate table `master_risk.m_consolidacion_fraudes`;

  -- ===========================================================
  -- INSERT principal
  -- ===========================================================
  INSERT INTO `master_risk.m_consolidacion_fraudes`
  (
    process_date
	,fecha_trx
	,tarjeta_encriptada
	,cod_comercio
	,cod_respuesta
    ,cod_autorizacion
	,mto_fraude_soles
	,nom_comercio
	,accion_tomada
    ,tipo_fraude_marcado
	,fecha_carga
	,estado_fraude
	,fecha_envio
    ,nom_entidad
	,proceso
    ,tarjeta_sha256_trx
	,hora_trx
	,mto_trx
	,codigo_cio_trx
    ,nom_cio_trx
	,cod_giro_comercio_trx
	,bin_trx
	,id_cliente_trx
    ,entry_mode_trx
	,ucaf_trx
	,canal_trx
	,id_comercio_trx
    ,tarjetaregistro750_trx
    ,record_source
	,load_date
	,creation_user
  )

  WITH

  -- -----------------------------------------------------------
  -- FUENTE ÚNICA: Asbanc + TC40 + Contracargos
  --
  -- IMPORTANTE: todos los nombres de columna dentro de cada SELECT
  -- corresponden a los nombres BQ de cada tabla fuente,
  -- según el Excel de homologación SQL↔BigQuery.
  -- -----------------------------------------------------------
  Fuentes_ALL AS (

    -- ── ASBANC ───────────────────────────────────────────────
    -- Tabla BQ  : master_risk.t_alerta_fraude_asbanc
    -- Columnas BQ usadas (← nombre SQL original):
    --   process_date      ← fecha_carga
    --   fecha_trx         ← fecha_trx
    --   tarjeta_encriptada← tarjeta_encriptada
    --   bin               ← bin
    --   cod_comercio      ← cod_comercio
    --   mto_sol           ← monto_soles
    --   mto_venta_dolar   ← importe_dolares
    --   nom_comercio      ← nombre_del_comercio
    --   cod_autorizacion  ← autorizacion
    --   cod_rpta_trx      ← cod_rpta
    SELECT DISTINCT
      process_date                                                   AS fecha_carga,
      fecha_trx                                                      AS fecha,
      tarjeta_encriptada,
      RIGHT(tarjeta_encriptada,4)                                    AS sufix,
      CASE
        WHEN SUBSTR(cod_comercio,1,2) = '00'    THEN SUBSTR(cod_comercio,3,7)
        WHEN RIGHT(cod_comercio,5)    = '00000' THEN SUBSTR(cod_comercio,1,7)
        ELSE RIGHT(cod_comercio,7)
      END                                                            AS cod_comercio,
      bin,
      CASE
        WHEN cod_rpta_trx <> '00' THEN null
        WHEN NOT (
          mto_venta_dolar IS NOT NULL
          AND TRIM(cod_autorizacion) <> ''
          AND LPAD(TRIM(cod_autorizacion),6,'0') NOT LIKE '%000000%'
        ) THEN null
        ELSE LPAD(TRIM(cod_autorizacion),6,'0')
      END                                                            AS cod_autorizacion,
      mto_sol				                	                     AS monto_adq,
      mto_venta_dolar       				                         AS monto_emi,
      nom_comercio                                                   AS merchant_name,
      'F:ASBANC'                                                     AS accion_tomada,
      'REPORTADO X ASBANC'                                           AS tipo_fraude_marcado,
      'ASBANC'                                                       AS fuente
    FROM `master_risk.t_alerta_fraude_asbanc`
    WHERE process_date IS NOT NULL
      AND process_date BETWEEN emi_fecha2 AND emi_fecha1

    UNION ALL

    -- ── TC40 ─────────────────────────────────────────────────
    -- Tabla BQ  : master_risk.m_fraude_liquidacion
    -- Columnas BQ usadas (← nombre SQL original):
    --   fecha_alerta_fraude ← fecha_carga
    --   fecha_trx           ← fecha_transaccion
    --   pvc_id              ← tarjeta_encriptada
    --   cuarteto            ← sufix
    --   cod_comercio        ← establecimiento
    --   bin_6               ← bin
    --   cod_autorizacion    ← autorizacion
    --   mto_venta           ← importe
    --   nom_comercio        ← nombre_comercio
    --   record_source       ← fuente
    --   cod_tipo_fraude     ← tipo_fraude
    SELECT 
      fecha_alerta_fraude                                            AS fecha_carga,
      fecha_trx                                                      AS fecha,
      CONCAT(bin_6,'XXXXXX',cuarteto)                               AS tarjeta_encriptada,
      cuarteto                                                       AS sufix,
      cod_comercio,
      bin_6                                                          AS bin,
      LPAD(TRIM(cod_autorizacion),6,'0')                            AS cod_autorizacion,
      mto_venta                                                     AS monto_adq,
      mto_venta                                                    AS monto_emi,
      nom_comercio                                                   AS merchant_name,
      record_source                                                  AS accion_tomada,
      CASE cod_tipo_fraude
        WHEN '6' THEN 'F: TARJETA NO PRESENTE  MOTO-INTERNET'
        WHEN '4' THEN 'F: FALSIFICACION/ CLONACION'
        WHEN '1' THEN 'F: TARJETA ROBADA'
        WHEN '5' THEN 'MISCELLANEOUS'
        WHEN '0' THEN 'F: TARJETA PERDIDA'
        WHEN '2' THEN 'F: TARJETA NUNCA RECIBIDA DEL EMISOR'
        WHEN '3' THEN 'F: FRAUD APP'
        WHEN 'D' THEN 'MANIPULATION OF ACCOUNT HOLDER-MANIPULACIÓN DEL TITULAR DE LA CUENTA'
        WHEN 'A' THEN 'INCORRECT PROCESSING -PROCESAMIENTO INCORRECTO'
        WHEN 'B' THEN 'ACCOUNT OR CREDENTIALS TAKEOVER -ADQUISICIÓN DE CUENTAS O CREDENCIALES'
        ELSE cod_tipo_fraude
      END                                                            AS tipo_fraude_marcado,
      'TC40'                                                         AS fuente
    FROM `master_risk.m_fraude_liquidacion`
    WHERE fecha_alerta_fraude BETWEEN emi_fecha2 AND emi_fecha1

    UNION ALL

    -- ── CONTRACARGOS ─────────────────────────────────────────
    -- Tabla BQ  : bi_riesgo.dv_consolidacion_contracargo
    -- Columnas BQ usadas (← nombre SQL original):
    --   fecha_contracargo          ← FechaCC
    --   fecha_trx                  ← FechaTrx
    --   pvc_id                     ← Tarjeta
    --   bin_6                      ← BIN
    --   cod_comercio               ← CodComercio
    --   nom_comercio               ← NomComercio
    --   cod_autorizacion           ← CodAutorizacion
    --   mto_contracargo_pen        ← ImporteSoles
    --   categoria_motivo_contracargo ← CategoriaCC
    SELECT DISTINCT
      fecha_contracargo                                              AS fecha_carga,
      fecha_trx                                                      AS fecha,
      CONCAT(bin_6,'XXXXXX',cuarteto)           AS tarjeta_encriptada,
      cuarteto                                                AS sufix,
      RIGHT(cod_comercio,7)                                          AS cod_comercio,
      bin_6                                                          AS bin,
      LPAD(TRIM(cod_autorizacion),6,'0')                            AS cod_autorizacion,
      mto_contracargo_pen				                            AS monto_adq,
      mto_contracargo_pen               				              AS monto_emi,
      nom_comercio                                                   AS merchant_name,
      'F:CONTRACARGOS'                                               AS accion_tomada,
      'REPORTADO X CONTRACARGOS'                                     AS tipo_fraude_marcado,
      'CONTRACARGOS'                                                 AS fuente
    FROM `bi_riesgo.dv_consolidacion_contracargo`
    WHERE fecha_contracargo BETWEEN emi_fecha2 AND emi_fecha1
      AND categoria_motivo_contracargo = 'FRAUDE'
  ),

  -- -----------------------------------------------------------
  -- ALERTAS ADQ
  -- Tabla BQ: master_risk.t_alerta_adq_monitor
  -- Todos los nombres ya son BQ (la tabla SQL se llamaba igual
  -- que los campos BQ en este caso, verificado en homologación).
  -- Columnas BQ clave:
  --   tipo_result_investigacion, ind_correccion_aplicada,
  --   cod_respuesta_trx, ind_trx_reversada,
  --   fecha_trx, hora_trx, num_trx,
  --   cod_autorizacion_trx, mto_trx_sol,
  --   fecha_recepcion, fecha_cierre_caso, hora_fin_investigacion,
  --   bin, cod_institucion_financiera, num_tarjeta_formato,
  --   subtipo_result, desc_subtipo_result,
  --   usuario_investigador, desc_accion_investigacion
  -- -----------------------------------------------------------
  Alertas_ADQ AS (
    SELECT *
    FROM (
      SELECT
        CAST(fecha_trx AS DATE)                                      AS fecha_trx,
        bin,
        RIGHT(cod_institucion_financiera,7)                          AS cod_comercio,
        LPAD(TRIM(cod_autorizacion_trx),6,'0')                      AS cod_autorizacion,
        num_tarjeta_formato                                          AS tarjetaregistro750,
        subtipo_result,
        upper(trim(desc_subtipo_result)),
        fecha_recepcion                                AS fecha_recepcion,
        usuario_investigador,
        upper(trim(desc_accion_investigacion)),
        ROW_NUMBER() OVER (
          PARTITION BY fecha_trx, hora_trx, num_trx,
                       cod_autorizacion_trx
          ORDER BY fecha_recepcion ASC, fecha_cierre_caso ASC,
                   hora_fin_investigacion ASC
        ) AS rn
      FROM `master_risk.t_alerta_adq_monitor`
      WHERE process_date >= date_add(current_date("America/Lima"),interval -6 month)
	    AND tipo_result_investigacion = '1'
        AND ind_correccion_aplicada IN ('0','2')
        AND cod_respuesta_trx = '000'
        AND ind_trx_reversada = 'N'
        AND fecha_trx IS NOT NULL
    )
    WHERE rn = 1
  ),

  -- -----------------------------------------------------------
  -- ALERTAS EMISOR
  -- Tabla BQ: master_risk.t_alerta_emisor_monitor
  -- Columnas BQ usadas (← nombre SQL original):
  --   tipo_resultado_obtenido      ← ACF_TipodeResultadoCasodeInvestigacion
  --   indicador_correcion_transaccion ← IndicadordeCorreccion_ACF
  --   cod_respuesta                ← CodRpta_ACF
  --   transaccion_revertida        ← Reverso_ACF
  --   fecha_exacta                 ← HoraTRX_ACF (fecha)
  --   hora_exacta                  ← HoraTRX_ACF (hora)
  --   num_unico_transaccion        ← NumeroTrx_ACF
  --   hash_tarjeta                 ← Tarjeta_SHA256_ACF
  --   cod_comercio_interno         ← CodigoCIO_ACF
  --   cod_autorizacion             ← Autorizacion_ACF
  --   mto_soles                    ← MONTOSOLES_ACF
  --   fecha_recepcion_alerta       ← FechaRecepcion
  --   fecha_cierre_caso            ← ACF_FechaCierreCaso
  --   hora_fin_invest_caso         ← ACF_HoraFinCaso
  --   bin                          ← Bin_ACF
  --   registro_tarjeta_750         ← Tarjetaregistro750_ACF
  --   subtipo_resultado            ← ACF_SubtipoResultadoCasodeInvestigacion
  --   texto_subtipo                ← ACF_TextoSubTipodeResultado
  --   usuario_investigador         ← ACF_UsuarioInvestigador
  --   desc_accion                  ← ACF_TextoAccionTomada
  -- -----------------------------------------------------------
  Alertas_EMI AS (
    SELECT *
    FROM (
      SELECT
        fecha_exacta                                   AS fecha_trx,
        bin,
        RIGHT(cod_comercio_interno,7)                                AS cod_comercio,
        LPAD(TRIM(cod_autorizacion),6,'0')                          AS cod_autorizacion,
        registro_tarjeta_750                                         AS tarjetaregistro750,
        subtipo_resultado,
        upper(trim(texto_subtipo)),
        fecha_recepcion_alerta                         AS fecha_recepcion,
        upper(trim(usuario_investigador)),
        upper(trim(desc_accion)),
        ROW_NUMBER() OVER (
          PARTITION BY fecha_exacta, hora_exacta, num_unico_transaccion,
                       hash_tarjeta, cod_comercio_interno,
                       cod_autorizacion
          ORDER BY fecha_recepcion_alerta ASC, fecha_cierre_caso ASC,
                   hora_fin_invest_caso ASC
        ) AS rn
      FROM `master_risk.t_alerta_emisor_monitor`
      WHERE process_date >= date_add(current_date("America/Lima"),interval -6 month)
	    AND tipo_resultado_obtenido = '1'
        AND indicador_correcion_transaccion IN ('0','2')
        AND cod_respuesta = '000'
        AND transaccion_revertida = 'N'
    )
    WHERE rn = 1
  ),


  -- -----------------------------------------------------------
  -- TRANSACCIONAL ADQ
  -- Tabla BQ: master_risk.t_monitor_adquirente
  -- Columnas BQ usadas (← nombre SQL original):
  --   hash_tarjeta            ← Tarjeta_SHA256_ACF
  --   fecha_transaccion       ← FechaTRX_ACF
  --   hora_transaccion        ← HoraTRX_ACF
  --   mto_venta_sol           ← MontoLocalsoles_ACF
  --   cod_autorizacion        ← Autorizacion_ACF
  --   cod_oficina_comercial   ← CodigoCIO_ACF
  --   reg_formato_970         ← Tarjetaregistro750_ACF
  --   nom_oficina_comercial   ← NombreCIO_ACF
  --   cod_categoria_comerciante ← MCC_ACF
  --   bin                     ← Bin_ACF
  --   ident_unico_cliente     ← IDCliente_ACF
  --   modo_ingreso_dato_trx   ← EntryMode_ACF
  --   campo_autenticacion     ← UCAF_ACF
  --   canal                   ← Canal_ACF
  --   party_id_izi            ← IDComercio_ACF
  --   ind_transaccion_revertida ← Reverso_ACF
  -- -----------------------------------------------------------
  Transaccional_ADQ AS (
    SELECT
      hash_tarjeta                               AS tarjeta_sha256,
      fecha_transaccion                          AS fecha_trx,
      hora_transaccion                           AS hora_trx,
      mto_venta_sol                              AS monto_local_soles,
      cod_respuesta,
	  cod_autorizacion,
      cod_oficina_comercial                      AS codigo_cio,
      reg_formato_970                            AS tarjetaregistro750,
      nom_oficina_comercial                      AS nombre_cio,
      LEFT(cod_categoria_comerciante,4)          AS mcc,
      bin,
      ident_unico_cliente                        AS id_cliente,
      modo_ingreso_dato_trx                      AS entry_mode,
      campo_autenticacion                        AS ucaf,
      canal,
      party_id_izi                               AS id_comercio
    FROM `master_risk.t_monitor_adquirente`
    WHERE process_date >= date_add(current_date("America/Lima"),interval -6 month) and ind_transaccion_revertida = 'N'
  ),

  -- -----------------------------------------------------------
  -- TRANSACCIONAL EMISOR
  -- Tabla BQ: master_risk.t_trx_emisor_monitor
  -- Columnas BQ usadas (← nombre SQL original):
  --   tarjeta_hash        ← Tarjeta_SHA256_ACF
  --   fecha_proc_trx      ← FechaTRX_ACF
  --   hora_proc_trx       ← HoraTRX_ACF
  --   mto_trx_orig        ← MontoOrigTRX_ACF
  --   ind_autorizada      ← Autorizacion_ACF
  --   cod_resp_autoriza   ← CodRpta_ACF
  --   cod_relacion_trx    ← CodigoCIO_ACF
  --   ind_trx_tarjeta     ← Tarjetaregistro750_ACF
  --   nom_comercio        ← NombreCIO_ACF
  --   cod_cat_comercio    ← MCC_ACF
  --   bin                 ← Bin_ACF
  --   id_unico_cliente_trx← IDCliente_ACF
  --   modo_entrada_trx    ← EntryMode_ACF
  --   ucaf                ← UCAF_ACF
  --   canal_trx           ← Canal_ACF
  --   party_id_izi        ← IDComercio_ACF
  --   ind_reversa         ← Reverso_ACF
  -- -----------------------------------------------------------
  Transaccional_EMI AS (
    SELECT
      tarjeta_hash                               AS tarjeta_sha256,
      fecha_proc_trx                             AS fecha_trx,
      hora_proc_trx                              AS hora_trx,
      mto_trx_orig                               AS monto_orig_trx,
	  cod_resp_autoriza as cod_respuesta,
      ind_autorizada                             AS cod_autorizacion,
      cod_relacion_trx                           AS codigo_cio,
      ind_trx_tarjeta                            AS tarjetaregistro750,
      nom_comercio                               AS nombre_cio,
      LEFT(cod_cat_comercio,4)                   AS mcc,
      bin,
      id_unico_cliente_trx                       AS id_cliente,
      modo_entrada_trx                           AS entry_mode,
      ucaf,
      canal_trx                                  AS canal,
      party_id_izi                               AS id_comercio
    FROM `master_risk.t_trx_emisor_monitor`
    WHERE ind_reversa = 'N'
      AND ind_autorizada <> ''
      AND cod_resp_autoriza = '000'
  ),

  -- ===========================================================
  -- BLOQUE ADQ
  -- ===========================================================

  Dedup_ADQ AS (
    SELECT *,
      ROW_NUMBER() OVER (
        PARTITION BY fecha, tarjeta_encriptada, cod_comercio, cod_autorizacion
        ORDER BY CASE accion_tomada
          WHEN 'F:TC40'         THEN 1
          WHEN 'F:SAFE'         THEN 2
          WHEN 'F:ASBANC'       THEN 3
          WHEN 'F:CONTRACARGOS' THEN 4
          ELSE 5 END
      ) AS rn
    FROM Fuentes_ALL
    WHERE fecha_carga BETWEEN adq_fecha2 AND adq_fecha1
  ),

  Cruce_ADQ AS (
    SELECT
      f.tarjeta_encriptada
	  ,f.sufix
	  ,f.fecha
	  ,f.cod_comercio
	  ,f.bin
	  ,f.accion_tomada
	  ,f.tipo_fraude_marcado
	  ,f.monto_adq AS importe_fraude_soles
	  ,f.fecha_carga
	  ,f.merchant_name
	  ,CASE 
		WHEN a.cod_autorizacion IS NULL THEN 0 
		ELSE 1 
		END resultado_final
	  ,a.subtipo_result AS subtipo_resultado
	  ,a.desc_subtipo_result AS texto_subtipo
	  ,a.fecha_recepcion
	  ,a.usuario_investigador
	  ,a.desc_accion_investigacion
    FROM Dedup_ADQ f
    LEFT JOIN Alertas_ADQ a
      ON  f.bin              = a.bin
      AND f.cod_comercio     = a.cod_comercio
      AND f.cod_autorizacion = a.cod_autorizacion
      AND (
        (SUBSTR(f.tarjeta_encriptada,1,2) = '37'
          AND RIGHT(f.sufix,3) = RIGHT(a.tarjetaregistro750,3))
        OR (SUBSTR(f.tarjeta_encriptada,1,2) = '36'
          AND RIGHT(f.sufix,2) = RIGHT(a.tarjetaregistro750,2))
        OR (SUBSTR(f.tarjeta_encriptada,1,2) NOT IN ('37','36')
          AND RIGHT(f.sufix,4) = RIGHT(a.tarjetaregistro750,4))
      )
    WHERE f.rn = 1
  ),

  -- Estado A: Filtro Marcado Alerta ADQ
  Alerta_ADQ AS (
    SELECT DISTINCT
      fecha
	  ,tarjeta_encriptada
	  ,cod_comercio
	  ,cast(null as string) as cod_autorizacion
	  ,cod_autorizacion
	  ,importe_fraude_soles
	  ,accion_tomada
	  ,tipo_fraude_marcado
	  ,fecha_carga
	  ,CAST(NULL AS STRING) AS merchant_name
	  ,'FILTRO: MARCADO ALERTA' AS estado_fraude
	  ,'ADQ' AS nom_entidad
    FROM Cruce_ADQ
    WHERE resultado_final = 1
  ),

  Staging_ADQ AS (
    SELECT DISTINCT
      f.tarjeta_encriptada
	  ,f.sufix
	  ,f.fecha
	  ,f.cod_comercio
	  ,f.bin
	  ,f.cod_autorizacion
	  ,f.accion_tomada
	  ,f.tipo_fraude_marcado
	  ,f.importe_fraude_soles
	  ,f.fecha_carga
	  ,f.merchant_name
	  ,seg.cod_segmento
	  ,CASE
        WHEN f.fecha_carga >= '2022-05-25' AND seg.segmento IN ('E','N') THEN 1
        WHEN f.fecha_carga >= '2022-05-25' AND seg.segmento NOT IN ('E','N') AND f.importe_fraude_soles >= 150 THEN 1
        WHEN f.fecha_carga < '2022-05-25' THEN 1
        ELSE 0
      END flag_carga
    FROM Cruce_ADQ f
    LEFT JOIN `master_party.m_comercio` seg ON f.cod_comercio = seg.cod_comercio
    WHERE f.resultado_final = 0 AND f.cod_autorizacion <> '000000' AND UPPER(f.merchant_name) NOT LIKE '%IATA%' AND UPPER(f.merchant_name) NOT LIKE '%TC33%'
  ),

  -- Estado B: Enviado ADQ
  Enviado_ADQ AS (
    SELECT DISTINCT
      t.fecha_trx AS fecha,
      t.tarjetaregistro750 AS tarjeta_encriptada,
      RIGHT(t.codigo_cio,7) AS cod_comercio,
	  t.cod_respuesta,
      t.cod_autorizacion,
      CAST(t.monto_local_soles AS FLOAT64) AS importe_fraude_soles,
      f.merchant_name,
      f.accion_tomada, f.tipo_fraude_marcado, f.fecha_carga,
      'ENVIADO' AS estado_fraude,
      'ADQ' AS nom_entidad,
      t.tarjeta_sha256,
      t.hora_trx,
      t.monto_local_soles AS mto_trx,
      t.codigo_cio,
      t.nombre_cio,
      t.mcc,
      t.bin,
      t.id_cliente,
      t.entry_mode,
      t.ucaf,
      t.canal,
      t.id_comercio,
      t.tarjetaregistro750 AS tarjetaregistro750_trx
    FROM Staging_ADQ f
    INNER JOIN Transaccional_ADQ t
      ON  f.fecha            = t.fecha_trx
      AND f.cod_comercio     = RIGHT(t.codigo_cio,7)
      AND f.cod_autorizacion = t.cod_autorizacion
      AND f.bin              = t.bin
      AND (
        (SUBSTR(f.tarjeta_encriptada,1,2) = '37'
          AND CONCAT(SUBSTR(f.tarjeta_encriptada,1,6),'XXXXXX',
                     RIGHT(f.tarjeta_encriptada,3)) = t.tarjetaregistro750)
        OR (SUBSTR(f.tarjeta_encriptada,1,2) = '36'
          AND CONCAT(SUBSTR(f.tarjeta_encriptada,1,6),'XXXXXX',
                     RIGHT(f.tarjeta_encriptada,2)) = t.tarjetaregistro750)
        OR (SUBSTR(f.tarjeta_encriptada,1,2) NOT IN ('37','36')
          AND CONCAT(SUBSTR(f.tarjeta_encriptada,1,6),'XXXXXX',
                     RIGHT(f.tarjeta_encriptada,4)) = t.tarjetaregistro750)
      )
  ),

  -- Estado C: Filtro Cruce Transaccional ADQ
  Filtro_ADQ AS (
    SELECT DISTINCT
      f.fecha
	  ,CASE
        WHEN SUBSTR(f.tarjeta_encriptada,1,2) = '37'
          THEN CONCAT(SUBSTR(f.tarjeta_encriptada,1,6),'XXXXXX',RIGHT(f.tarjeta_encriptada,3))
        WHEN SUBSTR(f.tarjeta_encriptada,1,2) = '36'
          THEN CONCAT(SUBSTR(f.tarjeta_encriptada,1,6),'XXXXXX',RIGHT(f.tarjeta_encriptada,2))
        ELSE CONCAT(SUBSTR(f.tarjeta_encriptada,1,6),'XXXXXX',RIGHT(f.tarjeta_encriptada,4))
      END tarjeta_encriptada
	  ,f.cod_comercio
	  ,f.cod_respuesta
	  ,f.cod_autorizacion
	  ,f.importe_fraude_soles
	  ,f.merchant_name
	  ,f.accion_tomada
	  ,f.tipo_fraude_marcado
	  ,f.fecha_carga
	  ,'FILTRO: CRUCE TRANSACCIONAL' AS estado_fraude,
      'ADQ' AS nom_entidad
    FROM Staging_ADQ f
    LEFT JOIN Transaccional_ADQ t
      ON  f.fecha            = t.fecha_trx
      AND f.cod_comercio     = RIGHT(t.codigo_cio,7)
      AND f.cod_autorizacion = t.cod_autorizacion
      AND f.bin              = t.bin
      AND (
        (SUBSTR(f.tarjeta_encriptada,1,2) = '37'
          AND CONCAT(SUBSTR(f.tarjeta_encriptada,1,6),'XXXXXX',
                     RIGHT(f.tarjeta_encriptada,3)) = t.tarjetaregistro750)
        OR (SUBSTR(f.tarjeta_encriptada,1,2) = '36'
          AND CONCAT(SUBSTR(f.tarjeta_encriptada,1,6),'XXXXXX',
                     RIGHT(f.tarjeta_encriptada,2)) = t.tarjetaregistro750)
        OR (SUBSTR(f.tarjeta_encriptada,1,2) NOT IN ('37','36')
          AND CONCAT(SUBSTR(f.tarjeta_encriptada,1,6),'XXXXXX',
                     RIGHT(f.tarjeta_encriptada,4)) = t.tarjetaregistro750)
      )
    WHERE t.cod_autorizacion IS NULL
      AND f.cod_autorizacion <> ''
  ),

  -- Estado D: Segundo Reproceso Enviado ADQ
  Reproceso_Enviado_ADQ AS (
    SELECT DISTINCT
      t.fecha_trx AS fecha
	  ,t.tarjetaregistro750 AS tarjeta_encriptada
	  ,RIGHT(t.codigo_cio,7) AS cod_comercio
	  ,f.cod_respuesta
	  ,f.cod_autorizacion
	  ,CAST(t.monto_local_soles AS FLOAT64) AS importe_fraude_soles
	  ,f.merchant_name
	  ,f.accion_tomada
	  ,f.tipo_fraude_marcado
	  ,f.fecha_carga
      ,'SEGUNDO_REPROCESO_ENVIADO' AS estado_fraude
      ,'ADQ' AS nom_entidad
      ,t.tarjeta_sha256
      ,t.hora_trx
      ,t.monto_local_soles AS mto_trx
      ,t.codigo_cio
      ,t.nombre_cio
      ,t.mcc
      ,t.bin
      ,t.id_cliente
      ,t.entry_mode
      ,t.ucaf
      ,t.canal
      ,t.id_comercio
      ,t.tarjetaregistro750 AS tarjetaregistro750_tr
    FROM Filtro_ADQ f
    INNER JOIN Transaccional_ADQ t
      ON  f.fecha            = t.fecha_trx
      AND f.cod_comercio     = RIGHT(t.codigo_cio,7)
      AND f.cod_autorizacion = t.cod_autorizacion
  ),

  -- Estado E: Segundo Reproceso Filtro ADQ
  Reproceso_Filtro_ADQ AS (
    SELECT DISTINCT
      f.fecha
	  ,f.tarjeta_encriptada
	  ,f.cod_comercio
	  ,f.cod_respuesta
	  ,f.cod_autorizacion
	  ,f.importe_fraude_soles
	  ,f.merchant_name
	  ,f.accion_tomada
	  ,f.tipo_fraude_marcado
	  ,f.fecha_carga
      ,'SEGUNDO_REPROCESO_FILTRO: CRUCE TRANSACCIONAL' AS estado_fraude
      ,'ADQ'                                           AS nom_entidad
    FROM Filtro_ADQ f
    WHERE NOT EXISTS (
      SELECT 1 FROM Transaccional_ADQ t
      WHERE f.fecha            = t.fecha_trx
        AND f.cod_comercio     = RIGHT(t.codigo_cio,7)
        AND f.cod_autorizacion = t.cod_autorizacion
    )
  ),

  -- ===========================================================
  -- BLOQUE EMISOR
  -- ===========================================================

  Dedup_EMI AS (
    SELECT *,
      ROW_NUMBER() OVER (
        PARTITION BY fecha, tarjeta_encriptada, cod_comercio, cod_autorizacion
        ORDER BY CASE accion_tomada
          WHEN 'F:TC40'         THEN 1
          WHEN 'F:SAFE'         THEN 2
          WHEN 'F:ASBANC'       THEN 3
          WHEN 'F:CONTRACARGOS' THEN 4
          ELSE 5 END
      ) AS rn
    FROM Fuentes_ALL
    WHERE fecha_carga BETWEEN emi_fecha2 AND emi_fecha1
      AND bin IN (
        '521628','522772','545028','449577','475796','477151','489068',
        '512533','529206','550218','905050','546342','231000','231020',
        '233063','234057','234058','400657','486352','486353','483105'
      )
  ),

  Cruce_EMI AS (
    SELECT
      f.tarjeta_encriptada
	  ,f.sufix
	  ,f.fecha
	  ,f.cod_comercio
	  ,f.bin
      ,f.cod_autorizacion
	  ,f.accion_tomada
	  ,f.tipo_fraude_marcado
      ,CAST(f.monto_emi AS FLOAT64) AS importe_fraude_soles
      ,f.fecha_carga, f.merchant_name
      ,CASE 
		WHEN a.cod_autorizacion IS NULL THEN 0 
		ELSE 1 
		END resultado_final
      ,a.subtipo_resultado
      ,a.texto_subtipo
      ,a.fecha_recepcion
      ,a.usuario_investigador
      ,a.desc_accio
    FROM Dedup_EMI f
    LEFT JOIN Alertas_EMI a
      ON  f.bin              = a.bin
      AND f.cod_comercio     = a.cod_comercio
      AND RIGHT(f.sufix,4)   = RIGHT(a.tarjetaregistro750,4)
      AND f.cod_autorizacion = a.cod_autorizacion
    WHERE f.rn = 1
  ),

  -- Estado F: Filtro Marcado Alerta EMISOR
  Alerta_EMI AS (
    SELECT DISTINCT
      fecha
      ,CONCAT(SUBSTR(tarjeta_encriptada,1,6),'XXXXXX'
      ,RIGHT(tarjeta_encriptada,4)) AS tarjeta_encriptada
      ,cod_comercio
	  ,cast(null as string) as cod_respuesta
	  ,cod_autorizacion
      ,importe_fraude_soles
	  ,accion_tomada
	  ,tipo_fraude_marcado
	  ,fecha_carga
      ,CAST(NULL AS STRING) AS merchant_name
      ,'FILTRO: MARCADO ALERTA' AS estado_fraude
      ,'EMISOR' AS nom_entidad
    FROM Cruce_EMI
    WHERE resultado_final = 1
  ),

  Staging_EMI AS (
    SELECT DISTINCT
      f.tarjeta_encriptada
	  ,f.sufix
	  ,f.fecha
	  ,f.cod_comercio
	  ,f.bin
	  ,f.cod_autorizacion
	  ,f.accion_tomada
	  ,f.tipo_fraude_marcado
	  ,f.importe_fraude_soles
	  ,f.fecha_carga
	  ,f.merchant_name
      ,seg.cod_segmento
      ,CASE
        WHEN f.fecha_carga >= '2022-05-25' AND seg.cod_segmento IN ('E','N') THEN 1
        WHEN f.fecha_carga >= '2022-05-25' AND seg.cod_segmento NOT IN ('E','N') AND f.importe_fraude_soles >= 150 THEN 1
        WHEN f.fecha_carga < '2022-05-25' THEN 1
        ELSE 0
      END flag_carga
    FROM Cruce_EMI f
    LEFT JOIN `master_party.m_comercio` seg
      ON f.cod_comercio = seg.cod_comercio
    WHERE f.resultado_final = 0
      AND f.cod_autorizacion <> '000000'
      AND UPPER(f.merchant_name) NOT LIKE '%IATA%'
      AND UPPER(f.merchant_name) NOT LIKE '%TC33%'
      AND f.fecha_carga >= '2023-07-01'
  ),

  -- Estado G: Enviado EMISOR
  Enviado_EMI AS (
    SELECT DISTINCT
      t.fecha_trx AS fecha
      ,t.tarjetaregistro750 AS tarjeta_encriptada
      ,RIGHT(t.codigo_cio,7) AS cod_comercio
	  ,t.cod_respuesta
      ,t.cod_autorizacion
      ,t.monto_orig_trx AS importe_fraude_soles
      ,f.merchant_name
      ,CAST(NULL AS STRING)  AS accion_tomada
      ,f.tipo_fraude_marcado
	  ,f.fecha_carga
      ,'ENVIADO' AS estado_fraude
      ,'EMISOR' AS nom_entidad
      ,t.tarjeta_sha256
      ,t.hora_trx
      ,t.monto_orig_trx AS mto_trx
      ,t.codigo_cio
      ,t.nombre_cio
      ,t.mcc
      ,t.bin
      ,t.id_cliente
      ,t.entry_mode
      ,t.ucaf
      ,t.canal
      ,t.id_comercio
      t.tarjetaregistro750 AS tarjetaregistro750_trx
    FROM Staging_EMI f
    INNER JOIN Transaccional_EMI t
      ON  f.fecha            = t.fecha_trx
      AND f.cod_comercio     = RIGHT(t.codigo_cio,7)
      AND f.cod_autorizacion = t.cod_autorizacion
      AND f.bin              = t.bin
      AND CONCAT(SUBSTR(f.tarjeta_encriptada,1,6),'XXXXXX',
                 RIGHT(f.tarjeta_encriptada,4)) = t.tarjetaregistro750
  ),

  -- Estado H: Filtro Cruce Transaccional EMISOR
  Filtro_EMI AS (
    SELECT DISTINCT
      f.fecha,
      CONCAT(SUBSTR(f.tarjeta_encriptada,1,6),'XXXXXX',
             RIGHT(f.tarjeta_encriptada,4))           AS tarjeta_encriptada
      ,f.cod_comercio
	  ,f.cod_respuesta
	  ,f.cod_autorizacion
	  ,f.importe_fraude_soles
	  ,f.merchant_name
	  ,f.accion_tomada
	  ,f.tipo_fraude_marcado
	  ,f.fecha_carga
	  ,'FILTRO: CRUCE TRANSACCIONAL' AS estado_fraude,
      'EMISOR' AS nom_entidad
    FROM Staging_EMI f
    LEFT JOIN Transaccional_EMI t
      ON  f.fecha            = t.fecha_trx
      AND f.cod_comercio     = RIGHT(t.codigo_cio,7)
      AND f.cod_autorizacion = t.cod_autorizacion
      AND f.bin              = t.bin
      AND CONCAT(SUBSTR(f.tarjeta_encriptada,1,6),'XXXXXX',
                 RIGHT(f.tarjeta_encriptada,4)) = t.tarjetaregistro750
    WHERE t.cod_autorizacion IS NULL
  ),

  -- ===========================================================
  -- UNION ALL de los 8 estados
  -- ===========================================================
  Union_Final AS (

    -- A: Filtro Marcado Alerta ADQ
    SELECT
      fecha
	  ,tarjeta_encriptada
	  ,cod_comercio
	  ,cod_respuesta
	  ,cod_autorizacion
      ,importe_fraude_soles
	  ,merchant_name
	  ,accion_tomada
      ,tipo_fraude_marcado
	  ,fecha_carga
	  ,estado_fraude
	  ,nom_entidad
      ,CAST(NULL AS STRING) AS tarjeta_sha256_out
      ,CAST(NULL AS STRING) AS hora_trx_out
      ,CAST(NULL AS STRING) AS mto_trx_out
      ,CAST(NULL AS STRING) AS codigo_cio_out
      ,CAST(NULL AS STRING) AS nombre_cio_out
      ,CAST(NULL AS STRING) AS mcc_out
      ,CAST(NULL AS STRING) AS bin_out
      ,CAST(NULL AS STRING) AS id_cliente_out
      ,CAST(NULL AS STRING) AS entry_mode_out
      ,CAST(NULL AS STRING) AS ucaf_out
      ,CAST(NULL AS STRING) AS canal_out
      ,CAST(NULL AS STRING) AS id_comercio_out
      ,CAST(NULL AS STRING) AS tarjetaregistro750_out
      'FRAUDES REPORTADOS+ALERTAS ADQ' AS record_source
    FROM Alerta_ADQ

    UNION ALL

    -- B: Enviado ADQ
    SELECT
      fecha
	  ,tarjeta_encriptada
	  ,cod_comercio
	  ,cod_respuesta
	  ,cod_autorizacion
	  ,importe_fraude_soles
	  ,merchant_name
	  ,accion_tomada
      ,tipo_fraude_marcado
	  ,fecha_carga
	  ,estado_fraude
	  ,nom_entidad
      ,tarjeta_sha256
	  ,hora_trx
	  ,CAST(mto_trx AS STRING)
      ,codigo_cio
	  ,nombre_cio
	  ,mcc
	  ,bin
	  ,id_cliente
      ,entry_mode
	  ,ucaf
	  ,canal
	  ,id_comercio
	  ,tarjetaregistro750_trx
      'FRAUDES REPORTADOS+ALERTAS ADQ'
    FROM Enviado_ADQ

    UNION ALL

    -- C: Filtro Cruce Transaccional ADQ
    SELECT
      fecha
	  ,tarjeta_encriptada
	  ,cod_comercio
	  ,cod_respuesta
	  ,cod_autorizacion
      ,importe_fraude_soles
	  ,merchant_name
	  ,accion_tomada
      ,tipo_fraude_marcado
	  ,fecha_carga
	  ,estado_fraude
	  ,nom_entidad
      ,CAST(NULL AS STRING)
	  ,CAST(NULL AS STRING)
	  ,CAST(NULL AS STRING)
      ,CAST(NULL AS STRING)
	  ,CAST(NULL AS STRING)
	  ,CAST(NULL AS STRING)
      ,CAST(NULL AS STRING)
	  ,CAST(NULL AS STRING)
	  ,CAST(NULL AS STRING)
      ,CAST(NULL AS STRING)
	  ,CAST(NULL AS STRING)
	  ,CAST(NULL AS STRING)
      ,CAST(NULL AS STRING)
      'FRAUDES REPORTADOS+ALERTAS ADQ'
    FROM Filtro_ADQ

    UNION ALL

    -- D: Segundo Reproceso Enviado ADQ
    SELECT
      fecha
	  ,tarjeta_encriptada
	  ,cod_comercio
	  ,cod_respuesta
	  ,cod_autorizacion
      ,importe_fraude_soles
	  ,merchant_name
	  ,accion_tomada
      ,tipo_fraude_marcado
	  ,fecha_carga
	  ,estado_fraude
	  ,nom_entidad
      ,tarjeta_sha256
	  ,hora_trx
	  ,CAST(mto_trx AS STRING)
      ,codigo_cio
	  ,nombre_cio
	  ,mcc
	  ,bin
	  ,id_cliente
      ,entry_mode
	  ,ucaf
	  ,canal
	  ,id_comercio
	  ,tarjetaregistro750_trx
      ,'FRAUDES REPORTADOS+ALERTAS ADQ'
    FROM Reproceso_Enviado_ADQ

    UNION ALL

    -- E: Segundo Reproceso Filtro ADQ
    SELECT
      fecha, tarjeta_encriptada
	  ,cod_comercio
	  ,cod_respuesta
	  ,cod_autorizacion
      ,importe_fraude_soles
	  ,merchant_name
	  ,accion_tomada
      ,tipo_fraude_marcado, fecha_carga, estado_fraude, nom_entidad
      ,CAST(NULL AS STRING),CAST(NULL AS STRING),CAST(NULL AS STRING)
      ,CAST(NULL AS STRING),CAST(NULL AS STRING),CAST(NULL AS STRING)
      ,CAST(NULL AS STRING),CAST(NULL AS STRING),CAST(NULL AS STRING)
      ,CAST(NULL AS STRING),CAST(NULL AS STRING),CAST(NULL AS STRING)
      ,CAST(NULL AS STRING)
      'FRAUDES REPORTADOS+ALERTAS ADQ'
    FROM Reproceso_Filtro_ADQ

    UNION ALL

    -- F: Filtro Marcado Alerta EMISOR
    SELECT
      fecha, tarjeta_encriptada, cod_comercio, cod_respuesta,cod_autorizacion,
      importe_fraude_soles, merchant_name, accion_tomada,
      tipo_fraude_marcado, fecha_carga, estado_fraude, nom_entidad,
      CAST(NULL AS STRING),CAST(NULL AS STRING),CAST(NULL AS STRING),
      CAST(NULL AS STRING),CAST(NULL AS STRING),CAST(NULL AS STRING),
      CAST(NULL AS STRING),CAST(NULL AS STRING),CAST(NULL AS STRING),
      CAST(NULL AS STRING),CAST(NULL AS STRING),CAST(NULL AS STRING),
      CAST(NULL AS STRING),
      'FRAUDES REPORTADOS+ALERTAS EMISOR'
    FROM Alerta_EMI

    UNION ALL

    -- G: Enviado EMISOR
    SELECT
      fecha, tarjeta_encriptada, cod_comercio, cod_respuesta,cod_autorizacion,
      importe_fraude_soles, merchant_name, accion_tomada,
      tipo_fraude_marcado, fecha_carga, estado_fraude, nom_entidad,
      tarjeta_sha256, hora_trx, CAST(mto_trx AS STRING),
      codigo_cio, nombre_cio, mcc, bin, id_cliente,
      entry_mode, ucaf, canal, id_comercio, tarjetaregistro750_trx,
      'FRAUDES REPORTADOS+ALERTAS EMISOR'
    FROM Enviado_EMI

    UNION ALL

    -- H: Filtro Cruce Transaccional EMISOR
    SELECT
      fecha, tarjeta_encriptada, cod_comercio,cod_respuesta, cod_autorizacion,
      importe_fraude_soles, merchant_name, accion_tomada,
      tipo_fraude_marcado, fecha_carga, estado_fraude, nom_entidad,
      CAST(NULL AS STRING),CAST(NULL AS STRING),CAST(NULL AS STRING),
      CAST(NULL AS STRING),CAST(NULL AS STRING),CAST(NULL AS STRING),
      CAST(NULL AS STRING),CAST(NULL AS STRING),CAST(NULL AS STRING),
      CAST(NULL AS STRING),CAST(NULL AS STRING),CAST(NULL AS STRING),
      CAST(NULL AS STRING),
      'FRAUDES REPORTADOS+ALERTAS EMISOR'
    FROM Filtro_EMI
  ),

  -- ===========================================================
  -- SELECT FINAL con transformaciones TRIM / UPPER / NULLIF / CAST
  -- ===========================================================
  FIN AS
  (
  SELECT
    u.fecha AS fecha_trx,
    NULLIF(TRIM(UPPER(u.tarjeta_encriptada)),'') AS tarjeta_encriptada,
    NULLIF(TRIM(UPPER(u.cod_comercio)),'') AS cod_comercio,
	NULLIF(TRIM(UPPER(u.cod_respuesta)),'') AS cod_respuesta ,
	cod_respuesta
	NULLIF(TRIM(UPPER(u.cod_autorizacion)),'') AS cod_autorizacion,
    u.importe_fraude_soles AS mto_fraude_soles,
    NULLIF(TRIM(UPPER(u.merchant_name)),'') AS nom_comercio,
    NULLIF(TRIM(UPPER(u.accion_tomada)),'') AS accion_tomada,
    NULLIF(TRIM(UPPER(u.tipo_fraude_marcado)),'') AS tipo_fraude_marcado,
    u.fecha_carga AS fecha_carga,
    NULLIF(TRIM(UPPER(u.estado_fraude)),'') AS estado_fraude,
    CAST(CURRENT_DATE() AS DATE) AS fecha_envio,
    NULLIF(TRIM(UPPER(u.nom_entidad)),'') AS nom_entidad,
    CAST(NULL AS STRING) AS proceso,
    NULLIF(TRIM(UPPER(u.tarjeta_sha256_out)),'') AS tarjeta_sha256_trx,
    NULLIF(TRIM(UPPER(u.hora_trx_out)),'') AS hora_trx,
    mto_trx_out AS mto_trx,
    NULLIF(TRIM(UPPER(u.codigo_cio_out)),'') AS codigo_cio_trx,
    NULLIF(TRIM(UPPER(u.nombre_cio_out)),'') AS nom_cio_trx,
    NULLIF(TRIM(UPPER(u.mcc_out)),'') AS cod_giro_comercio_trx,
    NULLIF(TRIM(UPPER(u.bin_out)),'') AS bin_trx,
    NULLIF(TRIM(UPPER(u.id_cliente_out)),'') AS id_cliente_trx,
    NULLIF(TRIM(UPPER(u.entry_mode_out)),'') AS entry_mode_trx,
    NULLIF(TRIM(UPPER(u.ucaf_out)),'') AS ucaf_trx,
    NULLIF(TRIM(UPPER(u.canal_out)),'') AS canal_trx,
    NULLIF(TRIM(UPPER(u.id_comercio_out)),'') AS id_comercio_trx,
    NULLIF(TRIM(UPPER(u.tarjetaregistro750_out)),'') AS tarjetaregistro750_trx,
    u.record_source AS record_source
  FROM Union_Final u
  )
  select
	CURRENT_DATE() AS process_date,
	,fecha_trx
	,tarjeta_encriptada
	,cod_comercio
	,cod_respuesta
	,cod_autorizacion
	,mto_fraude_soles
	,nom_comercio
	,accion_tomada
	,tipo_fraude_marcado
	,fecha_carga
	,estado_fraude
	,fecha_envio
	,nom_entidad
	,proceso
	,tarjeta_sha256_trx
	,hora_trx
	,mto_trx
	,codigo_cio_trx
	,nom_cio_trx
	,cod_giro_comercio_trx
	,bin_trx
	,id_cliente_trx
	,entry_mode_trx
	,ucaf_trx
	,canal_trx
	,id_comercio_trx
	,tarjetaregistro750_trx
	,record_source
	,CURRENT_DATETIME('America/Lima') AS load_date
    ,SESSION_USER() AS creation_user
  from FIN
END;

  -- ===========================================================
  -- Inserta última foto en historia
  -- ===========================================================
  insert into `master_risk.m_consolidacion_fraudes_h`
	(
	process_date
	,fecha_trx
	,tarjeta_encriptada
	,cod_comercio
	,cod_respuesta
	,cod_autorizacion
	,mto_fraude_soles
	,nom_comercio
	,accion_tomada
	,tipo_fraude_marcado
	,fecha_carga
	,estado_fraude
	,fecha_envio
	,nom_entidad
	,proceso
	,tarjeta_sha256_trx
	,hora_trx
	,mto_trx
	,codigo_cio_trx
	,nom_cio_trx
	,cod_giro_comercio_trx
	,bin_trx
	,id_cliente_trx
	,entry_mode_trx
	,ucaf_trx
	,canal_trx
	,id_comercio_trx
	,tarjetaregistro750_trx
	,record_source
	,load_date
	,creation_user
	)
  select
	process_date
	,fecha_trx
	,tarjeta_encriptada
	,cod_comercio
	,cod_respuesta
	,cod_autorizacion
	,mto_fraude_soles
	,nom_comercio
	,accion_tomada
	,tipo_fraude_marcado
	,fecha_carga
	,estado_fraude
	,fecha_envio
	,nom_entidad
	,proceso
	,tarjeta_sha256_trx
	,hora_trx
	,mto_trx
	,codigo_cio_trx
	,nom_cio_trx
	,cod_giro_comercio_trx
	,bin_trx
	,id_cliente_trx
	,entry_mode_trx
	,ucaf_trx
	,canal_trx
	,id_comercio_trx
	,tarjetaregistro750_trx
	,record_source
	,load_date
	,creation_user
  from `master_risk.m_consolidacion_fraudes`;
  