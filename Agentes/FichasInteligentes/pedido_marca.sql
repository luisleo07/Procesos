
select 
 a.cod_comercio as cod_comercio,
 a.nom_comercio as nom_comercio,
 c.document_number as RUC,
 AEAD.DECRYPT_STRING(ec.key, a.correo_comercial, ec.constant)  as correo_comercial,
 AEAD.DECRYPT_STRING(e.key, a.correo_representante_legal, e.constant)  as correo_representante_legal,
 AEAD.DECRYPT_STRING(t.key,a.telefono_comercio, t.constant) as telefono,
 a.cod_situacion_comercio as situacion,
 a.flag_lpdp as flag_lpdp
from prd-izipay-data-storage-pv.master_party.m_comercio a
      LEFT JOIN prd-izipay-data-sensitive.master_pii.iden_party_data_control c on (a.party_id_izi = c.party_id_izi)
      LEFT JOIN `prd-izipay-data-sensitive.secure_secrets` e on (e.code = 'C_EMAIL')
      LEFT JOIN `prd-izipay-data-sensitive.secure_secrets` ec on (ec.code = 'C_FULL_NAME')--C_FULL_NAME
      LEFT JOIN `prd-izipay-data-sensitive.secure_secrets` t on (t.code = 'C_TELEPHONE')

      --filtros parque 
where a.cod_situacion_comercio not in ('3', '9')
and a.cod_situacion_comercio is not null
and a.compania in ('PMP','IZIPAY')
and a.nom_producto NOT IN ('CAJERO CORRESPONSAL',
      'INTEROPERABILIDAD VISANET',
      'VENDEMAS','IZIPAY YA')
      
and a.flag_parque = true

