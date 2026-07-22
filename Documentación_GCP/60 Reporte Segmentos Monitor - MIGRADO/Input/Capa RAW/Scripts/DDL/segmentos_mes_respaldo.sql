CREATE OR REPLACE TABLE prd-izipay-data-storage-pv.raw_dataentry_operaciones.segmentos_mes_respaldo (
process_date DATE NOT NULL OPTIONS(description='Fecha de foto/datos configurada en el ETL para la extracción de datos, corresponde a aperturas de comercios hasta el cierre del día anterior'),
record_source STRING NOT NULL OPTIONS(description='Dato de Auditoría: Descripción del aplicativo origen de los datos.'),
load_date DATETIME NOT NULL OPTIONS(description='Fecha y hora de inserción del registro en el modelo'),
creation_user STRING NOT NULL OPTIONS(description='Usuario que crea el registro en la BD'),
party_id_izi STRING  OPTIONS(description='Código identificador del número de documento del cliente afiliado a IziPay'),
cta_esp_anterior STRING  OPTIONS(description='Código del segmento que tiene el cliente al cierre del mes anterior'),
situac_anterior STRING  OPTIONS(description='Situación que tiene el cliente al cierre del mes anterior'),
fecha_corte DATE  OPTIONS(description='Fecha del último día del mes anterior donde se evaluó su código de segmento y situación'),
PRIMARY KEY (party_id_izi) NOT ENFORCED
)
PARTITION BY process_date
CLUSTER BY cta_esp_anterior, situac_anterior
OPTIONS (description='Tabla que guarda historia a cierre de cada mes de los códigos de segmentos a nivel documento del cliente afiliado');
