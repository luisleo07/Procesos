--=====================================================================
--- DATA AS400
--=====================================================================

create or replace table dev-izipay-data-storage.master_stage_product.dataterminales_as as
select
right(a.usefj,7) as codcomercio
,trim(a.csiac) as estado
,trim(a.cacfj) as marguesi
,trim(a.tmrfj) as marca
,trim(a.tmofj) as modelo
,upper(trim(a.nsefj)) as serie
,date(cast(a.acofj as int64), cast(a.mcofj as int64), cast(a.dcofj as int64)) as feccompra
,trim(c.mencom) as nomcomercial
,c.medire as direccion
,trim(c.meprov) as prov
,trim(c.medepa) as dpto
,trim(c.medist) as dist
from dev-izipay-data-storage.raw_as400.akfmitem a
left join dev-izipay-data-storage.raw_as400.mcfm019i c
on trim(right(a.usefj,7)) = trim(c.mecest)
left join dev-izipay-data-storage.abravo.modelo_terminal_desuso d
on(trim(a.tmofj) = d.modelo_desuso)
left join dev-izipay-data-storage.abravo.marguesi_terminal_desuso e
on(trim(a.cacfj) = e.marguesi_desuso)
WHERE trim(a.tmrfj) IN ('DS1READ','DSPREAD','INGENICO','PAX','SUNMI','VERIFON','VERIFONE','SUMNI','WISEPAD')
AND d.modelo_desuso is null
AND e.marguesi_desuso is null -- PARCHE SERIE DUPLICADA EN EL ACTIVO FIJO / V810 / SERIES MAL ASIGNADAS
AND ((trim(a.tmrfj) IN ('VERIFON','VERIFONE')	AND LEFT(RTRIM(LTRIM(a.nsefj)),1)<>'F')
		OR (LEFT(RTRIM(LTRIM(a.tmofj)),4) ='MOVE' AND LEFT(RTRIM(LTRIM(a.nsefj)),1) NOT IN ('V','F'))
		OR (a.tmrfj NOT IN ('VERIFON','VERIFONE') AND LEFT(RTRIM(LTRIM(a.tmofj)),4) <>'MOVE' AND  a.csiac<>'B')
		OR RTRIM(LTRIM(a.tmofj)) IN ('ICT220-EM','IWL250','ICT220 EMC','IWL250 3G','ICT220 EM','IWL220 3G','ICT220GEMC'))
AND right(a.usefj,7)<>'7010427'
AND a.tmofj <> '';

--=====================================================================
--- DATA ADQUIRENTE
--=====================================================================

create or replace table dev-izipay-data-storage.abravo.terminal_a as
with ultimaversionmain as (
	select 
		ctafilesversion,
		ctamerchantid,
		ctaterminalnum,
		ctaterminalsn,
		row_number() over (
			partition by ctamerchantid, ctaterminalnum, ctaterminalsn 
			order by ctafilesversion desc
		) as seq
	from dev-izipay-data-storage.raw_mccenter_adq.taterminalapplication
	where ctaapplicationid = 'MAIN'
)
select 
distinct
	a.cmrmerchantid as comercio,
	case 
		when trim(mcfv1001.pfpfnc) = 'IZI*' then 'ADQ-IZIPAY'
		else 'ADQ-PMP'
	end adq_c_cor,
	--a.dmrmerchantname as nombre,
	a.cmrmcc as rubro,
	a.party_id_izi,
	i.dlfdescription as departamento,
	j.dlfdescription as provincia,
	k.dlfdescription as distrito,
	b.ctrmultmerchant as multicomercio,
	case 
		when b.ctrmultmerchant in ('0','2') then true
		else false
	end flag_multicomercio,
	a.dmrphone as telefono_comercio,
	a.dmrcontactname as contacto_comercio,
	a.cmrprofileid as perfil_comercio,
	c.ddpprofilename as perfil_descarga,
	b.ctrterminalnum as terminal, 
	b.dtrterminalsn as serie,
	b.ntrlongitudtrama as medio_mcc,
	b.dtrdescription as descripcion_terminal,
	b.ftrlastechodate as fecha_ultimo_eco,
	b.ftrlasttrxfindate as fecha_ultima_transaccion_financiera, 
	b.ftrlasttrxadmdate as fecha_ultima_transaccion_administrativa,
	trim(b.ctrmodel) as modelo_mcc, 
	nullif(trim(b.ntrswversion),'') as version_swb,
	b.dtrosversion as os_version,
	b.ntrchipnumber as chip,
	d.telefono as telefono_chip,
	case
		when left(trim(b.ntrchipnumber),6) = '893407' then 'MOVISTAR-SM'
		when left(trim(b.ntrchipnumber),6) = '895106' then 'MOVISTAR'
		when left(trim(b.ntrchipnumber),6) = '895110' then 'CLARO'
		when left(trim(b.ntrchipnumber),6) = '895117' then 'ENTEL'
		when left(trim(b.ntrchipnumber),6) = '895115' then 'BITEL'
	else upper(trim(d.operador))
	end operador,
	trim(l.dlfdescription) as estado_comercio,
	trim(m.dlfdescription) as estado_logico_comercio, 
	trim(n.dlfdescription) as estado_terminal,
	trim(o.dlfdescription) as estado_logico_terminal,
	e.ctaapplicationid as aplicacion,
	b.ctramountpaid as facturacion,
	b.dtre105sn,
	e.ctafilesversion as version_flujo,
	p.ctafilesversion as version_main,
	case 
		when nullif(trim(b.dtrterminalcompletesn),'') <> '' and (upper(trim(desuso.medio)) <> 'MPOS' or upper(trim(desuso.medio)) is null) then upper(trim(b.dtrterminalcompletesn)) --Nuevo
		when length(trim(b.dtrterminalcompletesn)) = 9 and trim(b.dtrterminalsn) = left(trim(b.dtrterminalcompletesn),8) then substr(trim(b.dtrterminalcompletesn),1,3) || '-' || substr(trim(b.dtrterminalcompletesn),4,3)|| '-' || substr(trim(b.dtrterminalcompletesn),7,3)
		when length(trim(b.dtrterminalcompletesn)) > 9 and trim(b.dtrterminalsn) = right(trim(b.dtrterminalcompletesn),8) then trim(b.dtrterminalcompletesn)
		when r.serie is not null then r.serie
		when r2.serie is not null then r2.serie
		when r3.serie is not null then r3.serie
		end serie_completa,
	IF(f.cfltransactionid = '13', true, false) AS pre_autorizacion_nivel_comercio,
	IF(g.ctattransactionid = '13', true, false) AS pre_autorizacion_nivel_terminal,
	CASE 
		WHEN h.cmacardwriter = '2' THEN true
		WHEN h.cmacardwriter = '1' THEN false
		ELSE false
	END digitacion_manual_nivel_comercio,
	CASE 
		WHEN e.ctamultimerchantwriter = '2' THEN true
		WHEN e.ctamultimerchantwriter = '1' THEN false
		ELSE false
	END digitacion_manual_nivel_terminal,
	CASE 
		WHEN e.ctaonlinetip = '0' THEN 'ONLINE' 
		WHEN e.ctaonlinetip = '2' THEN 'AMBAS' 
		WHEN e.ctaonlinetip = '3' THEN 'OFFLINE' 
		ELSE 'NINGUNO' 
	END propina,
	e.ftaupdatedate as fecha_actualizacion_app,
	e.htaupdatetime as hora_actualizacion_app,
	b.ntrdownloadattempts as num_intentos,
	b.ftrlastdownloaddate as fecha_ultima_actualizacion,
	b.htrlastdownloadtime as hora_ultima_actualizacion,
	IF(e.ctaversionapl = q.dvrfile, true, false) AS version_actualizado,
	e.ctafilesversion,
	q.cvrversionid,
	e.ctaversionapl,
	q.dvrfile,
	r.marguesi,
	r.feccompra,
	r.modelo as modelo_as,
	mcfm019i.cod_madre as cod_madre,
	case
		when trim(r.estado) = 'A' then 'ACTIVO'
		when trim(r.estado) = 'B' then 'BAJA'
		when trim(r.estado) = 'Q' then 'ALQUILER'
		when trim(r.estado) = 'V' then 'VENTA'
	end situacion_as400
	,'MCCENTER ADQUIRENTE' as record_source
from dev-izipay-data-storage.raw_mccenter_adq.tmmerchant a --1138754
inner join dev-izipay-data-storage.raw_mccenter_adq.tmterminal b 	on a.cmrmerchantid = b.ctrmerchantid --1468224
left join dev-izipay-data-storage.raw_mccenter_adq.tmchipsgprs d	on b.ntrchipnumber = d.simcard --1472405
inner join dev-izipay-data-storage.raw_mccenter_adq.taterminalapplication e 	on b.ctrterminalnum = e.ctaterminalnum and b.ctrmerchantid = e.ctamerchantid
inner join dev-izipay-data-storage.raw_mccenter_adq.tmdownloadprofile c 	on a.cmrdownloadprofile = c.cdpprofileid --2336341
left join dev-izipay-data-storage.raw_mccenter_adq.tafloorlimit f 	on a.cmrprofileid = f.cflmrprofileid and f.cflaplicacion = 'POS' and f.cfltransactionid = '13' --2336341
left join dev-izipay-data-storage.raw_mccenter_adq.taterminalappltransaction g 	on b.ctrterminalnum = g.ctatterminalnum and b.ctrmerchantid = g.ctatmerchantid and g.ctattransactionid = '13' --2336341
left join dev-izipay-data-storage.raw_mccenter_adq.tamerchantprofileapplication h 	on a.cmrprofileid = h.cmamerchantprofileid and e.ctaapplicationid = h.cmaapplicationid
left join dev-izipay-data-storage.raw_mccenter_adq.tmversion q 	on e.ctafilesversion = q.cvrversionid and e.ctaapplicationid = q.cvrapplicationid
left join dev-izipay-data-storage.raw_mccenter_adq.txlistfield i 	on i.dlffieldname = 'Provincia' and i.clfcode = a.cmrdepartcode
left join dev-izipay-data-storage.raw_mccenter_adq.txlistfield j 	on j.dlffieldname = 'Ciudad' AND j.clfcode = a.cmrprovincecode
left join dev-izipay-data-storage.raw_mccenter_adq.txlistfield k 	on k.dlffieldname = 'Zona' AND k.clfcode = a.cmrdistrictcode
left join dev-izipay-data-storage.raw_mccenter_adq.txlistfield l 	on l.dlffieldname = 'EstadoComercio' and l.clfcode = a.cmrstatus
left join dev-izipay-data-storage.raw_mccenter_adq.txlistfield m 	on m.dlffieldname = 'EstadoLogicoTerminal' and m.clfcode = a.cmrlogicalstatus
left join dev-izipay-data-storage.raw_mccenter_adq.txlistfield n 	on n.dlffieldname = 'EstadoTerminal' and n.clfcode = b.ctrstatus
left join dev-izipay-data-storage.raw_mccenter_adq.txlistfield o 	on o.dlffieldname = 'EstadoLogicoTerminal' and o.clfcode = b.ctrlogicalstatus
left join ultimaversionmain p on p.ctamerchantid = b.ctrmerchantid and p.ctaterminalnum = b.ctrterminalnum and p.ctaterminalsn = b.dtrterminalsn and p.seq = 1
left join dev-izipay-data-storage.master_stage_product.dataterminales_as r
  ON LEFT(a.cmrmerchantid,7) = r.codcomercio 
	AND ((upper(b.dtrterminalsn) = RIGHT(REPLACE(REPLACE(r.serie,' ',''),'-',''),8) 
	AND LEFT(RTRIM(LTRIM(b.ctrmodel)),7) <> 'Cliente' 
	AND r.marca IN ('INGENICO','PAX','SUNMI','VERIFON','VERIFONE','SUMNI')) OR (b.dTrE105SN = RIGHT(REPLACE(REPLACE(r.serie,'',''),'-',''),9)
	AND LEFT(RTRIM(LTRIM(b.ctrmodel)),7) = 'Cliente'
	AND r.marca IN ('DS1READ','DSPREAD','WISEPAD')))
left join (select
	RIGHT(REPLACE(REPLACE(serie,' ',''),'-',''),8) as serie_corta
	,max(serie) as serie
	from dev-izipay-data-storage.master_stage_product.dataterminales_as
	where marca IN ('INGENICO','PAX','SUNMI','VERIFON','VERIFONE','SUMNI')
	group by all
	having count(1) = 1
	) r2 on (upper(b.dtrterminalsn) = RIGHT(REPLACE(REPLACE(r2.serie,' ',''),'-',''),8) AND LEFT(trim(b.ctrmodel),7) <> 'Cliente')
left join (select
	RIGHT(REPLACE(REPLACE(serie,' ',''),'-',''),9) as serie_corta
	,max(serie) as serie
	from dev-izipay-data-storage.master_stage_product.dataterminales_as
	where marca in ('DS1READ','DSPREAD','WISEPAD')
	group by all
	having count(1) = 1
			) r3 on (b.dtre105sn = RIGHT(REPLACE(REPLACE(r3.serie,' ',''),'-',''),9) AND LEFT(trim(b.ctrmodel),7) = 'Cliente'
	)
left join (select mecest,case when trim(memcom) in ('0','1') then null else trim(memcom) end cod_madre from dev-izipay-data-storage.raw_as400.mcfm019i) as mcfm019i on (left(a.cmrmerchantid,7) = mcfm019i.mecest)
left join dev-izipay-data-storage.raw_as400.mcfm019i as mcfm019i_2 on (left(cmrmerchantid,7) = mcfm019i_2.mecest)
left join (select pfpfid,pfpfnc
	from dev-izipay-data-storage.raw_as400.mcfv1001 qualify row_number() over(partition by pfpfid order by pffing desc,pfhing desc) = 1
	) mcfv1001 on (mcfm019i_2.mepfid = mcfv1001.pfpfid)
left join dev-izipay-data-storage.raw_dataentry_operaciones.modelos_old_terminal_desuso desuso on (upper(trim(b.ctrmodel)) = upper(desuso.modelo_mcc)) --Nuevo
where a.cmrlogicalstatus = '0' and b.ctrlogicalstatus = '0' and b.ctrtype in ('2','3') and e.ctaapplicationid <> 'MAIN' and left(a.cmrmerchantid,1) <> '3';

--=====================================================================
--- DATA CACO
--=====================================================================

create or replace table dev-izipay-data-storage.abravo.terminal_cc as
with ultimaversionmain as (
  select 
    ctafilesversion,
    ctamerchantid,
    ctaterminalnum,
    ctaterminalsn,
    row_number() over (
      partition by ctamerchantid, ctaterminalnum, ctaterminalsn 
      order by ctafilesversion desc
    ) as seq
  from dev-izipay-data-storage.raw_mccenter_caco.taterminalapplication
  where ctaapplicationid = 'MAIN'
)
select 
distinct
	a.cmrmerchantid as comercio,
		case 
		when trim(mcfv1001.pfpfnc) = 'IZI*' then 'C.COR-IZIPAY'
		else 'C.COR-PMP'
	end adq_c_cor,
	--a.dmrmerchantname as nombre,
	a.cmrmcc as rubro,
	a.party_id_izi,
	i.dlfdescription as departamento,
	j.dlfdescription as provincia,
	k.dlfdescription as distrito,
	b.ctrmultmerchant as multicomercio,
	case 
		when b.ctrmultmerchant in ('0','2') then true
		else false
	end flag_multicomercio,
	a.dmrphone as telefono_comercio,
	a.dmrcontactname as contacto_comercio,
	a.cmrprofileid as perfil_comercio,
	c.ddpprofilename as perfil_descarga,
	b.ctrterminalnum as terminal, 
	b.dtrterminalsn as serie,
	b.ntrlongitudtrama as medio_mcc,
	b.dtrdescription as descripcion_terminal,
	b.ftrlastechodate as fecha_ultimo_eco,
	b.ftrlasttrxfindate as fecha_ultima_transaccion_financiera, 
	b.ftrlasttrxadmdate as fecha_ultima_transaccion_administrativa,
	trim(b.ctrmodel) as modelo_mcc,
	nullif(trim(b.ntrswversion),'') as version_swb,
	b.dtrosversion as os_version,
	b.ntrchipnumber as chip,
	d.telefono as telefono_chip,
	case
		when left(trim(b.ntrchipnumber),6) = '893407' then 'MOVISTAR-SM'
		when left(trim(b.ntrchipnumber),6) = '895106' then 'MOVISTAR'
		when left(trim(b.ntrchipnumber),6) = '895110' then 'CLARO'
		when left(trim(b.ntrchipnumber),6) = '895117' then 'ENTEL'
		when left(trim(b.ntrchipnumber),6) = '895115' then 'BITEL'
	else upper(trim(d.operador))
	end operador,
	trim(l.dlfdescription) as estado_comercio,
	trim(m.dlfdescription) as estado_logico_comercio,
	trim(n.dlfdescription) as estado_terminal,
	trim(o.dlfdescription) as estado_logico_terminal,
	e.ctaapplicationid as aplicacion,
	b.ctramountpaid as facturacion,
	b.dtre105sn,
	e.ctafilesversion as version_flujo,
	p.ctafilesversion as version_main,
	case 
		/*when length(trim(b.dtrterminalcompletesn)) = 9 and trim(b.dtrterminalsn) = left(trim(b.dtrterminalcompletesn),8) then substr(trim(b.dtrterminalcompletesn),1,3) || '-' || substr(trim(b.dtrterminalcompletesn),4,3)|| '-' || substr(trim(b.dtrterminalcompletesn),7,3)
		when length(trim(b.dtrterminalcompletesn)) > 9 and trim(b.dtrterminalsn) = left(trim(b.dtrterminalcompletesn),8) then trim(b.dtrterminalcompletesn)*/
		--when nullif(trim(b.dtrterminalcompletesn),'') <> '' then upper(trim(b.dtrterminalcompletesn))
		when nullif(trim(b.dtrterminalcompletesn),'') <> '' and (upper(trim(desuso.medio)) <> 'MPOS' or upper(trim(desuso.medio)) is null) then upper(trim(b.dtrterminalcompletesn)) --Nuevo
		when r.serie is not null then r.serie
		when r2.serie is not null then r2.serie
		when r3.serie is not null then r3.serie
		end serie_completa,
	IF(f.cfltransactionid = '13', true, false) AS pre_autorizacion_nivel_comercio,
	IF(g.ctattransactionid = '13', true, false) AS pre_autorizacion_nivel_terminal,
	CASE 
		WHEN h.cmacardwriter = '2' THEN true 
		WHEN h.cmacardwriter = '1' THEN false 
		ELSE false
	END digitacion_manual_nivel_comercio,
	CASE 
		WHEN e.ctamultimerchantwriter = '2' THEN true 
		WHEN e.ctamultimerchantwriter = '1' THEN false
		ELSE false
	END digitacion_manual_nivel_terminal,
	CASE
		WHEN e.ctaonlinetip = '0' THEN 'ONLINE'
		WHEN e.ctaonlinetip = '2' THEN 'AMBAS'
		WHEN e.ctaonlinetip = '3' THEN 'OFFLINE'
		ELSE 'NINGUNO' 
	END propina,
	e.ftaupdatedate as fecha_actualizacion_app,
	e.htaupdatetime as hora_actualizacion_app,
	b.ntrdownloadattempts as num_intentos,
	b.ftrlastdownloaddate as fecha_ultima_actualizacion,
	b.htrlastdownloadtime as hora_ultima_actualizacion,
	IF(e.ctaversionapl = q.dvrfile, true, false) AS version_actualizado,
	e.ctafilesversion,
	q.cvrversionid,
	e.ctaversionapl,
	q.dvrfile,
	r.marguesi,
	r.feccompra,
	r.modelo as modelo_as,
	mcfm019i.cod_madre as cod_madre,
	case 
		when trim(r.estado) = 'A' then 'ACTIVO'
		when trim(r.estado) = 'B' then 'BAJA'
		when trim(r.estado) = 'Q' then 'ALQUILER'
		when trim(r.estado) = 'V' then 'VENTA'
	end situacion_as400
	,'MCCENTER CAJERO CORRESPONSAL' as record_source
from dev-izipay-data-storage.raw_mccenter_caco.tmmerchant a --1138754
inner join dev-izipay-data-storage.raw_mccenter_caco.tmterminal b 	on a.cmrmerchantid = b.ctrmerchantid --1468224
left join dev-izipay-data-storage.raw_mccenter_caco.tmchipsgprs d	on b.ntrchipnumber = d.simcard --1472405
inner join dev-izipay-data-storage.raw_mccenter_caco.taterminalapplication e 	on b.ctrterminalnum = e.ctaterminalnum and b.ctrmerchantid = e.ctamerchantid --2336371
inner join dev-izipay-data-storage.raw_mccenter_caco.tmdownloadprofile c 	on a.cmrdownloadprofile = c.cdpprofileid --2336341
left join dev-izipay-data-storage.raw_mccenter_caco.tafloorlimit f 	on a.cmrprofileid = f.cflmrprofileid and f.cflaplicacion = 'POS' and f.cfltransactionid = '13' --2336341
left join dev-izipay-data-storage.raw_mccenter_caco.taterminalappltransaction g 	on b.ctrterminalnum = g.ctatterminalnum and b.ctrmerchantid = g.ctatmerchantid and g.ctattransactionid = '13' --2336341
left join dev-izipay-data-storage.raw_mccenter_caco.tamerchantprofileapplication h 	on a.cmrprofileid = h.cmamerchantprofileid and e.ctaapplicationid = h.cmaapplicationid --2336341
left join dev-izipay-data-storage.raw_mccenter_caco.tmversion q 	on e.ctafilesversion = q.cvrversionid and e.ctaapplicationid = q.cvrapplicationid
left join dev-izipay-data-storage.raw_mccenter_caco.txlistfield i 	on i.dlffieldname = 'Provincia' and i.clfcode = a.cmrdepartcode
left join dev-izipay-data-storage.raw_mccenter_caco.txlistfield j 	on j.dlffieldname = 'Ciudad' AND j.clfcode = a.cmrprovincecode
left join dev-izipay-data-storage.raw_mccenter_caco.txlistfield k 	on k.dlffieldname = 'Zona' AND k.clfcode = a.cmrdistrictcode
left join dev-izipay-data-storage.raw_mccenter_caco.txlistfield l 	on l.dlffieldname = 'EstadoComercio' and l.clfcode = a.cmrstatus
left join dev-izipay-data-storage.raw_mccenter_caco.txlistfield m 	on m.dlffieldname = 'EstadoLogicoTerminal' and m.clfcode = a.cmrlogicalstatus
left join dev-izipay-data-storage.raw_mccenter_caco.txlistfield n 	on n.dlffieldname = 'EstadoTerminal' and n.clfcode = b.ctrstatus
left join dev-izipay-data-storage.raw_mccenter_caco.txlistfield o 	on o.dlffieldname = 'EstadoLogicoTerminal' and o.clfcode = b.ctrlogicalstatus
left join ultimaversionmain p 	on p.ctamerchantid = b.ctrmerchantid and p.ctaterminalnum = b.ctrterminalnum and p.ctaterminalsn = b.dtrterminalsn and p.seq = 1
left join dev-izipay-data-storage.master_stage_product.dataterminales_as r
  ON LEFT(a.cmrmerchantid,7) = r.codcomercio 
	AND ((upper(b.dtrterminalsn) = RIGHT(REPLACE(REPLACE(r.serie,' ',''),'-',''),8) 
	AND LEFT(RTRIM(LTRIM(b.ctrmodel)),7) <> 'Cliente' 
	AND r.marca IN ('INGENICO','PAX','SUNMI','VERIFON','VERIFONE','SUMNI')) OR (b.dTrE105SN = RIGHT(REPLACE(REPLACE(r.serie,'',''),'-',''),9) 
	AND LEFT(RTRIM(LTRIM(b.ctrmodel)),7) = 'Cliente' 
	AND r.marca IN ('DS1READ','DSPREAD','WISEPAD')))
left join (select 
	RIGHT(REPLACE(REPLACE(serie,' ',''),'-',''),8) as serie_corta
	,max(serie) as serie
	from dev-izipay-data-storage.master_stage_product.dataterminales_as
	where marca IN ('INGENICO','PAX','SUNMI','VERIFON','VERIFONE','SUMNI')
	group by all
	having count(1) = 1
	) r2 on (upper(b.dtrterminalsn) = RIGHT(REPLACE(REPLACE(r2.serie,' ',''),'-',''),8) AND LEFT(trim(b.ctrmodel),7) <> 'Cliente')
left join (select 
	RIGHT(REPLACE(REPLACE(serie,' ',''),'-',''),9) as serie_corta
	,max(serie) as serie
	from dev-izipay-data-storage.master_stage_product.dataterminales_as
	where marca in ('DS1READ','DSPREAD','WISEPAD') 
	group by all
	having count(1) = 1) r3 on (b.dtre105sn = RIGHT(REPLACE(REPLACE(r3.serie,' ',''),'-',''),9) AND LEFT(trim(b.ctrmodel),7) = 'Cliente'
	)
left join (select mecest,case when trim(memcom) in ('0','1') then null else trim(memcom) end cod_madre from dev-izipay-data-storage.raw_as400.mcfm019i) as mcfm019i on (left(cMrMerchantId,7) = mcfm019i.mecest)
left join dev-izipay-data-storage.raw_as400.mcfm019i as mcfm019i_2 on (left(cmrmerchantid,7) = mcfm019i_2.mecest)
left join (select pfpfid,pfpfnc 
	from dev-izipay-data-storage.raw_as400.mcfv1001 qualify row_number() over(partition by pfpfid order by pffing desc,pfhing desc) = 1
	) mcfv1001 on (mcfm019i_2.mepfid = mcfv1001.pfpfid)
left join dev-izipay-data-storage.raw_dataentry_operaciones.modelos_old_terminal_desuso desuso on (upper(trim(b.ctrmodel)) = upper(desuso.modelo_mcc)) --Nuevo
where a.cmrlogicalstatus = '0' and b.ctrlogicalstatus = '0' and b.ctrtype in ('2','3') and e.ctaapplicationid <> 'MAIN' and left(a.cmrmerchantid,1) = '3';

--=====================================================
-- UNION ADQUIRENTE - CACO
--=====================================================

create or replace table dev-izipay-data-storage.abravo.pre_m_terminal as
select * from dev-izipay-data-storage.abravo.terminal_a 
union all
select * from dev-izipay-data-storage.abravo.terminal_cc;


--=====================================================
-- PARTE FINAL
--=====================================================

create or replace table dev-izipay-data-storage.abravo.m_terminal as
with series_completas as
(
	select distinct
	serie_completa
	,cod_madre
	,flag_multicomercio
	,multicomercio
	from dev-izipay-data-storage.abravo.pre_m_terminal
	where serie_completa is not null
),
series_completas_u8 as
(
select
right(replace(replace(a.serie,' ',''),'-',''),8) as serie_corta
,min(a.serie) as serie
from dev-izipay-data-storage.master_stage_product.dataterminales_as a
left join series_completas b
on (a.serie = b.serie_completa)
where a.marca in ('INGENICO','PAX','SUNMI','VERIFON','VERIFONE','SUMNI')
and a.estado <>'B'
and (b.serie_completa is null or b.flag_multicomercio is true)
group by all
),
series_completas_u9 as
(
select
right(replace(replace(a.serie,' ',''),'-',''),9) as serie_corta
,min(a.serie) as serie
from dev-izipay-data-storage.master_stage_product.dataterminales_as a
left join series_completas b
on (a.serie = b.serie_completa)
where a.marca in ('DS1READ','DSPREAD','WISEPAD')
and a.estado <>'B'
and (b.serie_completa is null or b.flag_multicomercio is true)
group by all
),
m_terminal as
(
select a.* except(serie_completa), coalesce(a.serie_completa,d.serie_completa,b.serie,c.serie) as serie_completa
from dev-izipay-data-storage.abravo.pre_m_terminal a
left join series_completas_u8 b on (a.serie = right(replace(replace(b.serie,' ',''),'-',''),8) and left(trim(a.modelo_mcc),7) <> 'Cliente')
left join series_completas_u9 c on (a.dtre105sn = right(replace(replace(c.serie,' ',''),'-',''),9) and left(trim(a.modelo_mcc),7) = 'Cliente')
left join series_completas d on ((a.cod_madre = d.cod_madre or d.cod_madre = left(a.comercio,7))  and left(a.adq_c_cor,3)='ADQ'
		and a.serie = right(replace(replace(d.serie_completa,' ',''),'-',''),8) and left(trim(a.modelo_mcc),7) <> 'Cliente')
		or (left(a.adq_c_cor,5) = 'C.COR'
		and a.serie = right(replace(replace(d.serie_completa,' ',''),'-',''),8) and left(trim(a.modelo_mcc),7) <> 'Cliente')
),
m_terminal_final as
(
select 
left(a.comercio,7) as cod_comercio
,a.comercio as cod_comercio_mccenter
,a.adq_c_cor as adq_cajero_corr
--,nombre
--,rubro
,case
	when a.record_source = 'MCCENTER ADQUIRENTE' and c.cod_segmento = 'N' then '3. NEGOCIOS'
	when a.record_source = 'MCCENTER ADQUIRENTE' and c.cod_segmento = 'E' then '2. EMPRESAS'
	when a.record_source = 'MCCENTER ADQUIRENTE' and c.cod_segmento = 'G' then '1. GRANDES EMPRESAS'
	when a.record_source = 'MCCENTER ADQUIRENTE' and c.cod_segmento = 'C' then '0. CORPORACIONES'
	when a.record_source = 'MCCENTER CAJERO CORRESPONSAL' and a.aplicacion = 'BNACJCO' then '4. BANCO NACION'
	when a.record_source = 'MCCENTER CAJERO CORRESPONSAL' and a.aplicacion = 'CAJERO' then '8. SCOTIABANK'
	when a.record_source = 'MCCENTER CAJERO CORRESPONSAL' and a.aplicacion = 'CMACHYO' then '6. CMAC HUANCAYO'
	when a.record_source = 'MCCENTER CAJERO CORRESPONSAL' and a.aplicacion = 'CMAREQUIPA' then '5. CMAC AREQUIPA'
	when a.record_source = 'MCCENTER CAJERO CORRESPONSAL' and a.aplicacion = 'HERMESMB' then '8. SCOTIABANK'
	when a.record_source = 'MCCENTER CAJERO CORRESPONSAL' and a.aplicacion = 'IBDIRECTO' then '7. INTERBANK'
	when a.record_source = 'MCCENTER CAJERO CORRESPONSAL' and a.aplicacion = 'CMICA' then '9. CMAC ICA'
end categoria_comercio
,a.party_id_izi
--,direccion
--,departamento
--,provincia
--,distrito
--,multicomercio
,a.telefono_comercio
,a.contacto_comercio
,upper(trim(a.perfil_comercio)) as perfil_comercio
,upper(trim(a.perfil_descarga)) as perfil_descarga
,upper(trim(a.terminal)) as cod_terminal
,upper(trim(a.serie)) as num_serie_sistema
,nullif(upper(trim(a.medio_mcc)),'') as tipo_conexion_mcc
,ifnull(upper(d.medio),
  case
    when trim(a.chip) <> '' THEN 'GPRS FIJO'
    when trim(a.medio_mcc) = 'ETHERNET' THEN 'IP'
    when trim(a.medio_mcc) = 'DIAL' THEN 'DIAL'
    else 'IP'
  end
) as tipo_conexion
,upper(trim(a.descripcion_terminal)) as descripcion_terminal
,safe.parse_date('%Y%m%d',a.fecha_ultimo_eco) as fecha_ult_conex_mccenter
,safe.parse_date('%Y%m%d',a.fecha_ultima_transaccion_financiera) as fecha_ult_trx_financiera
,safe.parse_date('%Y%m%d',a.fecha_ultima_transaccion_administrativa) as fecha_ult_trx_administrativa
,case
  when a.fecha_ultima_transaccion_financiera is null then '99 - SIN REGISTRO DE TRX.'
  when date_diff(current_date("America/Lima"), safe.parse_date('%Y%m%d',a.fecha_ultima_transaccion_financiera), month) > 12 then '2 - SIN MOVIMIENTO ÚLTIMOS 12 MESES'
  when date_diff(current_date("America/Lima"), safe.parse_date('%Y%m%d',a.fecha_ultima_transaccion_financiera), month) > 6 then '6 - SIN MOVIMIENTO ÚLTIMOS 6 MESES'
  when date_diff(current_date("America/Lima"), safe.parse_date('%Y%m%d',a.fecha_ultima_transaccion_financiera), month) > 3 then '4 - SIN MOVIMIENTO ÚLTIMOS 3 MESES'
  when date_diff(current_date("America/Lima"), safe.parse_date('%Y%m%d',a.fecha_ultima_transaccion_financiera), month) >= 0 then '1 - CON MOVIMIENTO EN LOS ÚLTIMOS 3 MESES'
  ELSE '2 - SIN MOVIMIENTO ÚLTIMOS 12 MESES'
end situacion_terminal
,nullif(upper(trim(a.modelo_as)),'') as modelo_terminal_general
,nullif(upper(trim(a.modelo_mcc)),'') as modelo_terminal_mcc
,nullif(upper(trim(a.version_swb)),'') as version_software
,nullif(upper(trim(a.os_version)),'') as version_firmware_contactless
,nullif(upper(trim(a.chip)),'') as nro_chip
,a.telefono_chip as nro_telefono_chip
,nullif(upper(trim(a.operador)),'') as operador_chip
,nullif(upper(trim(a.estado_comercio)),'') as estado_comercio
,nullif(upper(trim(a.estado_logico_comercio)),'') as estado_logico_comercio
,nullif(upper(trim(a.estado_terminal)),'') as estado_terminal
,nullif(upper(trim(a.estado_logico_terminal)),'') as estado_logico_terminal
,nullif(upper(trim(a.aplicacion)),'') as tipo_aplicacion
,case
		when a.aplicacion = 'POS' then 'ADQUIRIENTE'
		when a.aplicacion = 'BNACJCO' then 'BANCO NACION'
		when a.aplicacion = 'BRIPLEY' then 'ADQUIRIENTE'
		when a.aplicacion = 'CAJERO' then 'SCOTIABANK'
		when a.aplicacion = 'CMACHYO' then 'CMAC HUANCAYO'
		when a.aplicacion = 'CMAREQUIPA' then 'CMAC AREQUIPA'
		when a.aplicacion = 'HERMESMB' then 'SCOTIABANK'
		when a.aplicacion = 'IBDIRECTO' then 'INTERBANK'
		when a.aplicacion = 'PUNTOS' then 'ADQUIRIENTE'
		when a.aplicacion = 'APLSCOTCUPN' then 'ADQUIRIENTE'
		when a.aplicacion = 'CMICA' then 'CMAC ICA'
	end desc_aplicacion
,if(a.facturacion = '1', true, false) as flag_facturacion
,nullif(upper(trim(a.dtre105sn)),'') as num_serie_mpos
,nullif(upper(trim(a.version_flujo)),'') as cod_version_flujo
,nullif(upper(trim(a.version_main)),'') as cod_version_main
,nullif(upper(trim(a.serie_completa)),'') as num_serie_real
,case
   when d.marca is not null then upper(trim(d.marca))
   else upper(trim(a.modelo_as))
end marca
,case
	when a.record_source = 'MCCENTER CAJERO CORRESPONSAL' then null
	when a.record_source = 'MCCENTER ADQUIRENTE' and d.ctls IN ('NO HW CTLS','NO SW CTLS') then false
	when a.record_source = 'MCCENTER ADQUIRENTE' and a.version_swb in ('B7.854','B8.001','B8.002','B8.003','B8.012','B8.013','B8.014','B8.015','B8.017','B8.018','B8.019','B8.022','B8.100','B8.110','B8.111','B8.114','B8.306','B8.401','B8.420','B8.423','B8.460','B8.463','B8.464','B8.481','B8.4815','B80106','B80107','B80108','B80112','B80113','B80114','B80115','B80117','B80118','B80119') then false
	else true
end flag_software_contactless
,case
	when a.record_source = 'MCCENTER CAJERO CORRESPONSAL' then null
	when a.record_source = 'MCCENTER ADQUIRENTE' and d.ctls = 'NO HW CTLS' then false
  else true
end flag_hardware_contactless
,a.pre_autorizacion_nivel_comercio as flag_pre_autorizacion_comercio
,a.pre_autorizacion_nivel_terminal as flag_pre_autorizacion_terminal
,a.digitacion_manual_nivel_comercio as flag_dig_manual_comercio
,a.digitacion_manual_nivel_terminal as flag_dig_manual_terminal
,a.propina as ind_propina
,safe.parse_date('%Y%m%d',a.fecha_actualizacion_app) as fecha_actualizacion_app
,format('%s:%s:%s',
  lpad(safe_cast(substr(lpad(cast(a.hora_actualizacion_app as string), 6, '0'), 1, 2) as string), 2, '0'),
  lpad(safe_cast(substr(lpad(cast(a.hora_actualizacion_app as string), 6, '0'), 3, 2) as string), 2, '0'),
  lpad(safe_cast(substr(lpad(cast(a.hora_actualizacion_app as string), 6, '0'), 5, 2) as string), 2, '0')
) as hora_actualizacion_app
,safe.parse_datetime(
  '%Y%m%d %H:%M:%S',
  format(
    '%s %s:%s:%s',
    cast(fecha_actualizacion_app as string),
    substr(lpad(cast(hora_actualizacion_app as string), 6, '0'), 1, 2),
    substr(lpad(cast(hora_actualizacion_app as string), 6, '0'), 3, 2),
    substr(lpad(cast(hora_actualizacion_app as string), 6, '0'), 5, 2)
  )
) as fecha_hora_actualizacion_app
,safe_cast(a.num_intentos as int64) as cant_intento
,safe.parse_date('%Y%m%d',a.fecha_ultima_actualizacion) as fecha_ult_actualizacion
,format('%s:%s:%s',
  lpad(safe_cast(substr(lpad(cast(a.hora_ultima_actualizacion as string), 6, '0'), 1, 2) as string), 2, '0'),
  lpad(safe_cast(substr(lpad(cast(a.hora_ultima_actualizacion as string), 6, '0'), 3, 2) as string), 2, '0'),
  lpad(safe_cast(substr(lpad(cast(a.hora_ultima_actualizacion as string), 6, '0'), 5, 2) as string), 2, '0')
) as hora_ult_actualizacion
,safe.parse_datetime(
  '%Y%m%d %H:%M:%S',
  format(
    '%s %s:%s:%s',
    cast(a.fecha_ultima_actualizacion as string),
    substr(lpad(cast(a.hora_ultima_actualizacion as string), 6, '0'), 1, 2),
    substr(lpad(cast(a.hora_ultima_actualizacion as string), 6, '0'), 3, 2),
    substr(lpad(cast(a.hora_ultima_actualizacion as string), 6, '0'), 5, 2)
  )
) as fecha_hora_ult_actualizacion
,a.version_actualizado as flag_version_actualizada
--,a.ctafilesversion
,upper(trim(a.cvrversionid)) as cod_version_app
,upper(trim(a.ctaversionapl)) as version_app
,upper(trim(a.dvrfile)) as version_flujo
--,a.cod_madre
,a.flag_multicomercio
,case
	when a.record_source = 'MCCENTER CAJERO CORRESPONSAL' then null
	when a.record_source = 'MCCENTER ADQUIRENTE' and (case when a.version_flujo = '' then 0 else safe_cast(a.version_flujo as int64) end) <= 214 and a.version_swb in ('B7.854','B8.001','B8.002','B8.003','B8.012','B8.013','B8.014','B8.015','B8.017','B8.018','B8.019','B8.022','B8.100','B8.110','B8.111','B8.114','B8.306','B8.401','B8.420','B80106','B80107','B80108','B80112','B80113','B80114','B80115','B80117','B80118','B80119') then false
	when a.version_swb in ('B80106','B80107','B80108','B80112','B80113','B80114','B80115','B80117','B80118','B80119') then false
   else true
end flag_pos_emv_diners
,case
 when date_diff(current_date("America/Lima"), safe.parse_date('%Y%m%d',a.fecha_ultima_transaccion_financiera), month) >= 0 and date_diff(current_date("America/Lima"), safe.parse_date('%Y%m%d',a.fecha_ultima_transaccion_financiera), month) < 3
  then true
  else false
end flag_terminal_activo
,if(e.modelo_pinpad is not null and a.record_source = 'MCC ADQUIRENTE', true, false) as flag_pinpad
,case
  when date_diff(current_date("America/Lima"), c.fecha_apertura_comercio, MONTH) >= 12 THEN '1. COSECHA 1 AÑO A MÁS'
  when date_diff(current_date("America/Lima"), c.fecha_apertura_comercio, MONTH) >= 6 THEN '2. COSECHA DE 6 A 12 MESES'
  when date_diff(current_date("America/Lima"), c.fecha_apertura_comercio, MONTH) >= 3 THEN '3. COSECHA DE 3 A 6 MESES'
  else concat('4. ', format_date('%Y%m', c.fecha_apertura_comercio))
end cosecha
,case
		when upper(trim(a.departamento)) = 'LA LIBERTAD' THEN 'OF. TRUJILLO'
		when upper(trim(a.departamento)) = 'AREQUIPA' THEN 'OF. AREQUIPA'
		when upper(trim(a.departamento)) = 'PIURA' THEN 'OF. PIURA'
		when upper(trim(a.departamento)) = 'CUSCO' THEN 'OF. CUSCO'
		when upper(trim(a.departamento)) = 'LAMBAYEQUE' THEN 'OF. CHICLAYO'
		when upper(trim(a.departamento)) = 'ICA' THEN 'OF. ICA'
		when upper(trim(a.departamento)) = 'JUNIN' THEN 'OF. HUANCAYO'
		when upper(trim(a.departamento)) = 'ANCASH' THEN 'OF. TRUJILLO'
		when upper(trim(a.departamento)) = 'CAJAMARCA' THEN 'OF. CHICLAYO'
		when upper(trim(a.departamento)) = 'LORETO' THEN 'OF. IQUITOS'
		when upper(trim(a.departamento)) = 'SAN MARTIN' THEN 'OF. CHICLAYO'
		when upper(trim(a.departamento)) = 'PUNO' THEN 'OF. CUSCO'
		when upper(trim(a.departamento)) = 'UCAYALI' THEN 'OF. HUANCAYO'
		when upper(trim(a.departamento)) = 'HUANUCO' THEN 'OF. HUANCAYO'
		when upper(trim(a.departamento)) = 'TACNA' THEN 'OF. AREQUIPA'
		when upper(trim(a.departamento)) = 'TUMBES' THEN 'OF. PIURA'
		when upper(trim(a.departamento)) = 'AYACUCHO' THEN 'OF. ICA'
		when upper(trim(a.departamento)) = 'MOQUEGUA' THEN 'OF. AREQUIPA'
		when upper(trim(a.departamento)) = 'HUANCAVELICA' THEN 'OF.HUANCAYO'
		when upper(trim(a.departamento)) = 'APURIMAC' THEN 'OF. CUSCO'
		when upper(trim(a.departamento)) = 'AMAZONAS' THEN 'OF. CHICLAYO'
		when upper(trim(a.departamento)) = 'PASCO' THEN 'OF. HUANCAYO'
		when upper(trim(a.departamento)) = 'MADRE DE DIOS' THEN 'OF. CUSCO'
		else 'LIMA'
	end oficina_comercio
,coalesce(upper(trim(d.modelo_terminal)),upper(trim(a.modelo_mcc))) as modelo_terminal_especifico
,a.record_source
,min(a.marguesi) as cod_marguesi
,min(a.feccompra) as fecha_compra
,min(a.situacion_as400) as situacion_as400
,min(safe.parse_date('%Y%m%d',b.mdfere)) as fecha_instalacion
from m_terminal a
left join dev-izipay-data-storage.raw_as400.mcfv030e b on (b.mdterm <> '9999' and a.serie_completa = b.mdserm and left(a.comercio,7) = b.mdcoco)
left join dev-izipay-data-storage.master_party.m_comercio c on (left(a.comercio,7) = c.cod_comercio)
left join dev-izipay-data-storage.abravo.modelos_old_terminal_desuso d on (upper(trim(a.modelo_mcc)) = upper(d.modelo_mcc))
left join dev-izipay-data-storage.abravo.modelo_terminal_pinpad e on (upper(trim(a.modelo_as)) = upper(e.modelo_pinpad))
group by all
)
select
cod_comercio
,cod_comercio_mccenter
,adq_cajero_corr
,categoria_comercio
,party_id_izi
,telefono_comercio
,contacto_comercio
,perfil_comercio
,perfil_descarga
,cod_terminal
,num_serie_sistema
,tipo_conexion_mcc
,tipo_conexion
,descripcion_terminal
,fecha_ult_conex_mccenter
,fecha_ult_trx_financiera
,fecha_ult_trx_administrativa
,situacion_terminal
,modelo_terminal_general
,modelo_terminal_mcc
,version_software
,version_firmware_contactless
,nro_chip
,nro_telefono_chip
,operador_chip
,estado_comercio
,estado_logico_comercio
,estado_terminal
,estado_logico_terminal
,tipo_aplicacion
,desc_aplicacion
,num_serie_mpos
,cod_version_flujo
,cod_version_main
,num_serie_real
,marca
,ind_propina
,fecha_actualizacion_app
,hora_actualizacion_app
,fecha_hora_actualizacion_app
,fecha_ult_actualizacion
,hora_ult_actualizacion
,fecha_hora_ult_actualizacion
,cod_version_app
,version_app
,version_flujo
,cod_marguesi
,fecha_compra
,situacion_as400
,cosecha
,oficina_comercio
,modelo_terminal_especifico
,fecha_instalacion
,cant_intento
,flag_terminal_activo
,flag_facturacion
,flag_software_contactless
,flag_hardware_contactless
,flag_pre_autorizacion_comercio
,flag_pre_autorizacion_terminal
,flag_dig_manual_comercio
,flag_dig_manual_terminal
,flag_version_actualizada
,flag_pos_emv_diners
,flag_pinpad
,flag_multicomercio
,record_source
from m_terminal_final;

--=====================
-- FIN
--=====================