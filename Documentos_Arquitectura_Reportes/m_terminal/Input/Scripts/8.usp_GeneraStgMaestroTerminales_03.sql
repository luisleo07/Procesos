/****** Object:  StoredProcedure [Stage].[usp_GeneraStgMaestroTerminales_03]    Script Date: 5/29/2025 4:24:23 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [Stage].[usp_GeneraStgMaestroTerminales_03] AS
BEGIN

/*============================================================================================= 
Autor					:Business Analytics SAC
Fecha creación			:2021/04/12
Objetivos				:Agrega los campos nuevos (CANT_TERM, CANT_TERM_ACT, FLG_PINPAD, FLG_INGENICO, FLG_MULT_APP, FLG_MULTICOMERCIO, FLG_TELECARGA, a la tabla StgMaestroTerminales
                         Actualización de los campos (HW_CTLS, MODELO, MARCA, MEDIO)
						 Agrega los campos GIRO y GIRO_MC
Ejecutar				:EXECUTE [Stage].[usp_GeneraStgMaestroTerminales_03]
Observaciones			:Se renombrarón las tablas temporales #FINAL a #FINAL_1,#FINAL_2,#FINAL_3,#FINAL_4,#FINAL_5,y #FINAL_6 para no reutilizar el mismo 	nombre en distintas secciones 
						 Se agregaron 2 REPLACE a la conversión del campo VERSION_SWB para reemplazar las letras E y H puesto que habian registros con caracteristicas no contempladas en el query.  
						 Se agregaron 1 REPLACE a la conversión del campo VERSION_SWB para reemplazar las letras NULL puesto que habian registros con caracteristicas no contempladas en el query.  
Comentarios				:Este SP es equivalente a 
							S4_P06_Pedidos_eventuales
===============================================================================================*/ 
/*====================================== PROCESO 0 ============================================ 
							Definición de variables temporales 
===============================================================================================*/ 
DECLARE @fecIniLog DATETIME;
SET @fecIniLog			= DATEADD(HOUR,-5,GETDATE());
/*====================================== PROCESO 1 ============================================ 
							Comprobación de tablas temporales
===============================================================================================*/ 

IF OBJECT_ID('TempDB..#TEMP') IS NOT NULL
BEGIN
	TRUNCATE TABLE #TEMP;
	DROP TABLE #TEMP;
END;

IF OBJECT_ID('TempDB..#TEMP_1') IS NOT NULL
BEGIN
	TRUNCATE TABLE #TEMP_1;
	DROP TABLE #TEMP_1;
END;

IF OBJECT_ID('TempDB..#TEMP_2') IS NOT NULL
BEGIN
	TRUNCATE TABLE #TEMP_2;
	DROP TABLE #TEMP_2;
END;

IF OBJECT_ID('TempDB..#TEMP_3') IS NOT NULL
BEGIN
	TRUNCATE TABLE #TEMP_3;
	DROP TABLE #TEMP_3;
END;

IF OBJECT_ID('TempDB..#TEMP_4') IS NOT NULL
BEGIN
	TRUNCATE TABLE #TEMP_4;
	DROP TABLE #TEMP_4;
END;

IF OBJECT_ID('TempDB..#TEMP_5') IS NOT NULL
BEGIN
	TRUNCATE TABLE #TEMP_5;
	DROP TABLE #TEMP_5;
END;

IF OBJECT_ID('TempDB..#TEMP_6') IS NOT NULL
BEGIN
	TRUNCATE TABLE #TEMP_6;
	DROP TABLE #TEMP_6;
END;

IF OBJECT_ID('TempDB..#TEMP_7') IS NOT NULL
BEGIN
	TRUNCATE TABLE #TEMP_7;
	DROP TABLE #TEMP_7;
END;

IF OBJECT_ID('TempDB..#FINAL') IS NOT NULL
BEGIN
	TRUNCATE TABLE #FINAL;
	DROP TABLE #FINAL;
END;

IF OBJECT_ID('TempDB..#FINAL_1') IS NOT NULL
BEGIN
	TRUNCATE TABLE #FINAL_1;
	DROP TABLE #FINAL_1;
END;

IF OBJECT_ID('TempDB..#FINAL_2') IS NOT NULL
BEGIN
	TRUNCATE TABLE #FINAL_2;
	DROP TABLE #FINAL_2;
END;

IF OBJECT_ID('TempDB..#FINAL_3') IS NOT NULL
BEGIN
	TRUNCATE TABLE #FINAL_3;
	DROP TABLE #FINAL_3;
END;

IF OBJECT_ID('TempDB..#FINAL_4') IS NOT NULL
BEGIN
	TRUNCATE TABLE #FINAL_4;
	DROP TABLE #FINAL_4;
END;

IF OBJECT_ID('TempDB..#FINAL_5') IS NOT NULL
BEGIN
	TRUNCATE TABLE #FINAL_5;
	DROP TABLE #FINAL_5;
END;

IF OBJECT_ID('TempDB..#FINAL_6') IS NOT NULL
BEGIN
	TRUNCATE TABLE #FINAL_6;
	DROP TABLE #FINAL_6;
END;


/*====================================== PROCESO 2 ============================================ 
Agregar campos nuevos (CANT_TERM, CANT_TERM_ACT, FLG_PINPAD, FLG_INGENICO, FLG_MULT_APP, FLG_MULTICOMERCIO, FLG_TELECARGA, a la tabla StgMaestroTerminales
===============================================================================================*/ 

/* CANTIDAD DE TERMINALES (CANT_TERM)*/


SELECT COMERCIO, COUNT(DISTINCT SERIE) CANT_TERM
INTO #TEMP
  FROM [Stage].[StgMaestroTerminales]
  WHERE [ADQ_C_COR]='ADQ-PMP'
  GROUP BY COMERCIO;

SELECT COMERCIO,COUNT(DISTINCT SERIE) CANT_TERM_ACT
INTO #TEMP_1 
  FROM [Stage].[StgMaestroTerminales]
  WHERE SITUACION_TERMINAL='1 - Con movimiento en los ultimos 3 meses.'
  AND [ADQ_C_COR]='ADQ-PMP'
  GROUP BY COMERCIO;

SELECT A.*,
	CASE
		WHEN A.[ADQ_C_COR]='ADQ-PMP' AND ISNULL(B.CANT_TERM,0) < 6 THEN CAST(B.CANT_TERM AS VARCHAR(15))
		WHEN A.[ADQ_C_COR]='ADQ-PMP' AND B.CANT_TERM < 11 THEN 'ENTRE 6 Y 10'
		WHEN A.[ADQ_C_COR]='ADQ-PMP' AND B.CANT_TERM < 16 THEN 'ENTRE 11 Y 15'
		WHEN A.[ADQ_C_COR]='ADQ-PMP' THEN 'MAS DE 15'
		ELSE ''
	END AS CANT_TERM
INTO #FINAL
FROM [Stage].[StgMaestroTerminales] A
LEFT JOIN #TEMP B
ON A.COMERCIO=B.COMERCIO;

IF OBJECT_ID('Stage.StgMaestroTerminales') IS NOT NULL
	BEGIN
		TRUNCATE TABLE [Stage].[StgMaestroTerminales];
		DROP TABLE 	[Stage].[StgMaestroTerminales];
	END

SELECT *
INTO [Stage].[StgMaestroTerminales]
FROM #FINAL;

------------------------------------------------------------------------------------------------------
/* CANTIDAD DE TERMINALES ACTIVOS (CANT_TERM_ACT) */

SELECT A.*,
	CASE
		WHEN A.[ADQ_C_COR]='ADQ-PMP' AND ISNULL(B.CANT_TERM_ACT,0) < 6 THEN CAST(B.CANT_TERM_ACT AS VARCHAR(15))
		WHEN A.[ADQ_C_COR]='ADQ-PMP' AND B.CANT_TERM_ACT < 11 THEN 'ENTRE 6 Y 10'
		WHEN A.[ADQ_C_COR]='ADQ-PMP' AND B.CANT_TERM_ACT < 16 THEN 'ENTRE 11 Y 15'
		WHEN  A.[ADQ_C_COR]='ADQ-PMP' THEN 'MAS DE 15'
		ELSE ''
	END AS CANT_TERM_ACT
INTO #FINAL_1
FROM [Stage].[StgMaestroTerminales] A
LEFT JOIN #TEMP_1 B
ON A.COMERCIO=B.COMERCIO;

IF OBJECT_ID('Stage.StgMaestroTerminales') IS NOT NULL
	BEGIN
		TRUNCATE TABLE [Stage].[StgMaestroTerminales];
		DROP TABLE 	[Stage].[StgMaestroTerminales];
	END

SELECT *
INTO [Stage].[StgMaestroTerminales]
FROM #FINAL_1;

------------------------------------------------------------------------------------------------------
/* COMERCIO CON PINPAD(FLG_PINPAD) */

SELECT DISTINCT COMERCIO
INTO #TEMP_2
  FROM [Stage].[StgMaestroTerminales]
WHERE MEDIO='PINPAD'
AND [ADQ_C_COR]='ADQ-PMP';

SELECT A.*,
	CASE
		WHEN A.[ADQ_C_COR]='ADQ-PMP' AND B.COMERCIO IS NOT NULL THEN 'COMERCIO_PINPAD'
		WHEN A.[ADQ_C_COR]='ADQ-PMP' THEN 'COMERCIO_NO_PINPAD'
	END AS FLG_PINPAD
INTO #FINAL_2
FROM [Stage].[StgMaestroTerminales] A
LEFT JOIN #TEMP_2 B
ON A.COMERCIO=B.COMERCIO;

IF OBJECT_ID('Stage.StgMaestroTerminales') IS NOT NULL
	BEGIN
		TRUNCATE TABLE [Stage].[StgMaestroTerminales];
		DROP TABLE 	[Stage].[StgMaestroTerminales];
	END

SELECT *
INTO [Stage].[StgMaestroTerminales]
FROM #FINAL_2;

------------------------------------------------------------------------------------------------------
/* COMERCIO CON INGENICO (FLG_INGENICO)*/

SELECT DISTINCT COMERCIO
INTO #TEMP_3
  FROM [Stage].[StgMaestroTerminales]
WHERE MARCA='Ingenico'
AND SITUACION_TERMINAL='1 - Con movimiento en los ultimos 3 meses.'
AND [ADQ_C_COR]='ADQ-PMP';

SELECT A.*,
	CASE
		WHEN A.[ADQ_C_COR]='ADQ-PMP' AND B.COMERCIO IS NOT NULL THEN 'COMERCIO_INGENICO'
		WHEN A.[ADQ_C_COR]='ADQ-PMP' THEN 'COMERCIO_NO_INGENICO'
	END AS FLG_INGENICO
INTO #FINAL_3
FROM [Stage].[StgMaestroTerminales] A
LEFT JOIN #TEMP_3 B
ON A.COMERCIO=B.COMERCIO;

IF OBJECT_ID('Stage.StgMaestroTerminales') IS NOT NULL
	BEGIN
		TRUNCATE TABLE [Stage].[StgMaestroTerminales];
		DROP TABLE 	[Stage].[StgMaestroTerminales];
	END

SELECT *
INTO [Stage].[StgMaestroTerminales]
FROM #FINAL_3;

------------------------------------------------------------------------------------------------------
/* COMERCIO MULTI-APLICACION (FLG_MULT_APP)*/

SELECT DISTINCT COMERCIO
INTO #TEMP_4
  FROM [Stage].[StgMaestroTerminales]
WHERE APLICACION<>'POS'
AND [ADQ_C_COR]='ADQ-PMP';

SELECT A.*,
	CASE
		WHEN A.[ADQ_C_COR]='ADQ-PMP' AND B.COMERCIO IS NOT NULL THEN 'COMERCIO_MULT_APP'
		WHEN A.[ADQ_C_COR]='ADQ-PMP' THEN 'COMERCIO_MONO_APP'
	END AS FLG_MULT_APP
INTO #FINAL_4
FROM [Stage].[StgMaestroTerminales] A
LEFT JOIN #TEMP_4 B
ON A.COMERCIO=B.COMERCIO;

IF OBJECT_ID('Stage.StgMaestroTerminales') IS NOT NULL
	BEGIN
		TRUNCATE TABLE [Stage].[StgMaestroTerminales];
		DROP TABLE 	[Stage].[StgMaestroTerminales];
	END

SELECT *
INTO [Stage].[StgMaestroTerminales]
FROM #FINAL_4;

------------------------------------------------------------------------------------------------------
/*
COMERCIO MULTI-COMERCIO

2 - MULTICOMERCIO / INTERIOR DE LOCAL
5 - BIPOLAR
1 - NORMAL
0 - MULTICOMERCIO / CABINA PUBLICA
9 - NORMAL

 */

SELECT DISTINCT COMERCIO
INTO #TEMP_5
  FROM [Stage].[StgMaestroTerminales]
WHERE MULTICOMERCIO IN ('2','0')
AND [ADQ_C_COR]='ADQ-PMP';

SELECT A.*,
	CASE
		WHEN A.[ADQ_C_COR]='ADQ-PMP' AND B.COMERCIO IS NOT NULL THEN 'MULTICOMERCIO'
		WHEN A.[ADQ_C_COR]='ADQ-PMP' THEN 'COMERCIO'
	END AS FLG_MULTICOMERCIO
INTO #FINAL_5
FROM [Stage].[StgMaestroTerminales] A
LEFT JOIN #TEMP_5 B
ON A.COMERCIO=B.COMERCIO;

IF OBJECT_ID('Stage.StgMaestroTerminales') IS NOT NULL
	BEGIN
		TRUNCATE TABLE [Stage].[StgMaestroTerminales];
		DROP TABLE 	[Stage].[StgMaestroTerminales];
	END

SELECT *
INTO [Stage].[StgMaestroTerminales]
FROM #FINAL_5;

------------------------------------------------------------------------------------------------------
/* COMERCIO CON VERSION NO TELECAGABLE (FLG_TELECARGA)*/

SELECT DISTINCT COMERCIO
INTO #TEMP_6
  FROM [Stage].[StgMaestroTerminales]
WHERE (REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(VERSION_SWB,'.',''),'B',''),'I',''),'P',''),'A',''),'T',''),'E',''),'H',''),'R',''),'NULL','') <= 8500)
AND SITUACION_TERMINAL='1 - Con movimiento en los ultimos 3 meses.'
AND MARCA='Verifone'
AND [ADQ_C_COR]='ADQ-PMP'; --and VERSION_SWB<>'A8null';





SELECT A.*,
	CASE
		WHEN A.[ADQ_C_COR]='ADQ-PMP' AND B.COMERCIO IS NOT NULL THEN 'VERSION_NO_TELECARGABLE'
		WHEN A.[ADQ_C_COR]='ADQ-PMP' THEN 'VERSION_TELECARGABLE'
	END AS FLG_TELECARGA
INTO #FINAL_6
FROM [Stage].[StgMaestroTerminales] A
LEFT JOIN #TEMP_6 B
ON A.COMERCIO=B.COMERCIO;

IF OBJECT_ID('Stage.StgMaestroTerminales') IS NOT NULL
	BEGIN
		TRUNCATE TABLE [Stage].[StgMaestroTerminales];
		DROP TABLE 	[Stage].[StgMaestroTerminales];
	END

SELECT *
INTO [Stage].[StgMaestroTerminales]
FROM #FINAL_6;




/*====================================== PROCESO 3 ============================================ 
							Actualizaciones (HW_CTLS, MODELO, MARCA, MEDIO)
===============================================================================================*/ 

------------------------------------------------------------------------------------------------------
/*ACTUALIZACIÓN HW CTLS EN ALMACENES*/


UPDATE A
SET 
	[HW_CTLS]='2.POS sin HW CTLS'
FROM [Stage].[StgMaestroTerminales] A
WHERE EXISTS ( SELECT 1 FROM [RAW].[520_NO_CTLS_RP] B WHERE A.SERIE=B.SERIE)
AND HW_CTLS IS NULL;

UPDATE A
SET 
	[HW_CTLS]='1.POS con HW CTLS'
FROM [Stage].[StgMaestroTerminales] A
WHERE MODELO LIKE '%IZI%'
AND HW_CTLS IS NULL;

UPDATE A
SET 
	[HW_CTLS]='1.POS con HW CTLS'
FROM [Stage].[StgMaestroTerminales] A
WHERE HW_CTLS IS NULL
AND (MODELO LIKE '%VX%520%'
OR MODELO LIKE '%MC%925%'
OR MODELO LIKE '%VX%820%'
OR MODELO LIKE '%IWL%220%'
OR MODELO LIKE '%IWL%250%');

------------------------------------------------------------------------------------------------------
/*ACTUALIZACIÓN MODELOS*/

UPDATE [Stage].[StgMaestroTerminales]
SET 
	MODELO='Verifone - VX510'
	,MARCA='Verifone'
	,MEDIO='GPRS Fijo'
WHERE MODELO LIKE '%510%GPRS%'
AND [ADQ_C_COR]='ALMACEN';

UPDATE [Stage].[StgMaestroTerminales]
SET 
	MODELO='Verifone - VX510'
	,MARCA='Verifone'
	,MEDIO='DIAL/IP'
WHERE MODELO LIKE '%510%'
AND MODELO NOT LIKE '%GPRS%'
AND [ADQ_C_COR]='ALMACEN';

UPDATE [Stage].[StgMaestroTerminales]
SET 
	MODELO='Verifone - VX520'
	,MARCA='Verifone'
	,MEDIO='DIAL/IP'
WHERE MODELO LIKE '%520%'
AND MODELO NOT LIKE '%GPRS%'
AND MODELO NOT LIKE '%3G%'
AND [ADQ_C_COR]='ALMACEN';

UPDATE [Stage].[StgMaestroTerminales]
SET 
	MODELO='Verifone - VX520C'
	,MARCA='Verifone'
	,MEDIO='GPRS Fijo'
WHERE MODELO LIKE '%520%3G%'
AND [ADQ_C_COR]='ALMACEN';

UPDATE [Stage].[StgMaestroTerminales]
SET 
	MODELO='Verifone - VX520'
	,MARCA='Verifone'
	,MEDIO='GPRS Fijo'
WHERE MODELO LIKE '%520%GPRS%'
AND [ADQ_C_COR]='ALMACEN';

UPDATE [Stage].[StgMaestroTerminales]
SET 
	MODELO='Verifone - VX610'
	,MARCA='Verifone'
	,MEDIO='GPRS Movil'
WHERE MODELO LIKE '%610%'
AND [ADQ_C_COR]='ALMACEN';

UPDATE [Stage].[StgMaestroTerminales]
SET 
	MODELO='Verifone - VX680'
	,MARCA='Verifone'
	,MEDIO='GPRS Movil'
WHERE MODELO LIKE '%680%'
AND [ADQ_C_COR]='ALMACEN';

UPDATE [Stage].[StgMaestroTerminales]
SET 
	MODELO='Verifone - VX810'
	,MARCA='Verifone'
	,MEDIO='PINPAD'
WHERE MODELO LIKE '%810%'
AND [ADQ_C_COR]='ALMACEN';

UPDATE [Stage].[StgMaestroTerminales]
SET 
	MODELO='Verifone - VX820'
	,MARCA='Verifone'
	,MEDIO='PINPAD'
WHERE MODELO LIKE '%820%'
AND [ADQ_C_COR]='ALMACEN';

UPDATE [Stage].[StgMaestroTerminales]
SET 
	MODELO='Ingenico - IWL250'
	,MARCA='Ingenico'
	,MEDIO='GPRS Movil'
WHERE MODELO LIKE '%IWL%250%'
AND [ADQ_C_COR]='ALMACEN';

UPDATE [Stage].[StgMaestroTerminales]
SET 
	MODELO='Ingenico - IWL220'
	,MARCA='Ingenico'
	,MEDIO='GPRS Movil'
WHERE MODELO LIKE '%IWL%220%'
AND [ADQ_C_COR]='ALMACEN';

UPDATE [Stage].[StgMaestroTerminales]
SET 
	MODELO='Ingenico - IWL220'
	,MARCA='Ingenico'
	,MEDIO='DIAL/IP'
WHERE MODELO LIKE '%ICT%220%'
AND MODELO NOT LIKE '%G%'
AND [ADQ_C_COR]='ALMACEN';

UPDATE [Stage].[StgMaestroTerminales]
SET 
	MODELO='Ingenico - IWL220'
	,MARCA='Ingenico'
	,MEDIO='GPRS Fijo'
WHERE MODELO LIKE '%ICT%220%G%'
AND [ADQ_C_COR]='ALMACEN';

UPDATE [Stage].[StgMaestroTerminales]
SET 
	MODELO='Verifone - P400'
	,MARCA='Verifone'
	,MEDIO='PINPAD'
WHERE MODELO LIKE '%P%400%'
AND [ADQ_C_COR]='ALMACEN';

UPDATE [Stage].[StgMaestroTerminales]
SET 
	MODELO='IZI SMART'
	,MARCA='Ingenico'
	,MEDIO='GPRS MOVIL'
WHERE MODELO LIKE '%SOVE%5000%'
AND [ADQ_C_COR]='ALMACEN';

UPDATE [Stage].[StgMaestroTerminales]
SET 
	MODELO='IZI JR'
	,MARCA='DSPREAD'
WHERE MODELO LIKE '%IZI%JR%'
AND [ADQ_C_COR]='ALMACEN';

UPDATE [Stage].[StgMaestroTerminales]
SET 
	MODELO='Verifone - MX925'
	,MARCA='Verifone'
WHERE MODELO LIKE '%MC925%'
AND [ADQ_C_COR]='ALMACEN';

UPDATE [Stage].[StgMaestroTerminales]
SET 
	MODELO='OTROS'
	,MARCA='OTROS'
WHERE [ADQ_C_COR]='ADQ-PMP'
AND MARCA='OTROS'
AND MODELO <>'Verifone - E105';

UPDATE [Stage].[StgMaestroTerminales]
SET 
	MODELO='Verifone - P400'
	,MARCA='Verifone'
	,MEDIO='PINPAD'
WHERE MODELO LIKE '%P%400%'
AND [ADQ_C_COR]='ADQ-PMP';

UPDATE [Stage].[StgMaestroTerminales]
SET 
	MODELO='OTROS'
	,MARCA='OTROS'
	,MEDIO=NULL
WHERE [ADQ_C_COR]='ADQ-IZIPAY'
AND MODELO='OTROS';

UPDATE [Stage].[StgMaestroTerminales]
SET 
	MODELO='Verifone - MX915'
	,MARCA='Verifone'
WHERE MODELO LIKE '%MX915%';

UPDATE [Stage].[StgMaestroTerminales]
SET 
	MARCA='Verifone'
	,MODELO='Verifone - V240M'
WHERE MODELO='V240M';

UPDATE [Stage].[StgMaestroTerminales]
SET 
	MARCA='PAX'
	,MODELO='PAX - D200'
WHERE MODELO='D200';


/*====================================== PROCESO 4 ============================================ 
Agrega los campos GIRO y GIRO_MC a la tabla StgMaestroTerminales en función a MCESTAB_RP
===============================================================================================*/ 


SELECT A.*, B.GIRO
	,CASE 
		WHEN B.GIRO = 'Farmacias, boticas' THEN '1.Farmacias, boticas'
		WHEN B.GIRO = 'Supermercados' THEN '2.Supermercados'
		WHEN B.GIRO = 'Tiendas por departamentos' THEN '3.Tiendas por departamentos'
		WHEN B.GIRO = 'Comida rapida' THEN '4.Comida rapida'
		WHEN B.GIRO = 'Estaciones de servicio, grifos' THEN '5.Estaciones de servicio, grifos'
		WHEN B.GIRO = 'Cines' THEN 	'6.Cines'
		WHEN B.GIRO = 'Centros Comerciales' THEN '7.Centros Comerciales'
		WHEN B.GIRO = 'Restaurantes' THEN '8. Restaurantes'
		ELSE '9.Otros'
	END GIRO_MC
  INTO #TEMP_7
  FROM [Stage].[StgMaestroTerminales] A
  LEFT JOIN stage.StgMcestab B
  ON LEFT(RTRIM(LTRIM(A.COMERCIO)),7)=RTRIM(LTRIM(B.codigo))
  WHERE A.[ADQ_C_COR]='ADQ-PMP';

INSERT INTO #TEMP_7
SELECT A.*, B.GIRO
	,CASE 
		WHEN B.GIRO = 'Farmacias, boticas' THEN '1.Farmacias, boticas'
		WHEN B.GIRO = 'Supermercados' THEN '2.Supermercados'
		WHEN B.GIRO = 'Tiendas por departamentos' THEN '3.Tiendas por departamentos'
		WHEN B.GIRO = 'Comida rapida' THEN '4.Comida rapida'
		WHEN B.GIRO = 'Estaciones de servicio, grifos' THEN '5.Estaciones de servicio, grifos'
		WHEN B.GIRO = 'Cines' THEN 	'6.Cines'
		WHEN B.GIRO = 'Centros Comerciales' THEN '7.Centros Comerciales'
		WHEN B.GIRO = 'Restaurantes' THEN '8. Restaurantes'
		ELSE '9.Otros'
	END GIRO_MC
  FROM [Stage].[StgMaestroTerminales] A
  LEFT JOIN stage.StgMcestab B
  ON LEFT(RTRIM(LTRIM(A.COMERCIO)),7)=RTRIM(LTRIM(B.codigo))
  WHERE A.[ADQ_C_COR]='ADQ-IZIPAY';

INSERT INTO #TEMP_7
SELECT A.*, B.GIRO
	,CASE 
		WHEN B.GIRO = 'Farmacias, boticas' THEN '1.Farmacias, boticas'
		WHEN B.GIRO = 'Supermercados' THEN '2.Supermercados'
		WHEN B.GIRO = 'Tiendas por departamentos' THEN '3.Tiendas por departamentos'
		WHEN B.GIRO = 'Comida rapida' THEN '4.Comida rapida'
		WHEN B.GIRO = 'Estaciones de servicio, grifos' THEN '5.Estaciones de servicio, grifos'
		WHEN B.GIRO = 'Cines' THEN 	'6.Cines'
		WHEN B.GIRO = 'Centros Comerciales' THEN '7.Centros Comerciales'
		WHEN B.GIRO = 'Restaurantes' THEN '8. Restaurantes'
		ELSE '9.Otros'
	END GIRO_MC
  FROM [Stage].[StgMaestroTerminales] A
  LEFT JOIN stage.StgMcestab B
  ON LEFT(RTRIM(LTRIM(A.COMERCIO)),7)=RTRIM(LTRIM(B.codigo))
  WHERE A.[ADQ_C_COR] ='C.COR-PMP';

INSERT INTO #TEMP_7
SELECT A.*, B.GIRO
	,CASE 
		WHEN B.GIRO = 'Farmacias, boticas' THEN '1.Farmacias, boticas'
		WHEN B.GIRO = 'Supermercados' THEN '2.Supermercados'
		WHEN B.GIRO = 'Tiendas por departamentos' THEN '3.Tiendas por departamentos'
		WHEN B.GIRO = 'Comida rapida' THEN '4.Comida rapida'
		WHEN B.GIRO = 'Estaciones de servicio, grifos' THEN '5.Estaciones de servicio, grifos'
		WHEN B.GIRO = 'Cines' THEN 	'6.Cines'
		WHEN B.GIRO = 'Centros Comerciales' THEN '7.Centros Comerciales'
		WHEN B.GIRO = 'Restaurantes' THEN '8. Restaurantes'
		ELSE '9.Otros'
	END GIRO_MC
  FROM [Stage].[StgMaestroTerminales] A
  LEFT JOIN stage.StgMcestab B
  ON LEFT(RTRIM(LTRIM(A.COMERCIO)),7)=RTRIM(LTRIM(B.codigo))
  WHERE A.[ADQ_C_COR] ='C.COR-IZIPAY';

INSERT INTO #TEMP_7
SELECT A.*, B.GIRO
	,CASE 
		WHEN B.GIRO = 'Farmacias, boticas' THEN '1.Farmacias, boticas'
		WHEN B.GIRO = 'Supermercados' THEN '2.Supermercados'
		WHEN B.GIRO = 'Tiendas por departamentos' THEN '3.Tiendas por departamentos'
		WHEN B.GIRO = 'Comida rapida' THEN '4.Comida rapida'
		WHEN B.GIRO = 'Estaciones de servicio, grifos' THEN '5.Estaciones de servicio, grifos'
		WHEN B.GIRO = 'Cines' THEN 	'6.Cines'
		WHEN B.GIRO = 'Centros Comerciales' THEN '7.Centros Comerciales'
		WHEN B.GIRO = 'Restaurantes' THEN '8. Restaurantes'
		ELSE '9.Otros'
	END GIRO_MC
  FROM [Stage].[StgMaestroTerminales] A
  LEFT JOIN stage.StgMcestab B
  ON LEFT(RTRIM(LTRIM(A.COMERCIO)),7)=RTRIM(LTRIM(B.codigo))
  WHERE A.[ADQ_C_COR] ='ALMACEN';

IF OBJECT_ID('Stage.StgMaestroTerminales') IS NOT NULL
	BEGIN
		TRUNCATE TABLE [Stage].[StgMaestroTerminales];
		DROP TABLE 	[Stage].[StgMaestroTerminales];
	END

SELECT *
INTO [Stage].[StgMaestroTerminales]
FROM #TEMP_7;


/*====================================== PROCESO 5 ============================================ 
							Eliminación de Tablas Temporales 
===============================================================================================*/ 

IF OBJECT_ID('TempDB..#TEMP') IS NOT NULL
BEGIN
	TRUNCATE TABLE #TEMP;
	DROP TABLE #TEMP;
END;

IF OBJECT_ID('TempDB..#TEMP_1') IS NOT NULL
BEGIN
	TRUNCATE TABLE #TEMP_1;
	DROP TABLE #TEMP_1;
END;

IF OBJECT_ID('TempDB..#TEMP_2') IS NOT NULL
BEGIN
	TRUNCATE TABLE #TEMP_2;
	DROP TABLE #TEMP_2;
END;

IF OBJECT_ID('TempDB..#TEMP_3') IS NOT NULL
BEGIN
	TRUNCATE TABLE #TEMP_3;
	DROP TABLE #TEMP_3;
END;

IF OBJECT_ID('TempDB..#TEMP_4') IS NOT NULL
BEGIN
	TRUNCATE TABLE #TEMP_4;
	DROP TABLE #TEMP_4;
END;

IF OBJECT_ID('TempDB..#TEMP_5') IS NOT NULL
BEGIN
	TRUNCATE TABLE #TEMP_5;
	DROP TABLE #TEMP_5;
END;

IF OBJECT_ID('TempDB..#TEMP_6') IS NOT NULL
BEGIN
	TRUNCATE TABLE #TEMP_6;
	DROP TABLE #TEMP_6;
END;

IF OBJECT_ID('TempDB..#TEMP_7') IS NOT NULL
BEGIN
	TRUNCATE TABLE #TEMP_7;
	DROP TABLE #TEMP_7;
END;

IF OBJECT_ID('TempDB..#FINAL') IS NOT NULL
BEGIN
	TRUNCATE TABLE #FINAL;
	DROP TABLE #FINAL;
END;

IF OBJECT_ID('TempDB..#FINAL_1') IS NOT NULL
BEGIN
	TRUNCATE TABLE #FINAL_1;
	DROP TABLE #FINAL_1;
END;

IF OBJECT_ID('TempDB..#FINAL_2') IS NOT NULL
BEGIN
	TRUNCATE TABLE #FINAL_2;
	DROP TABLE #FINAL_2;
END;

IF OBJECT_ID('TempDB..#FINAL_3') IS NOT NULL
BEGIN
	TRUNCATE TABLE #FINAL_3;
	DROP TABLE #FINAL_3;
END;

IF OBJECT_ID('TempDB..#FINAL_4') IS NOT NULL
BEGIN
	TRUNCATE TABLE #FINAL_4;
	DROP TABLE #FINAL_4;
END;

IF OBJECT_ID('TempDB..#FINAL_5') IS NOT NULL
BEGIN
	TRUNCATE TABLE #FINAL_5;
	DROP TABLE #FINAL_5;
END;

IF OBJECT_ID('TempDB..#FINAL_6') IS NOT NULL
BEGIN
	TRUNCATE TABLE #FINAL_6;
	DROP TABLE #FINAL_6;
END;

INSERT INTO Stage.stglog (Fuente,Tabla,Cantidad,FechaINicio,FechaFIN)
SELECT 'Carga BI_Maestro_Terminales - Paso 4/8','BI_Maestro_Terminales',(SELECT COUNT(*) FROM [Stage].[StgMaestroTerminales]),@fecIniLog,DATEADD(HOUR,5,GETDATE());

END
