	/****** Object:  StoredProcedure [Stage].[usp_GeneraStgTerminalA]    Script Date: 5/29/2025 4:02:57 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [Stage].[usp_GeneraStgTerminalA] AS
BEGIN
/*======================================================================================= 
Autor					:Business Analytics SAC
Fecha creación			:2021/04/07
Objetivos				:Generar la tabla [Stage].[StgTerminalA]
Ejecutar				:EXECUTE [Stage].[usp_GeneraStgTerminalA]
=======================================================================================*/ 

/*==================================PROCESO 1============================================ 
Vaciar el contenido las tabla [Stage].[StgTerminalA]
=======================================================================================*/ 
TRUNCATE TABLE [Stage].[StgTerminalA];

/*==================================PROCESO 2============================================ 
Insertar datos a la tabla [Stage].[StgTerminalA] a partir de la tabla [RAW].[tmmerchant_a]
=======================================================================================*/
INSERT INTO [Stage].[StgTerminalA] ([COMERCIO]
      ,[NOMBRE]
      ,[RUBRO]
      ,[RUC]
      ,[DIRECCION]
      ,[DEPARTAMENTO]
      ,[PROVINCIA]
      ,[DISTRITO]
      ,[MULTICOMERCIO]
      ,[TELEFONO_COMERCIO]
      ,[CONTACTO]
      ,[PERFIL_COMERCIO]
      ,[PERFIL_DESCARGA]
      ,[TERMINAL]
      ,[SERIE]
      ,[MEDIO]
      ,[DESCRIPCION_TERMINAL]
      ,[FECHA_ULTIMO_ECO]
      ,[FECHA_ULTIMA_TRANSACCION_FINANCIERA]
      ,[FECHA_ULTIMA_TRANSACCION_ADMINISTRATIVA]
      ,[MODELO]
      ,[VERSION_SWB]
      ,[OS_VERSION]
      ,[CHIP]
      ,[TELEFONO_CHIP]
      ,[OPERADOR]
      ,[ESTADO_COMERCIO]
      ,[ESTADO_LOGICO_COMERCIO]
      ,[ESTADO_TERMINAL]
      ,[ESTADO_LOGICO_TERMINAL]
      ,[APLICACION]
      ,[FACTURACION]
      ,[dTrE105SN]
      ,[VERSION_FLUJO]
      ,[VERSION_MAIN]
      ,[SERIE_COMPLETA]
	  ,PRE_AUTORIZACION_NIVEL_COMERCIO
	  ,PRE_AUTORIZACION_NIVEL_TERMINAL
	  ,DIGITACION_MANUAL_NIVEL_COMERCIO
	  ,DIGITACION_MANUAL_NIVEL_TERMINAL	
	  ,PROPINA
	  ,FECHA_ACTUALIZACION_APP --- (*) AGREGADO
	  ,HORA_ACTUALIZACION_APP  --- (*) AGREGADO
	  ,NUM_INTENTOS  --- (*) AGREGADO
	  ,FECHA_ULTIMA_ACTUALIZACION  --- (*) AGREGADO
	  ,HORA_ULTIMA_ACTUALIZACION --- (*) AGREGADO
	  ,VERSION_ACTUALIZADO --- (*) AGREGADO
	  ,cTAFilesVersion --- (*) AGREGADO
	  ,cVrVersionId --- (*) AGREGADO
	  ,cTAVersionApl --- (*) AGREGADO
	  ,dVrFile --- (*) AGREGADO
	  )
SELECT 
	M.cMrMerchantId as COMERCIO,
	M.dMrMerchantName as NOMBRE,
	M.cMrMCC as RUBRO,
	M.cMrRucCode as RUC, 
	REPLACE(M.dMrAddress,',',' ') as DIRECCION,
	(SELECT dLfDescription FROM RAW.txlistfield_a WITH(NOLOCK) WHERE dLfFieldName = 'Provincia' AND cLfCode = M.cMrDepartCode) as DEPARTAMENTO,
	(SELECT dLfDescription FROM RAW.txlistfield_a WITH(NOLOCK) WHERE dLfFieldName = 'Ciudad' AND cLfCode = M.cMrProvinceCode) as PROVINCIA,
	(SELECT dLfDescription FROM RAW.txlistfield_a WITH(NOLOCK) WHERE dLfFieldName = 'Zona' AND cLfCode = M.cMrDistrictCode) as DISTRITO,
	T.ctrmultmerchant as MULTICOMERCIO,
	M.dMrPhone as TELEFONO_COMERCIO,
	REPLACE(M.dMrContactName,',',' ') as CONTACTO,
	M.cMrProfileId as PERFIL_COMERCIO,
	DP.dDPProfileName as PERFIL_DESCARGA,
	T.cTrTerminalNum as TERMINAL, 
	T.dTrTerminalSN as SERIE,
	T.nTrLongitudTrama as MEDIO,
	T.dTrDescription as DESCRIPCION_TERMINAL,
	T.fTrLastEchoDate as FECHA_ULTIMO_ECO,
	T.fTrLastTrxFinDate as FECHA_ULTIMA_TRANSACCION_FINANCIERA, 
	T.fTrLastTrxAdmDate as FECHA_ULTIMA_TRANSACCION_ADMINISTRATIVA,
	T.cTrModel as MODELO, 
	T.nTrSWVersion as VERSION_SWB,
	T.dTrOSVersion as OS_VERSION,
	T.nTrChipNumber as CHIP,
	TELEFONO as TELEFONO_CHIP,
	OPERADOR as OPERADOR,
	(SELECT dLfDescription FROM RAW.txlistfield_a WITH(NOLOCK) WHERE cLfCode=M.cMrStatus AND dLfFieldName='EstadoComercio') as 'ESTADO_COMERCIO',
	(SELECT dLfDescription FROM RAW.txlistfield_a WITH(NOLOCK) WHERE cLfCode=M.cMrLogicalStatus AND dLfFieldName='EstadoLogicoTerminal') as 'ESTADO_LOGICO_COMERCIO', 
	(SELECT dLfDescription FROM RAW.txlistfield_a WITH(NOLOCK) WHERE cLfCode=T.cTrStatus AND dLfFieldName='EstadoTerminal') as 'ESTADO_TERMINAL',
	(SELECT dLfDescription FROM RAW.txlistfield_a WITH(NOLOCK) WHERE cLfCode=T.cTrLogicalStatus AND dLfFieldName='EstadoLogicoTerminal') as 'ESTADO_LOGICO_TERMINAL',
	taterAP.cTAApplicationID as APLICACION,
	T.cTrAmountPaid as FACTURACION,
	dTrE105SN,
	ctafilesversion as VERSION_FLUJO,
	(SELECT max(ctafilesversion) from RAW.taterminalapplication_a ta1 with(nolock) where ta1.ctamerchantid = ctrmerchantid and ta1.ctaterminalnum = ctrterminalnum and ta1.ctaterminalsn = dtrterminalsn and ta1.ctaapplicationid = 'MAIN') as VERSION_MAIN,
	dTrTerminalCompleteSN as SERIE_COMPLETA,
	CASE WHEN TransCmr.cFLTransactionId = '13' THEN 'SI' ELSE 'NO' END PRE_AUTORIZACION_NIVEL_COMERCIO,
	CASE WHEN tat.cTATTransactionId = '13' THEN 'SI' ELSE 'NO' END PRE_AUTORIZACION_NIVEL_TERMINAL,
	CASE WHEN taMpApp.cMACardWriter = '2' THEN 'SI' WHEN taMpApp.cMACardWriter = '1' THEN 'NO' ELSE 'NO' END DIGITACION_MANUAL_NIVEL_COMERCIO,   -----(*) SE CAMBIO EL PRIMER NO (ANTES ERA SI)
	CASE WHEN cTAMultimerchantWriter = '2' THEN 'SI' WHEN cTAMultimerchantWriter = '1' THEN 'NO' ELSE 'NO' END DIGITACION_MANUAL_NIVEL_TERMINAL,   -----(*) SE CAMBIO EL PRIMER NO (ANTES ERA SI)
	CASE WHEN cTAOnlineTip = '0' THEN 'ONLINE' WHEN cTAOnlineTip = '2' THEN 'AMBAS' WHEN cTAOnlineTip = '3' THEN 'OFFLINE' ELSE 'NINGUNO' END PROPINA,
	--IIF( (taMpApp.cMACardWriter = '2'),'SI',IIF((taMpApp.cMACardWriter = '1'),'NO','NO')) DIGITACION_MANUAL_NIVEL_COMERCIO,
	--IIF((cTAMultimerchantWriter = '2'),'SI',IIF((cTAMultimerchantWriter = '1'),'NO','NO')) DIGITACION_MANUAL_NIVEL_TERMINAL,
	--IIF((cTAOnlineTip = '0') ,'ONLINE',IIF((cTAOnlineTip = '2'),'AMBAS',IIF((cTAOnlineTip = '3'),'OFFLINE','NINGUNO')) ) PROPINA

	--iIF((TransCmr.cFLTransactionId = '13') ,'SI','NO') PRE_AUTORIZACION_NIVEL_COMERCIO--,
	--IIF((tat.cTATTransactionId = '13') ,'SI','NO') PRE_AUTORIZACION_NIVEL_TERMINAL,
	--IIF( (taMpApp.cMACardWriter = '2'),'SI',IIF((taMpApp.cMACardWriter = '1'),'NO','NO')) DIGITACION_MANUAL_NIVEL_COMERCIO,
	--IIF((cTAMultimerchantWriter = '2'),'SI',IIF((cTAMultimerchantWriter = '1'),'NO','NO')) DIGITACION_MANUAL_NIVEL_TERMINAL,
	--IIF((cTAOnlineTip = '0') ,'ONLINE',IIF((cTAOnlineTip = '2'),'AMBAS',IIF((cTAOnlineTip = '3'),'OFFLINE','NINGUNO')) ) PROPINA
	---
	taterAP.fTAUpdateDate as FECHA_ACTUALIZACION_APP,
	taterAP.hTAUpdateTime as HORA_ACTUALIZACION_APP,
	t.nTrDownloadAttempts as NUM_INTENTOS,
	t.fTrLastDownloadDate as FECHA_ULTIMA_ACTUALIZACION,
	t.hTrLastDownloadTime as HORA_ULTIMA_ACTUALIZACION,
	CASE WHEN taterAP.cTAVersionApl=tmV.dVrFile THEN 'SI' ELSE 'NO' END VERSION_ACTUALIZADO,
	taterAP.cTAFilesVersion,
	tmV.cVrVersionId ,
	taterAP.cTAVersionApl ,
	tmV.dVrFile
FROM RAW.tmmerchant_a M WITH(NOLOCK) 
INNER JOIN RAW.tmterminal_a as T WITH(NOLOCK) ON M.cMrMerchantId=T.cTrMerchantId 
LEFT JOIN RAW.tmchipsgprs_a as CH WITH(NOLOCK) ON T.nTrChipNumber=CH.SIMCARD
INNER JOIN RAW.taterminalapplication_a as taterAP WITH(NOLOCK) ON T.cTrTerminalNum=taterAP.cTATerminalNum AND T.cTrMerchantId=taterAP.cTAMerchantId
INNER JOIN RAW.tmDownloadProfile_a as DP with(nolock) ON M.cMrDownloadProfile=DP.cDPProfileID
LEFT JOIN RAW.taFloorLimit_a as TransCmr WITH(NOLOCK) ON M.cMrProfileId = TransCmr.cFLMrProfileId AND TransCmr.cFLAplicacion='POS' AND TransCmr.cFLTransactionId='13'
LEFT  JOIN RAW.taTerminalApplTransaction_a as tat WITH(NOLOCK) ON T.cTrTerminalNum =tat.cTATTerminalNum AND T.cTrMerchantId=tat.cTATMerchantId and tat.cTATTransactionId='13'
LEFT JOIN RAW.taMerchantProfileApplication_a as taMpApp WITH(NOLOCK) ON cMrProfileId = taMpApp.cMAMerchantProfileId AND cTAApplicationID =taMpApp.cMAApplicationID
LEFT JOIN RAW.tmVersion_a tmV WITH(NOLOCK) ON(taterAP.cTAFilesVersion=tmV.cVrVersionId AND taterAP.cTAApplicationID=tmV.cVrApplicationId)
WHERE M.cMrLogicalStatus='0' AND T.cTrLogicalStatus='0' AND T.cTrType IN ('2','3') AND taterAP.cTAApplicationID <> 'MAIN';

--------------------------------------------------------------------------------------------------------------
END
