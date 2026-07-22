CREATE OR REPLACE TABLE prd-izipay-data-storage-pv.bi_riesgo.dv_coincidencia_bl (
process_date DATE NOT NULL OPTIONS(description='Fecha de foto/datos configurada en el ETL para la extracción de datos, corresponde a aperturas de comercios hasta el cierre del día anterior'),
cod_comercio STRING  OPTIONS(description='Código del comercio activo sospechoso relacionado a un comercio bloqueado po fraude'),
cod_comercio_bl STRING  OPTIONS(description='Código del comercio que fue bloqueado por fraude y se encuentra en el blacklist'),
correo_representante_legal BYTES  OPTIONS(description='Correo de representante legal del comerco sospechoso'),
cod_bloqueo_comercio_bl STRING  OPTIONS(description='Código de bloqueo del comercio bloqueado'),
detalle_bloqueo_comercio_bl STRING  OPTIONS(description='Detalle del motivo del bloqueo del comercio bloqueado'),
fecha_apertura_comercio DATE  OPTIONS(description='Fecha de apertura del comercio sospechoso'),
cod_situacion_comercio STRING  OPTIONS(description='Sirve para ver el estado o situación del comercioel comercio sospechoso'),
party_id_izi STRING  OPTIONS(description='Código único del número de documento con el cual se afilia el cliente a Izipay asociado al comercio sospechoso'),
party_id_izi_representante STRING  OPTIONS(description='Número de documento (dni/carnet de extranjería) afiliado del comercio sospechoso'),
segmento_parque STRING  OPTIONS(description='Categoría definida para clientes (DNI/RUC) definida por la gestión comercial del comercio sospechoso'),
nom_comercio STRING  OPTIONS(description='Nombre del comercio sospechoso'),
num_cuenta_comercio BYTES  OPTIONS(description='Número de cuenta a pagar del comercio sospechoso'),
telefono_comercio BYTES  OPTIONS(description='Teléfono del comercio sospechoso'),
nom_producto STRING  OPTIONS(description='Nombre del producto adquirido por el comercio sospechoso'),
razon_social_dealer STRING  OPTIONS(description='Nombre del distribuidor general que registró el comercio sospechoso'),
categoria_coincidencia STRING  OPTIONS(description='Categorización de coincidencia detectada (ejemplo: solo teléfono, solo RRLL, NroDoc y RRLL, etc.) Coincidencia entre ambos'),
flag_telefono BOOLEAN  OPTIONS(description='Flag que indica si el teléfono del comercio sospechoso coincide con el teléfono de un comercio bloqueado'),
flag_correo_representante BOOLEAN  OPTIONS(description='Flag que indica si el correo del representante del comercio sospechoso coincide con el correo del representante de un comercio bloqueado'),
flag_cuenta_bancaria BOOLEAN  OPTIONS(description='Flag que indica si la cuenta bancaria del comercio sospechoso coincide con la cuenta bancaria de un comercio bloqueado'),
flag_cliente BOOLEAN  OPTIONS(description='Flag que indica si el documento afiliado del comercio sospechoso coincide con el documento afiliado o del representante de un comercio bloqueado'),
flag_representante BOOLEAN  OPTIONS(description='Flag que indica si el documento del representante del comercio sospechoso coincide con el documento afiliado o del representante de un comercio bloqueado'),
flag_ruc10_dni BOOLEAN  OPTIONS(description='Flag que indica si el documento afiliado (RUC 10) del comercio sospechoso coincide con el DNI del documento afiliado o del representante de un comercio bloqueado'),
flag_bloqueo_fraude BOOLEAN  OPTIONS(description='Flag que indica si el comercio sospechoso fue bloqueado por fraude'),
record_source STRING NOT NULL OPTIONS(description='Dato de Auditoría: Descripción del aplicativo origen de los datos.'),
load_date DATETIME NOT NULL OPTIONS(description='Fecha y hora de inserción del registro en el modelo'),
creation_user STRING NOT NULL OPTIONS(description='Usuario que crea el registro en la BD')
)
PARTITION BY process_date
CLUSTER BY cod_bloqueo_comercio_bl, fecha_apertura_comercio, segmento_parque, nom_comercio
OPTIONS (description='Tabla que permite identificar comercios activos sospechosos que podrían estar vinculados con comercios bloqueados en lista negra (blacklist)');
