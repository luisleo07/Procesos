CREATE OR REPLACE TABLE prd-izipay-data-storage-pv.master_data.c_situacion_comercio (
process_date DATE NOT NULL OPTIONS(description='Fecha de foto/datos configurada en el ETL para la extracción de datos, corresponde a aperturas de comercios hasta el cierre del día anterior'),
cod_situacion_comercio STRING NOT NULL OPTIONS(description='Código que indica la situación del comercio'),
desc_situacion_comercio STRING NOT NULL OPTIONS(description='Descripción del estado o situación del comercio'),
record_source STRING NOT NULL OPTIONS(description='Dato de Auditoría: Descripción del aplicativo origen de los datos.'),
load_date DATETIME NOT NULL OPTIONS(description='Fecha y hora de inserción del registro en el modelo'),
creation_user STRING NOT NULL OPTIONS(description='Usuario que crea el registro en la BD'),
PRIMARY KEY (cod_situacion_comercio) NOT ENFORCED
)
PARTITION BY process_date
CLUSTER BY cod_situacion_comercio
OPTIONS (description='Catálogo que muestra la descripción de las situaciones por la que pasa un comercio de IziPay');
