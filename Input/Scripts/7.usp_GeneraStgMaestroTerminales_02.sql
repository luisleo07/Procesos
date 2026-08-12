/****** Object:  StoredProcedure [Stage].[usp_GeneraStgMaestroTerminales_02]    Script Date: 5/29/2025 4:23:34 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [Stage].[usp_GeneraStgMaestroTerminales_02] AS
BEGIN

/*============================================================================================= 
Autor					:Business Analytics SAC
Fecha creación			:2021/04/12
Objetivos				:1. Agregar el campo EMV_DINERS a la tabla [Stage].[StgMaestroTerminales]
						 2. Actualización del campo VERSION_SWB en la tabla [Stage].[StgMaestroTerminales]
						 3. Insertar nuevos registros en la tabla [Stage].[StgMaestroTerminales] a través de la tabla [ALMACENES_RP]
Ejecutar				:EXECUTE [Stage].[usp_GeneraStgMaestroTerminales_02]
Observaciones			:
Comentarios				:Este SP es equivalente a 
							S4_P03_Flg_Diners_EMV
							S4_P04_Reg_Versiones
							S4_P05_Almacen
===============================================================================================*/ 
/*====================================== PROCESO 0 ============================================ 
							Definición de variables temporales 
===============================================================================================*/ 
DECLARE @fecIniLog DATETIME;
SET @fecIniLog			= DATEADD(HOUR,-5,GETDATE());
/*====================================== PROCESO 1.1 ============================================ 
							Comprobación de tablas temporales
===============================================================================================*/ 

IF OBJECT_ID('TempDB..#TEMPORAL') IS NOT NULL
BEGIN
	TRUNCATE TABLE #TEMPORAL;
	DROP TABLE #TEMPORAL;
END;

/*====================================== PROCESO 1.2 ============================================ 
					Agregación del campo EMV_DINERS a la tabla StgMaestroTerminales
===============================================================================================*/ 
-- EMV DINERS


SELECT A.*
	,CASE 
		WHEN A.MARCA='Verifone' AND [ADQ_C_COR] ='ADQ-PMP'AND CAST(CASE WHEN A.[VERSION_FLUJO]='' THEN 0 ELSE A.[VERSION_FLUJO] END AS numeric)>214 AND A.[VERSION_SWB] NOT IN ('B7.854','B8.001','B8.002','B8.003','B8.012','B8.013',
		'B8.014','B8.015','B8.017','B8.018','B8.019','B8.022','B8.100','B8.110','B8.111','B8.114','B8.306','B8.401','B8.420',
		'B80106','B80107','B80108','B80112','B80113','B80114','B80115','B80117','B80118','B80119')	THEN '1.POS EMV DINERS'
		WHEN A.MARCA='Ingenico' AND A.[VERSION_SWB] NOT IN ('B80106','B80107','B80108','B80112','B80113','B80114','B80115','B80117','B80118','B80119')
		THEN '1.POS EMV DINERS'
		WHEN [ADQ_C_COR] ='ADQ-IZIPAY' THEN '1.POS EMV DINERS'
		ELSE '2.POS no EMV DINERS'
	END 'EMV_DINERS'
INTO #TEMPORAL
FROM [Stage].[StgMaestroTerminales] A

IF OBJECT_ID('Stage.StgMaestroTerminales') IS NOT NULL
	BEGIN
		TRUNCATE TABLE [Stage].[StgMaestroTerminales];
		DROP TABLE 	[Stage].[StgMaestroTerminales];
	END

SELECT *
INTO [Stage].[StgMaestroTerminales]
FROM #TEMPORAL;


/*====================================== PROCESO 1.3 ============================================ 
							  Eliminación de tablas temporales
===============================================================================================*/ 

IF OBJECT_ID('TempDB..#TEMPORAL') IS NOT NULL
BEGIN
	TRUNCATE TABLE #TEMPORAL;
	DROP TABLE #TEMPORAL;
END


/*====================================== PROCESO 2.1 ============================================ 
				Actualización del campo VERSION_SWB en la tabla StgMaestroTerminales
===============================================================================================*/ 

UPDATE [Stage].[StgMaestroTerminales]
SET VERSION_SWB='000000'
WHERE [ADQ_C_COR]='ADQ-IZIPAY'
AND MODELO ='IZI'
AND (VERSION_SWB NOT LIKE 'B803%' AND VERSION_SWB NOT LIKE 'B804%' AND VERSION_SWB NOT LIKE 'B802%');

UPDATE [Stage].[StgMaestroTerminales]
SET VERSION_SWB='000000'
WHERE [ADQ_C_COR]='ADQ-IZIPAY'
AND MODELO ='IZI PRINT'
AND VERSION_SWB NOT IN ('I8.637','B8.621','I8.652');

UPDATE [Stage].[StgMaestroTerminales]
SET VERSION_SWB='000000'
WHERE [ADQ_C_COR]='ADQ-IZIPAY'
AND MODELO ='IZI SMART'
AND VERSION_SWB NOT LIKE 'B805%';



/*====================================== PROCESO 3.1 ============================================ 
Actualización del tamaño de los campos CATEGORIA, MEDIO, SITUACION_TERMINAL, MARCA, FLG_PCI, HW_CTLS, SITUACION_AS400, EMV_DINERS
===============================================================================================*/ 


ALTER TABLE [Stage].[StgMaestroTerminales]
ALTER COLUMN CATEGORIA VARCHAR(19) NULL;

ALTER TABLE [Stage].[StgMaestroTerminales]
ALTER COLUMN MEDIO VARCHAR(10) NULL;

ALTER TABLE [Stage].[StgMaestroTerminales]
ALTER COLUMN FEC_COMPRA VARCHAR(40) NULL;

ALTER TABLE [Stage].[StgMaestroTerminales]
ALTER COLUMN SITUACION_TERMINAL VARCHAR(42) NULL;

ALTER TABLE [Stage].[StgMaestroTerminales]
ALTER COLUMN MARCA VARCHAR(255) NULL;

ALTER TABLE [Stage].[StgMaestroTerminales]
ALTER COLUMN FLG_PCI VARCHAR(7) NULL;

ALTER TABLE [Stage].[StgMaestroTerminales]
ALTER COLUMN HW_CTLS VARCHAR(17) NULL;

ALTER TABLE [Stage].[StgMaestroTerminales]
ALTER COLUMN SITUACION_AS400 VARCHAR(7) NULL;

ALTER TABLE [Stage].[StgMaestroTerminales]
ALTER COLUMN EMV_DINERS VARCHAR(19) NULL;


/*====================================== PROCESO 3.2 ============================================ 
							Comprobación de tablas temporales
===============================================================================================*/ 

IF OBJECT_ID('TempDB..#TEMP') IS NOT NULL
BEGIN
	TRUNCATE TABLE #TEMP;
	DROP TABLE #TEMP;
END;

/*====================================== PROCESO 3.3 ============================================ 
				Inserción de nuevos registros en base a la tabla Terminales
===============================================================================================*/ 

SELECT A.*
INTO #TEMP
FROM Stage.StgTerminalAS400 A
WHERE not exists
	(SELECT 1 FROM [Stage].[StgMaestroTerminales] B WHERE B.MARGUESI<>'' AND B.MARGUESI=A.MARGUESI);--NULLIF(B.MARGUESI,'')<>''

INSERT INTO [Stage].[StgMaestroTerminales]
SELECT 
	rtrim(ltrim(A.COMERCIO )) --COMERCIO
	,'ALMACEN' --ADQ_C_COR
	,A.NOMBRE_COMERCIAL -- NOMBRE
	,'' --RUBRO
	,'' --SITUACION
	,B.CLASIFICACION -- CATEGORIA
	,'' --GRUPO_ECO
	,A.RAZON_SOCIAL 
	,A.RUC 
	,A.DIRECCION
	,A.DEPARTAMENTO
	,A.PROVINCIA
	,A.DISTRITO
	,'' --MULTICOMERCIO
	,'' --TELF_COMERCIO
	,'' --CONTACTO
	,'' --PERFIL_COMERCIO
	,'' --PERFIL_DESCARGA
	,'' --TERMINAL
	,RIGHT(RTRIM(LTRIM(A.SERIE_POS)),8) --SERIE
	,'' --MEDIO_MCC
	,'' --MEDIO
	,'' --DESCRIP
	,A.FEC_TRX_ECO --FECHA_ULTIMO_ECO
	,A.FEC_TRX_FIN --FECHA_ULTIMA_TRANSACCION_FINANCIERA
	,A.FEC_TRX_ADM --FECHA_ULTIMA_TRANSACCION_ADMINISTRATIVA
	,'' --SITUACION_TERMINAL
	,CASE
		WHEN A.MODELO LIKE '%MOVE%5000%' THEN 'IZI SMART'
		WHEN A.MODELO LIKE '%LINK%2500%' THEN 'IZI'
		WHEN A.MODELO LIKE '%QPOS%MINI%' THEN 'IZI JR'
		WHEN A.MODELO LIKE '%C%680%' AND A.NOMBRE_COMERCIAL LIKE '%IZI%' THEN 'IZI PRINT'
		ELSE A.MODELO
	END
    ,'' --[MODELO_MCC]
    ,'' --[VERSION_SWB]
    ,'' --[OS_VERSION]
    ,'' --[CHIP]
    ,'' --[TELEFONO_CHIP]
    ,'' --[OPERADOR]
    ,'' --[ESTADO_COMERCIO]
    ,'' --[ESTADO_LOGICO_COMERCIO]
    ,'' --[ESTADO_TERMINAL]
    ,'' --[ESTADO_LOGICO_TERMINAL]
    ,'' --[APLICACION]
    ,'' --[APL_DESC]
    ,'' --[FACTURACION]
    ,'' --[dTrE105SN]
    ,'' --[VERSION_FLUJO]
    ,'' --[VERSION_MAIN]
	,A.SERIE_POS --SERIE_COMPLETA
	,RTRIM(LTRIM(A.MARCA))
	,'' -- FLG_PCI
	,'' --SW_CTLS 
	,'' --HW_CTLS
    ,'' --[PRE_AUTORIZACION_NIVEL_COMERCIO]
    ,'' --[PRE_AUTORIZACION_NIVEL_TERMINAL]
    ,'' --[DIGITACION_MANUAL_NIVEL_COMERCIO]
    ,'' --[ DIGITACION_MANUAL_NIVEL_TERMINAL]
    ,'' --[PROPINA]
    ,'' --[ FECHA_ACTUALIZACION_APP]
    ,'' --[ HORA_ACTUALIZACION_APP]
    ,'' --[ NUM_INTENTOS]
    ,'' --[ FECHA_ULTIMA_ACTUALIZACION]
    ,'' --[ HORA_ULTIMA_ACTUALIZACION]
    ,'' --[ VERSION_ACTUALIZADO]
    ,'' --[ cTAFilesVersion]
    ,'' --[ cVrVersionId]
    ,'' --[ cTAVersionApl]
    ,'' --[dVrFile]
	,A.MARGUESI
	,A.FEC_COMPRA
	,'' --SITUACION_AS400
	,'' --EMV_DINERS
  FROM #TEMP A
  LEFT JOIN [RAW].[ALMACENES_RP] B
  ON A.COMERCIO=B.UBICACION;


/*====================================== PROCESO 3.4 ============================================ 
							Eliminación de las tablas temporales
===============================================================================================*/ 
IF OBJECT_ID('TempDB..#TEMP') IS NOT NULL
	BEGIN
		TRUNCATE TABLE #TEMP;
		DROP TABLE 	#TEMP
	END


INSERT INTO Stage.stglog (Fuente,Tabla,Cantidad,FechaINicio,FechaFIN)
SELECT 'Carga BI_Maestro_Terminales - Paso 3/8','BI_Maestro_Terminales',(SELECT COUNT(*) FROM [Stage].[StgMaestroTerminales]),@fecIniLog,DATEADD(HOUR,5,GETDATE());

END
