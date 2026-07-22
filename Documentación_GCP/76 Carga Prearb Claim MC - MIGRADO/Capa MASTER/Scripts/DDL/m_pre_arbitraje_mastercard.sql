CREATE OR REPLACE TABLE prd-izipay-data-storage-pv.master_risk.m_pre_arbitraje_mastercard (
process_date DATE NOT NULL OPTIONS(description='Fecha de foto/datos configurada en el ETL para la extracción de datos, corresponde a aperturas de comercios hasta el cierre del día anterior'),
fecha_actualizacion DATE  OPTIONS(description='Fecha en la que hubo una actualización del prearbitraje, ocurre cuando se detecta un cambio del código del caso, por defecto nace en nulo y se inserta un dato cuando se realizó algún cambio en las demás columnas'),
cod_caso STRING  OPTIONS(description='Id del caso'),
tipo_caso STRING  OPTIONS(description='Tipo de caso'),
pvc_id STRING  OPTIONS(description='Numero de tarjeta'),
cod_razon STRING  OPTIONS(description='Codigo razon del contracargo'),
mto_disputa FLOAT64  OPTIONS(description='Monto en disputa'),
moneda STRING  OPTIONS(description='Moneda de la disputa'),
ard STRING  OPTIONS(description='ARD de la transaccion'),
nro_control STRING  OPTIONS(description='Numero de control del contracargo'),
fecha_pre_arbitraje DATE  OPTIONS(description='Fecha del prearbitraje'),
estado STRING  OPTIONS(description='Estado del prearbitraje'),
estado_final STRING  OPTIONS(description='Estado final del prearbitraje'),
record_source STRING  OPTIONS(description='Dato de Auditoría: Descripción del aplicativo origen de los datos.'),
load_date DATETIME NOT NULL OPTIONS(description='Fecha y hora de inserción del registro en el modelo'),
creation_user STRING NOT NULL OPTIONS(description='Usuario que crea el registro en la BD')
)
PARTITION BY process_date
CLUSTER BY tipo_caso, cod_razon, estado, estado_final
OPTIONS (description='Tabla con la información histórica de prearbitrajes Mastercad provenientes de la Web');
