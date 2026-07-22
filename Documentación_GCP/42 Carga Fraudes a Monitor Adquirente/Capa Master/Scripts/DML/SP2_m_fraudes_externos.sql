-- ============================================================
-- PROCEDURE: master_risk.sp_carga_m_fraudes_externos
--
-- Fuente  : master_risk.m_consolidacion_fraudes
-- Destino : master_risk.m_fraudes_externos
--
-- Columnas de auditoría:
--   process_date  → CURRENT_DATE()
--   record_source → 'FRAUDES ASBANC, TC40, SAFE Y CONTRACARGOS'
--   load_date     → CURRENT_DATETIME('America/Lima')
--   creation_user → SESSION_USER()
--
-- Reglas transformación SELECT final:
--   STRING  → NULLIF(TRIM(UPPER(campo)), '')
--   fecha*  → CAST(... AS DATE)
--   mto*    → CAST(... AS FLOAT64)
-- ============================================================

CREATE OR REPLACE PROCEDURE `master_risk.sp_carga_m_fraudes_externos`()
BEGIN

  -- ===========================================================
  -- truncate última fota
  -- ===========================================================
  TRUNCATE TABLE `master_risk.m_fraudes_externos`;

  -- ===========================================================
  -- INSERT
  -- ===========================================================
  INSERT INTO `master_risk.m_fraudes_externos`
  (
    process_date,
    cod_reclamo,
    correlativo,
    usuario_reclamo,
    sucursal_reclamo,
    fecha_reclamo,
    hora_reclamo,
    detalle_reclamo,
    medio_canal_reclamo,
    fuente_reclamo,
    departamento_division,
    cod_evento,
    id_cliente,
    tarjeta_sha256,
    fecha_trx,
    hora_trx,
    mto_trx,
    cod_autorizacion,
    cod_respuesta,
    resultado_reclamo,
    cod_comercio,
    tarjeta_registro750,
    nom_comercio,
    cod_giro_comercio,
    bin_6,
    modo_ingreso,
    ucaf,
    canal_trx,
    id_comercio,
    disponible1,
    disponible2,
    disponible3,
    disponible4,
    disponible5,
    disponible6,
    cod_resultado,
    detalle_investigacion,
    usuario_investigador,
    cod_institucion,
    fecha_investigacion,
    hora_investigacion,
    detectado_monitoreo,
    record_source,
    load_date,
    creation_user
  )

  WITH

  -- -----------------------------------------------------------
  -- Fuente: master_risk.m_consolidacion_fraudes
  --
  -- Se leen solo los estados que tienen datos transaccionales
  -- (tarjeta_sha256_trx IS NOT NULL = registros con cruce BQ).
  -- Columnas de la tabla origen (nombres BQ del Data Model):
  --   estado_fraude, tarjeta_sha256_trx, hora_trx, mto_trx,
  --   cod_autorizacion, cod_comercio, tarjetaregistro750_trx,
  --   nom_cio_trx, cod_giro_comercio_trx, bin_trx,
  --   id_cliente_trx, entry_mode_trx, ucaf_trx, canal_trx,
  --   id_comercio_trx, fecha_trx, fecha_carga, nom_entidad,
  --   process_date
  -- -----------------------------------------------------------
  Base AS (
    SELECT
      *,
      -- Correlativo: YYMMDD + secuencia 4 dígitos
      CONCAT(
        FORMAT_DATE('%y%m%d', CURRENT_DATE()),
        LPAD(CAST(
          ROW_NUMBER() OVER (ORDER BY fecha_trx ASC, hora_trx ASC)
        AS STRING), 4, '0')
      ) AS correlativo_gen,
      -- Deduplicación: preferir ENVIADO sobre SEGUNDO_REPROCESO_ENVIADO
      ROW_NUMBER() OVER (
        PARTITION BY fecha_trx, tarjeta_encriptada,
                     cod_comercio, cod_autorizacion
        ORDER BY
          CASE estado_fraude
            WHEN 'ENVIADO'                   THEN 1
            WHEN 'SEGUNDO_REPROCESO_ENVIADO' THEN 2
            ELSE 3
          END
      ) AS rn
    FROM `master_risk.m_consolidacion_fraudes`
    WHERE estado_fraude IN ('ENVIADO','SEGUNDO_REPROCESO_ENVIADO')
      AND tarjeta_sha256_trx IS NOT NULL
      AND process_date = CURRENT_DATE()
  ),

  Dedup AS (
    SELECT * FROM Base WHERE rn = 1
  ),

  -- -----------------------------------------------------------
  -- Mapeo a columnas destino m_fraudes_externos
  -- -----------------------------------------------------------
  Union_Final AS (
    SELECT
      '1' AS cod_reclamo,
      correlativo_gen AS correlativo,
      'IZIPAY'  AS usuario_reclamo,
      'PERU' AS sucursal_reclamo,
      fecha_carga AS fecha_reclamo,
      '00:00:01' AS hora_reclamo,
      case 
		when a.accion_tomada='F:TC40' then '1' 
		when a.accion_tomada='F:SAFE' then '2' 
		when a.accion_tomada='F:ASBANC' then '3' 
		else  '4' 
		end detalle_reclamo,
      '0000' AS medio_canal_reclamo,
      case 
		when a.accion_tomada='F:TC40' then '1' 
		when a.accion_tomada='F:SAFE' then '2' 
		when a.accion_tomada='F:ASBANC' then '3' 
		else  '4' 
		end fuente_reclamo,
      'REP'  AS departamento_division,
      CASE nom_entidad
        WHEN 'ADQ'    THEN '8751'
        WHEN 'EMISOR' THEN '8750'
        ELSE NULL
      END cod_evento,
      id_cliente_trx AS id_cliente,
      tarjeta_sha256_trx AS tarjeta_sha256,
      fecha_trx AS fecha_trx,
      hora_trx AS hora_trx,
      mto_trx AS mto_trx,
      cod_autorizacion AS cod_autorizacion,
      cod_respuesta AS cod_respuesta,
      '1' AS resultado_reclamo,
      cod_comercio AS cod_comercio,
      tarjetaregistro750_trx AS tarjeta_registro750,
      nom_cio_trx AS nom_comercio,
      cod_giro_comercio_trx AS cod_giro_comercio,
      bin_trx AS bin_6,
      entry_mode_trx AS modo_ingreso,
      ucaf_trx AS ucaf,
      canal_trx AS canal_trx,
      id_comercio_trx AS id_comercio,
      '000' AS disponible1,
      '000' AS disponible2,
      '000' AS disponible3,
      '000' AS disponible4,
      '000' AS disponible5,
      '000'	AS disponible6,
      case 
		when a.accion_tomada='F:TC40' then '210' 
		when a.accion_tomada='F:SAFE' then '211' 
		when a.accion_tomada='F:ASBANC' then '212' 
		else  '213'
		end cod_resultado,
      tipo_fraude_marcado AS detalle_investigacion,
      '000' AS usuario_investigador,
      '001' AS cod_institucion,
      current_date("America/Lima") AS fecha_investigacion,
      current_time("America/Lima") AS hora_investigacion,
      '0' AS detectado_monitoreo
    FROM Dedup
  )

  -- ===========================================================
  -- SELECT FINAL:
  -- ===========================================================
  SELECT
    CURRENT_DATE("America/Lima") AS process_date
    ,cod_reclamo
    ,correlativo
    ,usuario_reclamo
    ,sucursal_reclamo
    ,fecha_reclamo
    ,hora_reclamo
    ,detalle_reclamo
    ,medio_canal_reclamo
    ,fuente_reclamo
    ,departamento_division
    ,cod_evento
    ,id_cliente
    ,tarjeta_sha256
    ,fecha_trx
    ,hora_trx
    ,mto_trx
    ,cod_autorizacion
    ,cod_respuesta
    ,resultado_reclamo
    ,cod_comercio
    ,tarjeta_registro750
    ,nom_comercio
    ,cod_giro_comercio
    ,bin_6
    ,modo_ingreso
    ,ucaf
    ,canal_trx
    ,id_comercio
    ,disponible1
    ,disponible2
    ,disponible3
    ,disponible4
    ,disponible5
    ,disponible6
    ,cod_resultado
    ,detalle_investigacion
    ,usuario_investigador
    ,cod_institucion
    ,fecha_investigacion
    ,hora_investigacion
    ,detectado_monitoreo
    ,'FRAUDES ASBANC, TC40, SAFE Y CONTRACARGOS' AS record_source
    ,CURRENT_DATETIME('America/Lima') AS load_date
    ,SESSION_USER() AS creation_user
  FROM Union_Final;

END;

---Insertar última foto en historia:
insert into `master_risk.m_fraudes_externos_h`
(
	process_date
	,cod_reclamo
	,correlativo
	,usuario_reclamo
	,sucursal_reclamo
	,fecha_reclamo
	,hora_reclamo
	,detalle_reclamo
	,medio_canal_reclamo
	,fuente_reclamo
	,departamento_division
	,cod_evento
	,id_cliente
	,tarjeta_sha256
	,fecha_trx
	,hora_trx
	,mto_trx
	,cod_autorizacion
	,cod_respuesta
	,resultado_reclamo
	,cod_comercio
	,tarjeta_registro750
	,nom_comercio
	,cod_giro_comercio
	,bin_6
	,modo_ingreso
	,ucaf
	,canal_trx
	,id_comercio
	,disponible1
	,disponible2
	,disponible3
	,disponible4
	,disponible5
	,disponible6
	,cod_resultado
	,detalle_investigacion
	,usuario_investigador
	,cod_institucion
	,fecha_investigacion
	,hora_investigacion
	,detectado_monitoreo
	,record_source
	,load_date
	,creation_user
)
select 
	process_date
	,cod_reclamo
	,correlativo
	,usuario_reclamo
	,sucursal_reclamo
	,fecha_reclamo
	,hora_reclamo
	,detalle_reclamo
	,medio_canal_reclamo
	,fuente_reclamo
	,departamento_division
	,cod_evento
	,id_cliente
	,tarjeta_sha256
	,fecha_trx
	,hora_trx
	,mto_trx
	,cod_autorizacion
	,cod_respuesta
	,resultado_reclamo
	,cod_comercio
	,tarjeta_registro750
	,nom_comercio
	,cod_giro_comercio
	,bin_6
	,modo_ingreso
	,ucaf
	,canal_trx
	,id_comercio
	,disponible1
	,disponible2
	,disponible3
	,disponible4
	,disponible5
	,disponible6
	,cod_resultado
	,detalle_investigacion
	,usuario_investigador
	,cod_institucion
	,fecha_investigacion
	,hora_investigacion
	,detectado_monitoreo
	,record_source
	,load_date
	,creation_user
from `master_risk.m_fraudes_externos`