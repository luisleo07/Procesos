CREATE OR REPLACE TABLE prd-izipay-data-storage-pv.bi_riesgo.dv_facturacion_cybersource_trr( 
process_date DATE NOT NULL OPTIONS(description= 'Fecha de foto/datos configurada en el ETL para la extracción de datos, corresponde a la foto del día anterior (D-1)'), 
cod_comerciante STRING  OPTIONS(description= 'Identificador del comerciante. Tipo de transacción según el importe, transacciones mayores a 500 soles se clasifican como "IZIPAY_HIGH" y menores se clasifican como "IZIPAY_LOW".'), 
tipo_servicio STRING  OPTIONS(description= 'Tipo de servicio o nombre de aplicación.'), 
cant_trx FLOAT64  OPTIONS(description= 'Indica la cantidad de transacciones de cybersource trr (conteo del campo RequestID)'), 
record_source STRING NOT NULL OPTIONS(description= 'Dato de Auditoría: Descripción del aplicativo origen de los datos.'), 
load_date TIMESTAMP NOT NULL OPTIONS(description= 'Fecha y hora de inserción del registro en el modelo'), 
creation_user STRING NOT NULL OPTIONS(description= 'Usuario que crea el registro en la BD'), 
)
PARTITION BY process_date
CLUSTER BY tipo_servicio
OPTIONS (description ='Tabla que exporta el resumen de transacciones facturadas por Cybersource TRR mensualmente por tipo de servicio');