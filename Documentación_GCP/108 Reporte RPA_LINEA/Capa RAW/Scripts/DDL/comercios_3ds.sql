CREATE OR REPLACE TABLE prd-izipay-data-storage-pv.raw_dataentry_ecommerce.comercios_3ds (
codigo STRING  OPTIONS(description='Código del comercio'),
nombre_comercio STRING  OPTIONS(description='Nombre del comercio'),
marca STRING  OPTIONS(description='Marca de la tarjeta que indica qué tipo de autenticación debe pasar el tarjeta habiente'),
autenticacion STRING  OPTIONS(description='Tipo de autenticación que debe pasar el tarjeta habiente al momento de realizar la compra'),
process_date DATE NOT NULL OPTIONS(description='Fecha de foto/datos configurada en el ETL para la extracción de datos, corresponde a aperturas de comercios hasta el cierre del día anterior'),
record_source STRING NOT NULL OPTIONS(description='Dato de Auditoría: Descripción del aplicativo origen de los datos.'),
load_date DATETIME NOT NULL OPTIONS(description='Fecha y hora de inserción del registro en el modelo'),
creation_user STRING NOT NULL OPTIONS(description='Usuario que crea el registro en la BD')
)
PARTITION BY process_date
OPTIONS (description='Tabla que identifica la autenticación de seguridad que tienen los comercios ecommerce, por marca');
