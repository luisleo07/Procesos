    select 
    distinct
    c.document_number as RUC,
    AEAD.DECRYPT_STRING(e.key, a.correo_representante_legal, e.constant)  as correo_representante_legal,
    AEAD.DECRYPT_STRING(t.key, a.telefono_comercio, t.constant) as telefono,
    case 
      when seg.segmento in ('BC','BI','BE') then 'CORPO'
      when seg.segmento = 'BPE' then 'NEGOCIOS'
      when seg.segmento = 'RETAIL' then 'RETAIL'
      else 'SIN SEGMENTO' end as segmento_calculado,
      a.cod_situacion_comercio as situacion,
      a.flag_lpdp as flag_lpdp
    from prd-izipay-data-storage-pv.master_party.m_comercio a
        LEFT JOIN prd-izipay-data-sensitive.master_pii.iden_party_data_control c on (a.party_id_izi = c.party_id_izi)
        LEFT JOIN `prd-izipay-data-sensitive.secure_secrets` e on (e.code = 'C_EMAIL')
        LEFT JOIN `prd-izipay-data-sensitive.secure_secrets` ec on (ec.code = 'C_FULL_NAME')--C_FULL_NAME
        LEFT JOIN `prd-izipay-data-sensitive.secure_secrets` t on (t.code = 'C_TELEPHONE')
        LEFT JOIN prd-izipay-data-storage-pv.raw_dataentry_planeamiento.segmentacion seg on a.cod_comercio = seg.codigo and seg.periodo = '202603'
        --filtros parque 
    where a.cod_situacion_comercio not in ('3', '9')
    and a.cod_situacion_comercio is not null
    and a.compania in ('PMP','IZIPAY')
    and a.nom_producto NOT IN ('CAJERO CORRESPONSAL',
        'INTEROPERABILIDAD VISANET',
        'VENDEMAS','IZIPAY YA')
    and a.flag_parque = true