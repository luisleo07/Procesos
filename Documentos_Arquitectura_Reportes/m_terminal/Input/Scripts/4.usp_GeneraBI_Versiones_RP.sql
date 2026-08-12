/****** Object:  StoredProcedure [DWH].[usp_GeneraBI_Versiones_RP]    Script Date: 5/29/2025 4:58:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [DWH].[usp_GeneraBI_Versiones_RP] AS
BEGIN

/*======================================================================================= 
Autor			:Business Analytics SAC
Fecha creación	:19/04/2021
Objetivos		:Generar la [DWH].[BI_Versiones_RP]
Ejecutar		:EXECUTE  [DWH].[BI_Versiones_RP] 
=======================================================================================*/ 

/*==================================PROCESO 1============================================ 
Limpiar la tabla  [DWH].[BI_Versiones_RP] 
=======================================================================================*/

truncate table [DWH].[BI_Versiones_RP]

/*==================================PROCESO 2============================================ 
Insertar datos desde la tabla [RAW].[Versiones_RP] a la tabla [DWH].[BI_Versiones_RP] 
=======================================================================================*/

insert into [DWH].[BI_Versiones_RP] 
	  ([CARGA]
      ,[Fecha]
      ,[Atributo]
      ,[Valor])

SELECT CARGA,convert(date,Fecha) as Fecha,Atributo,Valor FROM [RAW].[Versiones_RP] UNPIVOT(
Valor
for Atributo in ([CTLS MC],[CVM 150],[CTLS VISA],[QR],[SIMFRIENDLY],[Fix Rappi],[CTLS AMEX],[QR Multiproducto],[CVM y QPS 150 sol/50 dol],[Flujo cuota rápida],[Firma Pantalla],[DCC Visa],[CTLS Diners],[CTLS Union Pay],[CTLS JCB])
) as UPVT where  Fecha is not null

END