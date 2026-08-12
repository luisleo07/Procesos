/****** Object:  StoredProcedure [Stage].[usp_GeneraStgTerminalCc]    Script Date: 5/29/2025 4:19:32 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [Stage].[usp_GeneraStgTerminalCc] AS
BEGIN

/*======================================================================================= 
Autor					:Business Analytics SAC
Fecha creación			:2021/04/07
Objetivos				:Generar la tabla [Stage].[StgTerminalCc]
Ejecutar				:EXECUTE [Stage].[usp_GeneraStgTerminalCc]
=======================================================================================*/ 

/*==================================PROCESO 1============================================ 
Vaciar el contenido las tabla [Stage].[StgTerminalCc]
=======================================================================================*/ 
TRUNCATE TABLE [Stage].[StgTerminalCc];

/*==================================PROCESO 2============================================ 
Insertar datos a la tabla [Stage].[StgTerminalCc] a partir de la tabla [RAW].[tmmerchant_cc]
=======================================================================================*/
INSERT INTO [Stage].[StgTerminalCc] ([COMERCIO]
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
	  ,FECHA_ACTUALIZACION_APP   ----(*)
	  ,HORA_ACTUALIZACION_APP   ----(*)
	  ,NUM_INTENTOS   ----(*)
	  ,FECHA_ULTIMA_ACTUALIZACION   ----(*)
	  ,HORA_ULTIMA_ACTUALIZACION   ----(*)
	  ,VERSION_ACTUALIZADO   ----(*)
	  ,cTAFilesVersion   ----(*)
	  ,cVrVersionId   ----(*)
	  ,cTAVersionApl   ----(*)
	  ,dVrFile   ----(*)
	  )
SELECT
	cMrMerchantId AS COMERCIO, 
	dMrMerchantName AS NOMBRE,
	cMrMCC AS RUBRO,
	cMrRucCode AS RUC,
	REPLACE(dMrAddress,',',' ') AS DIRECCION,
	(SELECT dLfDescription FROM RAW.txlistfield_cc WITH(NOLOCK) WHERE dLfFieldName = 'Provincia' AND cLfCode = cMrDepartCode) AS DEPARTAMENTO,
	(SELECT dLfDescription FROM RAW.txlistfield_cc WITH(NOLOCK) WHERE dLfFieldName = 'Ciudad' AND cLfCode = cMrProvinceCode) AS PROVINCIA,
	(SELECT dLfDescription FROM RAW.txlistfield_cc WITH(NOLOCK) WHERE dLfFieldName = 'Zona' AND cLfCode = cMrDistrictCode) AS DISTRITO,
	t.ctrmultmerchant AS MULTICOMERCIO,
	dMrPhone AS TELEFONO_COMERCIO,
	REPLACE(dMrContactName,',',' ') AS CONTACTO,
	cMrProfileId PERFIL_COMERCIO,
	dDPProfileName PERFIL_DESCARGA,
	t.cTrTerminalNum AS TERMINAL, 
	t.dTrTerminalSN AS SERIE,
	t.nTrLongitudTrama AS MEDIO,
	t.dTrDescription AS DESCRIPCION_TERMINAL,
	t.fTrLastEchoDate AS FECHA_ULTIMO_ECO, 
	t.fTrLastTrxFinDate AS FECHA_ULTIMA_TRANSACCION_FINANCIERA,
	t.fTrLastTrxAdmDate AS FECHA_ULTIMA_TRANSACCION_ADMINISTRATIVA, 
	t.cTrModel AS MODELO,
	t.nTrSWVersion AS VERSION_SWB,
	t.dTrOSVersion AS OS_VERSION,
	t.nTrChipNumber AS CHIP,
	TELEFONO AS TELEFONO_CHIP,
	OPERADOR AS OPERADOR,
	(SELECT dLfDescription FROM RAW.txlistfield_cc WITH(NOLOCK) WHERE cLfCode=cMrStatus AND dLfFieldName='EstadoComercio') AS 'ESTADO_COMERCIO',
	(SELECT dLfDescription FROM RAW.txlistfield_cc WITH(NOLOCK) WHERE cLfCode=cMrLogicalStatus AND dLfFieldName='EstadoLogicoTerminal') AS 'ESTADO_LOGICO_COMERCIO', 
	(SELECT dLfDescription FROM RAW.txlistfield_cc WITH(NOLOCK) WHERE cLfCode=cTrStatus AND dLfFieldName='EstadoTerminal') AS 'ESTADO_TERMINAL',
	(SELECT dLfDescription FROM RAW.txlistfield_cc WITH(NOLOCK) WHERE cLfCode=t.cTrLogicalStatus AND dLfFieldName='EstadoLogicoTerminal') AS 'ESTADO_LOGICO_TERMINAL',
	cTAApplicationID AS APLICACION,
	cTrAmountPaid AS FACTURACION,
	dTrE105SN,
	ctafilesversion as VERSION_FLUJO,
	(SELECT max(ctafilesversion) from RAW.taterminalapplication_cc ta1 with(nolock) where ta1.ctamerchantid = ctrmerchantid and ta1.ctaterminalnum = ctrterminalnum and ta1.ctaterminalsn = dtrterminalsn and ta1.ctaapplicationid = 'MAIN' ) as VERSION_MAIN,
	dTrTerminalCompleteSN as SERIE_COMPLETA,
	CASE WHEN TransCmr.cFLTransactionId = '13' THEN 'SI' ELSE 'NO' END PRE_AUTORIZACION_NIVEL_COMERCIO,
	CASE WHEN tat.cTATTransactionId = '13' THEN 'SI' ELSE 'NO' END PRE_AUTORIZACION_NIVEL_TERMINAL,
	CASE WHEN taMpApp.cMACardWriter = '2' THEN 'SI' WHEN taMpApp.cMACardWriter = '1' THEN 'NO' ELSE 'NO' END DIGITACION_MANUAL_NIVEL_COMERCIO,   ----(*)
	CASE WHEN cTAMultimerchantWriter = '2' THEN 'SI' WHEN cTAMultimerchantWriter = '1' THEN 'NO' ELSE 'NO' END DIGITACION_MANUAL_NIVEL_TERMINAL,   ----(*)
	CASE WHEN cTAOnlineTip = '0' THEN 'ONLINE' WHEN cTAOnlineTip = '2' THEN 'AMBAS' WHEN cTAOnlineTip = '3' THEN 'OFFLINE' ELSE 'NINGUNO' END PROPINA,
	--------
	taterAP.fTAUpdateDate FECHA_ACTUALIZACION_APP,
	taterAP.hTAUpdateTime HORA_ACTUALIZACION_APP,
	t.nTrDownloadAttempts NUM_INTENTOS,
	t.fTrLastDownloadDate FECHA_ULTIMA_ACTUALIZACION,
	t.hTrLastDownloadTime HORA_ULTIMA_ACTUALIZACION,
	CASE WHEN taterAP.cTAVersionApl=tmV.dVrFile THEN 'SI' ELSE 'NO' END VERSION_ACTUALIZADO,
	taterAP.cTAFilesVersion,
	tmV.cVrVersionId ,
	taterAP.cTAVersionApl ,
	tmV.dVrFile
-----
FROM RAW.tmmerchant_cc WITH(NOLOCK) 
INNER JOIN RAW.tmterminal_cc as t WITH(NOLOCK) ON cMrMerchantId=t.cTrMerchantId 
LEFT JOIN RAW.tmchipsgprs_cc WITH(NOLOCK) ON nTrChipNumber = SIMCARD
INNER JOIN RAW.taterminalapplication_cc taterAP WITH(NOLOCK) ON cTrTerminalNum =cTATerminalNum AND cTrMerchantId=cTAMerchantId
INNER JOIN RAW.tmDownloadProfile_cc with(nolock) ON cMrDownloadProfile=cDPProfileID
LEFT JOIN  RAW.taFloorLimit_cc TransCmr WITH(NOLOCK) ON cMrProfileId = TransCmr.cFLMrProfileId AND TransCmr.cFLAplicacion='POS' AND TransCmr.cFLTransactionId='13'
LEFT JOIN  RAW.taTerminalApplTransaction_cc tat WITH(NOLOCK) ON t.cTrTerminalNum =tat.cTATTerminalNum AND t.cTrMerchantId=tat.cTATMerchantId and tat.cTATTransactionId='13'
LEFT JOIN  RAW.taMerchantProfileApplication_cc taMpApp WITH(NOLOCK) ON cMrProfileId = taMpApp.cMAMerchantProfileId AND cTAApplicationID =taMpApp.cMAApplicationID
LEFT JOIN  RAW.tmVersion_cc tmV WITH(NOLOCK) ON(taterAP.cTAFilesVersion=tmV.cVrVersionId AND taterAP.cTAApplicationID=tmV.cVrApplicationId)   ---(*)
WHERE  cMrLogicalStatus='0' AND t.cTrLogicalStatus='0'
AND cTrType IN ('2','3') AND cTAApplicationID <> 'MAIN' 
END
