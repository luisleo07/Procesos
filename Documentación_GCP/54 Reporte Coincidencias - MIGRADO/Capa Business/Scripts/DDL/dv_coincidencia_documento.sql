CREATE OR REPLACE TABLE prd-izipay-data-storage-pv.bi_riesgo.dv_coincidencia_documento (
process_date DATE NOT NULL OPTIONS(description='Fecha de foto/datos configurada en el ETL para la extracción de datos, corresponde a aperturas de comercios hasta el cierre del día anterior'),
cod_comercio STRING  OPTIONS(description='Código del comercio activo sospechoso relacionado a un comercio bloqueado po fraude'),
correo_representante_legal BYTES  OPTIONS(description='Correo de representante legal del comerco sospechoso'),
cod_bloqueo_comercio STRING  OPTIONS(description='Código de bloqueo del comercio sospechoso'),
detalle_bloqueo_comercio STRING  OPTIONS(description='Detalle del motivo del bloqueo del comercio sospechoso'),
fecha_apertura_comercio DATE  OPTIONS(description='Fecha de apertura del comercio sospechoso'),
cod_situacion_comercio STRING  OPTIONS(description='Sirve para ver el estado o situación del comercioel comercio sospechoso'),
party_id_izi STRING  OPTIONS(description='Código único del número de documento con el cual se afilia el cliente a Izipay asociado al comercio sospechoso'),
party_id_izi_representante STRING  OPTIONS(description='Número de documento (dni/carnet de extranjería) afiliado del comercio sospechoso'),
nom_representante_legal BYTES  OPTIONS(description='Nombre de representante legal del comercio'),
segmento_parque STRING  OPTIONS(description='Categoría definida para clientes (DNI/RUC) definida por la gestión comercial del comercio sospechoso'),
nom_comercio STRING  OPTIONS(description='Nombre del comercio sospechoso'),
num_cuenta_comercio BYTES  OPTIONS(description='Número de cuenta a pagar del comercio sospechoso'),
telefono_comercio BYTES  OPTIONS(description='Teléfono del comercio sospechoso'),
nom_producto STRING  OPTIONS(description='Nombre del producto adquirido por el comercio sospechoso'),
razon_social_dealer STRING  OPTIONS(description='Nombre del distribuidor general que registró el comercio sospechoso'),
record_source STRING NOT NULL OPTIONS(description='Dato de Auditoría: Descripción del aplicativo origen de los datos.'),
load_date DATETIME NOT NULL OPTIONS(description='Fecha y hora de inserción del registro en el modelo'),
creation_user STRING NOT NULL OPTIONS(description='Usuario que crea el registro en la BD'),
)
PARTITION BY process_date
CLUSTER BY cod_comercio, cod_situacion_comercio, segmento_parque, nom_comercio
OPTIONS (description='Tabla que permite identificar comercios activos que podrían estar vinculados con comercios sospechosos que se relacionan con otros bloqueados en lista negra (blacklist) por coincidencia de documento afiliado o documento del representante', require_partition_filter = true);
