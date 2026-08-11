CREATE OR REPLACE PROCEDURE `prd-izipay-data-operation.master_stage_party.prc_load_master_m_comercio`(var_project_operation STRING, var_project_storage STRING, var_project_sensitive STRING)
BEGIN

  declare query STRING;
  declare var_process_date DATE;
  declare var_process_date_ini DATE;
  declare var_process_date_fin DATE;
  
  /*
  declare var_project_operation STRING;
  declare var_project_storage STRING;
  declare var_project_sensitive STRING;

  set var_project_operation = 'prd-izipay-data-operation';
  set var_project_storage = 'prd-izipay-data-storage-pv';
  set var_project_sensitive = 'prd-izipay-data-sensitive';
  */

  
  declare var_dataset_master_party STRING;
  declare var_dataset_raw_as400 STRING;
  declare var_dataset_master_pii STRING;
  declare var_dataset_raw_dataentry_planeamiento STRING;
  declare var_dataset_raw_dataentry_finanzas STRING;
  declare var_dataset_raw_dataentry_data STRING;
  declare var_dataset_secure_secrets STRING;
  declare var_table_m_comercio STRING;
  declare var_table_mcfm015 STRING;
  declare var_table_iden_party_data_control STRING;
  declare var_table_mcfv002 STRING;
  declare var_table_mcft168 STRING;
  declare var_table_mcfm004 STRING;
  declare var_table_mcfm019i STRING;
  declare var_table_mcfm029 STRING;
  declare var_table_mcfm027 STRING;
  declare var_table_mcfv075 STRING;
  declare var_table_segmentacion STRING;
  declare var_table_grupo_economico STRING;
  declare var_table_com_no_domiciliado STRING;
  declare var_table_mcfv030 STRING;
  declare var_table_config_protected_data STRING;
  declare var_table_mcfv012 STRING;
  declare var_table_mcfv014 STRING;
  declare var_table_mcfm602 STRING;
  declare var_table_mcfv004 STRING;
  declare var_table_mcfm020 STRING;
  declare var_table_mcfm021 STRING;
  declare var_table_mcfv068 STRING;
  declare var_table_mcfv1001 STRING;
  declare var_table_mcfs114 STRING;
  declare var_table_mcfm024 STRING;
  declare var_table_mcfs922 STRING;
  declare var_table_c_facilitador STRING;
  declare var_table_mcfm020o STRING;

  
  set var_dataset_master_party = 'master_party';
  set var_dataset_raw_as400 = 'raw_as400';
  set var_dataset_master_pii = 'master_pii';
  set var_dataset_raw_dataentry_planeamiento = 'raw_dataentry_planeamiento';
  set var_dataset_raw_dataentry_finanzas = 'raw_dataentry_finanzas';
  set var_dataset_raw_dataentry_data = 'raw_dataentry_data';
  set var_dataset_secure_secrets = 'secure_secrets';
  set var_table_m_comercio = 'm_comercio';
  set var_table_mcfm015 = 'mcfm015';
  set var_table_iden_party_data_control = 'iden_party_data_control';
  set var_table_mcfv002 = 'mcfv002';
  set var_table_mcft168 = 'mcft168';
  set var_table_mcfm004 = 'mcfm004';
  set var_table_mcfm019i = 'mcfm019i';
  set var_table_mcfm029 = 'mcfm029';
  set var_table_mcfm027 = 'mcfm027';
  set var_table_mcfv075 = 'mcfv075';
  set var_table_segmentacion = 'segmentacion';
  set var_table_grupo_economico = 'grupo_economico';
  set var_table_com_no_domiciliado = 'com_no_domiciliado';
  set var_table_mcfv030 = 'mcfv030';
  set var_table_config_protected_data = 'config_protected_data';
  set var_table_mcfv012 = 'mcfv012';
  set var_table_mcfv014 = 'mcfv014';
  set var_table_mcfm602 = 'mcfm602';
  set var_table_mcfv004 = 'mcfv004';
  set var_table_mcfm020 = 'mcfm020';
  set var_table_mcfm021 = 'mcfm021';
  set var_table_mcfv068 = 'mcfv068';
  set var_table_mcfv1001 = 'mcfv1001';
  set var_table_mcfs114 = 'mcfs114';
  set var_table_mcfm024 = 'mcfm024';
  set var_table_mcfs922 = 'mcfs922';
  set var_table_c_facilitador = 'c_facilitador';
  set var_table_mcfm020o = 'mcfm020o';

  set var_process_date = current_date('America/Lima')-1;
  set var_process_date_ini = date_trunc(var_process_date, month);
  set var_process_date_fin = last_day(var_process_date);


  SET query = """
    truncate table `"""||var_project_storage||"""."""||var_dataset_master_party||"""."""||var_table_m_comercio||"""` 
  """;
  EXECUTE IMMEDIATE(query);


  SET query = """
    insert into `"""||var_project_storage||"""."""||var_dataset_master_party||"""."""||var_table_m_comercio||"""` 
    (
      process_date,
      periodo,
      cod_comercio,
      cod_facilitador,
      compania,
      cod_situacion_comercio,
      desc_situacion_comercio,
      party_id_izi,
      cod_tipo_documento,
      tipo_documento,
      subtipo_documento,
      party_id,
      party_id_izi_facilitador,
      tipo_documento_facilitador,
      subtipo_documento_facilitador,
      cod_segmento,
      nom_comercio,
      razon_social,
      moneda_comercio,
      cod_giro_comercio,
      cod_grupo_giro_comercio,
      nom_giro_comercio,
      situacion_visa_credito,
      situacion_mastercard_credito,
      situacion_diners,
      situacion_amex,
      situacion_visa_debito,
      situacion_mastercard_debito,
      com_visa_credito,
      com_mastercard_credito,
      com_diners,
      com_amex,
      com_visa_debito,
      com_mastercard_debito,
      com_fee_visa_credito,
      com_fee_mastercard_credito,
      com_fee_diners,
      com_fee_amex,
      com_fee_visa_debito,
      com_fee_mastercard_debito,
      com_foranea_visa_credito,
      com_foranea_mastercard_credito,
      com_foranea_diners,
      com_foranea_amex,
      com_foranea_visa_debito,
      com_foranea_mastercard_debito,
      cod_contrato,
      cod_cadena_comercio,
      region_comercio,
      cod_responsable_cuenta,
      nom_responsable_cuenta,
      cod_ejecutivo_kam,
      cod_dealer,
      razon_social_dealer,
      cod_dealer_ejecutivo,
      nom_ejecutivo_dealer,
      nom_ejecutivo_kam,
      direccion_comercio,
      departamento_comercio,
      provincia_comercio,
      distrito_comercio,
      referencia_comercio,
      ubigeo_comercio,
      cod_postal_comercio,
      telefono_comercio,
      fax_comercio,
      cod_clasificacion_riesgo,
      fecha_apertura_comercio,
      fecha_modificacion_comercio,
      fecha_bloqueo_comercio,
      cod_bloqueo_comercio,
      detalle_bloqueo_comercio,
      cod_banco_pago_comercio,
      nom_banco_pago_comercio,
      tipo_cuenta_comercio,
      num_cuenta_comercio,
      nom_representante_cheque,
      nom_via_comercio,
      nom_via_oficina,
      cod_grupo_economico_comercio,
      nom_grupo_economico_comercio,
      cod_centro_comercial,
      nom_centro_comercial,
      cod_equipo_multicomercio,
      cod_equipo_multimoneda,
      party_id_izi_representante,
      tipo_comercio,
      tipo_prueba_pos,
      nom_facilitador_servicio,
      cod_facilitador_pagos,
      comision_porc_dcc,
      party_id_izi_cajero_corresponsal,
      nom_cajero_corresponsal,
      nom_facilitador_pagos,
      tipo_documento_tercero,
      party_id_izi_tercero,
      nom_tercero,
      cod_usuario_sistema,
      pag_web_comercio,
      cuadrante,
      tel_app_izipay,
      fecha_afiliacion_arisale,
      fecha_afiliacion_pptr,
      cod_multi_comercio,
      direccion_oficina,
      departamento_oficina,
      provincia_oficina,
      distrito_oficina,
      referencia_oficina,
      ubigeo_oficina,
      cod_postal_oficina,
      fecha_ult_compra,
      correo_comercial,
      nom_representante_legal,
      correo_representante_legal,
      nom_gerente_gen_comercio,
      correo_gerente_gen_comercio,
      cod_serie_equipo_multicomercio,
      cod_situacion_dcc,
      desc_situacion_dcc,
      nom_producto,
      tipo_producto,
      tipo_region,
      segmento_parque,
      grupo_economico,
      cod_amex,
      nom_cont_fact_elect,
      dir_cont_fact_elect,
      correo_fact_elect,
      telefono_oficina,
      fax_oficina,
      correo_operador_proceso,
      correo_representante_proceso,
      tipo_facilitador,
      nom_dealer_general,
      cant_terminal_pos_mcp_total,
      cant_terminal_pos_jockey,
      cant_terminales_dial,
      cant_terminales_cel_fijo,
      cant_terminales_cel_movil,
      cant_terminales_ip,
      cant_terminales_lan,
      cant_terminales_cip,
      cant_terminales_cpp,
      flag_parque,
      flag_genera_ingreso,
      flag_1uit,
      flag_12uit,
      flag_40uit,
      flag_60uit,
      flag_pago_terceros,
      flag_pago_adelantado,
      flag_multimoneda,
      flag_pre_autorizacion,
      flag_digitacion_manual,
      flag_tarjeta_prepago,
      flag_opcion_correo,
      flag_opcion_telefono,
      flag_tarjeta_no_show,
      flag_cargo_recurrente,
      flag_pos_virtual,
      flag_opc_ecommerce,
      flag_canje_puntos,
      flag_mpos,
      flag_pago_rapido,
      flag_propina,
      flag_canje_puntos_sbp,
      flag_canje_puntos_ibk,
      flag_canje_puntos_mr,
      flag_canje_puntos_rp,
      flag_canje_puntos_comp,
      flag_canje_puntos_ppoint,
      flag_canje_puntos_cuenta_sueldo,
      flag_verificacion_tarjeta,
      flag_exoneracion_portes,
      flag_delivery,
      flag_dcc,
      flag_cobro_manten_cuenta,
      flag_envio_duas,
      flag_lyra,
      flag_micro_visa,
      flag_micro_mastercard,
      flag_izi_virtual,
      flag_pago_deuda,
      flag_arisale,
      flag_pptr,
      flag_izipay_ya,
      flag_no_domiciliado,
      flag_comercio_activo,
      flag_lpdp,
      flag_monitoreo,
      flag_riesgo_visa_mc,
      flag_riesgo_sbs,
      flag_bloqueo_fraude,
      flag_fraude_riesgo,
      flag_fraude_cumplimiento,
      record_source,
      load_date,
      creation_user
    )
    with temp_mcfm015 as 
    (
      select 
        party_id_izi,
        ructes,
        rursoc
      from `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfm015||"""`
      /*where pgtipo = 'RUTDOI'*/
      group by all 
      QUALIFY ROW_NUMBER() OVER (PARTITION BY party_id_izi ORDER BY ructes  DESC) = 1 
    ), temp_mcfm015_2 as
    (
      select 
        party_id_izi,
        rursoc
      from `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfm015||"""`
      group by all 
      QUALIFY ROW_NUMBER() OVER (PARTITION BY party_id_izi ORDER BY rursoc  DESC) = 1 
    ), temp_iden_party_data_control as
    (
      select 
        party_id_izi,
        party_id,
        identification_document_type_id,
        identification_document_type,
        identification_document_subtype,
        document_number,
        flag_lpdp
      from `"""||var_project_sensitive||"""."""||var_dataset_master_pii||"""."""||var_table_iden_party_data_control||"""`
      group by all 
      QUALIFY ROW_NUMBER() OVER (PARTITION BY party_id_izi ORDER BY party_id  DESC) = 1 
    ), temp_mcfv002 as
    (
      select 
        cetcta,
        cectct,
        cecest
      from `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfv002||"""`
      QUALIFY ROW_NUMBER() OVER (PARTITION BY cecest ORDER BY cetcta  DESC) = 1 
    ), temp_mcfv002_tercero as
    (
      select 
        cecest,
        cetdot,
        party_id_izi_tercero,
        ceprod,
        cenomt,
        cepagt
      from `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfv002||"""`
      QUALIFY ROW_NUMBER() OVER (PARTITION BY cecest ORDER BY ceprod  ASC) = 1 
    ), temp_mcft168 as
    (
      select 
        tbcodigo,
        tbcodtbl,
        tbdeslar
      from `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcft168||"""`
      QUALIFY ROW_NUMBER() OVER (PARTITION BY tbcodigo,tbcodtbl ORDER BY tbdeslar  DESC) = 1 
    ), temp_mcfm004 as
    (
      select 
        mcoterm,
        mcocest,
      from `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfm004||"""`
      QUALIFY ROW_NUMBER() OVER (PARTITION BY mcocest ORDER BY mcoterm  DESC) = 1 
    ), mcfv1001_v2 as
    (
      select  
        trim(pfpfid) as pfpfid 
      from `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfv1001||"""`
      group by all
    ), temp_nom_producto as 
    (
      select
        a.mecest,
        case
          when d.pfpfid is not null then 'FACILITADOR VIRTUAL'
          when c.metapp = 'TK' or (trim(b1.memraf) = 'IY0002' and left(b1.mecest,1) = '9') then 'IZIPAY YA'
          when a.mepfid = '253254' then 'VENDEMAS'
          when left(trim(a.mecest), 1) = '3' then 'CAJERO CORRESPONSAL'
          when left(trim(a.mecest), 1) = '5' and trim(a.mepfid) <> '253357' then 'CARGO RECURRENTE'
          when left(trim(a.mecest), 2) = '45'then 'PC NET'
          when left(trim(a.mecest), 2) = '47'then 'INTEROPERABILIDAD VISANET'
          when left(trim(a.mecest), 2) in ('40', '48') and (trim(b1.meprly) <> '' or left(upper(trim(a.mencon)), 3) in ('CPI', 'PCI') or trim(a.mencon) = 'PCLICKIZI') then 'PAGO CLICK'
          when left(trim(a.mecest), 2) in ('40', '48')then 'COMERCIO ELECTRONICO'
          when left(trim(a.mecest), 2) = '80' and trim(a.mepfid) <> '253357' then 'MOTO'
          when left(trim(a.mecest), 2) = '81' and trim(a.mepfid) <> '253357' then 'MPOS'
          when trim(a.mepfid) = '253357' and (upper(trim(oo.pgdesc)) like '%MPOS%' or upper(trim(oo.pgdesc)) = 'IZI JR IZIPLUS') then 'IZI JR'
          when trim(a.mepfid) = '253357' and (upper(trim(oo.pgdesc)) like 'IZIPAY POS FISICO%' or upper(trim(oo.pgdesc)) = 'POS') then 'IZI LINK'
          when trim(a.mepfid) = '253357' and (upper(trim(oo.pgdesc)) like '%IZIPRINT%' or upper(trim(oo.pgdesc)) = 'IZIPAY IZIPRINT') then 'IZI PRINT'
          when trim(a.mepfid) = '253357' and (upper(trim(oo.pgdesc)) like '%SMART%' or upper(trim(oo.pgdesc)) = 'IZIPAY IZISMART') then 'IZI SMART'
          when trim(a.mepfid) = '253357' and upper(trim(oo.pgdesc)) = 'P2 LITE SE' then 'IZI ANDROID P2 LITE SE'
          when trim(a.mepfid) = '253357' and upper(trim(oo.pgdesc)) like '%IZI ANDROID MAX SE%' then 'IZI ANDROID P2 SE'
          when trim(a.mepfid) = '253357' and (upper(trim(oo.pgdesc)) like '%DX8000%' or upper(trim(oo.pgdesc)) like 'CAJERO%' or (upper(trim(oo.pgdesc)) like '%ANDROID%' and upper(trim(oo.pgdesc)) like '%PLUS%')) then 'IZI ANDROID DX8000'
          when trim(a.mepfid) = '253357' and (upper(trim(oo.pgdesc)) like '%P2MINI%' or upper(trim(oo.pgdesc)) like '%ANDROID%')then 'IZI ANDROID P2MINI'
          when trim(a.mepfid) = '253357' and upper(trim(oo.pgdesc)) like '%PAX D200%' then 'IZI PAX'
          when trim(a.mepfid) = '253357' and (upper(trim(oo.pgdesc)) like '%IZIPAY ECOMMERCE%' or upper(trim(oo.pgdesc)) in ('COMERCIO ELECTRONICO', 'BOTON DE PAGO APP', 'LINK DE PAGO', 'LINK DE PAGO PW 2.0')) then 'IZI ECOMMERCE'
          
          when trim(a.mepfid) = '253357' and upper(trim(a.mencon)) = 'ONEAPP' and (c.metapp <> 'TK' or c.metapp is null) then 'ONE APP'
          when trim(a.mepfid) = '253357' and upper(trim(oo.pgdesc)) = 'IZIPAY APP + SPEAKER' then 'IZI PARLANTE'
          when trim(a.mepfid) = '253357' and (upper(trim(oo.pgdesc)) = 'IZIPAY APP' or upper(trim(a.mencon)) like 'APP%') then 'IZI APP'
          when trim(a.mepfid) = '253357' and upper(trim(oo.pgdesc)) like '%ONLINE PAGINA WEB%' then 'IZI ONLINE PAGINA WEB'
          when trim(a.mepfid) = '253357' and upper(trim(oo.pgdesc)) like '%ONLINE PASARELA%' then 'IZI ONLINE PASARELA'
          when trim(a.mepfid) = '253357' and upper(trim(oo.pgdesc)) like '%IZIONLINE + WIX%' then 'IZI WIX'
          when trim(a.mepfid) = '253357' and upper(trim(oo.pgdesc)) like '%IZIPAY WEB BY WIX%' then 'IZI WEB BY WIX'
          when trim(a.mepfid) = '253357' and upper(trim(oo.pgdesc)) = 'APP ARISALE' then 'IZI ARISALE'
          when trim(a.mepfid) = '253357' and upper(trim(oo.pgdesc)) like '%SCAN%'then 'IZI SCAN'
          else 'POS FISICO' end as nom_producto
      from `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfm019i||"""` a
      left join `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfm029||"""` c on a.mecest = c.mecest
      left join `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfm027||"""` b1 on a.mecest = b1.mecest 
      left join `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfv075||"""` oo on b1.mecond = oo.pgcodi and oo.pgtipo = 'IACOND'
      left join mcfv1001_v2 d on (a.mepfid = d.pfpfid and d.pfpfid not in ('253254','253357'))
      group by all
      QUALIFY ROW_NUMBER() OVER (PARTITION BY a.mecest order by 2 desc) = 1 
    ), aux_segmentacion as 
    (
      select 
        max(process_date) as process_date
      from `"""||var_project_storage||"""."""||var_dataset_raw_dataentry_planeamiento||"""."""||var_table_segmentacion||"""`
    ), temp_segmentacion as 
    (
      select 
        b.party_id_izi,
        upper(trim(a.segmento)) as segmento
        /*ifnull(nullif(upper(trim(segmento)),''),'RETAIL') as segmento*/
      from `"""||var_project_storage||"""."""||var_dataset_raw_dataentry_planeamiento||"""."""||var_table_segmentacion||"""` a
      left join temp_iden_party_data_control b on trim(a.nro_ruc) = b.document_number
      inner join aux_segmentacion c on (a.process_date = c.process_date)
      where b.party_id_izi is not null
      group by all
      QUALIFY ROW_NUMBER() OVER (PARTITION BY b.party_id_izi ORDER BY count(1) DESC) = 1 
    ), aux_grupo_economico as 
    (
      select 
        max(process_date) as process_date
      from `"""||var_project_storage||"""."""||var_dataset_raw_dataentry_planeamiento||"""."""||var_table_grupo_economico||"""` a
    ), temp_grupo_economico as 
    (
      select 
        trim(ruc) as document_number,
        a.grupo_economico
      from `"""||var_project_storage||"""."""||var_dataset_raw_dataentry_planeamiento||"""."""||var_table_grupo_economico||"""` a
      inner join aux_grupo_economico b on (a.process_date = b.process_date)
      where a.grupo_economico IS NOT NULL
        and a.grupo_economico NOT IN ('',' ')
        and a.grupo_economico NOT LIKE '%blanco%'
      QUALIFY ROW_NUMBER() OVER (PARTITION BY trim(ruc) ORDER BY grupo_economico DESC) = 1 
    ), aux_com_no_domiciliado as 
    (
      select 
        max(process_date) as process_date
      from `"""||var_project_storage||"""."""||var_dataset_raw_dataentry_finanzas||"""."""||var_table_com_no_domiciliado||"""` a
    ), temp_com_no_domiciliado as 
    (
      select 
        trim(cod_comercio) as cod_comercio
      from `"""||var_project_storage||"""."""||var_dataset_raw_dataentry_finanzas||"""."""||var_table_com_no_domiciliado||"""` a
      inner join aux_com_no_domiciliado b on (a.process_date = b.process_date)
      QUALIFY ROW_NUMBER() OVER (PARTITION BY trim(cod_comercio) ORDER BY cod_comercio DESC) = 1 
    ), temp_mcfv030 as 
    (
      select 
        trim(mccesd) as mccesd,
        mctcom
      from `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfv030||"""` a
      QUALIFY ROW_NUMBER() OVER (PARTITION BY trim(mccesd) ORDER BY mccesd DESC) = 1 
    ),temp_mcfs922 as 
    (
      select 
        case 
          when upper(trim(b.mcnomfp)) = 'VENDEMAS' then b.party_id_izi
          when b.mccodcom is null then a.party_id_izi end party_id_izi,
        mccodcom,
      from `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfm019i||"""` a
      left join `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfs922||"""` b on (a.mecest = b.mccodcom and a.mepfid = '253254')
      group by all
    ),
    /*temp_mcfs922_segmento as 
    (
      select
        mccodcom, 
        case when a.mepfid = '253254' and upper(trim(c.mcnomfp)) = 'VENDEMAS' then c.party_id_izi else a.party_id_izi end party_id_izi
      from `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfm019i||"""` a
      left join `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfs922||"""` c on (a.mecest = c.mccodcom)
      group by all
    ),*/
     temp_mcfv1001 as 
    (
      select
        distinct
        pfpfnc,
        pfpfid,
      from `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfv1001||"""`
      qualify row_number() over(partition by pfpfid order by pffing desc,pfhing desc) = 1
    ), m_comercio as 
    (

      select
        date('"""||var_process_date||"""') as process_date,
        format_date('%Y%m',current_date('America/Lima')-1) as periodo,
        a.mecest as cod_comercio,
        a.mepfid as cod_facilitador,
        case 
          when trim(mencon) not in ('NIUBIZ-AX','OPEN-AX') then 
            case 
              when a.mepfid = '253254' then 'VENDEMAS' 
              when a.mepfid = '253357' then 'IZIPAY' 
              else 'PMP' end 
            end as compania,
        case when trim(a.mesitu) = '' then null else trim(a.mesitu) end as cod_situacion_comercio,
        upper(case
          when a.mesitu = '1' then 'Código activo (transaccionó en los últimos 3 meses)'
          when a.mesitu = '2' then 'Código activo sin transacciones por más de 12 meses (sí han transaccionado antes)'
          when a.mesitu = '3' then 'Código bloqueado permanentemente'
          when a.mesitu = '4' then 'Código sin transacciones por más de 3 meses (sí han transaccionado antes)'
          when a.mesitu = '5' then 'Código nuevo instalado, con transacción de prueba'
          when a.mesitu = '6' then 'Código sin transacciones por más de 6 meses (sí han transaccionado antes)'
          when a.mesitu = '7' then 'Código nuevo instalado'
          when a.mesitu = '8' then 'Código nuevo instalado sin transacciones por más de 3 meses'
          when a.mesitu = '9' then 'Código bloqueado temporalmente'
          end) as desc_situacion_comercio,
        a.party_id_izi,
        b.identification_document_type_id as cod_tipo_documento,
        b.identification_document_type as tipo_documento,
        b.identification_document_subtype as subtipo_documento,
        b.party_id,
        ifnull(y.party_id_izi,a.party_id_izi) as party_id_izi_facilitador,
        case when y.party_id_izi is not null then yy.identification_document_type else b.identification_document_type end tipo_documento_facilitador,
        case when y.party_id_izi is not null then yy.identification_document_subtype else b.identification_document_subtype end subtipo_documento_facilitador,
        case when trim(ructes) = '' then null else upper(trim(ructes)) end as cod_segmento,
        upper(trim(a.mencom)) as nom_comercio,
        case when c.rursoc is null then a.mersoc else c.rursoc end as razon_social,
        upper(case when a.memone = '604' then 'soles' when a.memone = '840' then 'dolares'else null end) as moneda_comercio,
        a.memcc as cod_giro_comercio,
        upper(case when trim(a.metcc) = '' then null else trim(a.metcc) end) as cod_grupo_giro_comercio,
        upper(cast(trim(regexp_replace(d.mcnm12, r'\\s+', ' ')) as string)) as nom_giro_comercio,
        case when trim(a.mest01) = '' then null else upper(trim(a.mest01)) end as situacion_visa_credito,
        case when trim(a.mest02) = '' then null else upper(trim(a.mest02)) end as situacion_mastercard_credito,
        case when trim(a.mest15) = '' then null else upper(trim(a.mest15)) end as situacion_diners,
        case when trim(a.mest31) = '' then null else upper(trim(a.mest31)) end as situacion_amex,
        case when trim(a.mest35) = '' then null else upper(trim(a.mest35)) end as situacion_visa_debito,
        case when trim(a.mest38) = '' then null else upper(trim(a.mest38)) end as situacion_mastercard_debito,
        cast(a.mepc01 as float64)*100 as com_visa_credito,
        cast(a.mepc02 as float64)*100 as com_mastercard_credito,
        cast(a.mepc15 as float64)*100 as com_diners,
        cast(a.mepc31 as float64)*100 as com_amex,
        cast(a.mepc35 as float64)*100 as com_visa_debito,
        cast(a.mepc38 as float64)*100 as com_mastercard_debito,
        cast(a.mefc01 as float64) as com_fee_visa_credito,
        cast(a.mefc02 as float64) as com_fee_mastercard_credito,
        cast(a.mefc15 as float64) as com_fee_diners,
        cast(a.mefc31 as float64) as com_fee_amex,
        cast(a.mefc35 as float64) as com_fee_visa_debito,
        cast(a.mefc38 as float64) as com_fee_mastercard_debito,
        cast(a.mepi01 as float64)*100 as com_foranea_visa_credito,
        cast(a.mepi02 as float64)*100 as com_foranea_mastercard_credito,
        cast(a.mepi15 as float64)*100 as com_foranea_diners,
        cast(a.mepi31 as float64)*100 as com_foranea_amex,
        cast(a.mepi35 as float64)*100 as com_foranea_visa_debito,
        cast(a.mepi38 as float64)*100 as com_foranea_mastercard_debito,
        case when trim(a.mencon) = '' then null else cast(trim(regexp_replace(a.mencon,r'\\s+','')) as string) end as cod_contrato,
        a.mecade as cod_cadena_comercio,
        cast(case when trim(e.t14reg) = '' then null else trim(regexp_replace(e.t14reg,r'\\s+',' ')) end as string) as region_comercio,
        trim(a.meprom) as cod_responsable_cuenta,
        case when a.meprom = f.codigb then f.nombrb else null end as nom_responsable_cuenta,
        trim(meejec) as cod_ejecutivo_kam,
        case when trim(g.memraf) = '' then null else trim(left(g.memraf, 2)) end as cod_dealer,
        h.pgdesc as razon_social_dealer,
        nullif(upper(trim(g.memraf)),'') as cod_dealer_ejecutivo,
        AEAD.ENCRYPT(ph.key, cast(hh.pgdesc as string), ph.constant) as nom_ejecutivo_dealer,
        case when a.meejec = ff.codigb then ff.nombrb else null end as nom_ejecutivo_kam,
        a.medire as direccion_comercio,
        case when trim(a.medepa) = '' then null else upper(trim(a.medepa)) end as departamento_comercio,
        case when trim(a.meprov) = '' then null else upper(trim(a.meprov)) end as provincia_comercio,
        case when trim(a.medist) = '' then null else upper(trim(a.medist)) end as distrito_comercio,
        case when trim(a.mezona) = '' then null else upper(trim(a.mezona)) end as referencia_comercio,
        trim(a.meubig) as ubigeo_comercio,
        trim(a.mecpos) as cod_postal_comercio,
        a.metele as telefono_comercio,
        a.mefax as fax_comercio,
        case when trim(a.meclaf) = '' then null else upper(trim(a.meclaf)) end as cod_clasificacion_riesgo,
        safe.parse_date('%Y%m%d',a.mefape) as fecha_apertura_comercio,
        safe.parse_date('%Y%m%d',a.mefmod) as fecha_modificacion_comercio,
        safe.parse_date('%Y%m%d',a.mefblq) as fecha_bloqueo_comercio,
        case when trim(a.memblq) = '' then null else upper(trim(a.memblq)) end as cod_bloqueo_comercio,
        case when trim(a.meobse) = '' then null else upper(trim(a.meobse)) end as detalle_bloqueo_comercio,
        cast(cast(a.mebcop as int64) as string) as cod_banco_pago_comercio,
        trim(replace(i.badeco,'  ',' ')) as nom_banco_pago_comercio,
        case when trim(j.cetcta) = '' then null else trim(j.cetcta) end as tipo_cuenta_comercio,
        j.cectct as num_cuenta_comercio,
        a.mechqn as nom_representante_cheque,
        case when trim(a.medtvi) = '' then null else upper(trim(a.medtvi)) end as nom_via_comercio,
        case when trim(a.meotvi) = '' then null else upper(trim(a.meotvi)) end as nom_via_oficina,
        case when trim(a.megrue) = '0' then null else upper(trim(a.megrue)) end as cod_grupo_economico_comercio,
        upper(trim(k.tbdeslar)) as nom_grupo_economico_comercio,
        case when trim(a.mececo ) = '0' then null else lpad(trim(a.mececo),6,'0') end as cod_centro_comercial,
        kkk.tbdeslar as nom_centro_comercial,
        case when trim(a.memcom) in ('0','1') then null else trim(a.memcom)  end as cod_equipo_multicomercio,
        case when trim(a.mecemm) in ('0','1') then null else trim(a.mecemm)  end as cod_equipo_multimoneda,
        l.party_id_izi_representante,
        upper(trim(regexp_replace(trim(hhh.pgdesc), r'\\s+', ' '))) as tipo_comercio,
        trim(hhhh.pgdesc) as tipo_prueba_pos,
        trim(hhhhh.pgdesc) as nom_facilitador_servicio,
        trim(hhhhhh.pgdesc) as cod_facilitador_pagos,
        case when trim(m.merxdc) = '' then null else cast(trim(m.merxdc) as float64) end as comision_porc_dcc,
        n.party_id_izi_cajero_corresponsal,
        case when n.party_id_izi_cajero_corresponsal is null then null else coalesce(c.rursoc,cc.rursoc) end as nom_cajero_corresponsal,
        trim(o.pfpfnc) as nom_facilitador_pagos,
        nullif(trim(jj.cetdot),'') as tipo_documento_tercero,
        jj.party_id_izi_tercero,
        jj.cenomt as nom_tercero,
        case when trim(a.meuser) = '' then null else trim(a.meuser) end as cod_usuario_sistema,
        case when trim(a.mepagw) in ('0','') then null else trim(a.mepagw) end as pag_web_comercio,
        nullif(trim(a.mecuad),'') as cuadrante,
        case when g.meceli = '0' then null else g.meceli end as tel_app_izipay,
        case when trim(g.mefil6) = 'ARISAL' then safe.parse_date('%Y%m%d',trim(g.mefil8)) else null end as fecha_afiliacion_arisale,
        case when g.mefil3 = 'Y' and p.pgsitu = '1' then parse_date('%Y%m%d',trim(p.pgfing)) else null end as fecha_afiliacion_pptr,
        cast(case when cast(a.metpmc as int64) = 0 then null else cast(a.meqtjp as int64) end as string) as cod_multi_comercio,
        a.mediof as direccion_oficina,
        case when trim(a.medeof) = '' then null else trim(a.medeof) end as departamento_oficina,
        case when trim(a.meprof) = '' then null else trim(a.meprof) end as provincia_oficina,
        case when trim(a.medsof) = '' then null else trim(a.medsof) end as distrito_oficina,
        case when trim(a.mezoof) = '' then null else trim(a.mezoof) end as referencia_oficina,
        case when trim(a.meubof) = '' then null else trim(a.meubof) end as ubigeo_oficina,
        case when trim(a.mecpof) = '' then null else trim(a.mecpof) end as cod_postal_oficina,
        case when a.mefuco = '0' or a.mefuco = '' then null else parse_date('%Y%m%d',a.mefuco) end as fecha_ult_compra,
        ll.ccnomb as correo_comercial,
        l.ccnomb as nom_representante_legal,
        l.ccmai1 as correo_representante_legal,
        lll.ccnomb as nom_gerente_gen_comercio,
        lll.ccmai1 as correo_gerente_gen_comercio,
        q.mcoterm as cod_serie_equipo_multicomercio,
        case when m.mesidc in ('C','U','D') then m.mesidc else null end as cod_situacion_dcc,
        case 
          when m.mesidc = 'C' then 'CREATE' 
          when m.mesidc = 'U' then 'UPDATE'
          when m.mesidc = 'D' then 'DELETE'
          else null end as desc_situacion_dcc,
        upper(r.nom_producto) as nom_producto,
        case
          when upper(r.nom_producto) in ('CAJERO CORRESPONSAL') then 'CAJERO CORRESPONSAL'
          when upper(r.nom_producto) in ('VENDEMAS') then 'VENDEMAS'
          when upper(r.nom_producto) in 
            (
              'CARGO RECURRENTE'
              ,'COMERCIO ELECTRONICO'
              ,'FACILITADOR VIRTUAL'
              ,'INTEROPERABILIDAD VISANET'
              ,'IZI APP'
              ,'ONE APP'
              ,'IZI ECOMMERCE'
              ,'IZI ONLINE PAGINA WEB'
              ,'IZI ONLINE PASARELA'
              ,'IZI WEB BY WIX'
              ,'IZI WIX'
              ,'MOTO'
              ,'PAGO CLICK'
              ,'PC NET'
              ,'IZIPAY YA'
            ) then 'VIRTUAL' 
          when upper(r.nom_producto) in 
            (
              'IZI ANDROID'
              ,'IZI ANDROID ALQUILER'
              ,'IZI ANDROID DX8000'
              ,'IZI ANDROID IZIPLUS MAX'
              ,'IZI ANDROID MAX P2SE'
              ,'IZI ANDROID P2MINI'
              ,'IZI ANDROID P2 LITE SE'
              ,'IZI ANDROID P2 SE'
              ,'IZI JR'
              ,'IZI LINK'
              ,'IZI PARLANTE'
              ,'IZI PAX'
              ,'IZI PRINT'
              ,'IZI SCAN'
              ,'IZI SMART'
              ,'IZI SMART ALQUILER'
              ,'IZI VALIDAR'
              ,'MPOS'
              ,'POS FISICO'
            ) then 'FISICO'
          end as tipo_producto,
        case when trim(a.mencon) not in ('NIUBIZ-AX','OPEN-AX') then
          case
            when upper(trim(a.MEDEPA)) in ('LIMA', 'CALLAO') then 
              case
                when upper(trim(a.meprov)) like 'BARRANCA' then 'PROVINCIA'
                when upper(trim(a.meprov)) like 'CAJATAMBO' then 'PROVINCIA'
                when upper(trim(a.meprov)) like 'HUARAL' then 'PROVINCIA'
                when upper(trim(a.meprov)) like 'HUAURA' then 'PROVINCIA'
                when upper(trim(a.meprov)) like 'OYON' then 'PROVINCIA'
                else 'LIMA' end
            when upper(trim(a.medepa)) in ('LIMA', 'CALLAO') then 'LIMA'
            when upper(trim(a.medepa)) not in ('AMAZONAS', 'ANCASH', 'APURIMAC', 'AREQUIPA', 'AYACUCHO', 'CAJAMARCA','CALLAO', 'CUSCO', 'HUANCAVELICA', 'HUANUCO', 'ICA', 'JUNIN','LA LIBERTAD', 'LAMBAYEQUE', 'LIMA', 'LORETO', 'MADRE DE DIOS', 'MOQUEGUA', 'PASCO', 'PIURA', 'PUNO', 'SAN MARTIN', 'TACNA', 'TUMBES', 'UCAYALI') then 'LIMA'
            else 'PROVINCIA' end 
          end as tipo_region,
        'RETAIL' as segmento_parque,
        case when trim(a.mencon) not in ('NIUBIZ-AX','OPEN-AX') then t.grupo_economico end as grupo_economico,
        case when trim(a.meceae) = '' then null else trim(a.meceae) end as cod_amex,
        aead.encrypt(ph.key,cast(trim(regexp_replace(regexp_replace(replace(aead.decrypt_string(ph.key,l4.ccnomb,ph.constant),'.',''),r'/+',' '),r' +',' ')) as string),ph.constant) as nom_cont_fact_elect,
        aead.encrypt(ph.key,upper(trim(regexp_replace(aead.decrypt_string(ph.key,l5.ccdire,ph.constant),r' +', ' '))),ph.constant) as dir_cont_fact_elect,
        aead.encrypt(pi.key,nullif(upper(trim(regexp_replace(aead.decrypt_string(pi.key,l5.ccmai1,pi.constant),r' +', ' '))),''),pi.constant) as correo_fact_elect,
        a.meteof as telefono_oficina,
        a.mefxof as fax_oficina,
        aead.encrypt(pi.key,nullif(upper(trim(regexp_replace(aead.decrypt_string(pi.key,l6.ccmai1,pi.constant), r' +', ' '))),''),pi.constant) as correo_operador_proceso,
        aead.encrypt(pi.key,nullif(upper(trim(regexp_replace(aead.decrypt_string(pi.key,l5.ccmail,pi.constant), r' +', ' '))),''),pi.constant) as correo_representante_proceso,
        upper(trim(z.tipo_facilitador)) as tipo_facilitador,
        case 
          when upper(trim(h.pgdesc)) like '%WUNDERMAN%' then 'WEB'
          when upper(trim(h.pgdesc)) like any ('%BBVA%','SCOTIABANK','FERIA') then 'OTROS'
          when upper(trim(h.pgdesc)) = '' or upper(trim(h.pgdesc)) = 'SIN GRUPO' then null
          else 'DEALER' end as nom_dealer_general,
        cast(a.meqtpr as int64) as cant_terminal_pos_mcp_total,
        cast(a.meqtjp as int64) as cant_terminal_pos_jockey,
        case when u.m4qtty is null then 0 else cast(u.m4qtty as int64) end as cant_terminales_dial,
        case when u2.m4qtty is null then 0 else cast(u2.m4qtty as int64) end as cant_terminales_cel_fijo,
        case when u3.m4qtty is null then 0 else cast(u3.m4qtty as int64) end as cant_terminales_cel_movil,
        case when u4.m4qtty is null then 0 else cast(u4.m4qtty as int64) end as cant_terminales_ip,
        case when u5.m4qtty is null then 0 else cast(u5.m4qtty as int64) end as cant_terminales_lan,
        case when u6.m4qtty is null then 0 else cast(u6.m4qtty as int64) end as cant_terminales_cip,
        case when u7.m4qtty is null then 0 else cast(u7.m4qtty as int64) end as cant_terminales_cpp,
        case when trim(a.mencon) not in ('NIUBIZ-AX','OPEN-AX') then TRUE else FALSE end as flag_parque,
        case when trim(a.mencon) not in ('NIUBIZ-AX','OPEN-AX') then
          case
            when 
              cast(trim(regexp_replace(a.mencon,r'\\s+','')) as string) in ('ENT EQUIPO', 'ENTR.EQ', 'ENTR.EQ.', 'ENTR.EQP.', 'ENTREG EQU', 'ENTEQUIPO', 'ENTREGAEQU', 'ENTREGA EQ', 'IZI-EEQUIP', 'ENTEQUIPOS',
                    'TRasL EQUI','CONTROL EQ', 'GUIA', 'GUIas', 'GUIS POS', 'MCGUIas', 'ALMACEN', 'COMPDEUDA', 'PRUEBas', 'PROYECSIGO', 'ALMACPRUEB', 
                    'PROYECSIGO', 'IOVISAPRUE','PRUEBA CA', 'PROYETSIGO', 'IZIPAY S.A.C', 'PRUEBA%', 'OPERas400', 'IZI-INTERN', 'IZIPAY-BIP', 'MUL', 
                    'MULTIC', 'MULTICOM', 'MULTICOME', 'MULTICOMEC','MULTICOMER', 'MULTICOMWE', 'MULTICON', 'MUTICOMER', 'MUTICOMERC')
              or cast(trim(regexp_replace(a.mencon,r'\\s+','')) as string) like '%EQP%' or cast(trim(regexp_replace(a.mencon,r'\\s+','')) as string) like '%EQUIP%' or cast(trim(regexp_replace(a.mencon,r'\\s+','')) as string) like '%EQUIPO%' 
              or cast(trim(regexp_replace(a.mencon,r'\\s+','')) as string) like '%EQUI%' or cast(trim(regexp_replace(a.mencon,r'\\s+','')) as string) like 'TRas%' or cast(trim(regexp_replace(a.mencon,r'\\s+','')) as string) like '%PRUEBA%'
              or cast(trim(regexp_replace(a.mencon,r'\\s+','')) as string) like '%SIGO' or cast(trim(regexp_replace(a.mencon,r'\\s+','')) as string) like '%PRUEB%' or cast(trim(regexp_replace(a.mencon,r'\\s+','')) as string) like 'MULTICOM%'
              or trim(hhhh.pgdesc) like 'PRUEBas' or trim(hhhh.pgdesc) like 'USO INTERNO'
              or trim(hhh.pgdesc) like '%PRUEBA%' or a.mencom like '%*PRUEBas%' 
              or a.mencom like '%*PRUEBA%' or a.mencom like 'IZI*PRUEBA IBK'
              or trim(i.badeco) like 'IZI*PRUEBA' or a.mencom like 'CAJEROS'
              or (a.mencom in ('IZI*IZIPAY', 'IZI*IZIPAY2') and left(a.mecest, 1) like '4')
              or ((a.mencom like 'IZI*%' or a.mencom like 'ZI*%' or a.mencom like 'IZ*%' 
              or a.mencom like 'IZI-%' or a.mencom like 'IZI%' 
              or a.mencom like 'ZI-%' or a.mencom like 'IZ-%') and left(a.mecest, 1) like '7')		
              or (substring(a.mecest, 1, 1) = '9' and trim(a.meprom) <> '1051' and left(a.mencom, 4) <> 'IZI*') then FALSE
            else TRUE end 
          end as flag_genera_ingreso,
        cast(null as bool) as flag_1uit,
        cast(null as bool) as flag_12uit,
        cast(null as bool) as flag_40uit,
        cast(null as bool) as flag_60uit,
        case when trim(jj.cepagt) <> '' and trim(jj.cepagt) is not null then TRUE else FALSE end as flag_pago_terceros,
        case when meiade = 'Y' then TRUE else FALSE end as flag_pago_adelantado,
        case when v.mccesd = a.mecest then TRUE else FALSE end as flag_multimoneda,
        case when m.meprau in ('1','P') then TRUE else FALSE end as flag_pre_autorizacion,
        case when a.metpim = 'Y' then TRUE else FALSE end as flag_digitacion_manual,
        case when a.meoptp = 'Y' then TRUE else FALSE end as flag_tarjeta_prepago,
        case when a.meopmo = 'Y' then TRUE else FALSE end as flag_opcion_correo,
        case when a.meopto = 'Y' then TRUE else FALSE end as flag_opcion_telefono,
        case when a.meopns = 'Y' then TRUE else FALSE end as flag_tarjeta_no_show,
        case when a.meopcr = 'Y' then TRUE else FALSE end as flag_cargo_recurrente,
        case when a.meoppv = 'Y' then TRUE else FALSE end as flag_pos_virtual,
        case when a.meopec = 'Y' then TRUE else FALSE end as flag_opc_ecommerce,
        case when m.meptsc = 'Y' then TRUE else FALSE end as flag_canje_puntos,
        case when upper(trim(v.mctcom)) = 'MPOS' then TRUE else FALSE end as flag_mpos,
        case when m.meivop = 'Y' then TRUE else FALSE end as flag_pago_rapido,
        case when a.meprop = 'Y' then TRUE else FALSE end as flag_propina,
        case when a.mepfsc = 'Y' then TRUE else FALSE end as flag_canje_puntos_sbp,
        case when a.mepfib = 'Y' then TRUE else FALSE end as flag_canje_puntos_ibk,
        case when a.mepfmr = 'Y' then TRUE else FALSE end as flag_canje_puntos_mr,
        case when g.meptrp = 'Y' then TRUE else FALSE end as flag_canje_puntos_rp,
        case when g.meptco = 'Y' then TRUE else FALSE end as flag_canje_puntos_comp,
        case when g.meppoi = 'Y' then TRUE else FALSE end as flag_canje_puntos_ppoint,
        case when g.mecsue = 'Y' then TRUE else FALSE end as flag_canje_puntos_cuenta_sueldo,
        case when a.meitar = 'Y' then TRUE else FALSE end as flag_verificacion_tarjeta,
        case when a.meiexp = 'Y' then TRUE else FALSE end as flag_exoneracion_portes,
        case when g.medvry = 'Y' then TRUE else FALSE end as flag_delivery,
        case when m.mesidc in ('C','U') then TRUE else FALSE end as flag_dcc,
        case when g.meamct = 'Y' then TRUE else FALSE end as flag_cobro_manten_cuenta,
        case when g.meendc in ('F','E') then TRUE else FALSE end as flag_envio_duas,
        case when trim(g.meprly) <> '' then TRUE else FALSE end as flag_lyra,
        case when g.memime = 'D' then TRUE else FALSE end as flag_micro_visa,
        case when g.mefil1 = 'Y' then TRUE else FALSE end as flag_micro_mastercard,
        case when g.mefivi in ('Y','S') then TRUE else FALSE end as flag_izi_virtual,
        case when g.medeud = '9' then TRUE else FALSE end as flag_pago_deuda,
        case when trim(g.mefil6) = 'ARISAL' then TRUE else FALSE end as flag_arisale,
        case when g.mefil3 = 'Y' and cast(p.pgsitu as string) = '1' then TRUE else FALSE end as flag_pptr,
        case 
          when w.metapp = 'TK' then TRUE 
          when trim(g.memraf) = 'IY0002' and left(trim(g.mecest),1) = '9' then TRUE
          else FALSE end as flag_izipay_ya,
        case when a.mecest = x.cod_comercio then TRUE else FALSE end as flag_no_domiciliado,
        case when a.mesitu = '1' then TRUE else FALSE end as flag_comercio_activo,
        b.flag_lpdp,
        if(upper(trim(a.meemon)) = 'P',TRUE,FALSE) as flag_monitoreo,
        case 
          when a.memcc in 
            (
              '5122',
              '5912',
              '5967',
              '7995',
              '7273',
              '5816',
              '6051',
              '6012',
              '4816',
              '5993',
              '5966',
              '6211',
              '5968',
              '7841',
              '7801',
              '7802',
              '7994',
              '9406',
              '5962',
              '5969',
              '7322'
            ) then TRUE 
          else FALSE end as flag_riesgo_visa_mc,
        case 
          when a.memcc in 
            (
              '1520',
              '4457',
              '4829',
              '5094',
              '5169',
              '5521',
              '5551',
              '5599',
              '5932',
              '5933',
              '5937',
              '5944',
              '5971',
              '5972',
              '6051',
              '7333',
              '7993',
              '7994',
              '7995',
              '8398'
            ) then TRUE
          else FALSE end as flag_riesgo_sbs,
        case
          when trim(a.mesitu) = '3' and upper(trim(a.memblq)) in ('01','03','04','05','07','10','11','13','14','FRA','SEG') and upper(a.meobse) not like '%CAS%' then TRUE
          else FALSE end as flag_bloqueo_fraude,
        case
          when trim(a.mesitu) = '3' and upper(trim(a.memblq)) in ('04','05','FRA','SEG') and upper(a.meobse) not like '%CAS%' then TRUE
          else FALSE end as flag_fraude_riesgo,
        case
          when trim(mesitu) = '3' and upper(trim(a.memblq)) in ('01','03','07','14','10','11','13') and upper(a.meobse) not like '%CAS%' then TRUE
          else FALSE end as flag_fraude_cumplimiento,
        'AS400' as record_source,
        current_datetime('America/Lima') as load_date,
        session_user() as creation_user
      from `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfm019i||"""` a 
      left join temp_iden_party_data_control b on (a.party_id_izi = b.party_id_izi)
      inner join `"""||var_project_sensitive||"""."""||var_dataset_secure_secrets||"""."""||var_table_config_protected_data||"""` ph on 1=1 and ph.code = 'C_FULL_NAME'
      inner join `"""||var_project_sensitive||"""."""||var_dataset_secure_secrets||"""."""||var_table_config_protected_data||"""` pi on 1=1 and pi.code = 'C_EMAIL'  
      left join temp_mcfm015 c on (a.party_id_izi = c.party_id_izi)
      left join temp_mcfm015_2 cc on (a.party_id_izi = cc.party_id_izi) 
      left join `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfv012||"""` d on (a.memcc = d.mcc012)
      left join `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfv014||"""` e on (a.mesucu = e.t14cod)
      left join `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfm602||"""` f on (a.meprom = f.codigb)
      left join `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfm027||"""` g on (a.mecest = g.mecest)
      left join `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfv075||"""` h on (left(trim(g.memraf),2) = trim(h.pgcodi) and trim(h.pgtipo) = 'DEALER')
      left join `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfv075||"""` hh on (left(trim(g.memraf),2) = trim(hh.pgcodi) and trim(hh.pgtipo) = 'IAMRAF')
      left join `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfv075||"""` hhh on (trim(g.mecond) = trim(hhh.pgcodi) and trim(hhh.pgtipo) = 'IACOND')
      left join `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfv075||"""` hhhh on (trim(g.metppr) = trim(hhhh.pgcodi) and trim(hhhh.pgtipo) = 'IATPPR')
      left join `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfv075||"""` hhhhh on (trim(g.mefsrv) = trim(hhhhh.pgcodi) and trim(hhhhh.pgtipo) = 'IAFSRV')
      left join `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfv075||"""` hhhhhh on (trim(g.mefpag) = trim(hhhhhh.pgcodi) and trim(hhhhhh.pgtipo) = 'IAFPAG')
      left join `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfm602||"""` ff on (a.meejec = ff.codigb)
      left join `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfv004||"""` i on (a.mebcop = i.bacodi)
      left join temp_mcfv002 j on (a.mecest = j.cecest)
      left join temp_mcfv002_tercero jj on (a.mecest = jj.cecest and trim(jj.ceprod)='')
      left join temp_mcft168 k on (lpad(trim(a.megrue),6,'0') = trim(k.tbcodigo) and upper(trim(k.tbcodtbl)) = 'GRUPOE') 
      left join temp_mcft168 kk on (a.mecafr = kk.tbcodigo and upper(trim(kk.tbcodtbl)) = 'FRANQU')
      left join temp_mcft168 kkk on (lpad(trim(a.mececo),6,'0') = trim(kkk.tbcodigo) and upper(trim(kkk.tbcodtbl)) = 'CENCOM')
      left join `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfm020||"""` l on (a.mecest = l.cccest and l.cccate = '1')
      left join `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfm020||"""` ll on (a.mecest = ll.cccest and ll.cccate = '3')
      left join `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfm020||"""` lll on (a.mecest = lll.cccest and lll.cccate = '2')
      left join `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfm020||"""` l4 on (a.mecest = l4.cccest and l4.cccate = '7')
      left join `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfm020||"""` l5 on (a.mecest = l5.cccest and l5.cccate = '8')
      left join `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfm020o||"""` l6 on (a.mecest = l6.cccest and l6.cccate = '5')
      left join `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfm021||"""` m on (a.mecest = m.mecest)
      left join `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfv068||"""` n on (a.mecest = n.mtcest and n.mtemis = '9')
      left join temp_mcfv1001 o on (a.mepfid = o.pfpfid)
      left join `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfs114||"""` p on (a.mecest = p.pgcest)
      left join temp_mcfs922 y on (a.mecest = y.mccodcom)
      left join temp_mcfm004 q on (a.mecest = q.mcocest)
      left join temp_nom_producto r on (a.mecest = r.mecest)

    /* left join temp_mcfs922_segmento y2 on (a.mecest = y2.mccodcom)

      left join temp_segmentacion s on (y2.party_id_izi = s.party_id_izi)*/
      left join temp_grupo_economico t on (b.document_number = t.document_number)
      left join `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfm024||"""` u on (a.mecest = u.m4cest and u.m4tico = '1')
      left join `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfm024||"""` u2 on (a.mecest = u2.m4cest and u2.m4tico = '2')
      left join `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfm024||"""` u3 on (a.mecest = u3.m4cest and u3.m4tico = '3')
      left join `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfm024||"""` u4 on (a.mecest = u4.m4cest and u4.m4tico = '4')
      left join `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfm024||"""` u5 on (a.mecest = u5.m4cest and u5.m4tico = '5')
      left join `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfm024||"""` u6 on (a.mecest = u6.m4cest and u6.m4tico = '6')
      left join `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfm024||"""` u7 on (a.mecest = u7.m4cest and u7.m4tico = '7')
      left join temp_mcfv030 v on a.mecest = v.mccesd 
      left join `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfm029||"""` w on (a.mecest = w.mecest)
      left join temp_com_no_domiciliado x on (a.mecest = x.cod_comercio)
      left join temp_iden_party_data_control yy on (y.party_id_izi = yy.party_id_izi)
      left join `"""||var_project_storage||"""."""||var_dataset_raw_dataentry_data||"""."""||var_table_c_facilitador||"""` z on (a.mepfid = z.cod_facilitador)
      where safe.parse_date('%Y%m%d',a.mefape) <= '"""||var_process_date||"""'
    )

    select 
      a.process_date,
      a.periodo,
      a.cod_comercio,
      a.cod_facilitador,
      a.compania,
      a.cod_situacion_comercio,
      a.desc_situacion_comercio,
      a.party_id_izi,
      a.cod_tipo_documento,
      a.tipo_documento,
      a.subtipo_documento,
      a.party_id,
      a.party_id_izi_facilitador,
      a.tipo_documento_facilitador,
      a.subtipo_documento_facilitador,
      a.cod_segmento,
      a.nom_comercio,
      a.razon_social,
      a.moneda_comercio,
      a.cod_giro_comercio,
      a.cod_grupo_giro_comercio,
      a.nom_giro_comercio,
      a.situacion_visa_credito,
      a.situacion_mastercard_credito,
      a.situacion_diners,
      a.situacion_amex,
      a.situacion_visa_debito,
      a.situacion_mastercard_debito,
      a.com_visa_credito,
      a.com_mastercard_credito,
      a.com_diners,
      a.com_amex,
      a.com_visa_debito,
      a.com_mastercard_debito,
      a.com_fee_visa_credito,
      a.com_fee_mastercard_credito,
      a.com_fee_diners,
      a.com_fee_amex,
      a.com_fee_visa_debito,
      a.com_fee_mastercard_debito,
      a.com_foranea_visa_credito,
      a.com_foranea_mastercard_credito,
      a.com_foranea_diners,
      a.com_foranea_amex,
      a.com_foranea_visa_debito,
      a.com_foranea_mastercard_debito,
      a.cod_contrato,
      a.cod_cadena_comercio,
      a.region_comercio,
      a.cod_responsable_cuenta,
      a.nom_responsable_cuenta,
      a.cod_ejecutivo_kam,
      a.cod_dealer,
      a.razon_social_dealer,
      a.cod_dealer_ejecutivo,
      a.nom_ejecutivo_dealer,
      a.nom_ejecutivo_kam,
      a.direccion_comercio,
      a.departamento_comercio,
      a.provincia_comercio,
      a.distrito_comercio,
      a.referencia_comercio,
      a.ubigeo_comercio,
      a.cod_postal_comercio,
      a.telefono_comercio,
      a.fax_comercio,
      a.cod_clasificacion_riesgo,
      a.fecha_apertura_comercio,
      a.fecha_modificacion_comercio,
      a.fecha_bloqueo_comercio,
      a.cod_bloqueo_comercio,
      a.detalle_bloqueo_comercio,
      a.cod_banco_pago_comercio,
      a.nom_banco_pago_comercio,
      a.tipo_cuenta_comercio,
      a.num_cuenta_comercio,
      a.nom_representante_cheque,
      a.nom_via_comercio,
      a.nom_via_oficina,
      a.cod_grupo_economico_comercio,
      a.nom_grupo_economico_comercio,
      a.cod_centro_comercial,
      a.nom_centro_comercial,
      a.cod_equipo_multicomercio,
      a.cod_equipo_multimoneda,
      a.party_id_izi_representante,
      a.tipo_comercio,
      a.tipo_prueba_pos,
      a.nom_facilitador_servicio,
      a.cod_facilitador_pagos,
      a.comision_porc_dcc,
      a.party_id_izi_cajero_corresponsal,
      a.nom_cajero_corresponsal,
      a.nom_facilitador_pagos,
      a.tipo_documento_tercero,
      a.party_id_izi_tercero,
      a.nom_tercero,
      a.cod_usuario_sistema,
      a.pag_web_comercio,
      a.cuadrante,
      a.tel_app_izipay,
      a.fecha_afiliacion_arisale,
      a.fecha_afiliacion_pptr,
      a.cod_multi_comercio,
      a.direccion_oficina,
      a.departamento_oficina,
      a.provincia_oficina,
      a.distrito_oficina,
      a.referencia_oficina,
      a.ubigeo_oficina,
      a.cod_postal_oficina,
      a.fecha_ult_compra,
      a.correo_comercial,
      a.nom_representante_legal,
      a.correo_representante_legal,
      a.nom_gerente_gen_comercio,
      a.correo_gerente_gen_comercio,
      a.cod_serie_equipo_multicomercio,
      a.cod_situacion_dcc,
      a.desc_situacion_dcc,
      a.nom_producto,
      a.tipo_producto,
      a.tipo_region,
      case when trim(a.cod_contrato) not in ('NIUBIZ-AX','OPEN-AX') then ifnull(b.segmento,'RETAIL') end as segmento_parque,
      a.grupo_economico,
      a.cod_amex,
      a.nom_cont_fact_elect,
      a.dir_cont_fact_elect,
      a.correo_fact_elect,
      a.telefono_oficina,
      a.fax_oficina,
      a.correo_operador_proceso,
      a.correo_representante_proceso,
      a.tipo_facilitador,
      a.nom_dealer_general,
      a.cant_terminal_pos_mcp_total,
      a.cant_terminal_pos_jockey,
      a.cant_terminales_dial,
      a.cant_terminales_cel_fijo,
      a.cant_terminales_cel_movil,
      a.cant_terminales_ip,
      a.cant_terminales_lan,
      a.cant_terminales_cip,
      a.cant_terminales_cpp,
      a.flag_parque,
      a.flag_genera_ingreso,
      a.flag_1uit,
      a.flag_12uit,
      a.flag_40uit,
      a.flag_60uit,
      a.flag_pago_terceros,
      a.flag_pago_adelantado,
      a.flag_multimoneda,
      a.flag_pre_autorizacion,
      a.flag_digitacion_manual,
      a.flag_tarjeta_prepago,
      a.flag_opcion_correo,
      a.flag_opcion_telefono,
      a.flag_tarjeta_no_show,
      a.flag_cargo_recurrente,
      a.flag_pos_virtual,
      a.flag_opc_ecommerce,
      a.flag_canje_puntos,
      a.flag_mpos,
      a.flag_pago_rapido,
      a.flag_propina,
      a.flag_canje_puntos_sbp,
      a.flag_canje_puntos_ibk,
      a.flag_canje_puntos_mr,
      a.flag_canje_puntos_rp,
      a.flag_canje_puntos_comp,
      a.flag_canje_puntos_ppoint,
      a.flag_canje_puntos_cuenta_sueldo,
      a.flag_verificacion_tarjeta,
      a.flag_exoneracion_portes,
      a.flag_delivery,
      a.flag_dcc,
      a.flag_cobro_manten_cuenta,
      a.flag_envio_duas,
      a.flag_lyra,
      a.flag_micro_visa,
      a.flag_micro_mastercard,
      a.flag_izi_virtual,
      a.flag_pago_deuda,
      a.flag_arisale,
      a.flag_pptr,
      a.flag_izipay_ya,
      a.flag_no_domiciliado,
      a.flag_comercio_activo,
      a.flag_lpdp,
      a.flag_monitoreo,
      a.flag_riesgo_visa_mc,
      a.flag_riesgo_sbs,
      a.flag_bloqueo_fraude,
      a.flag_fraude_riesgo,
      a.flag_fraude_cumplimiento,
      a.record_source,
      a.load_date,
      a.creation_user
    from m_comercio a
    left join temp_segmentacion b on (a.party_id_izi_facilitador = b.party_id_izi)
  """;
  EXECUTE IMMEDIATE(query);

  /* CARGAR DE DATA HISTORICA (DIARIA Y MENSUAL) */

  SET query = """
    delete from `"""||var_project_storage||"""."""||var_dataset_master_party||"""."""||var_table_m_comercio||"""_h` 
    where process_date = '"""||var_process_date||"""'
  """;
  EXECUTE IMMEDIATE(query);

  SET query = """
    insert into `"""||var_project_storage||"""."""||var_dataset_master_party||"""."""||var_table_m_comercio||"""_h` 
    select *
    from `"""||var_project_storage||"""."""||var_dataset_master_party||"""."""||var_table_m_comercio||"""` 
    where process_date = '"""||var_process_date||"""'
  """;
  EXECUTE IMMEDIATE(query);
  

  SET query = """
    delete from `"""||var_project_storage||"""."""||var_dataset_master_party||"""."""||var_table_m_comercio||"""_m` 
    where process_date between '"""||var_process_date_ini||"""' and '"""||var_process_date_fin||"""'
  """;
  EXECUTE IMMEDIATE(query);

  SET query = """
    insert into `"""||var_project_storage||"""."""||var_dataset_master_party||"""."""||var_table_m_comercio||"""_m` 
    select *
    from `"""||var_project_storage||"""."""||var_dataset_master_party||"""."""||var_table_m_comercio||"""` 
    where process_date between '"""||var_process_date_ini||"""' and '"""||var_process_date_fin||"""'
  """;
  EXECUTE IMMEDIATE(query);


END;



CREATE OR REPLACE PROCEDURE `prd-izipay-data-operation.raw_stage_as400.prc_load_as400_mcfm019i`(var_project_operation STRING, var_project_storage STRING, var_project_sensitive STRING)
BEGIN
  DECLARE query STRING;
  DECLARE cant INT64;
  DECLARE var_table_tmp_mcfm019i STRING;

  DECLARE var_dataset_raw_stage_as400 STRING;
  DECLARE var_dataset_raw_as400 STRING;
  DECLARE var_table_mcfm019i STRING;
  DECLARE var_dataset_bq_omni_izipay_azure STRING;  
  DECLARE var_dataset_secure_secrets STRING;
  DECLARE var_dataset_master_pii STRING;
  DECLARE var_table_config_protected_data STRING;
  DECLARE var_table_itc_iden_party_data_control STRING;

  SET var_dataset_raw_stage_as400 = 'raw_stage_as400';
  SET var_dataset_raw_as400 = 'raw_as400';
  SET var_table_mcfm019i = 'mcfm019i';
  SET var_dataset_bq_omni_izipay_azure = 'bq_omni_izipay_azure_saizipaydatamarts';
  SET var_dataset_secure_secrets = 'secure_secrets';
  SET var_dataset_master_pii = 'master_pii';
  SET var_table_config_protected_data = 'config_protected_data';
  SET var_table_itc_iden_party_data_control = 'iden_party_data_control';

/*
  DECLARE var_project_operation STRING;
  DECLARE var_project_storage STRING;
  DECLARE var_project_sensitive STRING; --prd-izipay-data-sensitive --> proyecto independiente

  SET var_project_operation = 'prd-izipay-data-operation';
  SET var_project_storage = 'prd-izipay-data-storage-pv';
  SET var_project_sensitive = 'prd-izipay-data-sensitive';


  */

  SET var_table_tmp_mcfm019i = concat('tmp_',var_table_mcfm019i);

  /* Verificar si la tabla EXTERNA tiene contenido, guardar el conteo*/
  SET query = """
   select count(1)
   from `"""||var_project_operation||"""."""||var_dataset_bq_omni_izipay_azure||"""."""||var_table_mcfm019i||"""`
  """;
  EXECUTE IMMEDIATE(query)
  into cant;

  /* Si la tabla tiene contenido, insertar la data desde la tabla  EXTERNA hacia la tabla en DATA_STORAGE*/
  IF ifnull(cant,0) > 0 

    THEN

      /* Crear una tabla temporal con los datos sumando las columnas adicionales para auditoria*/
      SET query = """
        create or replace table `"""||var_project_operation||"""."""||var_dataset_raw_stage_as400||"""."""||var_table_tmp_mcfm019i||"""` as
        select
          cast(mecest as string) as mecest,
          cast(mesitu as string) as mesitu,
          cast(meruce as string) as meruce,
          cast(mencom as string) as mencom,
          cast(memone as string) as memone,
          cast(mecemm as string) as mecemm,
          cast(memcc as string) as memcc,
          cast(metcc as string) as metcc,
          cast(meemod as string) as meemod,
          cast(meemon as string) as meemon,
          cast(meprau as string) as meprau,
          cast(meprop as string) as meprop,
          cast(mepags as string) as mepags,
          cast(mecash as string) as mecash,
          cast(metpmm as string) as metpmm,
          cast(metpim as string) as metpim,
          cast(metpid as string) as metpid,
          cast(mest01 as string) as mest01,
          cast(mest02 as string) as mest02,
          cast(mest03 as string) as mest03,
          cast(mest04 as string) as mest04,
          cast(mest05 as string) as mest05,
          cast(mest06 as string) as mest06,
          cast(mest07 as string) as mest07,
          cast(mest08 as string) as mest08,
          cast(mest09 as string) as mest09,
          cast(mest10 as string) as mest10,
          cast(mest11 as string) as mest11,
          cast(mest12 as string) as mest12,
          cast(mest13 as string) as mest13,
          cast(mest14 as string) as mest14,
          cast(mest15 as string) as mest15,
          cast(mest16 as string) as mest16,
          cast(mest17 as string) as mest17,
          cast(mest18 as string) as mest18,
          cast(mest19 as string) as mest19,
          cast(mest20 as string) as mest20,
          cast(mest21 as string) as mest21,
          cast(mest22 as string) as mest22,
          cast(mest23 as string) as mest23,
          cast(mest24 as string) as mest24,
          cast(mest25 as string) as mest25,
          cast(mest26 as string) as mest26,
          cast(mest27 as string) as mest27,
          cast(mest28 as string) as mest28,
          cast(mest29 as string) as mest29,
          cast(mest30 as string) as mest30,
          cast(mest31 as string) as mest31,
          cast(mest32 as string) as mest32,
          cast(mest33 as string) as mest33,
          cast(mest34 as string) as mest34,
          cast(mest35 as string) as mest35,
          cast(mest36 as string) as mest36,
          cast(mest37 as string) as mest37,
          cast(mest38 as string) as mest38,
          cast(mest39 as string) as mest39,
          cast(mest40 as string) as mest40,
          cast(mepc01 as string) as mepc01,
          cast(mepc02 as string) as mepc02,
          cast(mepc03 as string) as mepc03,
          cast(mepc04 as string) as mepc04,
          cast(mepc05 as string) as mepc05,
          cast(mepc06 as string) as mepc06,
          cast(mepc07 as string) as mepc07,
          cast(mepc08 as string) as mepc08,
          cast(mepc09 as string) as mepc09,
          cast(mepc10 as string) as mepc10,
          cast(mepc11 as string) as mepc11,
          cast(mepc12 as string) as mepc12,
          cast(mepc13 as string) as mepc13,
          cast(mepc14 as string) as mepc14,
          cast(mepc15 as string) as mepc15,
          cast(mepc16 as string) as mepc16,
          cast(mepc17 as string) as mepc17,
          cast(mepc18 as string) as mepc18,
          cast(mepc19 as string) as mepc19,
          cast(mepc20 as string) as mepc20,
          cast(mepc21 as string) as mepc21,
          cast(mepc22 as string) as mepc22,
          cast(mepc23 as string) as mepc23,
          cast(mepc24 as string) as mepc24,
          cast(mepc25 as string) as mepc25,
          cast(mepc26 as string) as mepc26,
          cast(mepc27 as string) as mepc27,
          cast(mepc28 as string) as mepc28,
          cast(mepc29 as string) as mepc29,
          cast(mepc30 as string) as mepc30,
          cast(mepc31 as string) as mepc31,
          cast(mepc32 as string) as mepc32,
          cast(mepc33 as string) as mepc33,
          cast(mepc34 as string) as mepc34,
          cast(mepc35 as string) as mepc35,
          cast(mepc36 as string) as mepc36,
          cast(mepc37 as string) as mepc37,
          cast(mepc38 as string) as mepc38,
          cast(mepc39 as string) as mepc39,
          cast(mepc40 as string) as mepc40,
          cast(mefc01 as string) as mefc01,
          cast(mefc02 as string) as mefc02,
          cast(mefc03 as string) as mefc03,
          cast(mefc04 as string) as mefc04,
          cast(mefc05 as string) as mefc05,
          cast(mefc06 as string) as mefc06,
          cast(mefc07 as string) as mefc07,
          cast(mefc08 as string) as mefc08,
          cast(mefc09 as string) as mefc09,
          cast(mefc10 as string) as mefc10,
          cast(mefc11 as string) as mefc11,
          cast(mefc12 as string) as mefc12,
          cast(mefc13 as string) as mefc13,
          cast(mefc14 as string) as mefc14,
          cast(mefc15 as string) as mefc15,
          cast(mefc16 as string) as mefc16,
          cast(mefc17 as string) as mefc17,
          cast(mefc18 as string) as mefc18,
          cast(mefc19 as string) as mefc19,
          cast(mefc20 as string) as mefc20,
          cast(mefc21 as string) as mefc21,
          cast(mefc22 as string) as mefc22,
          cast(mefc23 as string) as mefc23,
          cast(mefc24 as string) as mefc24,
          cast(mefc25 as string) as mefc25,
          cast(mefc26 as string) as mefc26,
          cast(mefc27 as string) as mefc27,
          cast(mefc28 as string) as mefc28,
          cast(mefc29 as string) as mefc29,
          cast(mefc30 as string) as mefc30,
          cast(mefc31 as string) as mefc31,
          cast(mefc32 as string) as mefc32,
          cast(mefc33 as string) as mefc33,
          cast(mefc34 as string) as mefc34,
          cast(mefc35 as string) as mefc35,
          cast(mefc36 as string) as mefc36,
          cast(mefc37 as string) as mefc37,
          cast(mefc38 as string) as mefc38,
          cast(mefc39 as string) as mefc39,
          cast(mefc40 as string) as mefc40,
          cast(mencon as string) as mencon,
          cast(mecade as string) as mecade,
          cast(mecafr as string) as mecafr,
          cast(mesucu as string) as mesucu,
          cast(meprom as string) as meprom,
          cast(meejec as string) as meejec,
          cast(medire as string) as medire,
          cast(meubig as string) as meubig,
          cast(mecpos as string) as mecpos,
          cast(metele as string) as metele,
          cast(mefax as string) as mefax,
          cast(mediof as string) as mediof,
          cast(meubof as string) as meubof,
          cast(mecpof as string) as mecpof,
          cast(meteof as string) as meteof,
          cast(mefxof as string) as mefxof,
          cast(meclaf as string) as meclaf,
          cast(meclar as string) as meclar,
          cast(mefing as string) as mefing,
          cast(mehing as string) as mehing,
          cast(mefape as string) as mefape,
          cast(mehape as string) as mehape,
          cast(mefmod as string) as mefmod,
          cast(mehmod as string) as mehmod,
          cast(mefblq as string) as mefblq,
          cast(mehblq as string) as mehblq,
          cast(meobse as string) as meobse,
          cast(mebcop as string) as mebcop,
          cast(mechqn as string) as mechqn,
          cast(meiade as string) as meiade,
          cast(mefpco as string) as mefpco,
          cast(mefuco as string) as mefuco,
          cast(mefpfr as string) as mefpfr,
          cast(mefufr as string) as mefufr,
          cast(mefipo as string) as mefipo,
          cast(mempgr as string) as mempgr,
          cast(mempfi as string) as mempfi,
          cast(mempqm as string) as mempqm,
          cast(mempfm as string) as mempfm,
          cast(mempim as string) as mempim,
          cast(meiemp as string) as meiemp,
          cast(meiexp as string) as meiexp,
          cast(meitar as string) as meitar,
          cast(metpmc as string) as metpmc,
          cast(meqtpr as string) as meqtpr,
          cast(meqtjp as string) as meqtjp,
          cast(meqomn as string) as meqomn,
          cast(meqbul as string) as meqbul,
          cast(meqter as string) as meqter,
          cast(meqina as string) as meqina,
          cast(meqtp0 as string) as meqtp0,
          cast(meimp0 as string) as meimp0,
          cast(meqtm0 as string) as meqtm0,
          cast(meimm0 as string) as meimm0,
          cast(meqtr0 as string) as meqtr0,
          cast(menet0 as string) as menet0,
          cast(mersoc as string) as mersoc,
          cast(meprov as string) as meprov,
          cast(medepa as string) as medepa,
          cast(meprof as string) as meprof,
          cast(medeof as string) as medeof,
          cast(medsof as string) as medsof,
          cast(mesvco as string) as mesvco,
          cast(medist as string) as medist,
          cast(mezona as string) as mezona,
          cast(memblq as string) as memblq,
          cast(mezoof as string) as mezoof,
          cast(mecuad as string) as mecuad,
          cast(mecuof as string) as mecuof,
          cast(mecedc as string) as mecedc,
          cast(medtvi as string) as medtvi,
          cast(mednvi as string) as mednvi,
          cast(mednro as string) as mednro,
          cast(medint as string) as medint,
          cast(medmz as string) as medmz,
          cast(medlot as string) as medlot,
          cast(medkm as string) as medkm,
          cast(medsec as string) as medsec,
          cast(medgpo as string) as medgpo,
          cast(medniv as string) as medniv,
          cast(medtda as string) as medtda,
          cast(meotvi as string) as meotvi,
          cast(meonvi as string) as meonvi,
          cast(meonro as string) as meonro,
          cast(meoint as string) as meoint,
          cast(meomz as string) as meomz,
          cast(meolot as string) as meolot,
          cast(meokm as string) as meokm,
          cast(meosec as string) as meosec,
          cast(meogpo as string) as meogpo,
          cast(meoniv as string) as meoniv,
          cast(meotda as string) as meotda,
          cast(mepagw as string) as mepagw,
          cast(mehatd as string) as mehatd,
          cast(mehath as string) as mehath,
          cast(meoptp as string) as meoptp,
          cast(meopmo as string) as meopmo,
          cast(meopto as string) as meopto,
          cast(meopcr as string) as meopcr,
          cast(meoppv as string) as meoppv,
          cast(meopec as string) as meopec,
          cast(meoppa as string) as meoppa,
          cast(meopns as string) as meopns,
          cast(medatd as string) as medatd,
          cast(medath as string) as medath,
          cast(memcom as string) as memcom,
          cast(megrue as string) as megrue,
          cast(mecjco as string) as mecjco,
          cast(mesadv as string) as mesadv,
          cast(meecmr as string) as meecmr,
          cast(meagen as string) as meagen,
          cast(mempti as string) as mempti,
          cast(meqtdu as string) as meqtdu,
          cast(meqtcf as string) as meqtcf,
          cast(meqtcm as string) as meqtcm,
          cast(meqtip as string) as meqtip,
          cast(meqtla as string) as meqtla,
          cast(mepais as string) as mepais,
          cast(megpdc as string) as megpdc,
          cast(mechqb as string) as mechqb,
          cast(meuser as string) as meuser,
          cast(meqtcp as string) as meqtcp,
          cast(meqtpp as string) as meqtpp,
          cast(meceae as string) as meceae,
          cast(mesubg as string) as mesubg,
          cast(mececo as string) as mececo,
          cast(mepfsc as string) as mepfsc,
          cast(mepfib as string) as mepfib,
          cast(mepfmr as string) as mepfmr,
          cast(mepfid as string) as mepfid,
          cast(mepi01 as string) as mepi01,
          cast(mepi02 as string) as mepi02,
          cast(mepi03 as string) as mepi03,
          cast(mepi04 as string) as mepi04,
          cast(mepi05 as string) as mepi05,
          cast(mepi06 as string) as mepi06,
          cast(mepi07 as string) as mepi07,
          cast(mepi08 as string) as mepi08,
          cast(mepi09 as string) as mepi09,
          cast(mepi10 as string) as mepi10,
          cast(mepi11 as string) as mepi11,
          cast(mepi12 as string) as mepi12,
          cast(mepi13 as string) as mepi13,
          cast(mepi14 as string) as mepi14,
          cast(mepi15 as string) as mepi15,
          cast(mepi16 as string) as mepi16,
          cast(mepi17 as string) as mepi17,
          cast(mepi18 as string) as mepi18,
          cast(mepi19 as string) as mepi19,
          cast(mepi20 as string) as mepi20,
          cast(mepi21 as string) as mepi21,
          cast(mepi22 as string) as mepi22,
          cast(mepi23 as string) as mepi23,
          cast(mepi24 as string) as mepi24,
          cast(mepi25 as string) as mepi25,
          cast(mepi26 as string) as mepi26,
          cast(mepi27 as string) as mepi27,
          cast(mepi28 as string) as mepi28,
          cast(mepi29 as string) as mepi29,
          cast(mepi30 as string) as mepi30,
          cast(mepi31 as string) as mepi31,
          cast(mepi32 as string) as mepi32,
          cast(mepi33 as string) as mepi33,
          cast(mepi34 as string) as mepi34,
          cast(mepi35 as string) as mepi35,
          cast(mepi36 as string) as mepi36,
          cast(mepi37 as string) as mepi37,
          cast(mepi38 as string) as mepi38,
          cast(mepi39 as string) as mepi39,
          cast(mepi40 as string) as mepi40,
          current_date ('America/Lima') as process_date,
          'as400' as record_source,
          cast(current_datetime('America/Lima') as timestamp) as load_date
        from `"""||var_project_operation||"""."""||var_dataset_bq_omni_izipay_azure||"""."""||var_table_mcfm019i||"""`
      """;
      EXECUTE IMMEDIATE(query);

      /* Truncar la tabla destino antes de insertar los nuevos datos*/
      SET query = """
        truncate table `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfm019i||"""` 
      """;
      EXECUTE IMMEDIATE(query);

      /* Insertar los datos desde la tabla temporal a la tabla destino*/
      SET query = """
        insert into `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfm019i||"""` 
        (
          mecest,
          mesitu,
          party_id_izi,
          mencom,
          memone,
          mecemm,
          memcc,
          metcc,
          meemod,
          meemon,
          meprau,
          meprop,
          mepags,
          mecash,
          metpmm,
          metpim,
          metpid,
          mest01,
          mest02,
          mest03,
          mest04,
          mest05,
          mest06,
          mest07,
          mest08,
          mest09,
          mest10,
          mest11,
          mest12,
          mest13,
          mest14,
          mest15,
          mest16,
          mest17,
          mest18,
          mest19,
          mest20,
          mest21,
          mest22,
          mest23,
          mest24,
          mest25,
          mest26,
          mest27,
          mest28,
          mest29,
          mest30,
          mest31,
          mest32,
          mest33,
          mest34,
          mest35,
          mest36,
          mest37,
          mest38,
          mest39,
          mest40,
          mepc01,
          mepc02,
          mepc03,
          mepc04,
          mepc05,
          mepc06,
          mepc07,
          mepc08,
          mepc09,
          mepc10,
          mepc11,
          mepc12,
          mepc13,
          mepc14,
          mepc15,
          mepc16,
          mepc17,
          mepc18,
          mepc19,
          mepc20,
          mepc21,
          mepc22,
          mepc23,
          mepc24,
          mepc25,
          mepc26,
          mepc27,
          mepc28,
          mepc29,
          mepc30,
          mepc31,
          mepc32,
          mepc33,
          mepc34,
          mepc35,
          mepc36,
          mepc37,
          mepc38,
          mepc39,
          mepc40,
          mefc01,
          mefc02,
          mefc03,
          mefc04,
          mefc05,
          mefc06,
          mefc07,
          mefc08,
          mefc09,
          mefc10,
          mefc11,
          mefc12,
          mefc13,
          mefc14,
          mefc15,
          mefc16,
          mefc17,
          mefc18,
          mefc19,
          mefc20,
          mefc21,
          mefc22,
          mefc23,
          mefc24,
          mefc25,
          mefc26,
          mefc27,
          mefc28,
          mefc29,
          mefc30,
          mefc31,
          mefc32,
          mefc33,
          mefc34,
          mefc35,
          mefc36,
          mefc37,
          mefc38,
          mefc39,
          mefc40,
          mencon,
          mecade,
          mecafr,
          mesucu,
          meprom,
          meejec,
          medire,
          meubig,
          mecpos,
          metele,
          mefax,
          mediof,
          meubof,
          mecpof,
          meteof,
          mefxof,
          meclaf,
          meclar,
          mefing,
          mehing,
          mefape,
          mehape,
          mefmod,
          mehmod,
          mefblq,
          mehblq,
          meobse,
          mebcop,
          mechqn,
          meiade,
          mefpco,
          mefuco,
          mefpfr,
          mefufr,
          mefipo,
          mempgr,
          mempfi,
          mempqm,
          mempfm,
          mempim,
          meiemp,
          meiexp,
          meitar,
          metpmc,
          meqtpr,
          meqtjp,
          meqomn,
          meqbul,
          meqter,
          meqina,
          meqtp0,
          meimp0,
          meqtm0,
          meimm0,
          meqtr0,
          menet0,
          mersoc,
          meprov,
          medepa,
          meprof,
          medeof,
          medsof,
          mesvco,
          medist,
          mezona,
          memblq,
          mezoof,
          mecuad,
          mecuof,
          mecedc,
          medtvi,
          mednvi,
          mednro,
          medint,
          medmz,
          medlot,
          medkm,
          medsec,
          medgpo,
          medniv,
          medtda,
          meotvi,
          meonvi,
          meonro,
          meoint,
          meomz,
          meolot,
          meokm,
          meosec,
          meogpo,
          meoniv,
          meotda,
          mepagw,
          mehatd,
          mehath,
          meoptp,
          meopmo,
          meopto,
          meopcr,
          meoppv,
          meopec,
          meoppa,
          meopns,
          medatd,
          medath,
          memcom,
          megrue,
          mecjco,
          mesadv,
          meecmr,
          meagen,
          mempti,
          meqtdu,
          meqtcf,
          meqtcm,
          meqtip,
          meqtla,
          mepais,
          megpdc,
          mechqb,
          meuser,
          meqtcp,
          meqtpp,
          meceae,
          mesubg,
          mececo,
          mepfsc,
          mepfib,
          mepfmr,
          mepfid,
          mepi01,
          mepi02,
          mepi03,
          mepi04,
          mepi05,
          mepi06,
          mepi07,
          mepi08,
          mepi09,
          mepi10,
          mepi11,
          mepi12,
          mepi13,
          mepi14,
          mepi15,
          mepi16,
          mepi17,
          mepi18,
          mepi19,
          mepi20,
          mepi21,
          mepi22,
          mepi23,
          mepi24,
          mepi25,
          mepi26,
          mepi27,
          mepi28,
          mepi29,
          mepi30,
          mepi31,
          mepi32,
          mepi33,
          mepi34,
          mepi35,
          mepi36,
          mepi37,
          mepi38,
          mepi39,
          mepi40,
          process_date,
          record_source,
          load_date,
          creation_user
        )
        select
          a.mecest,
          a.mesitu,
          b.party_id_izi as party_id_izi,
          a.mencom,
          a.memone,
          a.mecemm,
          a.memcc,
          a.metcc,
          a.meemod,
          a.meemon,
          a.meprau,
          a.meprop,
          a.mepags,
          a.mecash,
          a.metpmm,
          a.metpim,
          a.metpid,
          a.mest01,
          a.mest02,
          a.mest03,
          a.mest04,
          a.mest05,
          a.mest06,
          a.mest07,
          a.mest08,
          a.mest09,
          a.mest10,
          a.mest11,
          a.mest12,
          a.mest13,
          a.mest14,
          a.mest15,
          a.mest16,
          a.mest17,
          a.mest18,
          a.mest19,
          a.mest20,
          a.mest21,
          a.mest22,
          a.mest23,
          a.mest24,
          a.mest25,
          a.mest26,
          a.mest27,
          a.mest28,
          a.mest29,
          a.mest30,
          a.mest31,
          a.mest32,
          a.mest33,
          a.mest34,
          a.mest35,
          a.mest36,
          a.mest37,
          a.mest38,
          a.mest39,
          a.mest40,
          a.mepc01,
          a.mepc02,
          a.mepc03,
          a.mepc04,
          a.mepc05,
          a.mepc06,
          a.mepc07,
          a.mepc08,
          a.mepc09,
          a.mepc10,
          a.mepc11,
          a.mepc12,
          a.mepc13,
          a.mepc14,
          a.mepc15,
          a.mepc16,
          a.mepc17,
          a.mepc18,
          a.mepc19,
          a.mepc20,
          a.mepc21,
          a.mepc22,
          a.mepc23,
          a.mepc24,
          a.mepc25,
          a.mepc26,
          a.mepc27,
          a.mepc28,
          a.mepc29,
          a.mepc30,
          a.mepc31,
          a.mepc32,
          a.mepc33,
          a.mepc34,
          a.mepc35,
          a.mepc36,
          a.mepc37,
          a.mepc38,
          a.mepc39,
          a.mepc40,
          a.mefc01,
          a.mefc02,
          a.mefc03,
          a.mefc04,
          a.mefc05,
          a.mefc06,
          a.mefc07,
          a.mefc08,
          a.mefc09,
          a.mefc10,
          a.mefc11,
          a.mefc12,
          a.mefc13,
          a.mefc14,
          a.mefc15,
          a.mefc16,
          a.mefc17,
          a.mefc18,
          a.mefc19,
          a.mefc20,
          a.mefc21,
          a.mefc22,
          a.mefc23,
          a.mefc24,
          a.mefc25,
          a.mefc26,
          a.mefc27,
          a.mefc28,
          a.mefc29,
          a.mefc30,
          a.mefc31,
          a.mefc32,
          a.mefc33,
          a.mefc34,
          a.mefc35,
          a.mefc36,
          a.mefc37,
          a.mefc38,
          a.mefc39,
          a.mefc40,
          a.mencon,
          a.mecade,
          a.mecafr,
          a.mesucu,
          a.meprom,
          a.meejec,
          AEAD.ENCRYPT(c.key, cast(a.medire as string), c.constant) as medire,
          a.meubig,
          a.mecpos,
          AEAD.ENCRYPT(d.key, cast(a.metele as string), d.constant) as metele,
          AEAD.ENCRYPT(e.key, cast(a.mefax as string), e.constant) as mefax,
          AEAD.ENCRYPT(f.key, cast(a.mediof as string), f.constant) as mediof,
          a.meubof,
          a.mecpof,
          AEAD.ENCRYPT(g.key, cast(a.meteof as string), g.constant) as meteof,
          AEAD.ENCRYPT(h.key, cast(a.mefxof as string), h.constant) as mefxof,
          a.meclaf,
          a.meclar,
          a.mefing,
          a.mehing,
          a.mefape,
          a.mehape,
          a.mefmod,
          a.mehmod,
          a.mefblq,
          a.mehblq,
          a.meobse,
          a.mebcop,
          AEAD.ENCRYPT(i.key, cast(a.mechqn as string), i.constant) as mechqn,
          a.meiade,
          a.mefpco,
          a.mefuco,
          a.mefpfr,
          a.mefufr,
          a.mefipo,
          a.mempgr,
          a.mempfi,
          a.mempqm,
          a.mempfm,
          a.mempim,
          a.meiemp,
          a.meiexp,
          a.meitar,
          a.metpmc,
          a.meqtpr,
          a.meqtjp,
          a.meqomn,
          a.meqbul,
          a.meqter,
          a.meqina,
          a.meqtp0,
          a.meimp0,
          a.meqtm0,
          a.meimm0,
          a.meqtr0,
          a.menet0,
          AEAD.ENCRYPT(k.key, cast(a.mersoc as string), k.constant) as mersoc,
          a.meprov,
          a.medepa,
          a.meprof,
          a.medeof,
          a.medsof,
          a.mesvco,
          a.medist,
          a.mezona,
          a.memblq,
          a.mezoof,
          a.mecuad,
          a.mecuof,
          a.mecedc,
          a.medtvi,
          a.mednvi,
          a.mednro,
          a.medint,
          a.medmz,
          a.medlot,
          a.medkm,
          a.medsec,
          a.medgpo,
          a.medniv,
          a.medtda,
          a.meotvi,
          a.meonvi,
          a.meonro,
          a.meoint,
          a.meomz,
          a.meolot,
          a.meokm,
          a.meosec,
          a.meogpo,
          a.meoniv,
          a.meotda,
          a.mepagw,
          a.mehatd,
          a.mehath,
          a.meoptp,
          a.meopmo,
          a.meopto,
          a.meopcr,
          a.meoppv,
          a.meopec,
          a.meoppa,
          a.meopns,
          a.medatd,
          a.medath,
          a.memcom,
          a.megrue,
          a.mecjco,
          a.mesadv,
          a.meecmr,
          a.meagen,
          a.mempti,
          a.meqtdu,
          a.meqtcf,
          a.meqtcm,
          a.meqtip,
          a.meqtla,
          a.mepais,
          a.megpdc,
          AEAD.ENCRYPT(j.key, cast(a.mechqb as string), j.constant) as mechqb,
          a.meuser,
          a.meqtcp,
          a.meqtpp,
          a.meceae,
          a.mesubg,
          a.mececo,
          a.mepfsc,
          a.mepfib,
          a.mepfmr,
          a.mepfid,
          a.mepi01,
          a.mepi02,
          a.mepi03,
          a.mepi04,
          a.mepi05,
          a.mepi06,
          a.mepi07,
          a.mepi08,
          a.mepi09,
          a.mepi10,
          a.mepi11,
          a.mepi12,
          a.mepi13,
          a.mepi14,
          a.mepi15,
          a.mepi16,
          a.mepi17,
          a.mepi18,
          a.mepi19,
          a.mepi20,
          a.mepi21,
          a.mepi22,
          a.mepi23,
          a.mepi24,
          a.mepi25,
          a.mepi26,
          a.mepi27,
          a.mepi28,
          a.mepi29,
          a.mepi30,
          a.mepi31,
          a.mepi32,
          a.mepi33,
          a.mepi34,
          a.mepi35,
          a.mepi36,
          a.mepi37,
          a.mepi38,
          a.mepi39,
          a.mepi40,
          a.process_date,
          a.record_source,
          a.load_date,
          session_user() as creation_user
        from `"""||var_project_operation||"""."""||var_dataset_raw_stage_as400||"""."""||var_table_tmp_mcfm019i||"""` a
        left join `"""||var_project_sensitive||"""."""||var_dataset_master_pii||"""."""||var_table_itc_iden_party_data_control||"""` b on trim(a.meruce) = b.document_number
        left join `"""||var_project_sensitive||"""."""||var_dataset_secure_secrets||"""."""||var_table_config_protected_data||"""` c on c.code = 'C_ADDRESS'
        left join `"""||var_project_sensitive||"""."""||var_dataset_secure_secrets||"""."""||var_table_config_protected_data||"""` d on d.code = 'C_TELEPHONE'
        left join `"""||var_project_sensitive||"""."""||var_dataset_secure_secrets||"""."""||var_table_config_protected_data||"""` e on e.code = 'C_FAX'
        left join `"""||var_project_sensitive||"""."""||var_dataset_secure_secrets||"""."""||var_table_config_protected_data||"""` f on f.code = 'C_ADDRESS'
        left join `"""||var_project_sensitive||"""."""||var_dataset_secure_secrets||"""."""||var_table_config_protected_data||"""` g on g.code = 'C_TELEPHONE'
        left join `"""||var_project_sensitive||"""."""||var_dataset_secure_secrets||"""."""||var_table_config_protected_data||"""` h on h.code = 'C_ADDRESS'
        left join `"""||var_project_sensitive||"""."""||var_dataset_secure_secrets||"""."""||var_table_config_protected_data||"""` i on i.code = 'C_ACCOUNT_NUMBER'
        left join `"""||var_project_sensitive||"""."""||var_dataset_secure_secrets||"""."""||var_table_config_protected_data||"""` j on j.code = 'C_ACCOUNT_NUMBER'
        left join `"""||var_project_sensitive||"""."""||var_dataset_secure_secrets||"""."""||var_table_config_protected_data||"""` k on k.code = 'C_FULL_NAME'
      """;
      EXECUTE IMMEDIATE(query);

      /* Eliminar la tabla temporal*/
      SET query = """
        drop table `"""||var_project_operation||"""."""||var_dataset_raw_stage_as400||"""."""||var_table_tmp_mcfm019i||"""`
      """;
      EXECUTE IMMEDIATE(query);

  END IF;
END;


CREATE OR REPLACE PROCEDURE `prd-izipay-data-operation.raw_stage_as400.prc_load_as400_mcfm020`(var_project_operation STRING, var_project_storage STRING, var_project_sensitive STRING)
BEGIN
  DECLARE query STRING;
  DECLARE cant INT64;
  DECLARE var_table_tmp_mcfm020 STRING;

  DECLARE var_dataset_raw_as400 STRING;
  DECLARE var_table_mcfm020 STRING;
  DECLARE var_dataset_bq_omni_izipay_azure STRING;
  DECLARE var_dataset_raw_stage_as400 STRING;
  DECLARE var_dataset_secure_secrets STRING;
  DECLARE var_dataset_master_pii STRING;
  DECLARE var_table_config_protected_data STRING;
  DECLARE var_table_iden_party_data_control STRING;

  SET var_dataset_raw_stage_as400 = 'raw_stage_as400';
  SET var_dataset_raw_as400 = 'raw_as400';
  SET var_table_mcfm020 = 'mcfm020';
  SET var_dataset_bq_omni_izipay_azure = 'bq_omni_izipay_azure_saizipaydatamarts';  
  SET var_dataset_secure_secrets = 'secure_secrets'; 
  SET var_dataset_master_pii = 'master_pii'; 
  SET var_table_config_protected_data = 'config_protected_data';
  SET var_table_iden_party_data_control = 'iden_party_data_control';

/*
  DECLARE var_project_operation STRING;
  DECLARE var_project_storage STRING;
  DECLARE var_project_sensitive STRING; --prd-izipay-data-sensitive --> proyecto independiente

  SET var_project_operation = 'dev-izipay-data-operation';
  SET var_project_storage = 'dev-izipay-data-storage';
  SET var_project_sensitive = 'dev-izipay-data-storage';  
  */

  SET var_table_tmp_mcfm020 = concat('tmp_',var_table_mcfm020);

  /* Verificar si la tabla EXTERNA tiene contenido, guardar el conteo*/
  SET query = """
   select count(1)
   from `"""||var_project_operation||"""."""||var_dataset_bq_omni_izipay_azure||"""."""||var_table_mcfm020||"""`
  """;
  EXECUTE IMMEDIATE(query)
  into cant;

  /* Si la tabla tiene contenido, insertar la data desde la tabla  EXTERNA hacia la tabla en DATA_STORAGE*/
  IF ifnull(cant,0) > 0 

    THEN

      /* Crear una tabla temporal con los datos sumando las columnas adicionales para auditoria*/
      SET query = """
        create or replace table `"""||var_project_operation||"""."""||var_dataset_raw_stage_as400||"""."""||var_table_tmp_mcfm020||"""` as
        select
          cast(cccest as string) as cccest,
          cast(cccate as string) as cccate,
          cast(ccnomb as string) as ccnomb,          
          cast(cccarg as string) as cccarg,
          cast(ccdocu as string) as ccdocu,
          cast(ccdire as string) as ccdire,          
          cast(cccpos as string) as cccpos,
          cast(cctel1 as string) as cctel1,          
          cast(cctel2 as string) as cctel2,          
          cast(ccmail as string) as ccmail,          
          cast(ccfnac as string) as ccfnac,
          cast(ccpref as string) as ccpref,
          cast(ccfmod as string) as ccfmod,
          cast(cchmod as string) as cchmod,
          cast(ccumod as string) as ccumod,
          cast(cccomx as string) as cccomx,
          cast(ccrefe as string) as ccrefe,
          cast(ccmai1 as string) as ccmai1,          
          cast(ccmai2 as string) as ccmai2,          
          cast(ccmai3 as string) as ccmai3,          
          current_date ('America/Lima') as process_date,
          'as400' as record_source,
          cast(current_datetime('America/Lima') as timestamp) as load_date
        from `"""||var_project_operation||"""."""||var_dataset_bq_omni_izipay_azure||"""."""||var_table_mcfm020||"""` 
        """;
      EXECUTE IMMEDIATE(query);

      /* Truncar la tabla destino antes de insertar los nuevos datos*/
      SET query = """
        truncate table `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfm020||"""` 
      """;
      EXECUTE IMMEDIATE(query);

      /* Insertar los datos desde la tabla temporal a la tabla destino*/
      SET query = """
        insert into `"""||var_project_storage||"""."""||var_dataset_raw_as400||"""."""||var_table_mcfm020||"""` 
        (
          cccest,
          cccate,
          ccnomb,
          cccarg,
          party_id_izi_representante,
          ccdire,
          cccpos,
          cctel1,
          cctel2,
          ccmail,
          ccfnac,
          ccpref,
          ccfmod,
          cchmod,
          ccumod,
          cccomx,
          ccrefe,
          ccmai1,
          ccmai2,
          ccmai3,
          process_date,
          record_source,
          load_date,
          creation_user
        )
        select
          a.cccest,
          a.cccate,          
          AEAD.ENCRYPT(c.key, cast(a.ccnomb as string), c.constant) as ccnomb,
          a.cccarg,
          b.party_id_izi as party_id_izi_representante,
          AEAD.ENCRYPT(d.key, cast(a.ccdire as string), d.constant) as ccdire,
          a.cccpos,
          AEAD.ENCRYPT(e.key, cast(a.cctel1 as string), e.constant) as cctel1,
          AEAD.ENCRYPT(f.key, cast(a.cctel2 as string), f.constant) as cctel2,
          AEAD.ENCRYPT(g.key, cast(a.ccmail as string), g.constant) as ccmail,
          a.ccfnac,
          a.ccpref,
          a.ccfmod,
          a.cchmod,
          a.ccumod,
          a.cccomx,
          a.ccrefe,
          AEAD.ENCRYPT(h.key, cast(a.ccmai1 as string), h.constant) as ccmai1,
          AEAD.ENCRYPT(i.key, cast(a.ccmai2 as string), i.constant) as ccmai2,
          AEAD.ENCRYPT(j.key, cast(a.ccmai3 as string), j.constant) as ccmai3,
          a.process_date,
          a.record_source,
          a.load_date,
          session_user() as creation_user
        from `"""||var_project_operation||"""."""||var_dataset_raw_stage_as400||"""."""||var_table_tmp_mcfm020||"""` a 
        left join `"""||var_project_sensitive||"""."""||var_dataset_master_pii||"""."""||var_table_iden_party_data_control||"""` b on trim(a.ccdocu) = b.document_number
        left join `"""||var_project_sensitive||"""."""||var_dataset_secure_secrets||"""."""||var_table_config_protected_data||"""` c on c.code = 'C_FULL_NAME'
        left join `"""||var_project_sensitive||"""."""||var_dataset_secure_secrets||"""."""||var_table_config_protected_data||"""` d on d.code = 'C_FULL_NAME'
        left join `"""||var_project_sensitive||"""."""||var_dataset_secure_secrets||"""."""||var_table_config_protected_data||"""` e on e.code = 'C_TELEPHONE'
        left join `"""||var_project_sensitive||"""."""||var_dataset_secure_secrets||"""."""||var_table_config_protected_data||"""` f on f.code = 'C_TELEPHONE'
        left join `"""||var_project_sensitive||"""."""||var_dataset_secure_secrets||"""."""||var_table_config_protected_data||"""` g on g.code = 'C_EMAIL'
        left join `"""||var_project_sensitive||"""."""||var_dataset_secure_secrets||"""."""||var_table_config_protected_data||"""` h on h.code = 'C_EMAIL'
        left join `"""||var_project_sensitive||"""."""||var_dataset_secure_secrets||"""."""||var_table_config_protected_data||"""` i on i.code = 'C_EMAIL'
        left join `"""||var_project_sensitive||"""."""||var_dataset_secure_secrets||"""."""||var_table_config_protected_data||"""` j on j.code = 'C_EMAIL'
      """;
      EXECUTE IMMEDIATE(query);

      /* Eliminar la tabla temporal*/
      SET query = """
        drop table `"""||var_project_operation||"""."""||var_dataset_raw_stage_as400||"""."""||var_table_tmp_mcfm020||"""`
      """;
      EXECUTE IMMEDIATE(query);

  END IF;
END;


CREATE OR REPLACE PROCEDURE `prd-izipay-data-operation.raw_stage_salesforce.prc_load_salesforce_case`(var_project_operation STRING, var_project_storage STRING, var_project_sensitive STRING)
BEGIN
  DECLARE query STRING;
  DECLARE cant INT64;
  DECLARE var_table_tmp_case STRING;

  DECLARE var_dataset_raw_stage_salesforce STRING;
  DECLARE var_dataset_raw_salesforce STRING;
  DECLARE var_table_case STRING;
  DECLARE var_dataset_bq_omni_izipay_azure STRING;  
  DECLARE var_dataset_secure_secrets STRING;
  DECLARE var_dataset_master_pii STRING;
  DECLARE var_table_config_protected_data STRING;
  DECLARE var_table_itc_iden_party_data_control STRING;

  SET var_dataset_raw_stage_salesforce = 'raw_stage_salesforce';
  SET var_dataset_raw_salesforce = 'raw_salesforce';
  SET var_table_case = 'case';
  SET var_dataset_bq_omni_izipay_azure = 'bq_omni_izipay_azure_saizipaydatamarts';
  SET var_dataset_secure_secrets = 'secure_secrets';
  SET var_dataset_master_pii = 'master_pii';
  SET var_table_config_protected_data = 'config_protected_data';
  SET var_table_itc_iden_party_data_control = 'iden_party_data_control';

/*
  DECLARE var_project_operation STRING;
  DECLARE var_project_storage STRING;
  DECLARE var_project_sensitive STRING; --prd-izipay-data-sensitive --> proyecto independiente

  SET var_project_operation = 'dev-izipay-data-operation';
  SET var_project_storage = 'dev-izipay-data-storage';
  SET var_project_sensitive = 'dev-izipay-data-storage';


  */

  SET var_table_tmp_case = concat('tmp_',var_table_case);

  /* Verificar si la tabla EXTERNA tiene contenido, guardar el conteo*/
  SET query = """
   select count(1)
   from `"""||var_project_operation||"""."""||var_dataset_bq_omni_izipay_azure||"""."""||var_table_case||"""`
  """;
  EXECUTE IMMEDIATE(query)
  into cant;

  /* Si la tabla tiene contenido, insertar la data desde la tabla  EXTERNA hacia la tabla en DATA_STORAGE*/
  IF ifnull(cant,0) > 0 

    THEN

      /* Crear una tabla temporal con los datos sumando las columnas adicionales para auditoria*/
      SET query = """
        create or replace table `"""||var_project_operation||"""."""||var_dataset_raw_stage_salesforce||"""."""||var_table_tmp_case||"""` as
        select
            cast(accountid as string) as accountid,
            cast(businesshoursid as string) as businesshoursid,
            cast(c_digo_comercio_buscar__c as string) as c_digo_comercio_buscar__c,
            cast(casenumber as string) as casenumber,
            cast(cercania__c as string) as cercania__c,
            cast(closeddate as string) as closeddate,
            cast(comments as string) as comments,
            cast(contactemail as string) as contactemail,
            cast(contactfax as string) as contactfax,
            cast(contactid as string) as contactid,
            cast(contactmobile as string) as contactmobile,
            cast(contactphone as string) as contactphone,
            cast(createdbyid as string) as createdbyid,
            cast(createddate as string) as createddate,
            cast(currencyisocode as string) as currencyisocode,
            cast(description as string) as description,
            cast(gsc_accountsegment__c as string) as gsc_accountsegment__c,
            cast(gsc_additionalposinstallation__c as string) as gsc_additionalposinstallation__c,
            cast(gsc_area_responsable__c as string) as gsc_area_responsable__c,
            cast(gsc_arisale__c as string) as gsc_arisale__c,
            cast(gsc_asset__c as string) as gsc_asset__c,
            cast(gsc_attentionlevel__c as string) as gsc_attentionlevel__c,
            cast(gsc_blockingreason__c as string) as gsc_blockingreason__c,
            cast(gsc_bulkupload__c as string) as gsc_bulkupload__c,
            cast(gsc_casechangeofequipment__c as string) as gsc_casechangeofequipment__c,
            cast(gsc_casegivenassetserialnumber__c as string) as gsc_casegivenassetserialnumber__c,
            cast(gsc_casereceivedassetserialnumber__c as string) as gsc_casereceivedassetserialnumber__c,
            cast(gsc_casereceivedcommerceassettype__c as string) as gsc_casereceivedcommerceassettype__c,
            cast(gsc_channel__c as string) as gsc_channel__c,
            cast(gsc_classificationticket__c as string) as gsc_classificationticket__c,
            cast(gsc_codelocking__c as string) as gsc_codelocking__c,
            cast(gsc_codigo_de_comercio__c as string) as gsc_codigo_de_comercio__c,
            cast(gsc_commercecancellation__c as string) as gsc_commercecancellation__c,
            cast(gsc_customerservice__c as string) as gsc_customerservice__c,
            cast(gsc_dataupdatetype__c as string) as gsc_dataupdatetype__c,
            cast(gsc_derivado_a_wix__c as string) as gsc_derivado_a_wix__c,
            cast(gsc_derivedfromarisale__c as string) as gsc_derivedfromarisale__c,
            cast(gsc_derivedtoamex__c as string) as gsc_derivedtoamex__c,
            cast(gsc_establishmentcode__c as string) as gsc_establishmentcode__c,
            cast(gsc_fecha_de_retiro_de_pos__c as string) as gsc_fecha_de_retiro_de_pos__c,
            cast(gsc_installationcharge__c as string) as gsc_installationcharge__c,
            cast(gsc_isvirtualproduct__c as string) as gsc_isvirtualproduct__c,
            cast(gsc_izicollector__c as string) as gsc_izicollector__c,
            cast(gsc_locktype__c as string) as gsc_locktype__c,
            cast(gsc_modalitytype__c as string) as gsc_modalitytype__c,
            cast(gsc_motivo_consulta_de_producto_virtual__c as string) as gsc_motivo_consulta_de_producto_virtual__c,
            cast(gsc_motivo_de_instalacion__c as string) as gsc_motivo_de_instalacion__c,
            cast(gsc_newemail__c as string) as gsc_newemail__c,
            cast(gsc_newphone__c as string) as gsc_newphone__c,
            cast(gsc_numero_de_serie_del_pos__c as string) as gsc_numero_de_serie_del_pos__c,
            cast(gsc_oldemail__c as string) as gsc_oldemail__c,
            cast(gsc_oldphone__c as string) as gsc_oldphone__c,
            cast(gsc_parametercode__c as string) as gsc_parametercode__c,
            cast(gsc_posinstallationdatetime__c as string) as gsc_posinstallationdatetime__c,
            cast(gsc_posproblemdescription__c as string) as gsc_posproblemdescription__c,
            cast(gsc_principalsubject__c as string) as gsc_principalsubject__c,
            cast(gsc_proceso__c as string) as gsc_proceso__c,
            cast(gsc_product__c as string) as gsc_product__c,
            cast(gsc_producttype__c as string) as gsc_producttype__c,
            cast(gsc_programa_iziplus__c as string) as gsc_programa_iziplus__c,
            cast(gsc_querydetails__c as string) as gsc_querydetails__c,
            cast(gsc_realtimepaymentprogramcause__c as string) as gsc_realtimepaymentprogramcause__c,
            cast(gsc_reason__c as string) as gsc_reason__c,
            cast(gsc_reasondataupdate__c as string) as gsc_reasondataupdate__c,
            cast(gsc_reasondisaffiliationamexarisale__c as string) as gsc_reasondisaffiliationamexarisale__c,
            cast(gsc_reasonforchange__c as string) as gsc_reasonforchange__c,
            cast(gsc_reasonforlinkingdisconnection__c as string) as gsc_reasonforlinkingdisconnection__c,
            cast(gsc_referredtoamex__c as string) as gsc_referredtoamex__c,
            cast(gsc_refundmoney__c as string) as gsc_refundmoney__c,
            cast(gsc_reorganizationarisale__c as string) as gsc_reorganizationarisale__c,
            cast(gsc_reorganizeneeds__c as string) as gsc_reorganizeneeds__c,
            cast(gsc_reprogrammingrequests__c as string) as gsc_reprogrammingrequests__c,
            cast(gsc_ruc__c as string) as gsc_ruc__c,
            cast(gsc_scheduleddate__c as string) as gsc_scheduleddate__c,
            cast(gsc_selectedoptions__c as string) as gsc_selectedoptions__c,
            cast(gsc_sentsupport__c as string) as gsc_sentsupport__c,
            cast(gsc_separatingseries__c as string) as gsc_separatingseries__c,
            cast(gsc_serie_de_codigo_unico__c as string) as gsc_serie_de_codigo_unico__c,
            cast(gsc_seriesthatislinked__c as string) as gsc_seriesthatislinked__c,
            cast(gsc_shops__c as string) as gsc_shops__c,
            cast(gsc_suppliervisit__c as string) as gsc_suppliervisit__c,
            cast(gsc_supportvisittype__c as string) as gsc_supportvisittype__c,
            cast(gsc_tarea_abierta__c as string) as gsc_tarea_abierta__c,
            cast(gsc_tarea_de_gestion_de_campo_creada__c as string) as gsc_tarea_de_gestion_de_campo_creada__c,
            cast(gsc_tarea_fecha_de_instalacion_creada__c as string) as gsc_tarea_fecha_de_instalacion_creada__c,
            cast(gsc_thirdpartyaccount__c as string) as gsc_thirdpartyaccount__c,
            cast(gsc_ticketsubject__c as string) as gsc_ticketsubject__c,
            cast(gsc_tipo_de_cliente__c as string) as gsc_tipo_de_cliente__c,
            cast(gsc_tipo_de_incidencia_arisale__c as string) as gsc_tipo_de_incidencia_arisale__c,
            cast(gsc_turn__c as string) as gsc_turn__c,
            cast(gsc_typeofcare__c as string) as gsc_typeofcare__c,
            cast(gsc_typeofposwithincident__c as string) as gsc_typeofposwithincident__c,
            cast(gsc_typeofreasonforconsultation__c as string) as gsc_typeofreasonforconsultation__c,
            cast(gsc_typeproductchange__c as string) as gsc_typeproductchange__c,
            cast(gsc_uniquecodeseries__c as string) as gsc_uniquecodeseries__c,
            cast(gsc_validatebulkupload__c as string) as gsc_validatebulkupload__c,
            cast(gsc_valueaddedservice__c as string) as gsc_valueaddedservice__c,
            cast(id as string) as id,
            cast(isclosed as string) as isclosed,
            cast(isclosedoncreate as string) as isclosedoncreate,
            cast(isdeleted as string) as isdeleted,
            cast(isescalated as string) as isescalated,
            cast(isstopped as string) as isstopped,
            cast(language as string) as language,
            cast(lastmodifiedbyid as string) as lastmodifiedbyid,
            cast(lastmodifieddate as string) as lastmodifieddate,
            cast(lastreferenceddate as string) as lastreferenceddate,
            cast(lastvieweddate as string) as lastvieweddate,
            cast(masterrecordid as string) as masterrecordid,
            cast(milestonestatus as string) as milestonestatus,
            cast(motivo_de_consulta_izipay__c as string) as motivo_de_consulta_izipay__c,
            cast(origin as string) as origin,
            cast(ownerid as string) as ownerid,
            cast(parentid as string) as parentid,
            cast(priority as string) as priority,
            cast(productid as string) as productid,
            cast(provincia_del_comercio__c as string) as provincia_del_comercio__c,
            cast(reason as string) as reason,
            cast(recordtypeid as string) as recordtypeid,
            cast(servicio_de_comercio__c as string) as servicio_de_comercio__c,
            cast(slaexitdate as string) as slaexitdate,
            cast(slastartdate as string) as slastartdate,
            cast(sourceid as string) as sourceid,
            cast(status as string) as status,
            cast(stopstartdate as string) as stopstartdate,
            cast(subject as string) as subject,
            cast(suppliedcompany as string) as suppliedcompany,
            cast(suppliedemail as string) as suppliedemail,
            cast(suppliedname as string) as suppliedname,
            cast(suppliedphone as string) as suppliedphone,
            cast(systemmodstamp as string) as systemmodstamp,
            cast(tarea_fecha_recojo_pos_creada__c as string) as tarea_fecha_recojo_pos_creada__c,
            cast(titulo_del_caso__c as string) as titulo_del_caso__c,
            cast(type as string) as type,
            cast(izis_casetype__c as string) as izis_casetype__c,
            cast(izis_type__c as string) as izis_type__c,
            cast(estado_emailtocase__c as string) as estado_emailtocase__c,
            cast(izis_npsmail__c as string) as izis_npsmail__c,
            cast(gsc_contact_point_address__c as string) as gsc_contact_point_address__c,
            cast(izi_unidad_de_negocio_del_propietario__c as string) as izi_unidad_de_negocio_del_propietario__c,
            cast(izi_unidaddenegociopropietariodelcaso__c as string) as izi_unidaddenegociopropietariodelcaso__c,
            current_date ('America/Lima') as process_date,
            'salesforce' as record_source,
            cast(current_datetime('America/Lima') as timestamp) as load_date
        from `"""||var_project_operation||"""."""||var_dataset_bq_omni_izipay_azure||"""."""||var_table_case||"""`
      """;
      EXECUTE IMMEDIATE(query);

      /* Truncar la tabla destino antes de insertar los nuevos datos*/
      SET query = """
        truncate table `"""||var_project_storage||"""."""||var_dataset_raw_salesforce||"""."""||var_table_case||"""` 
      """;
      EXECUTE IMMEDIATE(query);

      /* Insertar los datos desde la tabla temporal a la tabla destino*/
      SET query = """
        insert into `"""||var_project_storage||"""."""||var_dataset_raw_salesforce||"""."""||var_table_case||"""` 
        (
            process_date,
            accountid,
            businesshoursid,
            c_digo_comercio_buscar__c,
            casenumber,
            cercania__c,
            closeddate,
            comments,
            contactemail,
            contactfax,
            contactid,
            contactmobile,
            contactphone,
            createdbyid,
            createddate,
            currencyisocode,
            description,
            gsc_accountsegment__c,
            gsc_additionalposinstallation__c,
            gsc_area_responsable__c,
            gsc_arisale__c,
            gsc_asset__c,
            gsc_attentionlevel__c,
            gsc_blockingreason__c,
            gsc_bulkupload__c,
            gsc_casechangeofequipment__c,
            gsc_casegivenassetserialnumber__c,
            gsc_casereceivedassetserialnumber__c,
            gsc_casereceivedcommerceassettype__c,
            gsc_channel__c,
            gsc_classificationticket__c,
            gsc_codelocking__c,
            gsc_codigo_de_comercio__c,
            gsc_commercecancellation__c,
            gsc_customerservice__c,
            gsc_dataupdatetype__c,
            gsc_derivado_a_wix__c,
            gsc_derivedfromarisale__c,
            gsc_derivedtoamex__c,
            gsc_establishmentcode__c,
            gsc_fecha_de_retiro_de_pos__c,
            gsc_installationcharge__c,
            gsc_isvirtualproduct__c,
            gsc_izicollector__c,
            gsc_locktype__c,
            gsc_modalitytype__c,
            gsc_motivo_consulta_de_producto_virtual__c,
            gsc_motivo_de_instalacion__c,
            gsc_newemail__c,
            gsc_newphone__c,
            gsc_numero_de_serie_del_pos__c,
            gsc_oldemail__c,
            gsc_oldphone__c,
            gsc_parametercode__c,
            gsc_posinstallationdatetime__c,
            gsc_posproblemdescription__c,
            gsc_principalsubject__c,
            gsc_proceso__c,
            gsc_product__c,
            gsc_producttype__c,
            gsc_programa_iziplus__c,
            gsc_querydetails__c,
            gsc_realtimepaymentprogramcause__c,
            gsc_reason__c,
            gsc_reasondataupdate__c,
            gsc_reasondisaffiliationamexarisale__c,
            gsc_reasonforchange__c,
            gsc_reasonforlinkingdisconnection__c,
            gsc_referredtoamex__c,
            gsc_refundmoney__c,
            gsc_reorganizationarisale__c,
            gsc_reorganizeneeds__c,
            gsc_reprogrammingrequests__c,
            party_id_izi,
            gsc_scheduleddate__c,
            gsc_selectedoptions__c,
            gsc_sentsupport__c,
            gsc_separatingseries__c,
            gsc_serie_de_codigo_unico__c,
            gsc_seriesthatislinked__c,
            gsc_shops__c,
            gsc_suppliervisit__c,
            gsc_supportvisittype__c,
            gsc_tarea_abierta__c,
            gsc_tarea_de_gestion_de_campo_creada__c,
            gsc_tarea_fecha_de_instalacion_creada__c,
            gsc_thirdpartyaccount__c,
            gsc_ticketsubject__c,
            gsc_tipo_de_cliente__c,
            gsc_tipo_de_incidencia_arisale__c,
            gsc_turn__c,
            gsc_typeofcare__c,
            gsc_typeofposwithincident__c,
            gsc_typeofreasonforconsultation__c,
            gsc_typeproductchange__c,
            gsc_uniquecodeseries__c,
            gsc_validatebulkupload__c,
            gsc_valueaddedservice__c,
            id,
            isclosed,
            isclosedoncreate,
            isdeleted,
            isescalated,
            isstopped,
            language,
            lastmodifiedbyid,
            lastmodifieddate,
            lastreferenceddate,
            lastvieweddate,
            masterrecordid,
            milestonestatus,
            motivo_de_consulta_izipay__c,
            origin,
            ownerid,
            parentid,
            priority,
            productid,
            provincia_del_comercio__c,
            reason,
            recordtypeid,
            servicio_de_comercio__c,
            slaexitdate,
            slastartdate,
            sourceid,
            status,
            stopstartdate,
            subject,
            suppliedcompany,
            suppliedemail,
            suppliedname,
            suppliedphone,
            systemmodstamp,
            tarea_fecha_recojo_pos_creada__c,
            titulo_del_caso__c,
            type,
            izis_casetype__c,
            izis_type__c,
            estado_emailtocase__c,
            izis_npsmail__c,
            gsc_contact_point_address__c,
            record_source,
            load_date,
            creation_user,
            izi_unidad_de_negocio_del_propietario__c,
            izi_unidaddenegociopropietariodelcaso__c
        )
        select
            a.process_date,
            a.accountid,
            a.businesshoursid,
            a.c_digo_comercio_buscar__c,
            a.casenumber,
            a.cercania__c,
            a.closeddate,
            a.comments,
            AEAD.ENCRYPT(h.key, cast(a.contactemail as string), h.constant) as contactemail,
            AEAD.ENCRYPT(e.key, cast(a.contactfax as string), e.constant) as contactfax,
            a.contactid,
            AEAD.ENCRYPT(d.key, cast(a.contactmobile as string), d.constant) as contactmobile,
            AEAD.ENCRYPT(d.key, cast(a.contactphone as string), d.constant) as contactphone,
            a.createdbyid,
            a.createddate,
            a.currencyisocode,
            a.description,
            a.gsc_accountsegment__c,
            a.gsc_additionalposinstallation__c,
            a.gsc_area_responsable__c,
            a.gsc_arisale__c,
            a.gsc_asset__c,
            a.gsc_attentionlevel__c,
            a.gsc_blockingreason__c,
            a.gsc_bulkupload__c,
            a.gsc_casechangeofequipment__c,
            a.gsc_casegivenassetserialnumber__c,
            a.gsc_casereceivedassetserialnumber__c,
            a.gsc_casereceivedcommerceassettype__c,
            a.gsc_channel__c,
            a.gsc_classificationticket__c,
            a.gsc_codelocking__c,
            a.gsc_codigo_de_comercio__c,
            a.gsc_commercecancellation__c,
            a.gsc_customerservice__c,
            a.gsc_dataupdatetype__c,
            a.gsc_derivado_a_wix__c,
            a.gsc_derivedfromarisale__c,
            a.gsc_derivedtoamex__c,
            a.gsc_establishmentcode__c,
            a.gsc_fecha_de_retiro_de_pos__c,
            a.gsc_installationcharge__c,
            a.gsc_isvirtualproduct__c,
            a.gsc_izicollector__c,
            a.gsc_locktype__c,
            a.gsc_modalitytype__c,
            a.gsc_motivo_consulta_de_producto_virtual__c,
            a.gsc_motivo_de_instalacion__c,
            AEAD.ENCRYPT(h.key, cast(a.gsc_newemail__c as string), h.constant) as gsc_newemail__c,
            AEAD.ENCRYPT(d.key, cast(a.gsc_newphone__c as string), d.constant) as gsc_newphone__c,
            a.gsc_numero_de_serie_del_pos__c,
            AEAD.ENCRYPT(h.key, cast(a.gsc_oldemail__c as string), h.constant) as gsc_oldemail__c,
            AEAD.ENCRYPT(d.key, cast(a.gsc_oldphone__c as string), d.constant) as gsc_oldphone__c,
            a.gsc_parametercode__c,
            a.gsc_posinstallationdatetime__c,
            a.gsc_posproblemdescription__c,
            a.gsc_principalsubject__c,
            a.gsc_proceso__c,
            a.gsc_product__c,
            a.gsc_producttype__c,
            a.gsc_programa_iziplus__c,
            a.gsc_querydetails__c,
            a.gsc_realtimepaymentprogramcause__c,
            a.gsc_reason__c,
            a.gsc_reasondataupdate__c,
            a.gsc_reasondisaffiliationamexarisale__c,
            a.gsc_reasonforchange__c,
            a.gsc_reasonforlinkingdisconnection__c,
            a.gsc_referredtoamex__c,
            a.gsc_refundmoney__c,
            a.gsc_reorganizationarisale__c,
            a.gsc_reorganizeneeds__c,
            a.gsc_reprogrammingrequests__c,
            b.party_id_izi as party_id_izi,
            a.gsc_scheduleddate__c,
            a.gsc_selectedoptions__c,
            a.gsc_sentsupport__c,
            a.gsc_separatingseries__c,
            a.gsc_serie_de_codigo_unico__c,
            a.gsc_seriesthatislinked__c,
            a.gsc_shops__c,
            a.gsc_suppliervisit__c,
            a.gsc_supportvisittype__c,
            a.gsc_tarea_abierta__c,
            a.gsc_tarea_de_gestion_de_campo_creada__c,
            a.gsc_tarea_fecha_de_instalacion_creada__c,
            a.gsc_thirdpartyaccount__c,
            a.gsc_ticketsubject__c,
            a.gsc_tipo_de_cliente__c,
            a.gsc_tipo_de_incidencia_arisale__c,
            a.gsc_turn__c,
            a.gsc_typeofcare__c,
            a.gsc_typeofposwithincident__c,
            a.gsc_typeofreasonforconsultation__c,
            a.gsc_typeproductchange__c,
            a.gsc_uniquecodeseries__c,
            a.gsc_validatebulkupload__c,
            a.gsc_valueaddedservice__c,
            a.id,
            a.isclosed,
            a.isclosedoncreate,
            a.isdeleted,
            a.isescalated,
            a.isstopped,
            a.language,
            a.lastmodifiedbyid,
            a.lastmodifieddate,
            a.lastreferenceddate,
            a.lastvieweddate,
            a.masterrecordid,
            a.milestonestatus,
            a.motivo_de_consulta_izipay__c,
            a.origin,
            a.ownerid,
            a.parentid,
            a.priority,
            a.productid,
            a.provincia_del_comercio__c,
            a.reason,
            a.recordtypeid,
            a.servicio_de_comercio__c,
            a.slaexitdate,
            a.slastartdate,
            a.sourceid,
            a.status,
            a.stopstartdate,
            a.subject,
            a.suppliedcompany,
            AEAD.ENCRYPT(h.key, cast(a.suppliedemail as string), h.constant) as suppliedemail,
            a.suppliedname,
            AEAD.ENCRYPT(d.key, cast(a.suppliedphone as string), d.constant) as suppliedphone,
            a.systemmodstamp,
            a.tarea_fecha_recojo_pos_creada__c,
            a.titulo_del_caso__c,
            a.type,
            a.izis_casetype__c,
            izis_type__c,
            estado_emailtocase__c,
            izis_npsmail__c,
            gsc_contact_point_address__c,
            a.record_source,
            a.load_date,
            session_user() as creation_user,
            a.izi_unidad_de_negocio_del_propietario__c,
            a.izi_unidaddenegociopropietariodelcaso__c        
        from `"""||var_project_operation||"""."""||var_dataset_raw_stage_salesforce||"""."""||var_table_tmp_case||"""` a
        left join `"""||var_project_sensitive||"""."""||var_dataset_master_pii||"""."""||var_table_itc_iden_party_data_control||"""` b on trim(a.gsc_ruc__c) = b.document_number
        left join `"""||var_project_sensitive||"""."""||var_dataset_secure_secrets||"""."""||var_table_config_protected_data||"""` c on c.code = 'C_FULL_NAME'
        left join `"""||var_project_sensitive||"""."""||var_dataset_secure_secrets||"""."""||var_table_config_protected_data||"""` d on d.code = 'C_TELEPHONE'
        left join `"""||var_project_sensitive||"""."""||var_dataset_secure_secrets||"""."""||var_table_config_protected_data||"""` e on e.code = 'C_FAX'
        left join `"""||var_project_sensitive||"""."""||var_dataset_secure_secrets||"""."""||var_table_config_protected_data||"""` f on f.code = 'C_ADDRESS'
        left join `"""||var_project_sensitive||"""."""||var_dataset_secure_secrets||"""."""||var_table_config_protected_data||"""` g on g.code = 'C_TELEPHONE'
        left join `"""||var_project_sensitive||"""."""||var_dataset_secure_secrets||"""."""||var_table_config_protected_data||"""` h on h.code = 'C_EMAIL'
        left join `"""||var_project_sensitive||"""."""||var_dataset_secure_secrets||"""."""||var_table_config_protected_data||"""` i on i.code = 'C_ACCOUNT_NUMBER'
        left join `"""||var_project_sensitive||"""."""||var_dataset_secure_secrets||"""."""||var_table_config_protected_data||"""` j on j.code = 'C_DOCUMENT_NUMBER'
      """;
      EXECUTE IMMEDIATE(query);

      /* Eliminar la tabla temporal*/
      SET query = """
        drop table `"""||var_project_operation||"""."""||var_dataset_raw_stage_salesforce||"""."""||var_table_tmp_case||"""`
      """;
      EXECUTE IMMEDIATE(query);

  END IF;
END;



