CREATE OR REPLACE TABLE prd-izipay-data-storage-pv.master_risk.t_contracargo_visa_rol1100 (
process_date DATE NOT NULL OPTIONS(description='Fecha de foto/datos configurada en el ETL para la extracción de datos, corresponde a aperturas de comercios hasta el cierre del día anterior'),
nro_caso STRING  OPTIONS(description='Número de caso asignado por Visa para el seguimiento del contracargo.'),
fecha_seguimiento_caso DATE  OPTIONS(description='Fecha de seguimiento o control interno del caso.'),
estado_caso STRING  OPTIONS(description='Estado actual del caso de disputa (e.g., recibido, en revisión).'),
cod_condicion_disputa STRING  OPTIONS(description='Código que representa la condición de disputa'),
cant_dias_vencimiento INT64  OPTIONS(description='Días restantes para actuar antes de vencer el plazo de respuesta.'),
moneda_transaccion STRING  OPTIONS(description='Moneda en la que se realizó la transacción.'),
mto_disputado FLOAT64  OPTIONS(description='Monto disputado expresado en moneda origen'),
pvc_id STRING  OPTIONS(description='Código único del número de tarjeta del cliente involucrado en el contracargo.'),
pvc_id_token STRING  OPTIONS(description='Código único del token de la tarjeta utilizada en la transacción.'),
estado_caso_emisor STRING  OPTIONS(description='Estado del caso asignado por la entidad emisora.'),
arn_inicio STRING  OPTIONS(description='Número ARN (Acquirer Reference Number) que identifica la transacción (primeros 23 caracteres del ARN)'),
arn_fin STRING  OPTIONS(description='Número ARN (Acquirer Reference Number) que identifica la transacción (últimos 12 caracteres del ARN)'),
usuario_asignado BYTES  OPTIONS(description='Usuario o agente que está gestionando el caso.'),
fecha_hora_ultima_accion DATETIME  OPTIONS(description='Fecha y hora de la última acción registrada en el caso, en horario local.'),
nom_banco_adquirente STRING  OPTIONS(description='Nombre del banco adquirente (BID) que procesó la transacción.'),
clasificacion_fraude STRING  OPTIONS(description='Clasificación del caso según indicadores de fraude.'),
cod_giro_comercio STRING  OPTIONS(description='Código MCC que representa el giro o actividad del comercio.'),
ind_moto STRING  OPTIONS(description='Indicador si la transacción fue realizada por MOTO (Mail Order/Telephone Order).'),
nom_comercio STRING  OPTIONS(description='Nombre del comercio donde se originó la transacción disputada.'),
cod_red_transaccion STRING  OPTIONS(description='Identificador de red en la que se procesó la transacción.'),
cod_jurisdiccion STRING  OPTIONS(description='Código de jurisdicción de la transacción.'),
ambito_transaccion STRING  OPTIONS(description='Indicador de si la transacción fue internacional, local u otro.'),
fecha_expiracion DATE  OPTIONS(description='Fecha de expiración del reglamento E/Reg Z aplicable al caso.'),
record_source STRING NOT NULL OPTIONS(description='Dato de Auditoría: Descripción del aplicativo origen de los datos.'),
load_date DATETIME NOT NULL OPTIONS(description='Fecha y hora de inserción del registro en el modelo'),
creation_user STRING NOT NULL OPTIONS(description='Usuario que crea el registro en la BD'),
PRIMARY KEY (pvc_id) NOT ENFORCED
)
PARTITION BY process_date
CLUSTER BY estado_caso, cod_condicion_disputa, cod_giro_comercio, ambito_transaccion
OPTIONS (description='Tabla que contiene la informacion historica de contracargos en prearbitraje y arbitraje extraídos de la plataforma de Visa proveniente de un conjunto de reportes demoninado Rol 1100');
