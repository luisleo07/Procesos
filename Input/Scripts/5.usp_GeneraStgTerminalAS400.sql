/****** Object:  StoredProcedure [Stage].[usp_GeneraStgTerminalAS400]    Script Date: 5/29/2025 4:13:45 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [Stage].[usp_GeneraStgTerminalAS400] AS
BEGIN
/*======================================================================================= 
	Autor			:Business Analytics SAC
	Fecha creación	:2021/08/04
	Objetivos		:Generar la tabla terminales
	Ejecutar		:EXECUTE  [Stage].[usp_GeneraStgTerminalAS400]  
=======================================================================================*/ 
/*====================================== PROCESO 0 ====================================== 
							Definición de variables temporales 
========================================================================================*/ 

DECLARE @fecIniLog DATETIME;
SET @fecIniLog			= DATEADD(HOUR,-5,GETDATE());

/*====================================== PROCESO 1 ======================================= 
	Limpieza y Generación de la tabla temporal de MCFH781
=========================================================================================*/ 

	IF OBJECT_ID('TempDB..#TempMCFH781') IS NOT NULL
	BEGIN
		TRUNCATE TABLE #TempMCFH781;
		DROP TABLE #TempMCFH781;
	END;

	SELECT DISTINCT	Stage.[fn_LimpiaCaracteres] (D.B1NSER,'^0-9') SERIE_POS, B1NSER,
			ISNULL(D.B1NCHI,'') AS SERIE_CHIP,
			ISNULL(D.B1TERM,'') AS NRO_TERMINAL,
			ISNULL(D.B1MCOM,'') AS MEDIO,
			ISNULL(D.B1FUTF,'') AS FEC_TRX_FIN,
			ISNULL(D.B1FUTA,'') AS FEC_TRX_ADM,
			ISNULL(D.B1FECO,'') AS FEC_TRX_ECO,
			ISNULL(D.B1HUTF,'') AS HR_TRX_FIN,
			ISNULL(D.B1HUTA,'') AS HR_TRX_ADM,
			ISNULL(D.B1HECO,'') AS HR_TRX_ECO,
			ISNULL(D.B1FFAC,'') AS FLG_FAC,
			ISNULL(D.B1FUTD,'') AS FEC_DESC,
			ISNULL(D.B1HUTD,'') AS HR_DESC,
			ISNULL(D.B1PDES,'') AS PERFIL_DESC,
			ISNULL(D.B1FINS,'') AS B1FINS,
			ROW_NUMBER() OVER(PARTITION BY B1NSER ORDER BY B1FUTD DESC) AS Fila
	INTO #TempMCFH781
	FROM RAW.MCFH781 D
	WHERE RTRIM(B1NSER)<>''

/*====================================== PROCESO 2 ======================================= 
	Limpieza y Generación de la tabla temporal de MCFT782
=========================================================================================*/ 

	IF OBJECT_ID('TempDB..#TempMCFT782') IS NOT NULL
	BEGIN
		TRUNCATE TABLE #TempMCFT782;
		DROP TABLE #TempMCFT782;
	END;

	SELECT DISTINCT Stage.[fn_LimpiaCaracteres] (BDNSER,'^0-9') AS SERIE_POS,BDNSER,BDTICO,BDFINS 
	INTO #TempMCFT782
	FROM RAW.MCFT782 
	WHERE RTRIM(BDNSER)<>''

/*====================================== PROCESO 3 ======================================= 
	Cruce entre MCFT782 y MCFH781
=========================================================================================*/ 

	IF OBJECT_ID('TempDB..#TempMatch1') IS NOT NULL
	BEGIN
		TRUNCATE TABLE #TempMatch1;
		DROP TABLE #TempMatch1;
	END;
	 
	SELECT DISTINCT A.SERIE_POS,B1NSER,A.B1FINS, B.BDTICO,B.BDFINS
	INTO #TempMatch1
	FROM #TempMCFH781 A
	LEFT JOIN (SELECT DISTINCT SERIE_POS,BDTICO,BDFINS FROM #TempMCFT782) B ON A.SERIE_POS=B.SERIE_POS

/*===================================== PROCESO 4.1 ====================================== 
	Selección de registros que cumplen la 1er condición para el cálculo del campo FEC_INST
=========================================================================================*/ 

	IF OBJECT_ID('TempDB..#TempMatch2') IS NOT NULL
	BEGIN
		TRUNCATE TABLE #TempMatch2;
		DROP TABLE #TempMatch2;
	END;

	SELECT SERIE_POS, B1FINS
	INTO #TempMatch2
	FROM #TempMatch1
	WHERE B1FINS<>'0' AND BDTICO NOT IN ('RUC PMP', 'Almacen') AND BDFINS=0 

/*===================================== PROCESO 4.2 ====================================== 
	Selección de registros que cumplen la 2da condición para el cálculo del campo FEC_INST
=========================================================================================*/ 

	IF OBJECT_ID('TempDB..#TempMatch3') IS NOT NULL
	BEGIN
		TRUNCATE TABLE #TempMatch3;
		DROP TABLE #TempMatch3;
	END;

	SELECT SERIE_POS, BDFINS
	INTO #TempMatch3
	FROM #TempMatch1
	WHERE B1FINS<>'0' AND SERIE_POS NOT IN (SELECT SERIE_POS FROM #TempMatch2) 

/*===================================== PROCESO 5.1 ====================================== 
	Generación de datos de terminales provenientes de AKFMITEM
=========================================================================================*/ 

	IF OBJECT_ID('TempDB..#TempTerminales01') IS NOT NULL
	BEGIN
		TRUNCATE TABLE #TempTerminales01;
		DROP TABLE #TempTerminales01;
	END;

	SELECT	A.NSEFJ,Stage.[fn_LimpiaCaracteres] (A.NSEFJ,'^0-9') AS SERIE_POS, A.CSIAC AS SIT_POS, 
			CONCAT(B.CCLF1,B.CCLF2,B.CCLF3,B.CCLF4) AS CATEGORIA,
			A.CACFJ AS MARGUESI,RTRIM(A.TMRFJ) AS MARCA,RTRIM(A.TMOFJ) AS MODELO,
			RTRIM(A.USEFJ) AS COMERCIO,C.MESITU AS SIT_COMERCIO, C.MERUCE AS RUC,
			RTRIM(C.MERSOC) AS RAZON_SOCIAL, RTRIM(C.MENCOM) AS NOMBRE_COMERCIAL, RTRIM(C.MEDIRE) AS DIRECCION,
			RTRIM(C.MEUBOF) AS UBIGEO, RTRIM(C.MEDEPA) AS DEPARTAMENTO, RTRIM(C.MEPROV) AS PROVINCIA, RTRIM(C.MEDIST) AS DISTRITO,
			C.MECPOS AS COD_POSTAL, RTRIM(C.MEZONA) AS REFERENCIA,B.ARTICO, 
			CASE WHEN C.MEMCOM=0 THEN 0 ELSE 1 END AS FLG_MULTICOMERCIO,
			A.NSEFJ AS [VERSION],
			CONVERT(VARCHAR(8),DATEFROMPARTS(A.ACOFJ,A.MCOFJ,A.DCOFJ),112) AS FEC_COMPRA,
			A.CESFJ AS SITUACION,A.CIDFJ AS DISPONIBILIDAD,
			A.AIDFJ*100+A.MIDFJ AS FEC_DEPRECIACION,
			A.IPCFJ AS PRECIO_COMPRA,
			CAST(A.IDAFJ AS FLOAT)*1.00 AS DEPRECIACION_ANIO_ANT,
			CAST(A.IDEFJ AS FLOAT)*1.00 AS DEPRECIACION_ANIO,
			CAST(A.IAJFJ AS FLOAT)*1.00 AS IMP_INFL,
			ACOFJ,
			RTRIM(ISNULL(E.CHCELU,'')) AS TELEFONO,RTRIM(ISNULL(E.CHTIOP,'')) AS OPERADOR,
			RTRIM(ISNULL(F.PGDESC,'')) AS TIP_INST,
			ROUND(CASE WHEN H.AFFLAG='S' THEN 
										CASE WHEN (CAST(A.IAJFJ AS FLOAT) - CAST(A.IDAFJ AS FLOAT) - CAST(A.IDEFJ AS FLOAT))<0 THEN 0.01 
											 ELSE  CAST(A.IAJFJ AS FLOAT) - CAST(A.IDAFJ AS FLOAT) - CAST(A.IDEFJ AS FLOAT) END
				 ELSE CASE WHEN (CAST(A.IPCFJ AS FLOAT)-CAST(A.IDAFJ AS FLOAT)-CAST(A.IDEFJ AS FLOAT))<0 THEN 0.01 
						   ELSE CAST(A.IPCFJ AS FLOAT)-CAST(A.IDAFJ AS FLOAT)-CAST(A.IDEFJ AS FLOAT) END END,2) VAL_NETO,						   
			CONVERT(VARCHAR(8),DATEADD(HOUR,-5,GETDATE()),112) AS FEC_PROCESO,
			REPLACE(CONVERT(VARCHAR(8),DATEADD(HOUR,-5,GETDATE()),24),':','') AS HR_PROCESO,
			CASE WHEN B.ARTICO<>0 THEN 0 END AS FLG_ORIGEN,
			CASE WHEN K.MECOME IS NOT NULL THEN 
											CASE WHEN L.DTIPCO IS NULL THEN M.DTIPCO ELSE L.DTIPCO END 
				 WHEN K.MECOME IS NULL THEN 
											CASE WHEN J.PGDESC IS NOT NULL THEN 'RUC PMP' ELSE 'ALMACEN' END END TIP_COMERCIO,
			P.PGDESC AS BCA_CACO,A.FGRRFJ 
	INTO #TempTerminales01
	FROM RAW.AKFMITEM A --  244074
	INNER JOIN RAW.AKFMARTI B ON A.CCLF1=B.CCLF1 AND A.CCLF2=B.CCLF2 AND A.CCLF3=B.CCLF3 AND A.CCLF4=B.CCLF4
	INNER JOIN (SELECT 	MECEST,MESITU,MERUCE,MERSOC,MENCOM,MEDIRE,MEUBOF,MEDEPA,MEPROV,
						MEDIST,MECPOS,MEZONA,MEMCOM
				FROM RAW.MCFM019i) C ON RTRIM(A.USEFJ)=RTRIM(C.MECEST)
	LEFT JOIN RAW.ALFM004 E ON RTRIM(E.CHSERI)=RTRIM(A.USEFJ)
	LEFT JOIN RAW.MCFV075 F ON F.PGTIPO='ARTICO' AND F.PGCODI=B.ARTICO
	LEFT JOIN RAW.AKFV002 H ON H.AFANOI=A.ACOFJ
	LEFT JOIN RAW.MCFV050 L ON RTRIM(L.TIPCOM)=LEFT(A.USEFJ,2)
	LEFT JOIN RAW.ALFW004 K ON RTRIM(K.MECOME)=RTRIM(A.USEFJ)
	LEFT JOIN RAW.MCFV050 M ON RTRIM(M.TIPCOM)=LEFT(A.USEFJ,1) AND LEN(RTRIM(M.TIPCOM))=1
	LEFT JOIN RAW.MCFV075 J ON J.PGTIPO='EMP' AND J.PGCODI='RUC' AND C.MERUCE=J.PGDESC
	LEFT JOIN RAW.MCFM027 O ON LEFT(O.MECEST,1)=3 AND RTRIM(A.USEFJ)=O.MECEST
	LEFT JOIN RAW.MCFV075 P ON P.PGTIPO='IAENCC' AND RTRIM(J.PGCODI)!='***' AND J.PGCODI=RTRIM(O.MEENCC)
	WHERE A.CSIAC='A' AND RTRIM(A.NSEFJ)<>''

/*===================================== PROCESO 5.2 ====================================== 
	Anexando campos provenientes o que requieren de MCFH781 y MCFT782
=========================================================================================*/ 

	IF OBJECT_ID('Stage.StgTerminalAS400') IS NOT NULL
	BEGIN
		TRUNCATE TABLE Stage.StgTerminalAS400;
		DROP TABLE Stage.StgTerminalAS400;
	END;

	SELECT A.SERIE_POS,A.SIT_POS,A.CATEGORIA,A.MARGUESI,A.MARCA,A.MODELO,A.COMERCIO,A.SIT_COMERCIO,A.RUC,A.RAZON_SOCIAL,
		A.NOMBRE_COMERCIAL,A.DIRECCION,A.UBIGEO,A.DEPARTAMENTO,A.PROVINCIA,A.DISTRITO,A.COD_POSTAL,A.REFERENCIA,
		D.SERIE_CHIP,A.TELEFONO,A.OPERADOR,A.TIP_INST,
		CASE WHEN G.SERIE_POS IS NOT NULL THEN G.B1FINS 
			 WHEN H.SERIE_POS IS NOT NULL THEN H.BDFINS
			 ELSE 0
		END AS FEC_INST,	
		D.NRO_TERMINAL,D.MEDIO,D.FEC_TRX_FIN,D.FEC_TRX_ADM,D.FEC_TRX_ECO,D.HR_TRX_FIN,
		D.HR_TRX_ADM,D.HR_TRX_ECO,D.FLG_FAC,A.FLG_MULTICOMERCIO,D.FEC_DESC,D.HR_DESC,
		A.[VERSION],D.PERFIL_DESC,A.FEC_PROCESO,A.HR_PROCESO,
		CASE WHEN I.SERIE_POS IS NOT NULL THEN 1 ELSE A.FLG_ORIGEN END FLG_ORIGEN,
		A.FEC_COMPRA,A.SITUACION,A.DISPONIBILIDAD,A.FEC_DEPRECIACION,A.PRECIO_COMPRA,
		A.DEPRECIACION_ANIO_ANT,A.DEPRECIACION_ANIO,A.IMP_INFL,A.VAL_NETO,A.TIP_COMERCIO, A.FGRRFJ 
	INTO Stage.StgTerminalAS400
	FROM #TempTerminales01 A --244074
	LEFT JOIN #TempMCFH781 D ON A.SERIE_POS=D.SERIE_POS AND D.Fila=1
	LEFT JOIN #TempMatch2 G ON A.SERIE_POS=G.SERIE_POS
	LEFT JOIN (SELECT DISTINCT SERIE_POS,BDFINS FROM #TempMatch3) H ON A.SERIE_POS=H.SERIE_POS
	LEFT JOIN (SELECT DISTINCT SERIE_POS FROM #TempMatch1 WHERE BDTICO IS NOT NULL) I ON  A.SERIE_POS=I.SERIE_POS

/*===================================== PROCESO 6 ====================================== 
	Insertando Log
=========================================================================================*/ 
	INSERT INTO Stage.StgLog (Fuente,Tabla,Cantidad,FechaINicio,FechaFIN)
	SELECT 'Tablas AS400','Stage.StgTerminalAS400',(select count(*) from Stage.StgTerminalAS400),@fecIniLog,DATEADD(HOUR,5,GETDATE());

END


