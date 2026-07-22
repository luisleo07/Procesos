
-----------------TABLAS INPUT -------------------------------------------
--FALTA MIGRAR:
--PFYCC_GI_CARGA_MASTERCARD_DIM_SITUACION
--PFYCC_GI_CARGA_CORREO_MASIVO_CC
--PFYCC_GI_MONITOR_DIM_MCC

--PFYCC_GI_CARGA_MASTERCARD_DIM_MC -- DIM QUE CONTIENE LOS USUARIOS DE CONTRACARGOS
--RT_GD_DIM_Bines -- DIM DE BINES DE BANCO EMISOR (NAC E INTER)
--PFYCC_GI_CARGA_MOTIVO_CC -- DIM MOTIVO CONTRACARGOS
--RT_GD_COMERCIOS_FULL_3DS -- carga unica
--RT_GD_CARGA_INCIDENCIA_RAPPI_DLOCAL -- carga unica
--RT_GD_CARGA_15_VARIABLES -- carga unica
--RT_GD_TRANS_MCESTAB_RPA_CC -- VISTA DEL RPA
--PFYCC_GI_CARGA_VISA_ROL1100_Jul21 -- proceso 77
--PFYCC_GI_TRANS_AS400_CONTRACARGOS_DEVOLUCIONES -- proceso 37 CONTIENE LAS DEVOLUCIONES Y RETENCIONES DE LAS TRANSACCIONES

--
--MIGRADOS:
--PFYCC_GI_TRANS_CONTRACARGOS_MASTERCARD -- CONTIENE LOS CONTRACARGOS MASTERCARD
--PFYCC_GI_TRANS_AS400_TRX -- TRANSACCIONAL DE LAS TRANSACCIONES CONTRACARGADAS
--PFYCC_GI_TRANS_VISA_ROL500_INCYOUT
-------------------------------------------------------------------------

WITH 
MCESTAB_0 AS (
SELECT A.codigo
	,A.nomcom
	,A.nroruc
	,razsoc = a.razsoc
	,a.cta_esp 
	,a.segmento
	,a.giro
	,a.facili_pago
	,a.PGS
	,a.situac
	,mailcom = a.mailcom
	,EmailOpera = CASE WHEN a.codigo = '4074946' THEN 'GESTION.CONTROVERSIAS@PROMART.PE'
						ELSE a.EmailOpera END
	,a.mcc
	,a.mail_fact_elec
	,a.mailrleg
	,a.PRODUCTO
	,a.NOMBRE_PRODUCTO
	,Direccion = a.dire
	,a.dire
	,a.dpto
	,a.dist
FROM PFYCC_GI_TRANS_MCESTAB A
)
 
,RT_GD_TRANS_MCESTAB_RPA_CC AS (
SELECT DISTINCT Codigo
	,nomcom
	,nroruc
	,razsoc = REPLACE(razsoc,',',';')				
	,cta_esp = CASE WHEN cta_esp = 'N' THEN 'Negocios'				
				WHEN cta_esp = 'E' THEN 'Empresas'
				WHEN cta_esp = 'G' THEN 'Grandes empresas'
				WHEN cta_esp = 'C' THEN 'Corporacion' 
				WHEN cta_esp = '' AND segmento = 'Negocio' THEN 'Negocios' END
	,giro = concat(a.mcc,' - ',d.Descripcion)--REPLACE(giro,',',';')				
	,facili_pago
	,segmento
	,PGS = CASE WHEN PGS = 'Y' THEN 'SI' ELSE 'NO' END
	,Situacion = REPLACE(B.Descripcion, ',', ';')
	,mailcom
	,Contacto_Opera  = CASE WHEN A.codigo = '4074946' THEN 'GESTION.CONTROVERSIAS@PROMART.PE'
						WHEN A.nroruc in ('20101087647','20505897812','20545699126','20101869947','20545699550','20144215649') THEN 'creditosycobranzas@ngr.com.pe' -- nuevo contacto ngr para CC
						WHEN A.nroruc = '20334461875' THEN 'teresa.delalamo@teleticket.com.pe' -- CONTACTO PARA TLK
						WHEN A.nroruc = '20101951872' THEN 'isabel.salazar@bata.com;luis.collantes@bata.com;katherine.carlos@bata.com' -- CONTACTO NUEVO PARA BATA
						WHEN A.nroruc = '20609101416' THEN 'antifraude@efe-lc.com.pe;mruizco@juntoz.com;jbellido@juntoz.com' -- CONTACTO PARA CONECTA MARKET PLACE
						WHEN A.nroruc = '20601020719' THEN 'estefania.rojas@ehiglobal.pe' -- ANC
						--WHEN A.nroruc = '20100123330' THEN 'smontalvo@franquiciasperu.com;caguila@FRANQUICIASPERU.COM;mcornejo@FRANQUICIASPERU.COM' -- DELOSI
						WHEN A.nroruc = '20608280333' THEN 'controversias.spsa@spsa.pe;FELIX.CARTAGENA@SPSA.PE;JUAN.BENITEZ@SPSA.PE;dte_20608280333@paperless.pe'
						WHEN A.nroruc = '20520929658' THEN 'carlos.ramirez@aunor.pe;daniel.vilcherres@aunor.pe;victor.tiradom@aunor.pe'
						WHEN A.nroruc = '20100176964' THEN 'ncaceres@clinicasanfelipe.com;marilu.gutierrez@sanna.pe;rafael.farina@sanna.pe' -- CORREGIDO CORREO INCOMPLETO
						WHEN A.nroruc = '20605977406' THEN 'recaudacion@wowperu.pe' -- UNICO CONTACTO OPERA ENCONTRADO
						WHEN A.nroruc = '20218245189' THEN 'RONNYDONNY100@GMAIL.COM;RONNYDONNYPERU@GMAIL.COM'
						WHEN A.nroruc = '20527599602' THEN 'WLEOREPRESENTACIONES@hotmail.com'
						WHEN A.nroruc = '20607773883' THEN 'Wilfredo@pagsmile.com ;Luis@pagsmile.com'
						WHEN A.nroruc = '20101039910' THEN 'contactos@oncosalud.pe;tsaldivar@auna.pe;VSALAS@AUNA.PE'
						WHEN A.nroruc = '20510931514' THEN 'tesoreria.lima@aranwahotels.com;msaldana@aranwahotels.com;cobranzas.tesoreria@aranwahotels.com'
						WHEN A.nroruc IN ('20553617627','20605391738','20137254205') THEN 'wcontreras@inlearning.pe;klam@inlearning.pe;caliaga@inlearning.pe' -- ZEGEL IPAE / IDAT
						WHEN A.nroruc = '20552536259' THEN 'tesoreria@mesa247.pe'
						WHEN A.nroruc = '20602386024' THEN 'GMEDINA.SOTELO@GMAIL.COM;GIANNIALVARADO27@GMAIL.COM'
						WHEN C.RUC IS NOT NULL THEN C.Correo_Masivo_CC
						--WHEN E.Cod IS NOT NULL THEN E.ContactoOpera -- CORRECCION TEMPORAL CORREOS INCOMPLETOS
						WHEN LEN(EmailOpera)>8 THEN EmailOpera
						WHEN LEN(mail_fact_elec)>8 THEN mail_fact_elec
						WHEN LEN(mailrleg)>8 THEN mailrleg 
						--WHEN LEN(EmailOpera)>8 AND LEN(mail_fact_elec)>8 AND LEN(mailrleg)>8 THEN CONCAT(EmailOpera,';',mail_fact_elec,';',mailrleg)
						--WHEN LEN(EmailOpera)>8 AND LEN(mail_fact_elec)>8 THEN CONCAT(EmailOpera,';',mail_fact_elec)
						--WHEN LEN(EmailOpera)>8 AND LEN(mailrleg)>8 THEN CONCAT(EmailOpera,';',mailrleg)
						--WHEN LEN(mail_fact_elec)>8 AND LEN(mailrleg)>8 THEN CONCAT(mail_fact_elec,';',mailrleg)
						ELSE 'NULL' END
	,MCESTAB_RPA = CASE WHEN A.facili_pago IN ('FP-VD+', 'NIUBIZ', 'INTEROPERABILIDAD') THEN 'NO'
						WHEN A.NOMBRE_PRODUCTO IN ('CAJERO CORRESPONSAL', 'Cajero Corresponsal', 'Interoperabilidad Visanet') THEN 'NO'
						ELSE 'SI' END
	,Direccion = CONCAT(dire,' ',dpto,' ',dist)
	--,orden_temp = ROW_NUMBER() over(partition by codigo order by codigo desc)
FROM MCESTAB_0 A with(nolock)--dbo.PFYCC_GI_TRANS_MCESTAB A WITH(NOLOCK)
LEFT JOIN dbo.PFYCC_GI_CARGA_MASTERCARD_DIM_SITUACION B ON A.situac = B.Sit
LEFT JOIN dbo.PFYCC_GI_CARGA_CORREO_MASIVO_CC C ON A.nroruc = C.RUC
LEFT JOIN dbo.PFYCC_GI_MONITOR_DIM_MCC D on a.mcc = d.MCC
)

,MC_USUARIOS AS (
SELECT MC
	,Usuario
FROM dbo.PFYCC_GI_CARGA_MASTERCARD_DIM_MC
)
,Ecom_VA AS (

SELECT distinct RolCaseNumber
	,ARN = LEFT(ARN,23)
	,MOTOInd
FROM dbo.PFYCC_GI_CARGA_VISA_ROL1100_Jul21 --Consultar a Sebas
WHERE MOTOInd <> ''
AND FechaCarga >= '2025-01-01' -- no habia restriccion
--and LEFT(ARN,23) = '74357043299001428124079'
--GROUP BY RolCaseNumber
--	,LEFT(ARN,23)
--	,MOTOInd
)

,BIN AS (
SELECT DISTINCT BIN
	,NOM_BANCO = REPLACE(BancoEmisor,',',';')
FROM dbo.RT_GD_DIM_Bines
)
,CATEGORIA_CC AS (
SELECT Razon
	,Descripcion = CASE WHEN LEFT(Razon,1) = '4' THEN Razon + ' ' + REPLACE(Descripcion,',',';') 
		                ELSE REPLACE(Descripcion,',',';') END
	,Categoria
FROM dbo.PFYCC_GI_CARGA_MOTIVO_CC
)
-- NUEVA FUENTE RETENCION Y DEV 25/06/2025 -- SE PODRIA AGREGAR DE FILTRO ORDEN = 1 PERO NO EXISTEN REGISTROS IGUALES DE MOMENTO
,TRANSACCIONAL_RETENCION AS (
SELECT A.* 
	,Orden = ROW_NUMBER() OVER (PARTITION BY TARJETA,COMERCIO,ARD_ARN,AUTORIZACION ORDER BY FECHA_PROCESO DESC)
FROM (	SELECT TARJETA
			,COMERCIO
			,ARD_ARN = CASE WHEN COMERCIO = '8053722' AND AUTORIZACION = '007478' THEN '74357044196003029300035'
							WHEN COMERCIO = '5511724' AND AUTORIZACION = '568256' THEN '75301504199001678800010'
							WHEN COMERCIO = '8575202' AND AUTORIZACION = '40673Z' THEN '75301504026004971600011'
							WHEN COMERCIO = '8740135' AND AUTORIZACION = '015375' THEN '75301503170000119000011'
							WHEN COMERCIO = '8327168' AND AUTORIZACION = 'NVFSAV' THEN '75301503317002570900030'
							WHEN COMERCIO = '5521923' AND AUTORIZACION = '456219' THEN '75301503348002376800015'
							WHEN COMERCIO = '5511724' AND AUTORIZACION = '983363' THEN '75301503301003287500012'
							WHEN COMERCIO = '5511724' AND AUTORIZACION = '593607' THEN '75301503301003287500020'
							WHEN COMERCIO = '8905855' AND AUTORIZACION = '476773' THEN '75301503145002633200012'
							WHEN COMERCIO = '8810629' AND AUTORIZACION = '056640' THEN '75301503193002803300023'
							WHEN COMERCIO = '8810629' AND AUTORIZACION = '407435' THEN '75301503192003220500014'
							WHEN COMERCIO = '5487188' AND AUTORIZACION = '039746' THEN '75301503192000527400013'
							WHEN COMERCIO = '5078336' AND AUTORIZACION = 'FZG5GB' THEN '75301502244006759400019'
							WHEN COMERCIO = '5078336' AND AUTORIZACION = 'BB1RN6' THEN '75301502244006759400027'
							WHEN COMERCIO = '2103192' AND AUTORIZACION = '462357' THEN '74357041361005169400108'
							WHEN COMERCIO = '1782380' AND AUTORIZACION = '098487' THEN '75301502145005542200033'
							WHEN COMERCIO = '2518287' AND AUTORIZACION = '673550' THEN '74357042234005718000055'
							WHEN COMERCIO = '8455141' AND AUTORIZACION = '049716' THEN '75301502012006716200205'
						ELSE PDARER END
			,AUTORIZACION
			,MONEDA
			,FECHA_PROCESO = MAX(FECHA_PROCESO)
			,ImporteTotalTrx = SUM(IMPORTE_TRX)
		FROM PFYCC_GI_TRANS_AS400_CONTRACARGOS_DEVOLUCIONES
		WHERE trx = '34'
		AND LEFT(TARJETA,1) IN ('4','2','5','3') -- VA 4 , MC 2 5, AMEX 3
		AND FECHA_PROCESO >= '2024-12-01' -- retenciones no tan antiguas
		GROUP BY TARJETA
			,COMERCIO
			,PDARER
			,AUTORIZACION
			,MONEDA
			) A
)
,TRANSACCIONAL_DEVOLUCION AS (
SELECT A.* 
	,Orden = ROW_NUMBER() OVER (PARTITION BY TARJETA,COMERCIO,ARD_ARN ORDER BY FECHA_PROCESO desc)
FROM (	select TARJETA
			,COMERCIO
			,ARD_ARN = PDARER
			,MONEDA
			,Entrymode = [ENTRY-MODE]
			,Ecom = NULL
			,Voucher = NULL
			,Terminal = NULL
			,Referencia = NULL
			,FECHA_TRX = MAX(FECHA_TRX)
			,FECHA_PROCESO = max(FECHA_PROCESO)
			,ImporteTotalTrx = SUM(IMPORTE_TRX)
		from PFYCC_GI_TRANS_AS400_CONTRACARGOS_DEVOLUCIONES
		where LEFT(TRX,1) = '8'
		AND LEFT(ARD_ARN,1) = '7'
		AND LEFT(TARJETA,1) IN ('4','2','5','3') -- VA 4 , MC 2 5, AMEX 3
		AND FECHA_PROCESO >= '2024-01-01' -- DEVOL no tan antiguas
		GROUP BY TARJETA
			,COMERCIO
			,PDARER
			,MONEDA
			,[ENTRY-MODE]) A
)

,TRANSACCIONAL AS (
SELECT FechaTrx
	,FechaProcesoTrx = FechaProceso
	,MonedaTrx = Moneda
	,ImporteTrx
	,Terminal
	,Entrymode
	,Referencia
	,Ecom
	,Voucher
	,ARN_ARD
	,Tarjeta
	,CodComercio
	,Autorizacion
	,NomComercio
	,ID_Transaction
	--,ID_Transaction_2
FROM dbo.PFYCC_GI_TRANS_AS400_TRX
WHERE TipoTrx IN ('76','77','78')
AND (Entrymode <> '' AND NomComercio <> '')
AND FechaTrx >= '2024-01-01'
UNION ALL

SELECT FechaTrx
	,FechaProceso
	,Moneda
	,ImporteTrx
	,Terminal
	,Entrymode
	,Referencia
	,Ecom
	,Voucher
	,ARN_ARD
	,Tarjeta
	,CodComercio
	,Autorizacion
	,NomComercio
	,ID_Transaction
	--,ID_Transaction_2
FROM dbo.PFYCC_GI_TRANS_AS400_TRX
WHERE ARN_ARD IN ('75301504316000101100038','75301504288000361800016','75301504361000069600015','75301503179005502200012')	--DEV QUE TAMBIEN SE NECESITAN
)
,MC_CONTRACARGOS AS (
SELECT * FROM (
	SELECT *
		,FechaContracargo = Fecha_CC
		--,Comision_CC = NULL
		,Orden = ROW_NUMBER() OVER (PARTITION BY  ARD, NroControl 
									 ORDER BY Fecha_CC ASC)
	FROM dbo.PFYCC_GI_TRANS_CONTRACARGOS_MASTERCARD
	WHERE Fun IN ('450','453')
	AND Fecha_CC >= '2024-01-01'
	) A
WHERE A.FechaContracargo >= '2025-01-01'
)

,MC_CONTRACARGOS_REVERSADOS AS (
SELECT B.ARD
	,B.NroControl
	,B.Razon
	,B.Fecha_CC
	,B.Moneda_CC
	,B.Importe_CC
	,A.Cantidad
FROM ( SELECT ARD
			,NroControl
			,Cantidad = count(1)
	   FROM dbo.PFYCC_GI_TRANS_CONTRACARGOS_MASTERCARD
	   WHERE Fun in ('450R','453R')
	   GROUP BY ARD
			,NroControl
	 ) A
INNER JOIN ( SELECT *
					,ORDEN = ROW_NUMBER() OVER (PARTITION BY ARD, NroControl ORDER BY Fecha_CC DESC, Importe_Soles DESC)
				FROM dbo.PFYCC_GI_TRANS_CONTRACARGOS_MASTERCARD
				WHERE Fun IN ('450R','453R')
			   ) B ON A.ARD = B.ARD
					AND A.NroControl = B.NroControl
					AND B.ORDEN = 1
)

,MASTERCARD AS (
SELECT Marca = 'Mastercard'
	,Tipo_Flujo = 'CC_ADQ'
	,Jurisdiccion = Intercambio
	,A.BIN
	,Emisor = CASE WHEN B.NOM_BANCO IS NULL THEN 'FORÁNEO' ElSE B.NOM_BANCO END
	,FechaCC = A.FechaContracargo
	,ICAIngresaCC = A.ICA_Ingresa_CC
	,ICARecibeCC = A.ICA_Recibe_CC
	,MTI
	,Fun
	,A.Tarjeta
	,Tipo
	,MonedaCC = A.Moneda_CC
	,ImporteCC = A.Importe_CC
	,CodAutorizacion = CASE WHEN A.Cod_Autorizacion = '' THEN F.Autorizacion ELSE A.Cod_Autorizacion END
	,ARD_ARN = A.ARD
	,CodComercio = CASE WHEN Cod_Comercio = '' THEN F.CodComercio ELSE Cod_Comercio END
	,NomComercio = F.NomComercio
	,NroControl_ROLCase = A.NroControl
	,Razon = A.Razon
	,CategoriaCC = C.Categoria
	,PaisEmisor = Pais_Emisor
	,MensajeEmisor = Mensaje_Emisor
	,EstadoAS400 = A.Estado_CC
	,FechaestadoAS400 = Fecha_Estado_CC
	,GestorestadoAS400 = D.Usuario
	,ObservacionesgestorAS400 = Obs_Gestor
	,Contracargo 
	,FechaTrx = CASE WHEN F.FechaTrx IS NULL THEN H.FECHA_TRX ELSE F.FechaTrx END
	,FechaProcesoTrx = CASE WHEN F.FechaProcesoTrx IS NULL THEN H.FECHA_PROCESO ELSE F.FechaProcesoTrx END
	,MonedaTrx = CASE WHEN F.MonedaTrx IS NULL THEN H.Moneda ELSE F.MonedaTrx END
	,ImporteTrx = CASE WHEN F.ImporteTrx IS NULL THEN H.ImporteTotalTrx ELSE F.ImporteTrx END
	,Entrymode = CASE WHEN F.Entrymode IS NULL THEN H.Entrymode ELSE F.Entrymode END
	,Ecom = CASE WHEN F.Ecom IS NULL THEN H.Ecom ELSE F.Ecom END
	,Voucher = CASE WHEN F.Voucher IS NULL THEN H.Voucher ELSE F.Voucher END
	,Terminal = CASE WHEN F.Terminal IS NULL THEN H.Terminal ELSE F.Terminal END
	,Referencia = CASE WHEN F.Referencia IS NULL THEN H.Referencia ELSE F.Referencia END
	,ID_Transacción = F.ID_Transaction
	,Reten_Dev = CASE WHEN G.FECHA_PROCESO IS NOT NULL AND H.FECHA_PROCESO IS NOT NULL THEN 'RET Y DEV'
					  WHEN G.FECHA_PROCESO IS NOT NULL THEN 'RETENCION'
					  WHEN H.FECHA_PROCESO IS NOT NULL THEN 'DEVOLUCION' 
					  ELSE 'NINGUNO' END
	,FechaRet = G.FECHA_PROCESO
	,MonedaRet =  CASE WHEN G.Moneda IS NULL THEN ' ' ELSE G.Moneda End
	,ImporteRet = CASE WHEN G.ImporteTotalTrx IS NULL THEN 0 ELSE G.ImporteTotalTrx END
	,FechaDev = H.FECHA_PROCESO
	,MonedaDev = CASE WHEN H.Moneda IS NULL Then '' ELSE H.Moneda END
	,ImporteDev = CASE WHEN H.ImporteTotalTrx IS NULL THEN 0 ELSE H.ImporteTotalTrx END
	,RUC = I.nroruc
	,RazonSocial = I.razsoc
	,ImporteSoles = A.Importe_Soles
	,Facilitador = I.facili_pago
	,Segmento = I.cta_esp
	,PPTR = I.PGS
	,Situacion = I.Situacion
	,GiroComercio = I.giro
	,RangoMonto = CASE WHEN CONVERT(DECIMAL(18,2),A.Importe_Soles) < 100   THEN 'a.[0;100>'
					   WHEN CONVERT(DECIMAL(18,2),A.Importe_Soles) < 350   THEN 'b.[100;350>'
					   WHEN CONVERT(DECIMAL(18,2),A.Importe_Soles) < 500   THEN 'c.[350;500>'
					   WHEN CONVERT(DECIMAL(18,2),A.Importe_Soles) < 1000  THEN 'd.[500;1k>'
					   WHEN CONVERT(DECIMAL(18,2),A.Importe_Soles) < 2000  THEN 'e.[1k;2k>'
					   WHEN CONVERT(DECIMAL(18,2),A.Importe_Soles) < 3000  THEN 'f.[2k;3k>'
					   WHEN CONVERT(DECIMAL(18,2),A.Importe_Soles) >= 3000 THEN 'g.>=3k' END
	,MotivoCC = C.Descripcion
	,Reversa1raEtapa = Case When J.Razon is not null Then CONCAT(J.Cantidad,'-',J.Razon) Else NULL END
	,FechaRV1raEtapa = J.Fecha_CC
	,Orden = A.Orden
	--,A.Comision_CC
FROM MC_CONTRACARGOS A
	LEFT JOIN BIN B ON A.Bin = B.BIN
	LEFT JOIN CATEGORIA_CC C ON A.Razon = C.Razon
	LEFT JOIN MC_USUARIOS D ON A.Gestor_Estado = D.MC
	LEFT JOIN TRANSACCIONAL F ON A.ARD = F.ARN_ARD
							  AND A.Tarjeta = F.Tarjeta
							  AND A.Cod_Comercio = F.CodComercio
	LEFT JOIN TRANSACCIONAL_RETENCION G ON A.ARD = G.ARD_ARN
										AND LEFT(A.Tarjeta,6) = LEFT(G.Tarjeta,6)
										AND RIGHT(A.Tarjeta,4) = RIGHT(G.Tarjeta,4)
										AND A.Cod_Comercio = G.COMERCIO
										--AND A.Cod_Autorizacion = G.AUTORIZACION -- MAS PRECISO
	LEFT JOIN TRANSACCIONAL_DEVOLUCION H ON A.ARD = H.ARD_ARN
										AND LEFT(A.Tarjeta,6) = LEFT(H.Tarjeta,6)
										AND RIGHT(A.Tarjeta,4) = RIGHT(H.Tarjeta,4)
										AND A.Cod_Comercio = H.COMERCIO
										--AND A.Cod_Autorizacion = H.AUTORIZACION -- MAS PRECISO
	LEFT JOIN RT_GD_TRANS_MCESTAB_RPA_CC I ON A.Cod_Comercio = I.codigo
	LEFT JOIN MC_CONTRACARGOS_REVERSADOS J ON A.ARD = J.ARD
											AND A.NroControl = J.NroControl
	WHERE A.FechaContracargo >= '2025-01-01' -- MODIFICA RANGO CC 2024 EN ADELANTE
)

,VA_CONTRACARGOS AS (
SELECT Jurisdiction
	,BIN = CASE WHEN Token <> '' THEN LEFT(Token,6) ELSE LEFT(Card_AccountNumber,6) END
	,FechaCC = SettleDate
	,Tarjeta = CASE WHEN Token <> '' THEN Token ELSE Card_AccountNumber END
	,TipoMoneda
	,Amount
	,ARN
	,ROLCase
	,Razon = REPLACE((REPLACE(VROLFinancialID,RIGHT (VROLFinancialID,5),'')),'M','')
	,VROLFinancialID
	,ImporteSoles = CAST(ROUND(Case When TipoMoneda = 'Soles' Then Amount Else Amount*3.7 END,2) as decimal(18,2))
	,Comision_CC = ROUND(ABS(InterFeeAmount),2)
	,Orden = CASE WHEN SettleDate = '2025-02-22' AND ARN = '74357045010004045201323' AND ROLCase = '5417808623' AND DisputeCategory = '10' AND DisputeCategoryCondition = '4' THEN 2 --RV es 10.4
				  WHEN SettleDate = '2025-02-22' AND ARN = '74357045010004045201323' AND ROLCase = '5417808623' AND DisputeCategory = '13' AND DisputeCategoryCondition = '1' THEN 1
				  WHEN SettleDate = '2025-04-16' AND ARN = '74357045032003264219820' AND ROLCase = '5428843693' AND DisputeCategory = '10' AND DisputeCategoryCondition = '4' THEN 2 --RV es 10.4
				  WHEN SettleDate = '2025-04-16' AND ARN = '74357045032003264219820' AND ROLCase = '5428843693' AND DisputeCategory = '13' AND DisputeCategoryCondition = '1' THEN 1
				  WHEN SettleDate = '2025-05-27' AND ARN = '74357045070001702321649' AND ROLCase = '5443953911' AND DisputeCategory = '10' AND DisputeCategoryCondition = '4' THEN 2 --RV es 27/05
				  WHEN SettleDate = '2025-05-28' AND ARN = '74357045070001702321649' AND ROLCase = '5443953911' AND DisputeCategory = '10' AND DisputeCategoryCondition = '4' THEN 1
				  WHEN SettleDate = '2025-05-10' AND ARN = '74357044340002888015754' AND ROLCase = '2545543136' AND DisputeCategory = '13' AND DisputeCategoryCondition = '6' AND Amount = 613.15 THEN 2 --RV es 27/05
				  WHEN SettleDate = '2025-05-10' AND ARN = '74357044340002888015754' AND ROLCase = '2545543136' AND DisputeCategory = '13' AND DisputeCategoryCondition = '6' THEN 1
				  WHEN SettleDate = '2025-06-13' AND ARN = '74357045033001414000289' AND ROLCase = '2551397602' AND DisputeCategory = '13' AND DisputeCategoryCondition = '6' AND Amount = 254.9 THEN 2 --RV es 27/05
				  WHEN SettleDate = '2025-06-13' AND ARN = '74357045033001414000289' AND ROLCase = '2551397602' AND DisputeCategory = '13' AND DisputeCategoryCondition = '6' AND Amount = 129.95 THEN 1 --RV es 27/05
				  ELSE ROW_NUMBER() OVER (PARTITION BY ARN, RolCase ORDER BY SettleDate ASC) END
				  --SOLO LO QUE ES RV, SE PONE ORDEN 2 (CUANDO NO HAY DIFERENCIA ENTRE AMBOS CC COMENTAR AMBOS Y ESPECIFICAR EN RV EL ORDEN 2)
	,Contracargo
FROM dbo.PFYCC_GI_TRANS_VISA_ROL500_INCYOUT
WHERE SettleDate >= '2025-01-01'
	AND DisputeStatusDescription = 'Dispute Financial'
) 

,VA_CONTRACARGOS_REVERSADOS AS (
SELECT FechaCC = B.SettleDate
	,B.ARN
	,B.ROLCase
	,Orden = CASE WHEN A.ARN = '74357045003001757523307' AND A.ROLCase = '5407262287' AND DisputeCategory = '13' AND DisputeCategoryCondition = '1' THEN 2 --Fecha RV es '2025-01-21'
				  WHEN A.ARN = '74357044341007549900277' AND A.ROLCase = '5405590657' AND DisputeCategory = '13' AND DisputeCategoryCondition = '1' THEN 2 --Fecha RV es '2025-01-17'
				  WHEN A.ARN = '74357045010004045201323' AND A.ROLCase = '5417808623' AND DisputeCategory = '10' AND DisputeCategoryCondition = '4' THEN 2 --RV es 10.4
				  WHEN A.ARN = '74357045032003264219820' AND A.ROLCase = '5428843693' AND DisputeCategory = '10' AND DisputeCategoryCondition = '4' THEN 2 --RV es 10.4
				  WHEN A.ARN = '74357045070001702321649' AND A.ROLCase = '5443953911' AND DisputeCategory = '10' AND DisputeCategoryCondition = '4' THEN 2 --RV es 27/05
				  WHEN A.ARN = '74357044340002888015754' AND A.ROLCase = '2545543136' AND DisputeCategory = '13' AND DisputeCategoryCondition = '6' THEN 2 --RV 
				  WHEN A.ARN = '74357045033001414000289' AND A.ROLCase = '2551397602' AND DisputeCategory = '13' AND DisputeCategoryCondition = '6' THEN 2 --RV 
				  ELSE ROW_NUMBER() OVER (PARTITION BY A.ARN, A.RolCase ORDER BY SettleDate ASC) END
				  --SOLO HABILITAR LA RV QUE SERA EL ORDEN 2
	,A.Cantidad
FROM (SELECT RolCase
		,ARN
		,Cantidad = COUNT(1)
		FROM dbo.PFYCC_GI_TRANS_VISA_ROL500_INCYOUT
		WHERE SettleDate >= '2025-01-01'
		AND DisputeStatusDescription = 'Dispute Reversal - Recall'
		GROUP BY RolCase
		,ARN
		)A
		INNER JOIN ( SELECT *
							,Orden = ROW_NUMBER() OVER (PARTITION BY ARN, RolCase ORDER BY SettleDate DESC, Amount DESC)
				FROM dbo.PFYCC_GI_TRANS_VISA_ROL500_INCYOUT
				WHERE SettleDate >= '2025-01-01'
				AND DisputeStatusDescription = 'Dispute Reversal - Recall'
				) B ON A.ARN = B.ARN 
					AND A.ROLCase = B.ROLCase
					AND B.Orden = 1
)

,VISA AS (
SELECT Marca = 'Visa'
	,Tipo_Flujo = 'CC_ADQ'
	,Jurisdiccion = A.Jurisdiction
	,Bin = A.BIN
	,Emisor = CASE WHEN B.NOM_BANCO IS NULL THEN 'FORÁNEO' ElSE B.NOM_BANCO END
	,FechaCC = A.FechaCC
	,ICAIngresaCC = ''
	,ICArecibeCC = ''
	,MTI = ''
	,Fun = CASE WHEN A.VROLFinancialID LIKE '%M%' THEN 'RDR' ELSE '' END
	,Tarjeta = A.Tarjeta
	,Tipo = ''
	,MonedaCC = A.TipoMoneda
	,ImporteCC = A.Amount
	,CodAutorizacion = C.Autorizacion
	,ARD_ARN = A.ARN
	,CodComercio = C.CodComercio
	,NomComercio = C.NomComercio
	,NroControl_ROLCase = A.ROLCase
	,Razon = A.Razon
	,CategoriaCC = D.Categoria
	,PaisEmisor = ''
	,Mensajeemisor = ''
	,EstadoAS = ''
	,FechaestadoAS = null
	,GestorestadoAS = ''
	,ObservacionesgestorAS = ''
	,Contracargo
	,FechaTrx = C.FechaTrx
	,FechaProcesoTrx = C.FechaProcesoTrx
	,MonedaTrx = C.MonedaTrx
	,ImporteTrx = C.ImporteTrx
	,Entrymode = C.Entrymode
	,Ecom = CASE WHEN V.MOTOInd IS NULL THEN '' ELSE V.MOTOInd END
	,Voucher = C.Voucher
	,Terminal = C.Terminal
	,Referencia = C.Referencia
	,ID_Transacción = C.ID_Transaction
	,Reten_Dev = CASE WHEN F.FECHA_PROCESO IS NOT NULL AND G.FECHA_PROCESO IS NOT NULL THEN 'RET Y DEV'
					  WHEN F.FECHA_PROCESO IS NOT NULL THEN 'RETENCION'
					  WHEN G.FECHA_PROCESO IS NOT NULL THEN 'DEVOLUCION' 
					  ELSE 'NINGUNO' END
	,FechaRet = F.FECHA_PROCESO
	,MonedaRet = CASE WHEN F.Moneda IS NULL THEN ' ' ELSE F.Moneda END 
	,ImporteRet = CASE WHEN F.ImporteTotalTrx IS NULL THEN 0 ELSE F.ImporteTotalTrx END
	,FechaDev = G.FECHA_PROCESO
	,MonedaDev = G.Moneda
	,ImporteDev = CASE WHEN G.ImporteTotalTrx IS NULL THEN 0 ELSE G.ImporteTotalTrx END
	,RUC = I.nroruc
	,RazonSocial = I.razsoc
	,ImporteSoles = A.ImporteSoles
	,Facilitador = I.facili_pago
	,Segmento = CASE WHEN C.CodComercio = '8897146' THEN 'Negocios'
					 WHEN C.CodComercio = '8836746' THEN 'Negocios' ELSE  I.cta_esp END-------------------------------------------------------------------------------------------------------
	,PPTR = I.PGS
	,Situacion = I.Situacion
	,GiroComercio = I.giro
	,RangoMonto = CASE WHEN CONVERT(DECIMAL(18,2),A.ImporteSoles) < 100   THEN 'a.[0;100>'
							WHEN CONVERT(DECIMAL(18,2),A.ImporteSoles) < 350   THEN 'b.[100;350>'
							WHEN CONVERT(DECIMAL(18,2),A.ImporteSoles) < 500   THEN 'c.[350;500>'
							WHEN CONVERT(DECIMAL(18,2),A.ImporteSoles) < 1000  THEN 'd.[500;1k>'
							WHEN CONVERT(DECIMAL(18,2),A.ImporteSoles) < 2000  THEN 'e.[1k;2k>'
							WHEN CONVERT(DECIMAL(18,2),A.ImporteSoles) < 3000  THEN 'f.[2k;3k>'
							WHEN CONVERT(DECIMAL(18,2),A.ImporteSoles) >= 3000 THEN 'g.>=3k' End
	,MotivoCC = CASE WHEN LEFT(A.VROLFinancialID,1) <> 'M' THEN D.Descripcion 
					 WHEN LEFT(A.VROLFinancialID,1) = 'M' THEN CONCAT('RDR ',AA.CaseStatus) ELSE D.Descripcion END 
	,Reversa1raEtapa = CASE WHEN U.ROLCase IS NOT NULL THEN CONCAT(U.Cantidad,'-',U.ROLCase) ELSE U.ROLCase END
	,FechaRV1raEtapa =  U.FechaCC 
	,Orden = A.Orden
	--,A.Comision_CC
FROM VA_CONTRACARGOS A
	LEFT JOIN BIN B ON A.BIN = B.BIN
	LEFT JOIN TRANSACCIONAL C ON A.ARN = C.ARN_ARD
							AND A.Tarjeta = C.Tarjeta
	LEFT JOIN CATEGORIA_CC D ON A.Razon = D.Razon
	LEFT JOIN TRANSACCIONAL_RETENCION F ON A.ARN = F.ARD_ARN
										AND LEFT(A.Tarjeta,6) = LEFT(F.Tarjeta,6)
										AND RIGHT(A.Tarjeta,4) = RIGHT(F.Tarjeta,4)
										--AND C.Autorizacion = F.AUTORIZACION -- CRUCE ARD_PROCESSED (TABLA C) CON AS400 RETEN (TABLA F)
	LEFT JOIN TRANSACCIONAL_DEVOLUCION G ON A.ARN = G.ARD_ARN
										AND LEFT(A.Tarjeta,6) = LEFT(G.Tarjeta,6)
										AND RIGHT(A.Tarjeta,4) = RIGHT(G.Tarjeta,4)
										--AND C.Autorizacion = G.AUTORIZACION -- CRUCE ARD_PROCESSED (TABLA C) CON AS400 DEVOL (TABLA G)
	LEFT JOIN TRANSACCIONAL H ON A.ARN = H.ARN_ARD
	LEFT JOIN dbo.RT_GD_TRANS_MCESTAB_RPA_CC I ON H.CodComercio = I.codigo -- Consultar a Sebas
	LEFT JOIN VA_CONTRACARGOS_REVERSADOS U ON A.ARN = U.ARN
											 AND A.ROLCase = U.ROLCase
											 AND A.Orden = U.Orden
    LEFT JOIN Ecom_VA V ON A.ARN = V.ARN
						AND A.ROLCase = V.RolCaseNumber
   LEFT JOIN (SELECT RolCaseNumber
				     ,ARN = LEFT(ARN,23)
					 ,CaseStatus
					 ,FechaCarga
				FROM (SELECT RolCaseNumber
									 ,ARN
									 ,CaseStatus
									 ,FechaCarga
									 ,Orden = ROW_NUMBER() OVER (PARTITION BY RolCaseNumber, ARN ORDER BY FechaCarga ASC)
						FROM dbo.PFYCC_GI_CARGA_VISA_ROL1100_Jul21 -- Consultar a Sebas
						WHERE FechaCarga  >= '2024-01-01') A
					WHERE Orden = 1 ) AA ON A.ARN = AA.ARN
										AND A.ROLCase = AA.ROLCaseNumber
WHERE A.FechaCC >= '2025-01-01'	-- MODIFICA RANGO CC 2024 EN ADELANTE		
)
,PRE_REPORTE_RPA AS (
	SELECT A.*
		,Prioridad = CASE WHEN   CategoriaCC = 'Errores de procesamiento' THEN '3'
					  WHEN  (Segmento = 'Negocios' AND (CategoriaCC = 'Fraude' OR CategoriaCC = 'Servicios/Mercadería - Disputas del consumidor')) THEN '1'
					  WHEN  (Segmento = 'Empresas' AND (CategoriaCC = 'Fraude' OR CategoriaCC = 'Servicios/Mercadería - Disputas del consumidor')) THEN '2'
					  WHEN ((Segmento = 'Grandes empresas' OR Segmento = 'Corporacion') AND (CategoriaCC = 'Fraude')) THEN '3'
					  WHEN  (Segmento = 'Negocios' AND (CategoriaCC = 'Errores de procesamiento' OR CategoriaCC = 'Autorización')) THEN '4'
					  WHEN  (Segmento = 'Empresas' AND (CategoriaCC = 'Errores de procesamiento' OR CategoriaCC = 'Autorización')) THEN '5'
					  WHEN ((Segmento = 'Grandes empresas' OR Segmento = 'Corporacion') AND (CategoriaCC = 'Errores de procesamiento' OR CategoriaCC = 'Autorización' OR CategoriaCC = 'Servicios/Mercadería - Disputas del consumidor')) THEN '6' END --ELSE 'Validar' END
						
	FROM (SELECT * FROM MASTERCARD
	UNION ALL
	SELECT * FROM VISA) A
)
,DEVOLUCIONES_POR_PROCESAR AS (
SELECT DISTINCT COD
	,ULTDIGTARJETA
	,REFERENCIA
	,AUTORIZACION
FROM dbo.RT_GD_CARGA_15_VARIABLES
)

,INCIDENCIA AS (
SELECT DISTINCT COMERCIO
	,TARJ
	,ARN
FROM dbo.RT_GD_CARGA_INCIDENCIA_RAPPI_DLOCAL
)

,PRE_FLAG_ATENCION_GD AS (
SELECT A.*
	,Segmento_F = B.segmento
	,Flag_Moneda = CASE WHEN MonedaCC = MonedaTrx  THEN 'UNI_MONEDA' ELSE 'BI_MONEDA' END
	,Flag_TICA = CASE WHEN MonedaCC = MonedaTrx  THEN ABS(ImporteCC - ImporteTrx )
					  WHEN MonedaCC = 'Soles' THEN ImporteCC / ImporteTrx
					  WHEN MonedaCC = 'Dólares americanos' THEN ImporteTrx / ImporteCC END
	,Tipo_Linea = CASE WHEN C.COD IS NOT NULL THEN 'L3'----------------------------------------------------------------------------------------------(INCIDENCIA DEV NO PROCESADAS)
					   WHEN D.COMERCIO IS NOT NULL THEN 'L3'-----------------------------------------------------------------------------------------(INCIDENCIA DEV NO PROCESADAS)
					   WHEN A.RUC = '20602985971' THEN 'L3'------------------------------------------------------------------------------------------(RAPPI DEFINIR PROCESO DE CC)
					   WHEN A.RUC = '20337101276' THEN 'L3' --------------- COMERCIO SAT PASAR A L3
					   WHEN A.RUC = '20505377142' THEN 'L3' --------------- REDVIAL 5 NO SE NOTIFICA, PASAR A L3
					   WHEN Contracargo <> 'CC Unico' THEN 'L3'
					   WHEN Tipo = '20' THEN 'L3'
					   WHEN (DATEDIFF(DAY,A.FechaProcesoTrx,A.FechaCC)) >= 121 THEN 'L3'
					   WHEN Prioridad IN ('1','2','4','5','6') THEN 'L3'
					   WHEN Prioridad = '3' AND FechaDev IS NOT NULL AND CategoriaCC = 'Fraude'  THEN 'L3'
					   WHEN GiroComercio IN ('4511 - Transportadores Aereos, Aerolineas-no clasificados en otro','3030 - Aerolineas Argentinas-AERO ARG','4722 - Agencias de Viaje y Operadores Turisticos'
											,'5592 - Vendedores de Casas Moviles','7512 - Agencia de Alquiler de Automoviles-no clasificada en otro','3502 - Best Western Hotels','Grua para vehiculos'
											,'3533 - Hotel Ibis','7011 - Alojamiento-Hoteles, Moteles, Centros Turisticos-no','3548 - Hotels Melia','7542 - Lavado de Autos','3509 - Marriott'
											,'3642 - Novotel Hotels','PRINCE HOTEL','3519 - Pullman International Hotels','3649 - Radisson Hotels','3503 - Sheraton (Sheraton Hotels)','SOFITEL HOTELS'
											,'3591 - Sonesta Hotels','Vehículo aeronaves y maquinas ','4722 - Agencias de Viaje y Operadores Turisticos','3513 - Westin (Westin Hotels)'
											,'6012 - Mercancia y Servicios-Institucion Financiera Cliente') --SOLICITUD DE JENNY POR CASO PREXPE
										THEN 'L3'
					   WHEN RUC = '20523621212'  THEN 'L3' --LIMA EXPRESA S.A.C.
					   WHEN Fun = 'RDR' THEN 'L3'
					   WHEN CONCAT(Entrymode,CategoriaCC) = 'PQFraude' THEN 'L3'
					   WHEN CONCAT(LEFT(Marca,1),LEFT(CategoriaCC,1),LEFT(Ecom,3)) = 'MF211' THEN 'L3'
					   WHEN CONCAT(LEFT(Marca,1),LEFT(CategoriaCC,1),LEFT(Ecom,3)) = 'MF212' THEN 'L3'
					   WHEN CONCAT(LEFT(Marca,1),LEFT(CategoriaCC,1),LEFT(Ecom,1)) = 'VF5'   THEN 'L3'
					   WHEN CONCAT(LEFT(Marca,1),LEFT(CategoriaCC,1),LEFT(Ecom,1)) = 'VF6'   THEN 'L3' 
					   WHEN Terminal in ('00000007','00000006') THEN 'L3'-- Terminal Billetera
					   WHEN E.codigo IS NOT NULL THEN 'L3' -- CC de comercios Full 3ds
					   --WHEN CategoriaCC = 'Errores de procesamiento' THEN 'L3' -- CC DE ERRORES DE PROCESAMIENTO A L3
					   --WHEN Razon in ('12.3','12.5','12.6.1','12.6.2','4831','4834') THEN 'L3' -- PAGO POR OTROS MEDIOS Y DUPLICIDAD 
					   WHEN Razon = '12.5' THEN 'L3' --MONTO INCORRECTO PASA A L3 27/06 acuerdo con Jenny y L1
					   ELSE 'L1' END
	,Flag_correo = CASE WHEN C.COD IS NOT NULL THEN 'NO' -----------------------------------------------------------------------------------------
						WHEN D.COMERCIO IS NOT NULL THEN 'NO' -----------------------------------------------------------------------------------------
						WHEN Contracargo <> 'CC Unico' THEN 'NO'
						WHEN Tipo = '20' THEN 'NO'
						WHEN FechaRV1raEtapa is not null THEN 'NO' -- NO ENVIAR A CC REVERSADOS PORQUE YA ESTÁN SALDADOS --EstadoActual <> 'EN ANALISIS' THEN 'NO'
						WHEN DATEDIFF(DAY,FechaCC,FechaProcesoTrx) >= 121 THEN 'NO'
						WHEN RUC = '20505377142' THEN 'NO' -- GRAN CONCENTRACIÓN DE CC REDVIAL 5 NO SE NOTIFICA, PENDIENTE DE REVISAR CONTRATO
	                    WHEN CategoriaCC = 'Autorización' AND RUC = '20505377142'  THEN 'NO' -- REDVIAL 5 NO SE NOTIFICA
						WHEN MotivoCC IN ('12.1 Processing Error - Late Presentment', 'Presentación tardía') THEN 'NO'
						WHEN (CategoriaCC = 'Fraude' AND Entrymode LIKE '%CHIP%') THEN 'NO'
						WHEN (CategoriaCC = 'Fraude' AND Entrymode = 'PQ') THEN 'NO' -- AND A.Terminal = '65656565'
						WHEN RUC IN ('20523621212','20555530090') THEN 'NO' -- LIMA EXPRESSA, CULQUI Y 
						WHEN FechaDev IS NOT NULL THEN 'NO'
						WHEN LEN(B.Contacto_Opera) <= 6 THEN 'NO' -- manda a notificar si no se tienen correos
						WHEN MotivoCC LIKE '%RDR %' THEN 'NO'--TEMPORAL POR COORDINACIÓN CON LA MARCA RDR
						WHEN CONCAT(LEFT(Marca,1),LEFT(CategoriaCC,1),LEFT(Ecom,3)) = 'MF211' THEN 'NO'
						WHEN CONCAT(LEFT(Marca,1),LEFT(CategoriaCC,1),LEFT(Ecom,3)) = 'MF212' THEN 'NO'
						WHEN CONCAT(LEFT(Marca,1),LEFT(CategoriaCC,1),LEFT(Ecom,1)) = 'VF5'   THEN 'NO'
						WHEN CONCAT(LEFT(Marca,1),LEFT(CategoriaCC,1),LEFT(Ecom,1)) = 'VF6'   THEN 'NO'
						WHEN GiroComercio IN ('6012 - Mercancia y Servicios-Institucion Financiera Cliente') THEN 'NO' -- NO PEDIR EVIDENCIAS POR SOLICITUD DE JENNY CASE PREXPE
						WHEN RUC IN ('20100070970','20331066703','20394077101','20493020618','20506035121','20511315922','20512002090','20536557858','20556246743','20600414276','20601233488','20603150954','20607607061','20608300393','20608430301') THEN 'NO' -- RUC Grupo Intercorp
						WHEN RUC IN ('20604068178','20451770501','20563525461','20333372216','20100017491','20551348041','20603543581','20462540745') THEN 'SI' --MP '20462540745'
						WHEN NomComercio LIKE '%IZI*%' THEN 'SI'
						ELSE 'SI' END
FROM PRE_REPORTE_RPA A
LEFT JOIN dbo.RT_GD_TRANS_MCESTAB_RPA_CC B ON A.CodComercio = B.codigo --Consultar a Sebas
LEFT JOIN DEVOLUCIONES_POR_PROCESAR C ON A.CodComercio = C.COD
										AND RIGHT(A.Tarjeta,4) = C.ULTDIGTARJETA
										AND A.Voucher = C.REFERENCIA
										AND A.CodAutorizacion = C.AUTORIZACION
LEFT JOIN INCIDENCIA D ON A.CodComercio = TRIM(D.COMERCIO)
						AND LEFT(A.Tarjeta,6) = LEFT((TRIM(D.TARJ)),6)
						AND RIGHT(A.Tarjeta,4) = RIGHT((TRIM(D.TARJ)),4)
						AND A.ARD_ARN =TRIM(D.ARN)
LEFT JOIN RT_GD_COMERCIOS_FULL_3DS E ON A.CodComercio = E.codigo
WHERE A. Tipo_Flujo = 'CC_ADQ'
AND A. Marca IN ('Visa', 'Mastercard')
)
--SELECT top 100 * FROM PRE_FLAG_ATENCION_GD

,VALIDACION_ATENCION AS (
SELECT A.*
	,Atencion_TICA = CASE WHEN Flag_Moneda = 'UNI_MONEDA' AND Flag_TICA * 10 <= ImporteTrx THEN 'Atención GD'
				          WHEN Flag_Moneda = 'BI_MONEDA' AND Flag_TICA BETWEEN 3.5 AND 4.2 THEN 'Atención GD' ELSE 'Flujo Regular' END
	,Atencion_Importe = CASE WHEN Segmento_F = 'Facilitador Virtual' AND Contracargo = 'CC Unico' THEN 'Atención GD'
							 WHEN ImporteSoles <= 1500 AND Contracargo = 'CC Unico' THEN 'Atención GD' ELSE 'Flujo Regular' END
FROM PRE_FLAG_ATENCION_GD A
)

,PFYCC_GI_REPORTE_RPA_LINEA AS (
SELECT A.*
	,Atencion_GD = CASE WHEN Tipo_Linea = 'L1' 
						AND Flag_correo = 'SI' 
						AND Atencion_TICA = 'Atención GD' 
						AND Atencion_Importe = 'Atención GD' 
						AND CategoriaCC = 'Fraude' 
						AND LEFT(MotivoCC,4)<>'10.3'
						AND CodComercio <> '4077524' THEN 'SI' --ultima mod, EXCLUIR JUNTOZ ESO VA DIRECTO A L1 O L3
				        ELSE 'NO' END
FROM VALIDACION_ATENCION A
)

SELECT *
FROM PFYCC_GI_REPORTE_RPA_LINEA
