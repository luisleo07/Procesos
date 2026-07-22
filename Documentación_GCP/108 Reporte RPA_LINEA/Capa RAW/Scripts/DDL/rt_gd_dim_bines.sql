CREATE OR REPLACE TABLE prd-izipay-data-storage-pv.raw_dataentry_operaciones.rt_gd_dim_bines (
bin STRING  OPTIONS(description='Bin del banco'),
bancoemisor STRING  OPTIONS(description='Nombre del banco emisor'),
marca STRING  OPTIONS(description='Marca perteneciente al Bin'),
formapago STRING  OPTIONS(description='Tipo de tarjeta credito o debito'),
tipoemisor STRING  OPTIONS(description='Emisor local o foráneo'),
abremisor STRING  OPTIONS(description='Nombre abreviado del banco emisor'),
pais STRING  OPTIONS(description='Pais del banco emisor'),
obs STRING  OPTIONS(description='Observación'),
process_date DATE NOT NULL OPTIONS(description='Fecha de foto/datos configurada en el ETL para la extracción de datos'),
record_source STRING NOT NULL OPTIONS(description='Dato de Auditoría: Descripción del aplicativo origen de los datos.'),
load_date DATETIME NOT NULL OPTIONS(description='Fecha y hora de inserción del registro en el modelo'),
creation_user STRING NOT NULL OPTIONS(description='Usuario que crea el registro en la BD'),
PRIMARY KEY (bin) NOT ENFORCED
)
PARTITION BY process_date
CLUSTER BY marca, formapago, tipoemisor, abremisor
OPTIONS (description='Tabla catalogo con los bines de bancos nacionales e internacionales');
