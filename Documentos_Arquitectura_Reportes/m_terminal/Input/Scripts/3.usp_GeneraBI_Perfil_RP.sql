/****** Object:  StoredProcedure [DWH].[usp_GeneraBI_Perfil_RP]    Script Date: 5/29/2025 4:56:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [DWH].[usp_GeneraBI_Perfil_RP] AS
BEGIN

/*======================================================================================= 
Autor			:Business Analytics SAC
Fecha creación	:19/04/2021
Objetivos		:Generar la [DWH].[usp_GeneraBI_Perfil_RP]
Ejecutar		:EXECUTE  [DWH].[usp_GeneraBI_Perfil_RP] 
=======================================================================================*/ 

/*==================================PROCESO 1============================================ 
Limpiar la tabla  [DWH].[BI_Perfil_RP] 
=======================================================================================*/ 
TRUNCATE TABLE [DWH].[BI_Perfil_RP]

/*==================================PROCESO 2============================================ 
Insertar los datos de la tabla  [RAW].[Perfil_RP] a la tabla [DWH].[BI_Perfil_RP]
=======================================================================================*/
insert into [DWH].[BI_Perfil_RP]
	  ([Perfil]
      ,[Atributo]
      ,[Valor])

SELECT Perfil,Atributo,Valor
  FROM [RAW].[Perfil_RP]

UNPIVOT(
Valor
for Atributo in ([Dig_Manual],[Bimoneda],[Multi_Producto],[Trx_Default],[Confirmacion_Pre],[Solcita_Tarj_Operador],[PIN_BYPASS],[Ajuste compra],[Ampliación de Pre-Autorización],[Anulación],[Anulación Canje],[Anulacion de Confirmacion de PreAutoricacion],[Anulacion de PreAtorizacion],[Anulación Offline],[Anulación Pago],[CAMBIO PIN],[CAMBIO_PIN_VALIDA],[Canje Comparte],[Canje Puntos],[Cierre],[Cierre Automatico],[Cierre Batch Upload],[Cierre Manual Web],[Compra],[Compra Offline],[Conf Preautorización],[Consulta Comparte],[CONSULTA DCC],[Consulta de Fondos],[Consulta de Servicio],[ConsultaQR],[Efectivo],[Gasolina],[Mensaje Administrativo],[Pago de Servicio],[Preautorización],[Reimpresion Cierre],[Reporte de Preautorizacion],[Reporte de Preautorizaciones por vencer],[Reporte Declinada],[Reporte detallado],[Reporte mozo],[Reporte reimpresion],[Reporte total],[Reporte_resumen],[Reversa],[SOLICITA_PIN_SLOT],[Solicitud de PIN],[Valida Usuario],[VALIDA_ARQC],[Consulta QPS],[No cuotas QPS])
) as UPVT 


  WHERE PERFIL IS NOT NULL
END