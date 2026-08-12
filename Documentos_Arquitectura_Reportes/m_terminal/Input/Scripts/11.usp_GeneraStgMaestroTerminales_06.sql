/****** Object:  StoredProcedure [Stage].[usp_GeneraStgMaestroTerminales_06]    Script Date: 5/29/2025 4:30:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [Stage].[usp_GeneraStgMaestroTerminales_06] AS
BEGIN

/*============================================================================================= 
Autor					:Business Analytics SAC
Fecha creación			:2021/04/12
Objetivos				:1. Actualizar el campo Giro_MC
						:2. Actualizar el campo fecape a través de MCESTAB_RP
						:3. Agregar el campo COSECHA a la tabla [StgMaestroTerminales]
						:4. Actualización del campo SERIE_UNICA
						:5. Actualizar el campo FLG_TELECARGA
						:6. Actualización del campo SITUACION
						:7. Agrega el campo Oficina
						:8. Agrega los campos Modelo_Terminal, Version_Base, Version_Enviada 
Ejecutar				:EXECUTE [Stage].[usp_GeneraStgMaestroTerminales_06]
Observaciones			:
Comentarios				:Este SP es equivalente a 
							S4_P13_Update_MC_CTLS
							S4_P14_Update_Fecha_Apertura
							S4_P15_Update_Fecha_Apertura1
							S4_P16_Serie_Unica_Mpos
							S4_P17_Actualización_Telecarga
							S4_P18_Nombre_Situaciones
							S4_P19_Oficinas
							S4_P20_Fix_20210210
							S4_P21_Fix_20210407
===============================================================================================*/ 
/*====================================== PROCESO 0 ============================================ 
							Definición de variables temporales 
===============================================================================================*/ 
DECLARE @fecIniLog DATETIME;
SET @fecIniLog			= DATEADD(HOUR,-5,GETDATE());
/*====================================== PROCESO 1.1 ============================================ 
								Actualiza el campo GIRO_MC
===============================================================================================*/ 

UPDATE A
SET A.GIRO_MC = B.GIRO_MC
FROM [Stage].[StgMaestroTerminales] A
LEFT JOIN [RAW].[CINES_RP] B
ON A.COMERCIO=B.COMERCIO
WHERE B.GIRO_MC='6.Cines'



/*====================================== PROCESO 2.1 ============================================ 
					Actualiza el campo fecape a través de MCESTAB_RP
===============================================================================================*/ 

UPDATE A
SET
	A.[fecape]=B.[fecape]
FROM [Stage].[StgMaestroTerminales] A
LEFT JOIN stage.StgMcestab B
ON left(A.comercio,7) = B.codigo
WHERE B.codigo IS NOT NULL;



/*====================================== PROCESO 3.1 ============================================ 
								Declaración de variables 
===============================================================================================*/ 

DECLARE @FECHA CHAR(10)

SET @FECHA = (SELECT MAX([FECHA_ULTIMA_TRANSACCION_FINANCIERA]) FROM [Stage].[StgMaestroTerminales])


/*====================================== PROCESO 3.2 ============================================ 
							Comprobación de tablas temporales
===============================================================================================*/ 

IF OBJECT_ID('TempDB..#TEMP') IS NOT NULL
BEGIN
	TRUNCATE TABLE #TEMP;
	DROP TABLE #TEMP;
END;

/*====================================== PROCESO 3.3 ============================================ 
								Agrega el campo COSECHA 
===============================================================================================*/ 

SELECT *,
	CASE
		WHEN datediff(month,cast([fecape] as datetime),cast(@FECHA as datetime))>=12 then '1. Cosecha 1 año a más'
		when datediff(month,cast([fecape] as datetime),cast(@FECHA as datetime))>=6 then '2 .Cosecha de 6 a 12 meses'
		when datediff(month,cast([fecape] as datetime),cast(@FECHA as datetime))>=3 then '3. Cosecha de 3 a 6 meses'
		ELSE concat('4. ',LEFT(rtrim(ltrim([fecape])),6))
	END 'COSECHA'
INTO #TEMP
FROM [Stage].[StgMaestroTerminales];

IF OBJECT_ID('Stage.StgMaestroTerminales') IS NOT NULL
	BEGIN
		TRUNCATE TABLE [Stage].[StgMaestroTerminales];
		DROP TABLE 	[Stage].[StgMaestroTerminales];
	END

SELECT * INTO [Stage].[StgMaestroTerminales] FROM #TEMP;



/*====================================== PROCESO 3.4 ============================================ 
								Eliminación de la tabla temporal
===============================================================================================*/ 

IF OBJECT_ID('TempDB..#TEMP') IS NOT NULL
BEGIN
	TRUNCATE TABLE #TEMP;
	DROP TABLE #TEMP;
END;

/*====================================== PROCESO 4.1 ============================================ 
							Comprobación de tablas temporales
===============================================================================================*/ 

IF OBJECT_ID('TempDB..#SERIES_UNICAS') IS NOT NULL
BEGIN
	TRUNCATE TABLE #SERIES_UNICAS;
	DROP TABLE #SERIES_UNICAS;
END;

IF OBJECT_ID('TempDB..#DEPURADO') IS NOT NULL
BEGIN
	TRUNCATE TABLE #DEPURADO;
	DROP TABLE #DEPURADO;
END;

/*====================================== PROCESO 4.2 ============================================ 
							Actualiza el campo SERIE_UNICA
===============================================================================================*/ 
/* IDENTIFICAR UN ÚNICO COMERCIO POR SERIE, CASO mPOS*/


SELECT
	A.[dTrE105SN]
	,A.COMERCIO
	,A.TERMINAL
INTO #SERIES_UNICAS
FROM (
	SELECT
	ROW_NUMBER() OVER (
		PARTITION BY [dTrE105SN]
		ORDER BY [dTrE105SN] ASC,FECHA_ULTIMA_TRANSACCION_FINANCIERA DESC,COMERCIO ASC) AS IDEM
	,[dTrE105SN]
	,COMERCIO
	,TERMINAL
FROM [Stage].[StgMaestroTerminales] 
WHERE [ADQ_C_COR] in ('ADQ-PMP','C.COR-PMP','ADQ-IZIPAY')
AND [dTrE105SN]<>'') AS A
WHERE IDEM='1';

UPDATE [Stage].[StgMaestroTerminales]
SET SERIE_UNICA='0'
WHERE [dTrE105SN] <> '';

UPDATE [Stage].[StgMaestroTerminales]
SET SERIE_UNICA='0'
WHERE [dTrE105SN] =''
AND MODELO_MCC LIKE '%Cliente%'
AND [ADQ_C_COR] = 'ADQ-IZIPAY';

UPDATE A
SET SERIE_UNICA='1'
FROM [Stage].[StgMaestroTerminales] A
LEFT JOIN #SERIES_UNICAS B
ON (A.COMERCIO=B.COMERCIO AND A.[dTrE105SN]=B.[dTrE105SN] AND A.TERMINAL=B.TERMINAL)
WHERE B.COMERCIO IS NOT NULL

UPDATE [Stage].[StgMaestroTerminales]
SET SERIE_UNICA='0'
WHERE [ADQ_C_COR]='C.COR-PMP'
AND APLICACION = 'HERMESMB'
AND SERIE_UNICA='1'

UPDATE [Stage].[StgMaestroTerminales]
SET SERIE_UNICA='0'
WHERE [ADQ_C_COR] IN ('ADQ-PMP','ADQ-IZIPAY')
AND APLICACION <> 'POS'
AND SERIE_UNICA='1'



/*====================================== PROCESO 4.3 ============================================ 
								Depuración de duplicados
===============================================================================================*/ 

SELECT DISTINCT *
INTO #DEPURADO
FROM [Stage].[StgMaestroTerminales];

IF OBJECT_ID('Stage.StgMaestroTerminales') IS NOT NULL
	BEGIN
		TRUNCATE TABLE [Stage].[StgMaestroTerminales];
		DROP TABLE 	[Stage].[StgMaestroTerminales];
	END

SELECT *
INTO [Stage].[StgMaestroTerminales]
FROM #DEPURADO;



/*====================================== PROCESO 4.4 ============================================ 
								Eliminación de tablas temporales
===============================================================================================*/ 

IF OBJECT_ID('TempDB..#SERIES_UNICAS') IS NOT NULL
BEGIN
	TRUNCATE TABLE #SERIES_UNICAS;
	DROP TABLE #SERIES_UNICAS;
END;

IF OBJECT_ID('TempDB..#DEPURADO') IS NOT NULL
BEGIN
	TRUNCATE TABLE #DEPURADO;
	DROP TABLE #DEPURADO;
END;

/*====================================== PROCESO 5.1 ============================================ 
							Comprobación de tablas temporales
===============================================================================================*/ 

IF OBJECT_ID('TempDB..#TEMP_TOTAL') IS NOT NULL
BEGIN
	TRUNCATE TABLE #TEMP_TOTAL;
	DROP TABLE #TEMP_TOTAL;
END;

IF OBJECT_ID('TempDB..#TEMP_1') IS NOT NULL
BEGIN
	TRUNCATE TABLE #TEMP_1;
	DROP TABLE #TEMP_1;
END;

IF OBJECT_ID('TempDB..#TEMP_NO_TELE') IS NOT NULL
BEGIN
	TRUNCATE TABLE #TEMP_NO_TELE;
	DROP TABLE #TEMP_NO_TELE;
END;

/*====================================== PROCESO 5.2 ============================================ 
							Actualizar el campo FLG_TELECARGA
===============================================================================================*/ 

/****** Script for SelectTopNRows command from SSMS  ******/
--DROP TABLE #TEMP_TOTAL;
--DROP TABLE #TEMP_1;
--DROP TABLE #TEMP_NO_TELE;


SELECT [COMERCIO]
      ,[ADQ_C_COR]
      ,[NOMBRE]
      ,[RUBRO]
      ,[SITUACION]
      ,[CATEGORIA]
      ,[GRUPO_ECO_DESC]
      ,[RAZON_SOCIAL]
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
      ,[MEDIO_MCC]
      ,[MEDIO]
      ,[DESCRIPCION_TERMINAL]
      ,[FECHA_ULTIMO_ECO]
      ,[FECHA_ULTIMA_TRANSACCION_FINANCIERA]
      ,[FECHA_ULTIMA_TRANSACCION_ADMINISTRATIVA]
      ,[SITUACION_TERMINAL]
      ,[MODELO]
      ,[MODELO_MCC]
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
      ,[APL_DESC]
      ,[FACTURACION]
      ,[dTrE105SN]
      ,[VERSION_FLUJO]
      ,[VERSION_MAIN]
      ,[SERIE_COMPLETA]
      ,[MARCA]
      ,[FLG_PCI]
      ,[SW_CTLS]
      ,[HW_CTLS]
      ,[MARGUESI]
      ,[FEC_COMPRA]
      ,[SITUACION_AS400]
      ,[EMV_DINERS]
      ,[CANT_TERM]
      ,[CANT_TERM_ACT]
      ,[FLG_PINPAD]
      ,[FLG_INGENICO]
      ,[FLG_MULT_APP]
      ,[FLG_MULTICOMERCIO]
      ,[FLG_TELECARGA]
      ,[GIRO]
      ,[GIRO_MC]
      ,[SERIE_UNICA]
	  ,[Razón Social]
	  ,[Grupo Económico]
	  ,[Unidad de Negocio]
	  ,CASE
		WHEN [SITUACION_TERMINAL] = '2 - Sin movimiento ultimos 12 meses.' THEN 'POS_NEUTRO'
		WHEN MEDIO = 'DIAL' THEN 'NO_TELECARGABLE_QR'
		WHEN MEDIO = 'PINPAD' THEN 'NO_TELECARGABLE_QR'
		WHEN FLG_PCI <> 'PCI' THEN 'NO_TELECARGABLE_QR'
		WHEN MODELO = 'Verifone - VX520C' THEN 'NO_TELECARGABLE_QR'
		WHEN MODELO = 'IZI SMART' THEN 'TELECARGABLE_QR'
		WHEN MODELO = 'IZI' AND VERSION_SWB <> 'B80205' THEN 'TELECARGABLE_QR'
		WHEN MODELO = 'VERIFONE - C680' THEN 'TELECARGABLE_QR'
		WHEN REPLACE(REPLACE(VERSION_SWB,'.',''),'B','') < '8502' THEN 'NO_TELECARGABLE_QR'
		WHEN MARCA = 'Ingenico' THEN 'NO_TELECARGABLE_QR'
		ELSE 'TELECARGABLE_QR'
	  END 'POS_TELECARGA_QR'
	  ,CASE
		WHEN [SITUACION_TERMINAL] = '2 - Sin movimiento ultimos 12 meses.' THEN 'POS_NEUTRO'
		WHEN MEDIO = 'DIAL' THEN 'POS DIAL'
		WHEN MEDIO = 'PINPAD' THEN 'PINPAD'
		WHEN MODELO = 'IZI SMART' THEN 'TELECARGABLE_QR'
		WHEN MODELO = 'IZI' AND VERSION_SWB <> 'B80205' THEN 'TELECARGABLE_QR'
		WHEN MODELO = 'VERIFONE - C680' THEN 'TELECARGABLE_QR'
		WHEN MARCA = 'Ingenico' THEN 'EQUIPO INGENICO'
		WHEN FLG_PCI <> 'PCI' THEN 'NO PCI'
		WHEN MODELO = 'Verifone - VX520C' THEN 'EQUIPO VX520C'
		WHEN REPLACE(REPLACE(VERSION_SWB,'.',''),'B','') < '8502' THEN 'VERSION NO TELECARGABLE'
		ELSE 'TELECARGABLE_QR'
	  END 'MOTIVO_TELECARGA_QR'
  INTO #TEMP_TOTAL
  FROM [Stage].[StgMaestroTerminales]
  WHERE [ADQ_C_COR]='ADQ-PMP';



SELECT *
INTO #TEMP_NO_TELE -- NO TELECARGABLES
FROM #TEMP_TOTAL B
WHERE B.POS_TELECARGA_QR='NO_TELECARGABLE_QR'
AND B.SITUACION_TERMINAL <> '2 - Sin movimiento ultimos 12 meses.';



SELECT *,
'COMERCIO_TELECARGABLE' AS 'TELECARGA_QR'
INTO #TEMP_1 -- SOLO TELECARGABLES
FROM #TEMP_TOTAL A
WHERE NOT EXISTS (
		SELECT 1
			FROM #TEMP_NO_TELE B
			WHERE A.COMERCIO=B.COMERCIO);

INSERT INTO #TEMP_1
SELECT *,
'COMERCIO_NO_TELECARGA' AS 'TELECARGA_QR'  -- NO TELECARGABLES
FROM #TEMP_TOTAL A
WHERE EXISTS (
		SELECT 1
			FROM #TEMP_NO_TELE B
			WHERE A.COMERCIO=B.COMERCIO);

UPDATE [Stage].[StgMaestroTerminales]
SET [FLG_TELECARGA]='';

UPDATE A
SET A.[FLG_TELECARGA]=B.TELECARGA_QR
FROM [Stage].[StgMaestroTerminales] A
LEFT JOIN #TEMP_1 B
ON A.COMERCIO=B.COMERCIO
WHERE B.COMERCIO IS NOT NULL;



/*====================================== PROCESO 5.3 ============================================ 
							Eliminación de tablas temporales
===============================================================================================*/ 

IF OBJECT_ID('TempDB..#TEMP_TOTAL') IS NOT NULL
BEGIN
	TRUNCATE TABLE #TEMP_TOTAL;
	DROP TABLE #TEMP_TOTAL;
END;

IF OBJECT_ID('TempDB..#TEMP_1') IS NOT NULL
BEGIN
	TRUNCATE TABLE #TEMP_1;
	DROP TABLE #TEMP_1;
END;

IF OBJECT_ID('TempDB..#TEMP_NO_TELE') IS NOT NULL
BEGIN
	TRUNCATE TABLE #TEMP_NO_TELE;
	DROP TABLE #TEMP_NO_TELE;
END;

/*====================================== PROCESO 6.1 ============================================ 
							Actualiza el campo SITUACION
===============================================================================================*/ 

UPDATE [Stage].[StgMaestroTerminales]
SET SITUACION='1.C/mov ult 3 meses'
WHERE SITUACION='1';

UPDATE [Stage].[StgMaestroTerminales]
SET SITUACION='2.S/mov más 12 meses'
WHERE SITUACION='2';

UPDATE [Stage].[StgMaestroTerminales]
SET SITUACION='3.Bloqueo definitivo'
WHERE SITUACION='3';

UPDATE [Stage].[StgMaestroTerminales]
SET SITUACION='4.S/mov más 3 meses'
WHERE SITUACION='4';

UPDATE [Stage].[StgMaestroTerminales]
SET SITUACION='5.Nuevo s/mov'
WHERE SITUACION='5';

UPDATE [Stage].[StgMaestroTerminales]
SET SITUACION='6.S/mov más 6 meses'
WHERE SITUACION='6';

UPDATE [Stage].[StgMaestroTerminales]
SET SITUACION='7.Nuevo'
WHERE SITUACION='7';

UPDATE [Stage].[StgMaestroTerminales]
SET SITUACION='8.Nuevo s/mov más 3 meses'
WHERE SITUACION='8';

UPDATE [Stage].[StgMaestroTerminales]
SET SITUACION='9.Bloqueo temporal'
WHERE SITUACION='9';



/*====================================== PROCESO 7.1 ============================================ 
							Comprobación de tablas temporales
===============================================================================================*/ 

IF OBJECT_ID('TempDB..#TEMP') IS NOT NULL
BEGIN
	TRUNCATE TABLE #TEMP;
	DROP TABLE #TEMP;
END;
 
/*====================================== PROCESO 7.2 ============================================ 
								Agrega el campo Oficina
===============================================================================================*/ 

SELECT *,	
	CASE
	WHEN [ADQ_C_COR]<>'ALMACEN' AND DEPARTAMENTO='LA LIBERTAD' THEN 'OF. Trujillo'
		WHEN [ADQ_C_COR]<>'ALMACEN' AND DEPARTAMENTO='AREQUIPA' THEN 'OF. Arequipa'
		WHEN [ADQ_C_COR]<>'ALMACEN' AND DEPARTAMENTO='PIURA' THEN 'OF. Piura'
		WHEN [ADQ_C_COR]<>'ALMACEN' AND DEPARTAMENTO='CUSCO' THEN 'OF. Cusco'
		WHEN [ADQ_C_COR]<>'ALMACEN' AND DEPARTAMENTO='LAMBAYEQUE' THEN 'OF. Chiclayo'
		WHEN [ADQ_C_COR]<>'ALMACEN' AND DEPARTAMENTO='ICA' THEN 'OF. Ica'
		WHEN [ADQ_C_COR]<>'ALMACEN' AND DEPARTAMENTO='JUNIN' THEN 'OF. Huancayo'
		WHEN [ADQ_C_COR]<>'ALMACEN' AND DEPARTAMENTO='ANCASH' THEN 'OF. Trujillo'
		WHEN [ADQ_C_COR]<>'ALMACEN' AND DEPARTAMENTO='CAJAMARCA' THEN 'OF. Chiclayo'
		WHEN [ADQ_C_COR]<>'ALMACEN' AND DEPARTAMENTO='LORETO' THEN 'OF. Iquitos'
		WHEN [ADQ_C_COR]<>'ALMACEN' AND DEPARTAMENTO='SAN MARTIN' THEN 'OF. Chiclayo'
		WHEN [ADQ_C_COR]<>'ALMACEN' AND DEPARTAMENTO='PUNO' THEN 'OF. Cusco'
		WHEN [ADQ_C_COR]<>'ALMACEN' AND DEPARTAMENTO='UCAYALI' THEN 'OF. Huancayo'
		WHEN [ADQ_C_COR]<>'ALMACEN' AND DEPARTAMENTO='HUANUCO' THEN 'OF. Huancayo'
		WHEN [ADQ_C_COR]<>'ALMACEN' AND DEPARTAMENTO='TACNA' THEN 'OF. Arequipa'
		WHEN [ADQ_C_COR]<>'ALMACEN' AND DEPARTAMENTO='TUMBES' THEN 'OF. Piura'
		WHEN [ADQ_C_COR]<>'ALMACEN' AND DEPARTAMENTO='AYACUCHO' THEN 'OF. Ica'
		WHEN [ADQ_C_COR]<>'ALMACEN' AND DEPARTAMENTO='MOQUEGUA' THEN 'OF. Arequipa'
		WHEN [ADQ_C_COR]<>'ALMACEN' AND DEPARTAMENTO='HUANCAVELICA' THEN 'OF.Huancayo'
		WHEN [ADQ_C_COR]<>'ALMACEN' AND DEPARTAMENTO='APURIMAC' THEN 'OF. Cusco'
		WHEN [ADQ_C_COR]<>'ALMACEN' AND DEPARTAMENTO='AMAZONAS' THEN 'OF. Chiclayo'
		WHEN [ADQ_C_COR]<>'ALMACEN' AND DEPARTAMENTO='PASCO' THEN 'OF. Huancayo'
		WHEN [ADQ_C_COR]<>'ALMACEN' AND DEPARTAMENTO='MADRE DE DIOS' THEN 'OF. Cusco'
		WHEN [ADQ_C_COR]<>'ALMACEN' THEN 'Lima'
		END 'Oficina'
INTO #TEMP
 FROM [Stage].[StgMaestroTerminales];

IF OBJECT_ID('Stage.StgMaestroTerminales') IS NOT NULL
	BEGIN
		TRUNCATE TABLE [Stage].[StgMaestroTerminales];
		DROP TABLE 	[Stage].[StgMaestroTerminales];
	END

 SELECT *
 INTO [Stage].[StgMaestroTerminales]
 FROM #TEMP
 


/*====================================== PROCESO 7.3 ============================================ 
							Eliminación de tablas temporales
===============================================================================================*/ 

IF OBJECT_ID('TempDB..#TEMP') IS NOT NULL
BEGIN
	TRUNCATE TABLE #TEMP;
	DROP TABLE #TEMP;
END;


/*====================================== PROCESO 8.1 ============================================ 
							Comprobación de tablas temporales
===============================================================================================*/ 

IF OBJECT_ID('TempDB..#TEMP') IS NOT NULL
BEGIN
	TRUNCATE TABLE #TEMP;
	DROP TABLE #TEMP;
END;

/*====================================== PROCESO 8.2 ============================================ 
				Agrega los campos Modelo_Terminal, Version_Base, Version_Enviada --> Fix 20210210
===============================================================================================*/ 


SELECT *
	,CASE
		WHEN MODELO='IZI JR' THEN 'QPOS Mini'
		WHEN MODELO='IZI' THEN 'Ingenico - Link2500'
		WHEN MODELO='IZI PRINT' THEN 'Verifone - C680'
		WHEN MODELO='IZI SMART' THEN 'Ingenico - Move5000'
		ELSE MODELO
	END Modelo_Terminal
	,CASE
		WHEN VERSION_SWB='' THEN 's/versión'
		WHEN VERSION_SWB='000000' THEN 'v/error'
		ELSE VERSION_SWB
	END Version_Base
	,CASE
		WHEN MEDIO='mPOS' THEN 'mPOS'
		WHEN PERFIL_DESCARGA in ('TELECARGA_IZIPAY_QR_CRC','TELECARGA_IZIPAY_F11','TELECARGA_IZIPAY_F21','TELECARGA_IZIPAY_F28_1','TELECARGA_IZIPAY_F25','TELECARGA_ IZIPAY_F27','IZIPAY_QR') AND MODELO='IZI' THEN 'B80409'
		WHEN PERFIL_DESCARGA in ('TELECARGA_IZIPAY_QR_CRC','TELECARGA_IZIPAY_F11','TELECARGA_IZIPAY_F21','TELECARGA_IZIPAY_F28_1','TELECARGA_IZIPAY_F25','TELECARGA_ IZIPAY_F27','IZIPAY_QR') AND MODELO='IZI SMART' THEN 'B80510'
		WHEN PERFIL_DESCARGA in ('TELECARGA_IZIPAY_QR_CRC','TELECARGA_IZIPAY_F11','TELECARGA_IZIPAY_F21','TELECARGA_IZIPAY_F28_1','TELECARGA_IZIPAY_F25','TELECARGA_ IZIPAY_F27','IZIPAY_QR') AND MODELO='IZI PRINT' THEN 'I8.652'
		WHEN PERFIL_DESCARGA='TELECARGA_PMP_QR_CRC' AND MODELO='IZI' THEN 'B80409'
		WHEN PERFIL_DESCARGA='TELECARGA_PMP_QR_CRC' AND MODELO='IZI SMART' THEN 'B80510'
		WHEN PERFIL_DESCARGA='TELECARGA_IZIPAY_2021_PRUEBA' AND MODELO='IZI' THEN 'B80412' ----(*)
		WHEN PERFIL_DESCARGA='TELECARGA_IZIPAY_2021_PRUEBA' AND MODELO='IZI SMART' THEN 'B80513' ----(*)
		WHEN PERFIL_DESCARGA='TELECARGA_PMP_QR_CRC' AND MODELO IN ('Verifone - C680','Verifone - VX520'
		,'Verifone - VX680','Verifone - VX820') THEN 'B8.652'
		WHEN VERSION_SWB='' THEN 's/versión'
		WHEN VERSION_SWB='000000' THEN 'v/error'
		ELSE VERSION_SWB
	END Version_Enviada
  INTO #TEMP
  FROM [Stage].[StgMaestroTerminales];

	IF OBJECT_ID('Stage.StgMaestroTerminales') IS NOT NULL
	BEGIN
		TRUNCATE TABLE [Stage].[StgMaestroTerminales];
		DROP TABLE 	[Stage].[StgMaestroTerminales];
	END

 SELECT *
 INTO [Stage].[StgMaestroTerminales]
 FROM #TEMP


 /*====================================== PROCESO 8.3 ============================================ 
							Fix/Parche 20210407 
===============================================================================================*/ 
UPDATE [Stage].[StgMaestroTerminales]
SET QR_CRC='1.Actualizado sin QR activo',
	QR_CRC_Pendiente='1.Actualizado sin QR activo'
  WHERE [ADQ_C_COR]='ADQ-PMP'
  AND VERSION_SWB='B8.652'
  AND LEFT(QR_CRC,'1')='3'
  AND SERIE_UNICA='1'
  AND ESTADO_COMERCIO='Habilitado'
  AND ESTADO_LOGICO_COMERCIO='Activo'
  AND ESTADO_TERMINAL='Habilitado'
  AND ESTADO_LOGICO_TERMINAL='Activo'
  AND MODELO NOT IN ('OTROS','OMNI3750','Verifone - E105','Verifone - VX510','Verifone - VX810','Verifone - VX670','Verifone - VX610')
  AND APLICACION='POS'
  AND LEFT(SITUACION,'1') NOT IN ('3','9');


  UPDATE [Stage].[StgMaestroTerminales]
	SET QR_CRC='0.Actualizado con QR activo',
		QR_CRC_Pendiente='0.Actualizado con QR activo'
  WHERE [ADQ_C_COR]='ADQ-PMP'
  AND VERSION_SWB='B8.652'
  AND LEFT(QR_CRC,'1')='1'
  AND PERFIL_COMERCIO LIKE '%QR%'
  AND SERIE_UNICA='1'
  AND ESTADO_COMERCIO='Habilitado'
  AND ESTADO_LOGICO_COMERCIO='Activo'
  AND ESTADO_TERMINAL='Habilitado'
  AND ESTADO_LOGICO_TERMINAL='Activo'
  AND MODELO NOT IN ('OTROS','OMNI3750','Verifone - E105','Verifone - VX510','Verifone - VX810','Verifone - VX670','Verifone - VX610')
  AND APLICACION='POS'
  AND LEFT(SITUACION,'1') NOT IN ('3','9');

  DELETE [Stage].[StgMaestroTerminales]
  WHERE [ADQ_C_COR]='ALMACEN';

   /*====================================== PROCESO 8.4 ============================================ 
							Fix/Parche 20210502 
===============================================================================================*/ 
	IF OBJECT_ID('TempDB..#TEMP') IS NOT NULL
	BEGIN
		TRUNCATE TABLE #TEMP;
		DROP TABLE #TEMP;
	END;

	SELECT	A.*,
			B.FGRRFJ AS FEC_INST
	INTO #TEMP
	FROM [Stage].[StgMaestroTerminales] A
	LEFT JOIN [Stage].[StgTerminalAS400] B
	ON RTRIM(LTRIM(ISNULL(A.dTrE105SN,'')))=RIGHT(RTRIM(LTRIM(B.[SERIE_POS])),8) AND B.MARCA <> 'DSPREAD' AND UPPER(A.MARCA)=B.MARCA
	WHERE ISNULL(A.MEDIO,'')='mPOS'

	UNION ALL

	SELECT	A.*,
			B.FGRRFJ AS FEC_INST
	--INTO #TEMP
	FROM [Stage].[StgMaestroTerminales] A
	LEFT JOIN [Stage].[StgTerminalAS400] B
	ON RTRIM(LTRIM(A.SERIE))=RIGHT(RTRIM(LTRIM(B.[SERIE_POS])),8) AND B.MARCA <>'DSPREAD' AND UPPER(A.MARCA)=B.MARCA
	WHERE ISNULL(A.MEDIO,'')<>'mPOS'

	--759,414
	-- 81,703
	--677,711

	IF OBJECT_ID('Stage.StgMaestroTerminales') IS NOT NULL
	BEGIN
		TRUNCATE TABLE [Stage].[StgMaestroTerminales];
		DROP TABLE 	[Stage].[StgMaestroTerminales];
	END

	SELECT *
	INTO [Stage].[StgMaestroTerminales]
	FROM #TEMP

	IF OBJECT_ID('TempDB..#TEMP') IS NOT NULL
	BEGIN
		TRUNCATE TABLE #TEMP;
		DROP TABLE #TEMP;
	END;
	
	IF OBJECT_ID('TempDB..#TEMP_C') IS NOT NULL
	BEGIN
		TRUNCATE TABLE #TEMP_C;
		DROP TABLE #TEMP_C;
	END;

	ALTER TABLE  [Stage].[StgMaestroTerminales]
	DROP COLUMN [GRUPO_ECO_DESC];

	SELECT DISTINCT [Razón Social],[Grupo Económico],[RUC]
	INTO #TEMP_C
	FROM raw.CARTERA_RP;

	UPDATE A
	SET
		   A.[Razón Social]=B.[Razón Social],
		   A.[Grupo Económico]=B.[Grupo Económico]
	FROM [Stage].[StgMaestroTerminales] A
	LEFT JOIN #TEMP_C B
	ON (A.RUC = B.[RUC] AND A.[ADQ_C_COR] IN ('ADQ-PMP','ADQ-IZIPAY'))
	WHERE B.[RUC] IS NOT NULL
	AND A.[Razón Social] IS NULL;

	IF OBJECT_ID('TempDB..#TEMP_C') IS NOT NULL
	BEGIN
		TRUNCATE TABLE #TEMP_C;
		DROP TABLE #TEMP_C;
	END;


   /*====================================== PROCESO 8.5 ============================================ 
							Fix/Parche 20210611 
===============================================================================================*/ 
	UPDATE [Stage].[StgMaestroTerminales]
	SET MEDIO='GPRS Movil'
	  WHERE MODELO_MCC IN ('P2MINI','V240M','DX8000','D200','C680')

	UPDATE [Stage].[StgMaestroTerminales]
	SET MEDIO='PINPAD'
	  WHERE MODELO_MCC IN ('MX915')

	UPDATE [Stage].[StgMaestroTerminales]
	SET MEDIO='mPOS'
	  WHERE MODELO_MCC IN ('ClienteAD','ClienteIPH')

	UPDATE [Stage].[StgMaestroTerminales]
	SET MODELO='mPOS'
		   ,Modelo_Terminal='mPOS'
	  WHERE MODELO_MCC IN ('ClienteAD','ClienteIPH')
	  AND [ADQ_C_COR]='ADQ-PMP'
	  AND MODELO<>'OTROS'

	UPDATE [Stage].[StgMaestroTerminales]
	SET MODELO='Ingenico - DX8000'
		   ,Modelo_Terminal='Ingenico - DX8000'
	  WHERE MODELO_MCC ='DX8000'

	UPDATE [Stage].[StgMaestroTerminales]
	SET MODELO='Sunmi - P2mini'
		   ,Modelo_Terminal='Sunmi - P2mini'
	  WHERE MODELO_MCC ='P2MINI'

	-- TELECARGA AMEX CTLS --

	UPDATE [Stage].[StgMaestroTerminales]  -----(*)
	SET Version_Enviada = concat(Version_Enviada,'AM')
	  WHERE Version_Enviada IN ('B8.423'
			,'B8.460'
			,'B8.463'
			,'B8.500'
			,'B8.502'
			,'B8.601'
			,'B8.612'
			,'B8.620'
			,'B8.621'
			,'B8.622'
			,'B8.640'
			,'B8.641'
			,'B8.652'
			,'B9.041'
			,'B9.114'
			,'A9.113'
			,'B9.113')
	  AND [ADQ_C_COR]='ADQ-PMP'
	  AND PERFIL_DESCARGA IN ('TELECARGA_PMP_CTLSAMEX2021'
	  ,'TELECARGA_CTLS_AMEX_PINPAD'
	  ,'TELECARGA_PMP_QR_PEPPER','TELE_ADQ_ACTUALIZAQR_CTLSAMEX') -----(*)

	UPDATE [Stage].[StgMaestroTerminales]
	SET Version_Enviada = 'B80513'
	  WHERE Version_Enviada IN ('B80506'
		   ,'B80508'
		   ,'B80509'
		   ,'B80510'
		   ,'B80511')
	  AND [ADQ_C_COR]='ADQ-PMP'
	  AND PERFIL_DESCARGA IN ('TELECARGA_PMP_CTLSAMEX2021'
	  ,'TELECARGA_CTLS_AMEX_PINPAD'
	  ,'TELECARGA_PMP_QR_PEPPER','TELE_ADQ_ACTUALIZAQR_CTLSAMEX') -----(*)

	UPDATE [Stage].[StgMaestroTerminales]
	SET Version_Enviada = concat(Version_Enviada,'AM')
	  WHERE Version_Enviada IN ('B8.621'
		   ,'I8.637'
		   ,'I8.652')
	  AND [ADQ_C_COR]='ADQ-IZIPAY'
	  AND PERFIL_DESCARGA ='TELECARGA_CTLSAMEX_IZIPAYC680'


 /*====================================== PROCESO 8.5 ============================================ 
							Fix/Parche 20211108 
===============================================================================================*/ 

	UPDATE [Stage].[StgMaestroTerminales]
	SET Version_Enviada ='B8.672'
  WHERE Modelo_Terminal IN ('Verifone - C680','Verifone - VX680','Verifone - VX520','Verifone - VX820')
  AND [ADQ_C_COR]='ADQ-PMP'
  AND PERFIL_DESCARGA ='PRBTELE_QR_CONFIGURABLE_CONDCC'

	UPDATE [Stage].[StgMaestroTerminales]
	SET Version_Enviada = 'T9.143'
	WHERE Modelo_Terminal='Verifone - V240M'
	AND [ADQ_C_COR]='ADQ-PMP'
	AND PERFIL_DESCARGA ='PRBTELE_QR_CONFIGURABLE_CONDCC'

	UPDATE [Stage].[StgMaestroTerminales]
	SET Version_Enviada = 'T9.142'
	WHERE Modelo_Terminal='Verifone - P400'
	AND [ADQ_C_COR]='ADQ-PMP'
	AND PERFIL_DESCARGA ='PRBTELE_QR_CONFIGURABLE_CONDCC'

	UPDATE [Stage].[StgMaestroTerminales]
	SET Version_Enviada = 'B80515'
	WHERE Modelo_Terminal='Ingenico - Move5000'
	AND [ADQ_C_COR]='ADQ-PMP'
	AND PERFIL_DESCARGA ='PRBTELE_QR_CONFIGURABLE_CONDCC'

	UPDATE [Stage].[StgMaestroTerminales]
	SET Version_Enviada = 'B80413'
	WHERE Modelo_Terminal='Ingenico - Link2500'
	AND [ADQ_C_COR]='ADQ-PMP'
	AND PERFIL_DESCARGA ='PRBTELE_QR_CONFIGURABLE_CONDCC'

	UPDATE [Stage].[StgMaestroTerminales]
	SET Version_Enviada = 'B80515'
	WHERE Modelo_Terminal='Ingenico - Move5000'
	AND [ADQ_C_COR]='ADQ-IZIPAY'
	AND PERFIL_DESCARGA  ='TEL_FACILITADOR_QRCONFI_CONDCC'

	UPDATE [Stage].[StgMaestroTerminales]
	SET Version_Enviada = 'B80413'
	WHERE Modelo_Terminal='Ingenico - Link2500'
	AND [ADQ_C_COR]='ADQ-IZIPAY'
	AND PERFIL_DESCARGA ='TEL_FACILITADOR_QRCONFI_CONDCC'




/*====================================== PROCESO 8.6 ============================================ 
							Insert Log
===============================================================================================*/ 

INSERT INTO Stage.stglog (Fuente,Tabla,Cantidad,FechaINicio,FechaFIN)
SELECT 'Actualiza BI_Maestro_Terminales - Paso 7/8','BI_Maestro_Terminales',0,@fecIniLog,DATEADD(HOUR,5,GETDATE());

END
