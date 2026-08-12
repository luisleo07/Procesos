CREATE VIEW DWH.DataTerminalesAs
AS 
Select Right(a.USEFJ,7) as 'Codcomercio'
,a.CSIAC as 'Estado'
, a.CACFJ as 'Marguesi'
, a.TMRFJ as 'Marca'
, a.TMOFJ as 'Modelo'
, a.NSEFJ as 'Serie',
,CONVERT (VARCHAR(8) ,DATEFROMPARTS(A.ACOFJ,A.MCOFJ,A.DCOF)),112) AS 'FecCompra'
,C.MENCOM as 'NomComercial'
,c.MEDIRE as 'Direccion'
,c.MEPROV as 'Prov'
,c.MEDEPA as 'Dpto'
,c.MEDIST as 'Dist'
FROM RAW.AKFMITEM a
Left Join RAW MCFM019i C ON RTRIM(Right(a.USEFJ),7))=RTRIM(C.MECEST)