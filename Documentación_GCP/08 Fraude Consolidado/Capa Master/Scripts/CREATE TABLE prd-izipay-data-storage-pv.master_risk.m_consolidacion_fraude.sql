CREATE OR REPLACE TABLE prd-izipay-data-storage-pv.master_risk.m_consolidacion_fraude (
process_date DATE NOT NULL OPTIONS(description='Fecha de foto/datos configurada en el ETL para la extracción de datos, corresponde a aperturas de comercios hasta el cierre del día anterior'),
fecha_trx DATE NOT NULL OPTIONS(description='Fecha en la que se dio la transacción'),
hora_trx_fraude_monitor STRING  OPTIONS(description='Hora en que se identifico una transaccion fraudulenta en monitor'),
cod_comercio STRING  OPTIONS(description='Código que se utiliza para identificar cada comercio'),
nom_comercio STRING  OPTIONS(description='Nombre del comercio donde se realizo la transacción'),
cod_metodo_ingreso FLOAT64  OPTIONS(description='Código de la forma en que se ingresaron los datos de la tarjeta'),
mto_trx_pen FLOAT64  OPTIONS(description='Monto de la transacción convertido a soles.'),
cod_autorizacion STRING  OPTIONS(description='Codigo de autorización de la transacción'),
tarjeta_hash STRING  OPTIONS(description='Identificador de la tarjeta en formato hash'),
tarjeta_enmascarada STRING  OPTIONS(description='Número de tarjeta enmascarado o tokenizado según estándar interno'),
cod_tipo_fraude FLOAT64  OPTIONS(description='Código del tipo o categoría de fraude'),
canal STRING  OPTIONS(description='Canal a través del cual se realizó la transacción.'),
ident_terminal STRING  OPTIONS(description='Identificador o dirección IP del terminal.'),
condicion_pto_venta STRING  OPTIONS(description='Condicion de punto de venta'),
cant_trx FLOAT64  OPTIONS(description='Numero de transacciones realizadas'),
fecha_trx_fraude_monitor DATE  OPTIONS(description='Fecha en la que se identifico una transaccion fraudulenta en monitor'),
record_source STRING NOT NULL OPTIONS(description='Fuente desde donde se detecto dicho fraude'),
load_date TIMESTAMP NOT NULL OPTIONS(description='Fecha y hora de inserción del registro en el modelo'),
creation_user STRING NOT NULL OPTIONS(description='Usuario que crea el registro en la BD')
)
PARTITION BY process_date
CLUSTER BY fecha_trx, cod_comercio, canal, fecha_trx_fraude_monitor
OPTIONS (description='Tener un consolidado de todos los fraudes que se identifican desde tc40, asbanc, safe y monitor');
