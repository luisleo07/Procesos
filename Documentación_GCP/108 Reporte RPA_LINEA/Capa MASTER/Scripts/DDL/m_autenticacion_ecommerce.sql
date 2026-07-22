CREATE OR REPLACE TABLE prd-izipay-data-storage-pv.master_party.m_autenticacion_ecommerce (
process_date DATE NOT NULL OPTIONS(description='Fecha de foto/datos configurada en el ETL para la extracción de datos, corresponde a aperturas de comercios hasta el cierre del día anterior'),
cod_comercio STRING NOT NULL OPTIONS(description='Código del comercio'),
nom_comercio STRING NOT NULL OPTIONS(description='Nombre del comercio'),
marca_tarjeta STRING NOT NULL OPTIONS(description='Marca de la tarjeta que indica qué tipo de autenticación debe pasar el tarjeta habiente'),
tipo_autenticacion STRING NOT NULL OPTIONS(description='Tipo de autenticación que debe pasar el tarjeta habiente al momento de realizar la compra'),
record_source STRING NOT NULL OPTIONS(description='Dato de Auditoría: Descripción del aplicativo origen de los datos.'),
load_date DATETIME NOT NULL OPTIONS(description='Fecha y hora de inserción del registro en el modelo'),
creation_user STRING NOT NULL OPTIONS(description='Usuario que crea el registro en la BD'),
PRIMARY KEY (cod_comercio) NOT ENFORCED
)
PARTITION BY process_date
CLUSTER BY cod_comercio, marca_tarjeta, tipo_autenticacion
OPTIONS (description='Maestro que indica el tipo de autenticación que deben pasar los comercios ecommerce al momento de realizar la transacción (3DS/OTP)');
