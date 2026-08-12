/****** Object:  StoredProcedure [Stage].[usp_GeneraStgMaestroTerminales_04]    Script Date: 5/29/2025 4:25:33 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [Stage].[usp_GeneraStgMaestroTerminales_04] AS
BEGIN

/*============================================================================================= 
Autor					:Business Analytics SAC
Fecha creación			:2021/04/12
Objetivos				:1. Actualizar el campo GIRO_MC
						:2. Actualizar el campo [VERSION_SWB]
						:3. Agrega el campo SERIE_UNICA
						:4. Modificar campos en la tabla [StgMaestroTerminales]
						:5. Actualiza los campos [Razón Social], [Grupo Económico], [Unidad de Negocio]
Ejecutar				:EXECUTE [Stage].[usp_GeneraStgMaestroTerminales_04]
Observaciones			:4. Se modifico el tamaño asignado al campo [fecape] de varchar(255) a varchar(50)
Comentarios				:Este SP es equivalente a 
							S4_P07_Pedidos_eventuales_up
							S4_P08_Versiones_Izipay
							S4_P09_Serie_unica
							S4_P10_Columnas_adicionales
							S4_P11_Update_Cartera
===============================================================================================*/ 
/*====================================== PROCESO 0 ============================================ 
							Definición de variables temporales 
===============================================================================================*/ 
DECLARE @fecIniLog DATETIME;
SET @fecIniLog			= DATEADD(HOUR,-5,GETDATE());
/*====================================== PROCESO 1.1 ============================================ 
								Actualizar el campo GIRO_MC
===============================================================================================*/ 

UPDATE A
SET 
	A.GIRO_MC='7.Centros Comerciales'
FROM [Stage].[StgMaestroTerminales] A
LEFT JOIN [RAW].[CC_RP] B
ON LEFT(LTRIM(RTRIM(A.COMERCIO)),7)=LTRIM(RTRIM(B.CODIGO))
WHERE B.CENTRO_COM_DESC IS NOT NULL;

UPDATE [Stage].[StgMaestroTerminales]
SET 
	FLG_TELECARGA='VERSION_NO_TELECARGABLE'
WHERE COMERCIO IN (
'102862190000',
'102926590000',
'102926790000',
'102950290000',
'102950390000',
'102950490000',
'102950590000',
'102950690000',
'102950790000',
'102950890000',
'102951190000',
'102951290000',
'102951390000',
'102951590000',
'102951690000',
'102951890000',
'102951990000',
'102952090000',
'102952190000',
'102952390000',
'810009890000',
'810297090000',
'810782390000',
'811356490000',
'811554090000',
'811581890000',
'811714490000',
'811899090000',
'811974090000',
'812024290000',
'812037490000',
'812074790000',
'812077390000',
'812084690000',
'812090990000',
'812093090000',
'812093190000',
'812095390000',
'812121590000',
'812132990000',
'812133290000',
'812142290000',
'812147790000',
'180165190000',
'180171690000',
'180173290000',
'709233490000'
);


/*====================================== PROCESO 2.1 ============================================ 
							Actualizar el campo [VERSION_SWB]
===============================================================================================*/ 


 UPDATE [Stage].[StgMaestroTerminales]
 SET [VERSION_SWB]= CASE 
					WHEN FEC_COMPRA < 20191230 THEN  'B80500'
					ELSE 'B80501'
				END
 WHERE MODELO ='IZI SMART'
 AND [VERSION_SWB] IS NULL;

 UPDATE [Stage].[StgMaestroTerminales]
 SET [VERSION_SWB]= CASE 
					WHEN FEC_COMPRA < 20190730 THEN  'B80305'
					WHEN FEC_COMPRA < 20191217 THEN  'B80308'
					ELSE 'B80401'
				END
 WHERE MODELO ='IZI'
 AND [VERSION_SWB] IS NULL;
 


/*====================================== PROCESO 3.1 ============================================ 
							Comprobación de tablas temporales
===============================================================================================*/ 

IF OBJECT_ID('TempDB..#TEMP') IS NOT NULL
BEGIN
	TRUNCATE TABLE #TEMP;
	DROP TABLE #TEMP;
END;

IF OBJECT_ID('TempDB..#SERIES_UNICAS') IS NOT NULL
BEGIN
	TRUNCATE TABLE #SERIES_UNICAS;
	DROP TABLE #SERIES_UNICAS;
END;

/*====================================== PROCESO 3.2 ============================================ 
								Agrega el campo SERIE_UNICA
===============================================================================================*/ 

/* IDENTIFICAR UN ÚNICO COMERCIO POR SERIE, CASO MULTICOMECIOS */


SELECT
	A.SERIE
	,A.COMERCIO
	,A.TERMINAL
INTO #SERIES_UNICAS
FROM (
	SELECT
	ROW_NUMBER() OVER (
		PARTITION BY SERIE
		ORDER BY SERIE ASC,FECHA_ULTIMA_TRANSACCION_FINANCIERA DESC,COMERCIO ASC) AS IDEM
	,SERIE
	,COMERCIO
	,TERMINAL
FROM [Stage].[StgMaestroTerminales] 
WHERE [ADQ_C_COR] in ('ADQ-PMP','C.COR-PMP','ADQ-IZIPAY')) AS A
WHERE IDEM='1';

SELECT A.*
	,CASE
		WHEN B.SERIE IS NULL THEN ''
		ELSE 1
	 END SERIE_UNICA
INTO #TEMP
FROM [Stage].[StgMaestroTerminales] A
LEFT JOIN #SERIES_UNICAS B
ON (A.COMERCIO=B.COMERCIO AND A.SERIE=B.SERIE AND A.TERMINAL=B.TERMINAL);

IF OBJECT_ID('Stage.StgMaestroTerminales') IS NOT NULL
	BEGIN
		TRUNCATE TABLE [Stage].[StgMaestroTerminales];
		DROP TABLE 	[Stage].[StgMaestroTerminales];
	END

SELECT *
INTO [Stage].[StgMaestroTerminales]
FROM #TEMP;



/*====================================== PROCESO 3.3 ============================================ 
					Eliminación de tablas temporales #TEMP, #SERIES_UNICAS
===============================================================================================*/ 
IF OBJECT_ID('TempDB..#TEMP') IS NOT NULL
BEGIN
	TRUNCATE TABLE #TEMP;
	DROP TABLE #TEMP;
END;

IF OBJECT_ID('TempDB..#SERIES_UNICAS') IS NOT NULL
BEGIN
	TRUNCATE TABLE #SERIES_UNICAS;
	DROP TABLE #SERIES_UNICAS;
END;

/*==================================== 3.4 COMENTARIOS ============================================ 
						Comentarios encontrados en el SP Original
===============================================================================================*/ 

/*
ALTER TABLE [Stage].[StgMaestroTerminales]
ADD [Razón Social] varchar(255);

ALTER TABLE [Stage].[StgMaestroTerminales]
ADD [Grupo Económico] varchar(255);

ALTER TABLE [Stage].[StgMaestroTerminales]
ADD [Unidad de Negocio] varchar(255);

UPDATE A
SET
	A.[Razón Social]=B.[Razón Social],
	A.[Grupo Económico]=B.[Grupo Económico],
	A.[Unidad de Negocio]=B.[Unidad de Negocio]
FROM [Stage].[StgMaestroTerminales] A
LEFT JOIN [DIRP].[dbo].[CRM_CARTERA] B
ON (left(A.comercio,7) = B.[Código] AND A.[ADQ_C_COR] IN ('ADQ-PMP','ADQ-IZIPAY'))
WHERE B.[Código] IS NOT NULL;
*/

/*====================================== PROCESO 4.1 ============================================ 
Agregar los campos [Razón Social], [Grupo Económico], [Unidad de Negocio], [fecape]
===============================================================================================*/ 

ALTER TABLE [Stage].[StgMaestroTerminales]
ADD [Razón Social] varchar(255);

ALTER TABLE [Stage].[StgMaestroTerminales]
ADD [Grupo Económico] varchar(255);

ALTER TABLE [Stage].[StgMaestroTerminales]
ADD [Unidad de Negocio] varchar(255);

ALTER TABLE [Stage].[StgMaestroTerminales]
ADD [fecape] varchar(50);


/*====================================== PROCESO 5.1 ============================================ 
		Actualiza los campos [Razón Social], [Grupo Económico], [Unidad de Negocio]
===============================================================================================*/ 


UPDATE A
SET
	A.[Razón Social]=B.[Razón Social],
	A.[Grupo Económico]=B.[Grupo Económico],
	A.[Unidad de Negocio]=B.[Unidad de Negocio]
FROM [Stage].[StgMaestroTerminales] A
LEFT JOIN [RAW].[CARTERA_RP] B
ON (left(A.comercio,7) = B.[Código] AND A.[ADQ_C_COR] IN ('ADQ-PMP','ADQ-IZIPAY'))
WHERE B.[Código] IS NOT NULL;

INSERT INTO Stage.stglog (Fuente,Tabla,Cantidad,FechaINicio,FechaFIN)
SELECT 'Actualiza BI_Maestro_Terminales - Paso 5/8','BI_Maestro_Terminales',0,@fecIniLog,DATEADD(HOUR,5,GETDATE());

END
