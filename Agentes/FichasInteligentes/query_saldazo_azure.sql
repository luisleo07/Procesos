select
    DISTINCT
    mc.nroruc as ruc
    ,mc.razsoc as razon_social
    ,mc.mailrleg as correo_representante_legal
    ,case
        when seg.banca in ('RETAIL','G0') then 'RETAIL'
        when seg.banca = 'BPE' then 'NEGOCIOS'
        when seg.banca in ('BI','BE','BC') then 'CORPORATIVA'
        else 'SIN BANCA' end as Segmento
    ,mc.situac as situacion
    ,car.kam as nombre_kam
    ,case when lpdp.tratamiento_datos = 'SI' then 'SI'
    else 'NO' end as flag_lpdp
from dwh.te_parque par 
inner join dwh.BI_MCESTAB mc on cast(mc.codigo as varchar(7)) = cast(par.codigo as varchar(7)) 
left join RAW.dataentry_planeamiento_informacion_carteras car on cast(mc.nroruc as varchar) = cast(car.nro_ruc as varchar)
left join stage.salesforce_tratamiento_datos_lpdp lpdp on cast(mc.codigo as varchar(7)) = cast(lpdp.cod_comercio as varchar(7))
left join dwh.segmentacion seg on par.codigo = seg.codigo
where mc.situac not in ('3','9')
and par.compania in ('IZIPAY', 'PMP')
AND par.nom_com not like 'VD+%'
and par.nombre_producto not in ('Cajero Corresponsal', 'IZIPAY YA','VENDEMAS','Interoperabilidad Visanet')
and par.flg_filtro = '0'
and seg.periodo = '202603'