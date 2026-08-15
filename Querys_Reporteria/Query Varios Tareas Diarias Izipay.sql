
Para Desencriptar informacion :

select 
  trim(AEAD.DECRYPT_STRING(c.key, a.direccion_comercio, c.constant))         as direccion_comercio,
  trim(AEAD.DECRYPT_STRING(d.key, a.telefono_comercio, d.constant))         as telefono_comercio,
  trim(AEAD.DECRYPT_STRING(e.key, a.nom_representante_legal, e.constant))   as nom_representante_legal, -- incluye apellido
  trim(AEAD.DECRYPT_STRING(f.key, a.correo_representante_legal, f.constant)) as correo_representante_legal,
  trim(AEAD.DECRYPT_STRING(z.key, a.razon_social, z.constant))              as razon_social,
  trim(AEAD.DECRYPT_STRING(b.key, a.num_cuenta_comercio, b.constant))       as cuenta_desencriptada,
  trim(AEAD.DECRYPT_STRING(g.key, a.correo_comercial, g.constant))          as correo_comercial
from prd-izipay-data-storage-pv.master_party.m_comercio a
left join prd-izipay-data-sensitive.secure_secrets.config_protected_data b on (1=1 and b.code = 'C_ACCOUNT_NUMBER')
left join prd-izipay-data-sensitive.secure_secrets.config_protected_data c on (1=1 and c.code = 'C_ADDRESS')
left join prd-izipay-data-sensitive.secure_secrets.config_protected_data d on (1=1 and d.code = 'C_TELEPHONE')
left join prd-izipay-data-sensitive.secure_secrets.config_protected_data e on (1=1 and e.code = 'C_FULL_NAME')
left join prd-izipay-data-sensitive.secure_secrets.config_protected_data f on (1=1 and f.code = 'C_EMAIL')
left join prd-izipay-data-sensitive.secure_secrets.config_protected_data z on (1=1 and z.code = 'C_FULL_NAME')
left join prd-izipay-data-sensitive.secure_secrets.config_protected_data g on (1=1 and g.code = 'C_FULL_NAME')


create or replace table dev-izipay-data-storage.mc2253.base_libro2_final as 
with aux_iden_party_data_control as (
  select
    party_id_izi,
    document_number
  from prd-izipay-data-storage-pv.mc2253.iden_party_data_control
  where flag_customer is true or flag_facilitador is true
  qualify row_number() over (partition by party_id_izi order by document_number desc ) = 1
),
aux_base_comercio as (
  select distinct
    party_id_izi_facilitador,
    flag_lpdp,
    correo_representante_legal
  from prd-izipay-data-storage-pv.master_party.m_comercio
)
select 
distinct
a.*
,trim(AEAD.DECRYPT_STRING(f.key, c.correo_representante_legal, f.constant)) as correo_representante_legal
,c.flag_lpdp
from dev-izipay-data-storage.mc2253.base_libro23 a
left join aux_iden_party_data_control b on (b.document_number = a.NRO_RUC)
left join aux_base_comercio c on (c.party_id_izi_facilitador = b.party_id_izi)
left join prd-izipay-data-storage-pv.mc2253.config_protected_data f on ( 1=1 and f.code = 'C_EMAIL' )


--#########################################################>>  DETALLE TRANSACCION ##############################################################################>>>>

case
   when metodo_de_pago in ('Apple Pay', 'Click to Pay') then metodo_de_pago
   when trim (PDTERM) = '00000007' then 'Codigo Yape'
   when trim (PDTERM) = '00000003' and trim (PDMETR) = 'EC' then 'Interbank App'
   when trim (pduser) = 'PAGOEFE' then 'Pago Efectivo'
   when trim (pdmetr) in ('PQ', 'QA') then 'Codigo QR'
   when trim (pduser) = 'PAYZEN' and trim (pdterm) = '78787878' then 'Link de Pago'
   when trim (pduser) = 'SMART' then 'Tap to Phone'
   when trim (pdorig) in ('CL', 'VD') then 'Boton de Pago'
   when trim (pdmetr) in ('CA', 'EC', 'MT', 'PV', 'VM', 'VU') then 'Boton de Pago'
   else 'POS' end as medio_trx


SELECT
  FORMAT_DATE('%Y%m', t.process_date) AS periodo,
  t.pdcest,
  p.nom_comercio,
  p.cod_situacion_comercio,
  p.desc_situacion_comercio,
  p.flag_comercio_activo,
  t.pdmcc,
  CASE
    WHEN p.compania = 'VENDEMAS' THEN 'VENDEMAS'
    WHEN t.pdmetr IN ('PQ','QA') THEN 'QR'
    WHEN t.pdmetr IN ('TP') THEN 'T2P'
    WHEN t.pdmcc = '6012' THEN 'EECC'
    WHEN t.pdmetr IN ('CA','EC','PV') THEN 'e-Commerce'
    ELSE 'POS'
  END AS tipo_comercios,
  CASE
    WHEN t.metodo_de_pago IN ('Apple Pay', 'Click to Pay') THEN t.metodo_de_pago
    WHEN TRIM(t.pdterm) = '00000007' THEN 'Código YAPE'
    WHEN TRIM(t.pdterm) = '00000003' AND TRIM(t.pdmetr) = 'EC' THEN 'Interbank App'
    WHEN TRIM(t.pduser) = 'PAGOEFE' THEN 'Pago Efectivo'
    WHEN TRIM(t.pdmetr) IN ('PQ', 'QA') THEN 'Código QR'
    WHEN TRIM(t.pduser) = 'PAYZEN' AND TRIM(t.pdterm) = '78787878' THEN 'Link de Pago'
    WHEN TRIM(t.pduser) = 'SMART' THEN 'Tap to Phone'
    WHEN TRIM(t.pdorig) IN ('CL', 'VD') THEN 'Botón de Pago'
    WHEN TRIM(t.pdmetr) IN ('CA', 'EC', 'MT', 'PV', 'VM', 'VU') THEN 'Botón de Pago'
    ELSE 'POS'
  END AS medio_trx,
  t.marca,
  t.tipo_emisor,
  CASE
    WHEN t.subtipo_tarjeta LIKE 'Débito%' THEN 'Débito'
    WHEN t.subtipo_tarjeta LIKE 'Crédit%' THEN 'Crédito'
    WHEN t.subtipo_tarjeta LIKE 'Prepag%' THEN 'Débito'
    ELSE t.subtipo_tarjeta
  END AS tipo_tarjeta,
  t.pdmetr,
  t.pdorig,
  CASE t.pdorig
    WHEN 'MP' THEN 'MPP'
    WHEN 'VD' THEN 'VISA DIRECT'
    WHEN 'CU' THEN 'CAPTURA UATP'
    WHEN 'CV' THEN 'CAPTURA VARIOS'
    WHEN 'CM' THEN 'CAPTURA MOTO'
    WHEN 'PW' THEN 'PUNTO WEB'
    WHEN 'CB' THEN 'CAPTURA BATCH'
    WHEN 'PR' THEN 'POS REGULARIZADO'
    WHEN 'PO' THEN 'POS'
    WHEN 'IA' THEN 'CAPTURA DE IATA'
    WHEN 'TS' THEN 'TRANSFERS SOLUTION'
    WHEN 'CF' THEN 'FINES'
    WHEN 'RW' THEN 'RECURRENTE SISTEMA WEB'
    WHEN 'PD' THEN 'POS DIGITADO'
    WHEN 'BR' THEN 'CAPTURA BANCO RECEPTOR'
    WHEN 'SP' THEN 'PAGOS RECURRENTES'
    WHEN 'CL' THEN 'CAPTURA EN LINEA'
    ELSE 'SIN ORIGEN'
  END AS desc_origen,
  t.filtro_trx,
  t.pdmone,
  SUM(t.cant_trx)          AS cant_trx,
  ROUND(SUM(t.importe), 2) AS importe_soles,
  t.pdtcam,
  t.pdimpo
FROM `prd-izipay-data-storage-pv.master_transaction.t_detalle_transacciones` t
INNER JOIN `prd-izipay-data-storage-pv.master_party.m_comercio` p
  ON t.pdcest = p.cod_comercio
WHERE t.pdmcc = '5964'
  AND t.process_date BETWEEN '2020-01-01' AND '2026-06-09'
  --AND t.filtro_trx IN ('Compras', 'Dev. Compras')
  --AND t.tipo_trx IN ('Comisionable')
--GROUP BY ALL
ORDER BY periodo, t.pdcest

--REPORTE USUARIA

SELECT   
t.process_date AS FECHA_TRX,
pdtarj as TARJETA_ENCRIPTADA,
pdauto as AUTORIZACION,
pdcest as COD_COMERCIO,
p.nom_comercio as NOMBRE_COMERCIO,
pdmone as cod_moneda,
ROUND(t.importe,2) AS importe_soles,
t.pdimpo as monto_Soles,
p.fecha_apertura_comercio,
  CASE
    WHEN t.metodo_de_pago IN ('Apple Pay', 'Click to Pay') THEN t.metodo_de_pago
    WHEN TRIM(t.pdterm) = '00000007' THEN 'Código YAPE'
    WHEN TRIM(t.pdterm) = '00000003' AND TRIM(t.pdmetr) = 'EC' THEN 'Interbank App'
    WHEN TRIM(t.pduser) = 'PAGOEFE' THEN 'Pago Efectivo'
    WHEN TRIM(t.pdmetr) IN ('PQ', 'QA') THEN 'Código QR'
    WHEN TRIM(t.pduser) = 'PAYZEN' AND TRIM(t.pdterm) = '78787878' THEN 'Link de Pago'
    WHEN TRIM(t.pduser) = 'SMART' THEN 'Tap to Phone'
    WHEN TRIM(t.pdorig) IN ('CL', 'VD') THEN 'Botón de Pago'
    WHEN TRIM(t.pdmetr) IN ('CA', 'EC', 'MT', 'PV', 'VM', 'VU') THEN 'Botón de Pago'
    ELSE 'POS'
  END AS MODO_TRX
FROM `prd-izipay-data-storage-pv.master_transaction.t_detalle_transacciones` t
LEFT JOIN `prd-izipay-data-storage-pv.master_party.m_comercio` p ON p.cod_comercio = t.pdcest
WHERE  t.process_date >= '2010-01-01'
and t.pdcest = '8922248'
order by t.process_date asc 


--#########################################################>>  ABONO DETALLE ##############################################################################>>>>

create or replace table dev-izipay-data-operation.mc2253.t_abono_detalle_libre as 
WITH aux_iden_party_data_control AS (
  SELECT
    party_id_izi,
    document_number
  FROM `prd-izipay-data-storage-pv.mc2253.iden_party_data_control`
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY party_id_izi
    ORDER BY document_number DESC
  ) = 1
)
SELECT
  a.*,
  b.document_number AS nro_documento,
  trim(AEAD.DECRYPT_STRING(q.key, a.cuenta_abono, q.constant)) as cuenta_abono_desencriptada,
  trim(AEAD.DECRYPT_STRING(z.key, mc.razon_social, z.constant)) as razon_social 
FROM `prd-izipay-data-storage-pv.master_financial.t_abono_detalle` a 
left join aux_iden_party_data_control b ON b.party_id_izi = a.party_id_izi
left join prd-izipay-data-storage-pv.master_party.m_comercio mc on (mc.cod_comercio = a.cod_comercio)
left join prd-izipay-data-storage-pv.mc2253.config_protected_data q on (1=1 and q.code = 'C_ACCOUNT_NUMBER')
left join prd-izipay-data-storage-pv.mc2253.config_protected_data z on ( 1=1 and z.code = 'C_FULL_NAME' )
where a.process_date >= '2025-01-01' --limit 10

select count(1) from `prd-izipay-data-storage-pv.master_financial.t_abono_detalle`
where process_date >= '2025-01-01'                                          154 881 329

select count(1) from dev-izipay-data-operation.mc2253.t_abono_detalle_libre; 154 881 329


CREATE OR REPLACE TABLE dev-izipay-data-storage.mc2253.temp_abono_detalle_csv AS
with aux_iden_party_data_control as (
  select
    party_id_izi,
    document_number
  from prd-izipay-data-storage-pv.mc2253.iden_party_data_control
  qualify row_number() over (partition by party_id_izi order by document_number desc ) = 1
)
SELECT
  a.process_date,
  a.itc_company_id,
  a.itc_company_name,
  flujo,
  producto,
  cod_comercio,
  cod_transaccion,
  fecha_proceso,
  cod_banco,
  tipo_pago,
  AEAD.DECRYPT_STRING(b.key, a.cuenta_abono, b.constant) as cuenta_abono,
  hash_cuenta_abono,
  AEAD.DECRYPT_STRING(b.key, a.cuenta_corriente, b.constant) as cuenta_corriente,
  hash_cta_corriente,
  cod_moneda,
  importe,
  comision_abono,
  igv_comision,
  neto_1,
  cobro_devolucion,
  neto_2,
  importe_retenido,
  neto_2_dolar,
  neto_3,
  tipo_cambio,
  fecha_abono,
  tipo_cuenta,
  pago_tercero,
  ruc_tercero,
  AEAD.DECRYPT_STRING(c.key, a.nombre_tercero, c.constant) as nombre_tercero,
  tipo_doc,
  tipo_ruc,
  d.document_number as nro_documento,
  situacion,
  usuario_actualiza,
  mensaje,
  fecha_abono_mod,
  nro_dias_abono,
  sist_comp_tercero,
  cantidad,
  fac_estab,
  fecha_abono_referencial,
  nombre_cheque,
  agrupacion_abonos,
  fuerza_cuenta,
  nro_archivo_abono,
  cci,
  tipo_doc_tercero,
  cuenta_especial,
  cod_padre,
  tipo_facilitador,
  cod_estab_abono,
  nombre_comercial,
  cod_facilitador,
  tipo_doc_identificador,
  tipo_pendiente,
  fecha_entrante_DCP,
  ajuste_DCP,
  motivo_DCP,
  observacion,
  impuesto_emisor,
  cod_dcp,
  ind_capt_proces,
  filtro_abono,
  importe_solarizado,
  dq_flag_ind,
  dq_control_msg,
  dq_config_id,
  cast(format_datetime('%Y-%m-%d %H:%M:%S', cast(a.start_date as datetime)) as string) as start_date,
  cast(format_datetime('%Y-%m-%d %H:%M:%S', cast(a.end_date as datetime)) as string) as end_date,
  flag_active,
  a.record_source,
  cast(format_datetime('%Y-%m-%d %H:%M:%S', cast(a.load_date as datetime)) as string) as load_date,
  a.creation_user,
  producto_abono_det,
  tipo_abono,
  detalle_abono,
  flujo_fuente,
  flag_abono_comercio,
  des_producto,
  nombre_banco,
  des_moneda,
  des_situacion
FROM `prd-izipay-data-storage-pv.master_financial.t_abono_detalle` a
inner join prd-izipay-data-storage-pv.mc2253.data_bk b on (1=1 and b.code = 'C_ACCOUNT_NUMBER')
inner join prd-izipay-data-storage-pv.mc2253.data_bk c on (1=1 and c.code = 'C_BUSINESS_NAME')
left join aux_iden_party_data_control d on (d.party_id_izi = a.party_id_izi)
WHERE a.process_date >= '2026-05-01'
  AND a.process_date <= '2026-05-31'

--> ABONO IBK


create or replace table prd-izipay-data-storage-pv.mc2253.base_hash_izipay as  
select num_cuenta_comercio as cuenta_encriptada,
trim(AEAD.DECRYPT_STRING(b.key, a.num_cuenta_comercio, b.constant))   as cuenta_desencriptada,
UPPER(TO_HEX(SHA256(UPPER(TO_HEX(SHA256(LPAD(TRIM(CAST(AEAD.DECRYPT_STRING(b.key, a.num_cuenta_comercio, b.constant) AS STRING)), 18, '0'))))))) AS hash_cta_corriente,
upper(cast(to_base64(sha256(upper(cast(to_base64(sha256(lpad(trim(AEAD.DECRYPT_STRING(b.key, a.num_cuenta_comercio, b.constant)),18,'0'))) as string)))) as string)) as hash_cta_corriente_antiguo
from prd-izipay-data-storage-pv.master_party.m_comercio a
left join prd-izipay-data-sensitive.secure_secrets.config_protected_data b on ( 1=1 and b.code = 'C_ACCOUNT_NUMBER' ) 
where num_cuenta_comercio is not null;


select count(1) from prd-izipay-data-storage-pv.mc2253.base_hash_izipay
select * from prd-izipay-data-storage-pv.mc2253.base_hash_izipay where cuenta_encriptada is not null limit 10

select distinct  cuenta_desencriptada from prd-izipay-data-storage-pv.mc2253.base_hash_izipay

select count(1),hash_cta_corriente
from prd-izipay-data-storage-pv.mc2253.base_hash_izipay
group by hash_cta_corriente
having count(1)>1

select * from prd-izipay-data-storage-pv.mc2253.base_hash_izipay
where hash_cta_corriente = 'D7CB8AD9680E7764EA1E384E1082AB10FEFEC8106B436FECBD72EF4CCBEC9F4E'


create table prd-izipay-data-storage-pv.mc2253.base_hash_izipay_distinct as 
select distinct hash_cta_corriente,cuenta_desencriptada from prd-izipay-data-storage-pv.mc2253.base_hash_izipay 


create table prd-izipay-data-storage-pv.mc2253.base_hash_izipay_quitar as 
select distinct hash_cta_corriente from (
select count(1),hash_cta_corriente
from prd-izipay-data-storage-pv.mc2253.base_hash_izipay_distinct
group by hash_cta_corriente
having count(1)>1 )

select * from prd-izipay-data-storage-pv.mc2253.base_hash_izipay
where hash_cta_corriente = '011F919F54B204AE837325B8AC5EE7D123EC97936C069064294EC4E2444EE6C3'

create table prd-izipay-data-storage-pv.mc2253.base_hash_izipay_distinct_final as 
select distinct hash_cta_corriente,cuenta_desencriptada from prd-izipay-data-storage-pv.mc2253.base_hash_izipay_distinct
where hash_cta_corriente not in ( select hash_cta_corriente from prd-izipay-data-storage-pv.mc2253.base_hash_izipay_quitar )


select count(1),hash_cta_corriente
from prd-izipay-data-storage-pv.mc2253.base_hash_izipay_distinct_final
group by hash_cta_corriente
having count(1)>1

select * from prd-izipay-data-storage-pv.mc2253.base_hash_izipay_distinct_final
where hash_cta_corriente = '001AC3C90ED3CF8400731DCC0C4D7ADC7A17AFB1FA8D90F94A9823A0CD2A0177'


select count(1),hash_id_izi
from `prd-izipay-data-storage-pv.mc2253.base_cliente` 
group by hash_id_izi
having count(1)>1

create or replace table dev-izipay-data-operation.mc2253.abonos_ibk_libre_actual as 
with aux_iden_party_data_control as (
  select
    hash_id_izi,
    document_number
  from `prd-izipay-data-storage-pv.mc2253.base_cliente`
  qualify row_number() over (partition by hash_id_izi order by party_id_izi desc) = 1
)
select
  a.*,
  d.document_number as inter_hash_emp_libre,
  e.document_number as inter_hash_id_doc_libre,
  f.cuenta_desencriptada
from `prd-izipay-data-storage-pv.raw_ibk.abonos_ibk` a
left join aux_iden_party_data_control d on (a.inter_hash_emp = d.hash_id_izi)
left join aux_iden_party_data_control e on (a.inter_hash_id_doc = e.hash_id_izi)
left join `prd-izipay-data-storage-pv.mc2253.base_hash_izipay_distinct_final` f on (a.inter_hash_id_nro_cta = f.hash_cta_corriente)
where a.process_date >= '2026-01-01' -->  32 449 110

select distinct cuenta_desencriptada from dev-izipay-data-operation.mc2253.abonos_ibk_libre_actual

select count(1),cuenta_desencriptada from dev-izipay-data-operation.mc2253.abonos_ibk_libre_actual -->  32 449 110
select count(1) from prd-izipay-data-storage-pv.raw_ibk.abonos_ibk where a.process_date>= '2026-01-01'  --> 32 449 110

--->>> reporte lyra -->>

with
comercio_data as (
  select
    cod_comercio,
    nom_comercio,
    correo_comercial,
    correo_representante_legal,
    nom_banco_pago_comercio,
    cod_situacion_comercio,
    desc_situacion_comercio,
    cod_segmento,
    segmento_parque,
    flag_lpdp,
    flag_parque,
    flag_lyra
  from `prd-izipay-data-storage-pv.master_party.m_comercio`
  qualify row_number() over (partition by cod_comercio order by process_date desc) = 1
)
select
  c.cod_comercio,
  c.nom_comercio                                                                              as nombre_comercial,
  trim(AEAD.DECRYPT_STRING(k_nombre.key, c.correo_comercial, k_nombre.constant))               as correo_comercial,  -- warning: en realidad es un NOMBRE, bug en el SP fuente (deberia ser ll.ccmai1, no ll.ccnomb)
  trim(AEAD.DECRYPT_STRING(k_email.key, c.correo_representante_legal, k_email.constant))       as correo_representante_legal,
  c.nom_banco_pago_comercio                                                                     as banco_abono,
  c.cod_situacion_comercio,
  c.desc_situacion_comercio,
  c.flag_lpdp,
  c.flag_parque,
  c.flag_lyra,
  case
    when c.segmento_parque in ('BC','BI','BE') then 'CORPORACIONES'
    when c.segmento_parque = 'BPE' then 'NEGOCIOS'
    when c.segmento_parque = 'RETAIL' then 'RETAIL'
    else 'SIN SEGMENTO'
  end as segmento_calculado
from comercio_data c
left join `prd-izipay-data-sensitive.secure_secrets.config_protected_data` k_nombre on (k_nombre.code = 'C_FULL_NAME')
left join `prd-izipay-data-sensitive.secure_secrets.config_protected_data` k_email  on (k_email.code  = 'C_EMAIL')
where c.flag_parque = true
  and c.flag_lyra = true
  and c.cod_situacion_comercio not in ('3','9')


-->>  script marca :

with ultimo_periodo_segmentacion as (
    select codigo, segmento
    from `prd-izipay-data-storage-pv.raw_dataentry_planeamiento.segmentacion`
    where periodo = (
        select max(periodo) 
        from `prd-izipay-data-storage-pv.raw_dataentry_planeamiento.segmentacion`
    )
)
select distinct
    c.document_number as RUC,
    -- AEAD.DECRYPT_STRING(e.key, a.correo_representante_legal, e.constant) as correo_representante_legal,
    -- AEAD.DECRYPT_STRING(t.key, a.telefono_comercio, t.constant) as telefono,
    seg.segmento,
    a.cod_situacion_comercio as situacion,
    a.flag_lpdp as flag_lpdp
from `prd-izipay-data-storage-pv.master_party.m_comercio` a
left join `dev-izipay-data-storage.master_pii.iden_party_data_control` c on (a.party_id_izi = c.party_id_izi)
left join `dev-izipay-data-storage.secure_secrets.config_protected_data` e on (1=1 and e.code = 'C_EMAIL')
left join `dev-izipay-data-storage.secure_secrets.config_protected_data` ec on (1=1 and ec.code = 'C_FULL_NAME')
left join `dev-izipay-data-storage.secure_secrets.config_protected_data` t on (1=1 and t.code = 'C_TELEPHONE')
left join ultimo_periodo_segmentacion seg on (a.cod_comercio = seg.codigo)
where a.cod_situacion_comercio not in ('3', '9')
    and a.cod_situacion_comercio is not null
    and a.compania in ('PMP','IZIPAY')
    and a.nom_producto not in ('CAJERO CORRESPONSAL','INTEROPERABILIDAD VISANET','VENDEMAS','IZIPAY YA')
    and a.flag_parque = true limit 100

-->> 

with aux_iden_party_data_control as (
  select
    party_id_izi,
    document_number
  from prd-izipay-data-sensitive.master_pii.iden_party_data_control
  qualify row_number() over (partition by party_id_izi order by document_number desc ) = 1
)
select 
    AEAD.DECRYPT_STRING(e.key, a.correo_representante_legal, e.constant) as correo_representante_legal,
    cod_comercio as codigo_comercio,
    c.document_number as RUC,
    a.flag_lpdp as flag_lpdp,
    a.cod_situacion_comercio as situacion_comercio  
from `prd-izipay-data-storage-pv.master_party.m_comercio` a
left join aux_iden_party_data_control c on (a.party_id_izi = c.party_id_izi)
left join `prd-izipay-data-sensitive.secure_secrets.config_protected_data` e on (1=1 and e.code = 'C_EMAIL')
where a.cod_situacion_comercio in ('1','7')
    and a.tipo_producto = 'VIRTUAL' 
    and a.flag_parque = true
    and a.compania in ('PMP','IZIPAY')
    and a.nom_producto NOT IN ('CAJERO CORRESPONSAL','INTEROPERABILIDAD VISANET','VENDEMAS','IZIPAY YA')

-->> case 

with segmentacion_actual as(
  select * 
    from prd-izipay-data-storage-pv.raw_dataentry_planeamiento.segmentacion 
    where periodo = (select max(periodo) 
                      from prd-izipay-data-storage-pv.raw_dataentry_planeamiento.segmentacion)
)
,base_ggee as(
    SELECT 
      right(trim(c.gsc_codigo_de_comercio__c),7) AS GSC_Shops__rXxXName
      ,CASE
        WHEN a.ip4i_razon_social__c IS NOT NULL THEN  a.ip4i_razon_social__c
        ELSE AEAD.DECRYPT_STRING(e.key, mcom.razon_social, e.constant)
        END AS GSC_Shops__rXxXIP4i_Raz_n_Soci__c
      ,trim(AEAD.DECRYPT_STRING(m.key,a.name, m.constant)) AS AccountXxXName
      ,trim(dc.document_number) AS AccountXxXIP4i_Nro_RUC__c
      ,trim(AEAD.DECRYPT_STRING(e.key,ow.name, e.constant)) AS AccountXxXOwnerXxXName
      ,trim(seg.banca) AS AccountXxXIZI_bancaIBK__c
      ,a.izi_volumenretail__c AS AccountXxXIZI_volumenRetail__c
      ,trim(AEAD.DECRYPT_STRING(e.key,ecs.name, e.constant)) AS AccountXxXIZI_Ejecutivo_Customer_Success__rXxXName
      ,CASE
        WHEN seg.segmento in ('BE','BI','BC') THEN 'CORPORACIONES'
        WHEN seg.segmento = 'BPE' THEN 'NEGOCIOS'
        WHEN seg.segmento = 'RETAIL' THEN 'RETAIL'
        ELSE 'SIN SEGMENTO' END AS GSC_AccountSegment__c
      ,trim(c.casenumber) AS CaseNumber
      ,trim(c.subject) AS Subject
      ,trim(c.izis_type__c) AS IZIS_Type__c
      ,trim(c.gsc_attentionlevel__c) AS GSC_AttentionLevel__c
      ,trim(c.estado_emailtocase__c) AS Estado_EmailToCase__c
      ,trim(c.origin) AS Origin
      ,trim(c.status) AS Status
      ,trim(c.motivo_de_consulta_izipay__c) AS Motivo_de_consulta_IZIPAY__c
      ,trim(c.servicio_de_comercio__c) AS Servicio_de_comercio__c
      ,trim(c.createddate) AS CreatedDate
      ,trim(c.lastmodifieddate) AS LastModifiedDate
      ,trim(AEAD.DECRYPT_STRING(e.key,ou.name, e.constant)) AS OwnerXxXName
      ,trim(ou.ip4i_unidad_de_negocio__c) AS IZI_unidad_de_negocio_del_propietario__c
      ,trim(c.contactid) AS ContactId
      ,trim(AEAD.DECRYPT_STRING(l.key,c.contactemail, l.constant)) AS ContactXxXEmail
      ,trim(c.izis_npsmail__c) AS Email
      ,trim(AEAD.DECRYPT_STRING(e.key,cby.name, e.constant)) AS CreatedByXxXName
      ,trim(cby.department) as CreatedByXxXDepartment
      ,trim(cby.CompanyName) as CreatedByXxXCompanyName
      ,trim(dep.name) as IZI_lookDepartamento__c
      ,trim(prov.name) as IZI_lookProvincia__c
      ,trim(dis.name) as IZI_lookDistrito__c
      ,trim(mcom.nom_comercio) as IZIS_NombreComercio__c
      ,trim(tc.asunto) as GSC_PrincipalSubject__c
    FROM prd-izipay-data-storage-pv.raw_salesforce.case c
    LEFT JOIN prd-izipay-data-storage-pv.raw_salesforce.account a ON trim(c.accountid) = trim(a.id)
    LEFT JOIN prd-izipay-data-storage-pv.raw_salesforce.user ow ON trim(a.ownerid) = trim(ow.id)
    LEFT JOIN prd-izipay-data-storage-pv.raw_salesforce.user ecs ON trim(a.izi_ejecutivo_customer_success__c) = trim(ecs.id)
    LEFT JOIN prd-izipay-data-storage-pv.raw_salesforce.user ou ON trim(c.ownerid) = trim(ou.id)
    LEFT JOIN prd-izipay-data-storage-pv.raw_salesforce.user cby ON trim(c.createdbyid) = trim(cby.id)
    LEFT JOIN prd-izipay-data-storage-pv.raw_salesforce.contactpointaddress cpa on trim(cpa.id) = trim(c.gsc_contact_point_address__c)
    LEFT JOIN prd-izipay-data-storage-pv.raw_salesforce.ip4i_departamento__c dep on trim(cpa.ip4i_departamento__c) = trim(dep.id)
    LEFT JOIN prd-izipay-data-storage-pv.raw_salesforce.ip4i_distritos__c dis on trim(cpa.ip4i_distritos__c) = trim(dis.id)
    LEFT JOIN prd-izipay-data-storage-pv.raw_salesforce.ip4i_provincia__c prov on trim(cpa.ip4i_provincia__c) = trim(prov.id)
    LEFT JOIN prd-izipay-data-storage-pv.master_party.m_comercio mcom ON right(trim(c.gsc_codigo_de_comercio__c),7) = trim(mcom.cod_comercio)
    LEFT JOIN prd-izipay-data-storage-pv.raw_dataentry_cx.sf_tipo_caso tc on c.gsc_principalsubject__c = tc.gsc_principalsubject__c
    LEFT JOIN prd-izipay-data-sensitive.secure_secrets.config_protected_data e ON (1=1 and e.code = 'C_FULL_NAME')
    LEFT JOIN prd-izipay-data-sensitive.secure_secrets.config_protected_data m ON (1=1 and m.code = 'C_LAST_NAME')
    LEFT JOIN prd-izipay-data-sensitive.secure_secrets.config_protected_data l ON (1=1 and l.code = 'C_EMAIL')
    LEFT JOIN segmentacion_actual seg ON right(trim(c.gsc_codigo_de_comercio__c),7) = trim(seg.codigo)
    LEFT JOIN prd-izipay-data-sensitive.master_pii.iden_party_data_control dc ON a.party_id_izi = dc.party_id_izi
    WHERE
      --upper(a.IP4i_Cartera__c) in('CORPORACIONES', 'GRANDES EMPRESAS') 
        trim(ou.ip4i_unidad_de_negocio__c) IN ('Soporte Tecnico Izipay', 'Soporte Comercial Izipay', 'Ecommerce', 
    'Actualización de Datos', 'Agente Izipay', 'Retiro Inmediato', 'Soporte de Cambios', 'Arisale', 'Cajero Corresponsal')
        and c.status = 'Closed'
        and origin in ('email2case', 'Correo electrónico', 'Ejecutivo por correo', 
    'email2caseSC', 'email2caseGE', 'email2caseAC', 'Correo electronico')
        and date(TIMESTAMP_SUB(TIMESTAMP(PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%S+00', c.closeddate)),INTERVAL 5 HOUR)) = '2026-05-07'
)select
distinct
  *
  from base_ggee
  where lower(Email) not like '%@izipay.pe' or lower(Email) not like '%@covisian.com'
  order by 1 asc
  

el archivo resultante de query_webinar_silvia que se llame: base_webinar_experiencia_yyyymm.
el archivo resultante de query_webinar_silvia que se llame: base_webinar_marca_yyyymm.
 
ambos separados por ";". en la ruta de cs: Experiencia al cliente/Base Webinar/YYYY/MM y Marca/Base Webinar/YYYY/MM

-->> silvia - experiencia -->>

-->> dev -->> 

with segmentacion as (
        select codigo, segmento
        from prd-izipay-data-storage-pv.raw_dataentry_planeamiento.segmentacion
        where periodo =(select max(periodo) from prd-izipay-data-storage-pv.raw_dataentry_planeamiento.segmentacion)
)   select 
    distinct
    trim(c.document_number) as RUC,
    trim(AEAD.DECRYPT_STRING(ec.key, a.razon_social, ec.constant))  as razon_social,
    --AEAD.DECRYPT_STRING(e.key, a.correo_representante_legal, e.constant)  as correo_representante_legal,
    case
        when  AEAD.DECRYPT_STRING(t.key, tel.cctel1, t.constant) is not null then trim(AEAD.DECRYPT_STRING(t.key, tel.cctel1, t.constant))
        else trim(AEAD.DECRYPT_STRING(t.key, a.telefono_comercio, t.constant)) 
    end as telefono_representante,
    seg.segmento as segmento,
    case 
      when seg.segmento in ('BC','BI','BE') then 'CORPO'
      when seg.segmento = 'BPE' then 'NEGOCIOS'
      when seg.segmento = 'RETAIL' then 'RETAIL'
      else 'SIN SEGMENTO' end as segmento_calculado,
      a.cod_situacion_comercio as situacion,
      a.flag_lpdp as flag_lpdp
    from prd-izipay-data-storage-pv.master_party.m_comercio a
        LEFT JOIN prd-izipay-data-storage-pv.raw_as400.mcfm020o tel on trim(a.cod_comercio) = trim(tel.cccest)
        LEFT JOIN prd-izipay-data-storage-pv.master_pii.iden_party_data_control c on (a.party_id_izi = c.party_id_izi)
        --LEFT JOIN prd-izipay-data-sensitive.master_pii.iden_party_data_control c on (a.party_id_izi = c.party_id_izi)
        --LEFT JOIN `dev-izipay-data-storage.mc2053.data_bk` e on (e.code = 'C_EMAIL')
        LEFT JOIN `dev-izipay-data-storage.mc2053.data_bk` ec on (ec.code = 'C_FULL_NAME')--C_FULL_NAME
        LEFT JOIN `dev-izipay-data-storage.mc2053.data_bk` t on (t.code = 'C_TELEPHONE')
        LEFT JOIN segmentacion seg on a.cod_comercio = seg.codigo
        --filtros parque 
    where a.cod_situacion_comercio not in ('3', '9')
    and a.cod_situacion_comercio is not null
    and a.compania in ('PMP','IZIPAY')
    and a.nom_producto NOT IN ('CAJERO CORRESPONSAL',
        'INTEROPERABILIDAD VISANET',
        'VENDEMAS','IZIPAY YA')
    and a.flag_parque = true

select count(1) from prd-izipay-data-storage-pv.master_pii.iden_party_data_control limit 10

-->> prod -->> 

with segmentacion as(
        select codigo, segmento
        from prd-izipay-data-storage-pv.raw_dataentry_planeamiento.segmentacion
        where periodo =(select max(periodo) fromprd-izipay-data-storage-pv.raw_dataentry_planeamiento.segmentacion)
)   select 
    distinct
    trim(c.document_number) as RUC,
    trim(AEAD.DECRYPT_STRING(ec.key, a.razon_social, ec.constant))  as razon_social,
    --AEAD.DECRYPT_STRING(e.key, a.correo_representante_legal, e.constant)  as correo_representante_legal,
    case
        when  AEAD.DECRYPT_STRING(t.key, tel.cctel1, t.constant) is not null then trim(AEAD.DECRYPT_STRING(t.key, tel.cctel1, t.constant))
        else trim(AEAD.DECRYPT_STRING(t.key, a.telefono_comercio, t.constant)) 
    end as telefono_representante,
    seg.segmento as segmento,
    case 
      when seg.segmento in ('BC','BI','BE') then 'CORPO'
      when seg.segmento = 'BPE' then 'NEGOCIOS'
      when seg.segmento = 'RETAIL' then 'RETAIL'
      else 'SIN SEGMENTO' end as segmento_calculado,
      a.cod_situacion_comercio as situacion,
      a.flag_lpdp as flag_lpdp
    from prd-izipay-data-storage-pv.master_party.m_comercio a
        LEFT JOIN prd-izipay-data-storage-pv.raw_as400.mcfm020o tel on trim(a.cod_comercio) = trim(tel.cccest)
        LEFT JOIN prd-izipay-data-sensitive.master_pii.iden_party_data_control c on (a.party_id_izi = c.party_id_izi)
        --LEFT JOIN `dev-izipay-data-storage.mc2053.data_bk` e on (e.code = 'C_EMAIL')
        LEFT JOIN `dev-izipay-data-storage.mc2053.data_bk` ec on (ec.code = 'C_FULL_NAME')--C_FULL_NAME
        LEFT JOIN `dev-izipay-data-storage.mc2053.data_bk` t on (t.code = 'C_TELEPHONE')
        LEFT JOIN segmentacion seg on a.cod_comercio = seg.codigo
        --filtros parque 
    where a.cod_situacion_comercio not in ('3', '9')
    and a.cod_situacion_comercio is not null
    and a.compania in ('PMP','IZIPAY')
    and a.nom_producto NOT IN ('CAJERO CORRESPONSAL',
        'INTEROPERABILIDAD VISANET',
        'VENDEMAS','IZIPAY YA')
    and a.flag_parque = true


--->>>>> marca-->>>>>>><<

-->> dev -->> 
with segmentacion as(
        select codigo, segmento
        from prd-izipay-data-storage-pv.raw_dataentry_planeamiento.segmentacion
        where periodo =(select max(periodo) from prd-izipay-data-storage-pv.raw_dataentry_planeamiento.segmentacion)
)select 
    distinct
    trim(c.document_number) as RUC,
    trim(AEAD.DECRYPT_STRING(ec.key, a.razon_social, ec.constant))  as razon_social,
    trim(AEAD.DECRYPT_STRING(e.key, a.correo_representante_legal, e.constant))  as correo_representante_legal,
    /*case
        when  AEAD.DECRYPT_STRING(t.key, tel.cctel1, t.constant) is not null then AEAD.DECRYPT_STRING(t.key, tel.cctel1, t.constant)
        else AEAD.DECRYPT_STRING(t.key, a.telefono_comercio, t.constant) 
    end as telefono_representante,*/
    seg.segmento as segmento,
    case 
      when seg.segmento in ('BC','BI','BE') then 'CORPO'
      when seg.segmento = 'BPE' then 'NEGOCIOS'
      when seg.segmento = 'RETAIL' then 'RETAIL'
      else 'SIN SEGMENTO' end as segmento_calculado,
      a.cod_situacion_comercio as situacion,
      a.flag_lpdp as flag_lpdp
    from prd-izipay-data-storage-pv.master_party.m_comercio a
        --LEFT JOIN prd-izipay-data-storage-pv.raw_as400.mcfm020o tel on trim(a.cod_comercio) = trim(tel.cccest)
        LEFT JOIN prd-izipay-data-storage-pv.master_pii.iden_party_data_control c on (a.party_id_izi = c.party_id_izi)
        --LEFT JOIN prd-izipay-data-sensitive.master_pii.iden_party_data_control c on (a.party_id_izi = c.party_id_izi)
        LEFT JOIN `dev-izipay-data-storage.mc2053.data_bk` e on (e.code = 'C_EMAIL')
        LEFT JOIN `dev-izipay-data-storage.mc2053.data_bk` ec on (ec.code = 'C_FULL_NAME')--C_FULL_NAME
        --LEFT JOIN `dev-izipay-data-storage.mc2053.data_bk` t on (t.code = 'C_TELEPHONE')
        LEFT JOIN segmentacion seg on a.cod_comercio = seg.codigo
        --filtros parque 
    where a.cod_situacion_comercio not in ('3', '9')
    and a.cod_situacion_comercio is not null
    and a.compania in ('PMP','IZIPAY')
    and a.nom_producto NOT IN ('CAJERO CORRESPONSAL',
        'INTEROPERABILIDAD VISANET',
        'VENDEMAS','IZIPAY YA')
    and a.flag_parque = true


-->> prod -->> 

with segmentacion as(
        select codigo, segmento
        from prd-izipay-data-storage-pv.raw_dataentry_planeamiento.segmentacion
        where periodo =(select max(periodo) fromprd-izipay-data-storage-pv.raw_dataentry_planeamiento.segmentacion)
)select 
    distinct
    trim(c.document_number) as RUC,
    trim(AEAD.DECRYPT_STRING(ec.key, a.razon_social, ec.constant))  as razon_social,
    trim(AEAD.DECRYPT_STRING(e.key, a.correo_representante_legal, e.constant))  as correo_representante_legal,
    /*case
        when  AEAD.DECRYPT_STRING(t.key, tel.cctel1, t.constant) is not null then AEAD.DECRYPT_STRING(t.key, tel.cctel1, t.constant)
        else AEAD.DECRYPT_STRING(t.key, a.telefono_comercio, t.constant) 
    end as telefono_representante,*/
    seg.segmento as segmento,
    case 
      when seg.segmento in ('BC','BI','BE') then 'CORPO'
      when seg.segmento = 'BPE' then 'NEGOCIOS'
      when seg.segmento = 'RETAIL' then 'RETAIL'
      else 'SIN SEGMENTO' end as segmento_calculado,
      a.cod_situacion_comercio as situacion,
      a.flag_lpdp as flag_lpdp
    from prd-izipay-data-storage-pv.master_party.m_comercio a
        --LEFT JOIN prd-izipay-data-storage-pv.raw_as400.mcfm020o tel on trim(a.cod_comercio) = trim(tel.cccest)
        LEFT JOIN prd-izipay-data-sensitive.master_pii.iden_party_data_control c on (a.party_id_izi = c.party_id_izi)
        LEFT JOIN `dev-izipay-data-storage.mc2053.data_bk` e on (e.code = 'C_EMAIL')
        LEFT JOIN `dev-izipay-data-storage.mc2053.data_bk` ec on (ec.code = 'C_FULL_NAME')--C_FULL_NAME
        --LEFT JOIN `dev-izipay-data-storage.mc2053.data_bk` t on (t.code = 'C_TELEPHONE')
        LEFT JOIN segmentacion seg on a.cod_comercio = seg.codigo
        --filtros parque 
    where a.cod_situacion_comercio not in ('3', '9')
    and a.cod_situacion_comercio is not null
    and a.compania in ('PMP','IZIPAY')
    and a.nom_producto NOT IN ('CAJERO CORRESPONSAL',
        'INTEROPERABILIDAD VISANET',
        'VENDEMAS','IZIPAY YA')
    and a.flag_parque = true


--> 



with ultimo_periodo_segmentacion as (
    select codigo, segmento
    from `prd-izipay-data-storage-pv.raw_dataentry_planeamiento.segmentacion`
    where periodo = (
        select max(periodo) 
        from `prd-izipay-data-storage-pv.raw_dataentry_planeamiento.segmentacion`
    )
)
select 
cod_comercio
,trim(AEAD.DECRYPT_STRING(f.key, a.correo_representante_legal, f.constant)) as correo_representante_legal
,trim(AEAD.DECRYPT_STRING(g.key, a.correo_gerente_gen_comercio, g.constant)) as correo_comercial
,nom_comercio
,cod_banco_pago_comercio
,nom_banco_pago_comercio -->> solo interbank
,cod_situacion_comercio
,seg.segmento
,CASE
    WHEN seg.segmento IN ('BC', 'BE', 'BI') THEN 'Corporaciones'
    WHEN seg.segmento IN ('BPE', 'RETAIL') THEN 'Negocios'
    ELSE NULL
END AS clasificacion_segmento
,flag_lpdp
from prd-izipay-data-storage-pv.master_party.m_comercio a
left join prd-izipay-data-storage-pv.mc2253.data_bk f on ( 1=1 and f.code = 'C_EMAIL' )
left join prd-izipay-data-storage-pv.mc2253.data_bk g on ( 1=1 and g.code = 'C_EMAIL' )
left join ultimo_periodo_segmentacion seg on (a.cod_comercio = seg.codigo)
where a.cod_situacion_comercio  in ('1')
and a.compania in ('PMP','IZIPAY')
and a.nom_producto NOT IN ('CAJERO CORRESPONSAL','INTEROPERABILIDAD VISANET','VENDEMAS','IZIPAY YA')
and a.flag_parque = true
and a.cod_banco_pago_comercio = '5' -->> INTERBANK


-->> nps canales 

with segmentacion_actual as(
  select *
    from prd-izipay-data-storage-pv.raw_dataentry_planeamiento.segmentacion
    where periodo = (select max(periodo)
                      from prd-izipay-data-storage-pv.raw_dataentry_planeamiento.segmentacion)
)
,base_ggee as(
    SELECT
      right(trim(c.gsc_codigo_de_comercio__c),7) AS GSC_Shops__rXxXName
      --,CASE
   --     WHEN a.ip4i_razon_social__c IS NOT NULL THEN  a.ip4i_razon_social__c
   --     ELSE AEAD.DECRYPT_STRING(e.key, mcom.razon_social, e.constant)
  --      END AS GSC_Shops__rXxXIP4i_Raz_n_Soci__c
   --   ,trim(AEAD.DECRYPT_STRING(m.key,a.name, m.constant)) AS AccountXxXName
      ,trim(dc.document_number) AS AccountXxXIP4i_Nro_RUC__c
  --    ,trim(AEAD.DECRYPT_STRING(e.key,ow.name, e.constant)) AS AccountXxXOwnerXxXName
      ,trim(seg.banca) AS AccountXxXIZI_bancaIBK__c
      ,a.izi_volumenretail__c AS AccountXxXIZI_volumenRetail__c
  --    ,trim(AEAD.DECRYPT_STRING(e.key,ecs.name, e.constant)) AS AccountXxXIZI_Ejecutivo_Customer_Success__rXxXName
      ,CASE
        WHEN seg.segmento in ('BE','BI','BC') THEN 'CORPORACIONES'
        WHEN seg.segmento = 'BPE' THEN 'NEGOCIOS'
        WHEN seg.segmento = 'RETAIL' THEN 'RETAIL'
        ELSE 'SIN SEGMENTO' END AS GSC_AccountSegment__c
      ,trim(c.casenumber) AS CaseNumber
      ,trim(c.subject) AS Subject
      ,trim(c.izis_type__c) AS IZIS_Type__c
      ,trim(c.gsc_attentionlevel__c) AS GSC_AttentionLevel__c
      ,trim(c.estado_emailtocase__c) AS Estado_EmailToCase__c
      ,trim(c.origin) AS Origin
      ,trim(c.status) AS Status
      ,trim(c.motivo_de_consulta_izipay__c) AS Motivo_de_consulta_IZIPAY__c
      ,trim(c.servicio_de_comercio__c) AS Servicio_de_comercio__c
      --,trim(c.createddate) AS CreatedDate
      --,trim(c.lastmodifieddate) AS LastModifiedDate
      ,format_timestamp('%d/%m/%Y %H:%M:%S',timestamp(trim(c.createddate)),'America/Lima') as CreatedDate
      ,format_timestamp('%d/%m/%Y %H:%M:%S',timestamp(trim(c.lastmodifieddate)),'America/Lima') as LastModifiedDate
     -- ,trim(AEAD.DECRYPT_STRING(e.key,ou.name, e.constant)) AS OwnerXxXName
      ,trim(ou.ip4i_unidad_de_negocio__c) AS IZI_unidad_de_negocio_del_propietario__c
      ,trim(c.contactid) AS ContactId
     -- ,trim(AEAD.DECRYPT_STRING(l.key,c.contactemail, l.constant)) AS ContactXxXEmail
      ,trim(c.izis_npsmail__c) AS Email
    --  ,trim(AEAD.DECRYPT_STRING(e.key,cby.name, e.constant)) AS CreatedByXxXName
      ,trim(cby.department) as CreatedByXxXDepartment
      ,trim(cby.CompanyName) as CreatedByXxXCompanyName
      ,trim(dep.name) as IZI_lookDepartamento__c
      ,trim(prov.name) as IZI_lookProvincia__c
      ,trim(dis.name) as IZI_lookDistrito__c
      ,trim(mcom.nom_comercio) as IZIS_NombreComercio__c
      ,trim(tc.asunto) as GSC_PrincipalSubject__c
      --> Nuevos campos -->>
      ,format_timestamp('%d/%m/%Y %H:%M:%S',timestamp(c.closeddate),'America/Lima') as closeddate
    --  ,trim(AEAD.DECRYPT_STRING(l.key,d.suppliedemail, l.constant)) SuppliedEmail
    FROM prd-izipay-data-storage-pv.raw_salesforce.case c
    LEFT JOIN prd-izipay-data-storage-pv.raw_salesforce.case d ON trim(d.id) = trim(c.ParentId)
    LEFT JOIN prd-izipay-data-storage-pv.raw_salesforce.account a ON trim(c.accountid) = trim(a.id)
    LEFT JOIN prd-izipay-data-storage-pv.raw_salesforce.user ow ON trim(a.ownerid) = trim(ow.id)
    LEFT JOIN prd-izipay-data-storage-pv.raw_salesforce.user ecs ON trim(a.izi_ejecutivo_customer_success__c) = trim(ecs.id)
    LEFT JOIN prd-izipay-data-storage-pv.raw_salesforce.user ou ON trim(c.ownerid) = trim(ou.id)
    LEFT JOIN prd-izipay-data-storage-pv.raw_salesforce.user cby ON trim(c.createdbyid) = trim(cby.id)
    LEFT JOIN prd-izipay-data-storage-pv.raw_salesforce.contactpointaddress cpa on trim(cpa.id) = trim(c.gsc_contact_point_address__c)
    LEFT JOIN prd-izipay-data-storage-pv.raw_salesforce.ip4i_departamento__c dep on trim(cpa.ip4i_departamento__c) = trim(dep.id)
    LEFT JOIN prd-izipay-data-storage-pv.raw_salesforce.ip4i_distritos__c dis on trim(cpa.ip4i_distritos__c) = trim(dis.id)
    LEFT JOIN prd-izipay-data-storage-pv.raw_salesforce.ip4i_provincia__c prov on trim(cpa.ip4i_provincia__c) = trim(prov.id)
    LEFT JOIN prd-izipay-data-storage-pv.master_party.m_comercio mcom ON right(trim(c.gsc_codigo_de_comercio__c),7) = trim(mcom.cod_comercio)
    LEFT JOIN prd-izipay-data-storage-pv.raw_dataentry_cx.sf_tipo_caso tc on c.gsc_principalsubject__c = tc.gsc_principalsubject__c
   -- LEFT JOIN prd-izipay-data-sensitive.secure_secrets.config_protected_data e ON (1=1 and e.code = 'C_FULL_NAME')
   -- LEFT JOIN prd-izipay-data-sensitive.secure_secrets.config_protected_data m ON (1=1 and m.code = 'C_LAST_NAME')
   -- LEFT JOIN prd-izipay-data-sensitive.secure_secrets.config_protected_data l ON (1=1 and l.code = 'C_EMAIL')
    LEFT JOIN segmentacion_actual seg ON right(trim(c.gsc_codigo_de_comercio__c),7) = trim(seg.codigo)
    LEFT JOIN prd-izipay-data-storage-pv.mc2253.base_cliente dc ON a.party_id_izi = dc.party_id_izi
    WHERE trim(ou.ip4i_unidad_de_negocio__c) = 'Grandes Empresas'
     and c.status = 'Closed'
     and c.origin in ('email2case', 'Correo electrónico','Correo electronico' , 'Ejecutivo por correo','email2caseSC', 'email2caseGE', 'email2caseAC', 'Correo electronico')
     and date(TIMESTAMP_SUB(TIMESTAMP(PARSE_TIMESTAMP('%Y-%m-%d %H:%M:%S+00', c.closeddate)),INTERVAL 5 HOUR)) >= DATE '{var_fecha_ini}'
    -- and trim(AEAD.DECRYPT_STRING(e.key,cby.name, e.constant)) != 'Platform Integration User'
     and trim(tc.asunto) != 'Transferencias y Llamadas Vicio'
)select
distinct
  *
  from base_ggee
  where lower(SuppliedEmail) not like '%@izipay.pe' or lower(Email) not like '%@covisian.com'
  order by 1 asc


--> base terminales :


/*
Del Activo (POS):
Número de serie 
Número de caja 
ID Activo 
Marca 
Modelo 
Estado actual del activo 

Del Terminal:
Terminal ID 
Estado del terminal 

Del Comercio:
Código de comercio 
Estado del comercio 
*/

select * from prd-izipay-data-storage-pv.master_product.m_terminal

select distinct modelo_terminal_mcc,modelo_terminal_general,modelo_terminal_especifico from prd-izipay-data-storage-pv.master_product.m_terminal
modelo_terminal_mcc
modelo_terminal_general

select 
num_serie_real
,marca
,modelo_terminal_especifico
,situacion_as400 
-- terminal --
,estado_terminal
,fecha_ult_trx_financiera
-- comercio --
,cod_comercio
,estado_comercio
from prd-izipay-data-storage-pv.master_product.m_terminal


select 
COUNT(1)
from prd-izipay-data-storage-pv.master_product.m_terminal --1 058 885 -->> William Cipriani -> 

-->> base potencial



select count(1),process_date
from prd-izipay-data-storage-pv.bi_apm.dv_potencial_cuenta 
group by process_date
order by process_date desc 


SELECT
    FORMAT_DATE('%Y%m', process_date) AS periodo,
    dpto,
    mcc,
    giro,
    vertical,
    facilitador,
    marca,
    tarjeta,
    SUM(importe_total_izipay) AS suma_importe_total_izipay,
    SUM(mercado_estimado_final) AS suma_mercado_estimado_final
FROM `prd-izipay-data-storage-pv.bi_apm.dv_potencial_cuenta`
WHERE FORMAT_DATE('%Y%m', process_date) >= '202401'
GROUP BY
    periodo,
    dpto,
    mcc,
    giro,
    vertical,
    facilitador,
    marca,
    tarjeta
ORDER BY
    periodo DESC ;

---> trimestre -->>

1. Trimestral (Q1, Q2, Q3, Q4)
BigQuery tiene la función EXTRACT(QUARTER FROM date), así que puedes construir el periodo como año + trimestre:

SELECT
    CONCAT(EXTRACT(YEAR FROM process_date), 'T', EXTRACT(QUARTER FROM process_date)) AS periodo,
    dpto,
    mcc,
    giro,
    vertical,
    facilitador,
    marca,
    tarjeta,
    tipoproducto,
    SUM(importe_total_izipay) AS suma_importe_total_izipay,
    SUM(mercado_estimado_final) AS suma_mercado_estimado_final
FROM `prd-izipay-data-storage-pv.bi_apm.dv_potencial_cuenta`
WHERE FORMAT_DATE('%Y%m', process_date) >= '202401'
GROUP BY
    periodo,
    dpto,
    mcc,
    giro,
    vertical,
    facilitador,
    marca,
    tarjeta,
    tipoproducto
ORDER BY
    periodo DESC;


--2. Semestral (S1, S2)
--No hay función nativa para semestre, así que lo calculas con el mes:

SELECT
    CONCAT(
        EXTRACT(YEAR FROM process_date),
        'S',
        CASE WHEN EXTRACT(MONTH FROM process_date) <= 6 THEN 1 ELSE 2 END
    ) AS periodo,
    dpto,
    mcc,
    giro,
    vertical,
    facilitador,
    marca,
    tarjeta,
	tipoproducto,
    SUM(importe_total_izipay) AS suma_importe_total_izipay,
    SUM(mercado_estimado_final) AS suma_mercado_estimado_final
FROM `prd-izipay-data-storage-pv.bi_apm.dv_potencial_cuenta`
WHERE FORMAT_DATE('%Y%m', process_date) >= '202401'
GROUP BY
    periodo,
    dpto,
    mcc,
    giro,
    vertical,
    facilitador,
    marca,
    tarjeta,
	tipoproducto
ORDER BY
    periodo DESC;

--3. Anual
--Aquí simplemente usas el año:


SELECT
    EXTRACT(YEAR FROM process_date) AS periodo,
    dpto,
    mcc,
    giro,
    vertical,
    facilitador,
    marca,
    tarjeta,
	tipoproducto,
    SUM(importe_total_izipay) AS suma_importe_total_izipay,
    SUM(mercado_estimado_final) AS suma_mercado_estimado_final
FROM `prd-izipay-data-storage-pv.bi_apm.dv_potencial_cuenta`
WHERE FORMAT_DATE('%Y%m', process_date) >= '202401'
GROUP BY
    periodo,
    dpto,
    mcc,
    giro,
    vertical,
    facilitador,
    marca,
    tarjeta,
	tipoproducto
ORDER BY
    periodo DESC;


-->> 

with segmentacion_actual as(
  select *
    from prd-izipay-data-storage-pv.raw_dataentry_planeamiento.segmentacion
    where periodo = (select max(periodo)
                      from prd-izipay-data-storage-pv.raw_dataentry_planeamiento.segmentacion)
)
  select
        distinct
        trim(c.document_number) as RUC,
        trim(AEAD.DECRYPT_STRING(r.key, a.razon_social, r.constant))  as razon_social,
        trim(AEAD.DECRYPT_STRING(e.key, a.correo_representante_legal, e.constant))  as correo_representante_legal,
        seg.segmento,
        case
            when seg.segmento in ('BC','BI','BE') then 'CORPO'
            when seg.segmento = 'BPE' then 'NEGOCIOS'
            when seg.segmento = 'RETAIL' then 'RETAIL'
            else 'SIN SEGMENTO' end as segmento_calculado,
        a.cod_situacion_comercio as situacion,
        a.flag_lpdp as flag_lpdp,
  from prd-izipay-data-storage-pv.master_party.m_comercio a
  LEFT JOIN segmentacion_actual seg on a.cod_comercio = seg.codigo
  LEFT JOIN prd-izipay-data-sensitive.master_pii.iden_party_data_control c on (a.party_id_izi_facilitador = c.party_id_izi)
  LEFT JOIN `prd-izipay-data-sensitive.secure_secrets.config_protected_data` e on (e.code = 'C_EMAIL')
  LEFT JOIN `prd-izipay-data-sensitive.secure_secrets.config_protected_data` r on (r.code = 'C_FULL_NAME')
  INNER join prd-izipay-data-storage-pv.raw_salesforce.account acc on trim(a.party_id_izi_facilitador) = trim(acc.party_id_izi)
  where a.cod_situacion_comercio not in ('3', '9')
        and a.cod_situacion_comercio is not null
        and a.compania in ('PMP','IZIPAY')
        and a.nom_producto NOT IN ('CAJERO CORRESPONSAL',
            'INTEROPERABILIDAD VISANET',
            'VENDEMAS','IZIPAY YA')
        and a.flag_parque = true
        and a.cod_banco_pago_comercio in ('3', '5')
        and a.fecha_apertura_comercio >= '2026-06-01' and a.fecha_apertura_comercio <= '2026-06-30'
        and (c.flag_customer = true or c.flag_facilitador = true)
        and acc.Excuela__c = 'false'

--> reporte recupero 

    select
    distinct
    trim(cast(b.ruc as string)) as RUC,
    a.cod_comercio,
    AEAD.DECRYPT_STRING(e.key, a.correo_representante_legal, e.constant)  as correo_representante_legal,
    AEAD.DECRYPT_STRING(t.key, a.telefono_comercio, t.constant) as telefono,
    seg.segmento as segmento,
    case
      when seg.segmento in ('BC','BI','BE') then 'CORPO'
      when seg.segmento = 'BPE' then 'NEGOCIOS'
      when seg.segmento = 'RETAIL' then 'RETAIL'
      else 'SIN SEGMENTO' end as segmento_calculado,
      a.cod_situacion_comercio as situacion,
      a.flag_lpdp as flag_lpdp
    from prd-izipay-data-operation.mc2253.recupero_2_dias b
        LEFT JOIN prd-izipay-data-sensitive.master_pii.iden_party_data_control c on (trim(cast(b.ruc as string)) = c.document_number)
        LEFT JOIN prd-izipay-data-storage-pv.master_party.m_comercio a on c.party_id_izi = a.party_id_izi_facilitador
        LEFT JOIN `prd-izipay-data-sensitive.secure_secrets.config_protected_data` e on (e.code = 'C_EMAIL')
        LEFT JOIN `prd-izipay-data-sensitive.secure_secrets.config_protected_data` t on (t.code = 'C_TELEPHONE')
        LEFT JOIN prd-izipay-data-storage-pv.raw_dataentry_planeamiento.segmentacion seg on a.cod_comercio = seg.codigo and seg.periodo = '202607'
        --filtros parque
    where (c.flag_customer = true or c.flag_facilitador = true)

--> abono feriado 

select
distinct
trim(c.document_number) as RUC,
trim(AEAD.DECRYPT_STRING(ec.key, a.razon_social, ec.constant)) as razon_social,
case
  when a.flag_pago_adelantado = true then 'T+1'
  else 'T+2'
end as tipo_abono,
case
  when a.flag_pptr = true then 'PTTR'
  else 'NO PTTR'
end as flag_pptr,
trim(AEAD.DECRYPT_STRING(e.key, a.correo_representante_legal, e.constant)) as correo_representante_legal,
--AEAD.DECRYPT_STRING(t.key, a.telefono_comercio, t.constant) as telefono,
seg.segmento as segmento,
case
  when seg.segmento in ('BC','BI','BE') then 'CORPO'
  when seg.segmento = 'BPE' then 'NEGOCIOS'
  when seg.segmento = 'RETAIL' then 'RETAIL'
  else 'SIN SEGMENTO' end as segmento_calculado,
a.cod_situacion_comercio as situacion,
a.flag_lpdp as flag_lpdp
from prd-izipay-data-storage-pv.master_party.m_comercio a
  LEFT JOIN prd-izipay-data-sensitive.master_pii.iden_party_data_control c on (a.party_id_izi_facilitador = c.party_id_izi)
  LEFT JOIN prd-izipay-data-sensitive.secure_secrets.config_protected_data e on (e.code = 'C_EMAIL')
  LEFT JOIN prd-izipay-data-sensitive.secure_secrets.config_protected_data ec on (ec.code = 'C_FULL_NAME')--C_FULL_NAME
  LEFT JOIN prd-izipay-data-sensitive.secure_secrets.config_protected_data t on (t.code = 'C_TELEPHONE')
  LEFT JOIN prd-izipay-data-storage-pv.raw_dataentry_planeamiento.segmentacion seg on a.cod_comercio = seg.codigo and seg.periodo = '202607'
  --filtros parque
where a.cod_situacion_comercio not in ('3', '9')
and a.cod_situacion_comercio is not null
and a.compania in ('PMP','IZIPAY')
and a.nom_producto NOT IN ('CAJERO CORRESPONSAL',
  'INTEROPERABILIDAD VISANET',
  'VENDEMAS','IZIPAY YA')
and a.flag_parque = true
and (c.flag_customer = true or c.flag_facilitador = true)


--> plan de toques 

with
comercio_afiliados as (
  select
    cod_comercio,
    nom_comercio,
    tipo_producto,
    nom_producto,
    flag_arisale,
    cod_giro_comercio,
    nom_giro_comercio,
    fecha_apertura_comercio
  from `prd-izipay-data-storage-pv.master_party.m_comercio`
  qualify row_number() over (partition by cod_comercio order by process_date desc) = 1
),

comercio_cohorte as (
  select
    cod_comercio,
    nom_comercio,
    tipo_producto,
    nom_producto,
    flag_arisale,
    case when flag_arisale then 'ARISALE' else nom_producto end as detalle_producto,  -- prioriza arisale sobre el nombre de producto fisico/virtual
    cod_giro_comercio,
    nom_giro_comercio,
    fecha_apertura_comercio                              as fecha_afiliacion,
    date_add(fecha_apertura_comercio, interval 29 day)    as fecha_fin_ventana_analisis
  from comercio_afiliados
  --where --fecha_apertura_comercio >= date '2026-05-29'
   -- and date_add(fecha_apertura_comercio, interval 29 day) <= current_date('America/Lima')
),

detalle_transacciones as (
  select
    t.pdcest             as cod_comercio,
    t.process_date        as fecha_transaccion,
    round(t.importe, 2)   as monto_soles,
    t.pdimpo              as monto_moneda_origen,
    t.pdmone               as cod_moneda,
    t.pdmcc                 as cod_giro_trx,     -- giro a nivel de la transaccion (puede diferir del giro maestro del comercio)
    t.pdprod                as cod_producto_trx,  -- warning: codigo, requiere tabla de equivalencia para nombre legible
    t.pdsubp                as cod_subproducto_trx,
    t.tipo_qr                as tipo_qr,           -- estatico / dinamico, aplica solo a trx qr
    t.origen_qr               as origen_qr,        -- ej. PMPPOS; canal de origen del qr
    t.cant_trx                 as num_transacciones,
    t.filtro_trx                as estado_trx        -- warning: sin mapeo definido para "estado de transaccion (aprobada/anulada/reversada)"
  from `prd-izipay-data-storage-pv.master_transaction.t_detalle_transacciones` t
  inner join comercio_cohorte c on (t.pdcest = c.cod_comercio)
  where t.process_date between c.fecha_afiliacion and c.fecha_fin_ventana_analisis
    and t.process_date >= '2015-01-01'
)

select
  d.cod_comercio,
  c.nom_comercio,
  c.tipo_producto,
  c.detalle_producto,
  c.flag_arisale,
  c.nom_giro_comercio       as giro,
  --c.cod_giro_comercio        as cod_giro,
  c.fecha_afiliacion,
  d.fecha_transaccion,
  d.monto_soles,
  --d.monto_moneda_origen,
  --d.cod_moneda,
  --d.cod_giro_trx,
  --d.cod_producto_trx,
  --d.cod_subproducto_trx,
  --d.tipo_qr,
  --d.origen_qr,
  d.num_transacciones,
  d.estado_trx
from detalle_transacciones d
inner join comercio_cohorte c on (d.cod_comercio = c.cod_comercio)
where d.cod_comercio in (select TRIM(cast(COD_COMERCIO as string)) from dev-izipay-data-storage.mc2253.base_comercio_plan_toques_validar)
order by d.cod_comercio, d.fecha_transaccion 

--> reporte lyra :

Necesito un reporte en base a una ficha enviada : 

with
comercio_data as (
  select
    cod_comercio,
    nom_comercio,
    correo_comercial,
    correo_representante_legal,
    nom_banco_pago_comercio,
    cod_situacion_comercio,
    desc_situacion_comercio,
    cod_segmento,
    segmento_parque,
    flag_lpdp,
    flag_parque,
    flag_lyra
  from `prd-izipay-data-storage-pv.master_party.m_comercio`
  qualify row_number() over (partition by cod_comercio order by process_date desc) = 1
)
select
  c.cod_comercio,
  c.nom_comercio                                                                              as nombre_comercial,
  trim(AEAD.DECRYPT_STRING(k_nombre.key, c.correo_comercial, k_nombre.constant))               as correo_comercial,  -- warning: en realidad es un NOMBRE, bug en el SP fuente (deberia ser ll.ccmai1, no ll.ccnomb)
  trim(AEAD.DECRYPT_STRING(k_email.key, c.correo_representante_legal, k_email.constant))       as correo_representante_legal,
  c.nom_banco_pago_comercio                                                                     as banco_abono,
  c.cod_situacion_comercio,
  c.desc_situacion_comercio,
  c.flag_lpdp,
  c.flag_parque,
  c.flag_lyra,
  case
    when c.segmento_parque in ('BC','BI','BE') then 'CORPORACIONES'
    when c.segmento_parque = 'BPE' then 'NEGOCIOS'
    when c.segmento_parque = 'RETAIL' then 'RETAIL'
    else 'SIN SEGMENTO'
  end as segmento_calculado
from comercio_data c
left join `prd-izipay-data-sensitive.secure_secrets.config_protected_data` k_nombre on (k_nombre.code = 'C_FULL_NAME')
left join `prd-izipay-data-sensitive.secure_secrets.config_protected_data` k_email  on (k_email.code  = 'C_EMAIL')
where c.flag_parque = true
  and c.flag_lyra = true
  and c.cod_situacion_comercio not in ('3','9')


  --->> query para buscar en la m_comercio por documento de identidad -->> 
with
cte_llaves as (
  select
    max(case when code = 'C_EMAIL'     then key      end) as email_key,
    max(case when code = 'C_EMAIL'     then constant end) as email_const,
    max(case when code = 'C_FULL_NAME' then key      end) as nombre_key,
    max(case when code = 'C_FULL_NAME' then constant end) as nombre_const
  from `prd-izipay-data-sensitive.secure_secrets.config_protected_data`
  where code in ('C_EMAIL', 'C_FULL_NAME')
),
cte_comercio as (
  select
    party_id_izi,
    cod_comercio,
    nom_comercio,
    cod_segmento,
    segmento_parque,
    correo_representante_legal,
    correo_comercial,
    nom_ejecutivo_kam,
    nom_responsable_cuenta
  from `prd-izipay-data-storage-pv.master_party.m_comercio`
),
cte_documentos as (
  select distinct trim(documento)  as documento
  from prd-izipay-data-operation.mc2253.subida_tarifas
  where documento is not null
),
aux_iden_party_data_control as (
  select
    party_id_izi,
    document_number
  from prd-izipay-data-storage-pv.mc2253.base_cliente --prd-izipay-data-storage-pv.mc2253.iden_party_data_control
  where flag_customer is true or flag_facilitador is true
  qualify row_number() over (partition by party_id_izi order by document_number desc ) = 1
)
select
  a.cod_comercio                                                                        as cod_comercio,
  a.nom_comercio                                                                        as nombre_comercial,
  c.documento                                                                           as documento,
  case
    when a.segmento_parque in ('BC', 'BI', 'BE') then 'CORPORACIONES'
    when a.segmento_parque = 'BPE'                then 'NEGOCIOS'
    when a.segmento_parque = 'RETAIL'             then 'RETAIL'
    else 'SIN SEGMENTO'
  end                                                                                    as segmento,
  trim(SAFE.AEAD.DECRYPT_STRING(k.email_key,  a.correo_representante_legal, k.email_const))                                     as correo_representante_legal,
  trim(SAFE.AEAD.DECRYPT_STRING(k.nombre_key, a.correo_comercial, k.nombre_const))                                              as correo_comercial,
  trim(SAFE.AEAD.DECRYPT_STRING(k.nombre_key, a.nom_ejecutivo_kam, k.nombre_const))                                             as nombre_kam
from cte_comercio a
inner join aux_iden_party_data_control b on (a.party_id_izi = b.party_id_izi)
inner join cte_documentos c on (c.documento = b.document_number)
cross join cte_llaves k

-->> busqueda para por cod_comercio
  
with
-- llaves de desencriptado (solo las 2 que se usan: email y nombre)
cte_llaves as (
  select
    max(case when code = 'C_EMAIL'     then key      end) as email_key,
    max(case when code = 'C_EMAIL'     then constant end) as email_const,
    max(case when code = 'C_FULL_NAME' then key      end) as nombre_key,
    max(case when code = 'C_FULL_NAME' then constant end) as nombre_const
  from `prd-izipay-data-sensitive.secure_secrets.config_protected_data`
  where code in ('C_EMAIL', 'C_FULL_NAME')
),

-- listado de comercios ya cargado
cte_documentos as (
  select distinct trim(documento) cod_comercio_num
  from prd-izipay-data-operation.mc2253.subida_tarifas
  where documento is not null
),

-- ultima foto por comercio, solo columnas que pide la ficha
cte_comercio as (
  select
    cod_comercio,
    nom_comercio,
    cod_segmento,
    segmento_parque,
    correo_representante_legal,
    correo_comercial,
    nom_ejecutivo_kam,
    nom_responsable_cuenta
  from `prd-izipay-data-storage-pv.master_party.m_comercio`
  qualify row_number() over (partition by cod_comercio order by process_date desc) = 1
)

select
  a.cod_comercio                                                                        as cod_comercio,
  a.nom_comercio                                                                         as nombre_comercial,
  case
    when a.segmento_parque in ('BC', 'BI', 'BE') then 'CORPORACIONES'
    when a.segmento_parque = 'BPE'                then 'NEGOCIOS'
    when a.segmento_parque = 'RETAIL'             then 'RETAIL'
    else 'SIN SEGMENTO'
  end                                                                                    as segmento,
  trim(SAFE.AEAD.DECRYPT_STRING(k.email_key,  a.correo_representante_legal, k.email_const))                                     as correo_representante_legal,
  trim(SAFE.AEAD.DECRYPT_STRING(k.nombre_key, a.correo_comercial, k.nombre_const))                                              as correo_comercial,
  trim(SAFE.AEAD.DECRYPT_STRING(k.nombre_key, a.nom_ejecutivo_kam, k.nombre_const))                                             as nombre_kam
from cte_comercio a
inner join cte_documentos d on (a.cod_comercio = d.cod_comercio_num)
cross join cte_llaves k



