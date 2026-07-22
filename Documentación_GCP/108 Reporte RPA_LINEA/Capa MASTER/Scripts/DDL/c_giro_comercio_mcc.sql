CREATE OR REPLACE TABLE prd-izipay-data-storage-pv.master_data.c_giro_comercio_mcc (
process_date DATE NOT NULL OPTIONS(description='Fecha de foto/datos configurada en el ETL para la extracción de datos, corresponde a aperturas de comercios hasta el cierre del día anterior'),
cod_giro_comercio STRING NOT NULL OPTIONS(description='Código correspondiente al giro del negocio, proveniente de las diversas marcas (Visa, Mastercard)'),
nom_giro_comercio STRING NOT NULL OPTIONS(description='Descripción del giro del negocio que se utiliza para clasificar los comercios'),
record_source STRING NOT NULL OPTIONS(description='Dato de Auditoría: Descripción del aplicativo origen de los datos.'),
load_date DATETIME NOT NULL OPTIONS(description='Fecha y hora de inserción del registro en el modelo'),
creation_user STRING NOT NULL OPTIONS(description='Usuario que crea el registro en la BD'),
PRIMARY KEY (cod_giro_comercio) NOT ENFORCED
)
PARTITION BY process_date
CLUSTER BY cod_giro_comercio
OPTIONS (description='Catálogo que contiene los giros de comercios establecidos por las marcas (MCC) y su definicion');
