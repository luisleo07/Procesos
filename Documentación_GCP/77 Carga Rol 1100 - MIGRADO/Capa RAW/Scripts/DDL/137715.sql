CREATE OR REPLACE TABLE prd-izipay-data-storage-pv.raw_dataentry_operaciones.137715 (
rol_case_number   STRING  OPTIONS(description='Número de caso asignado por Visa para el seguimiento del contracargo.  '),
followup_date   STRING  OPTIONS(description='Fecha de seguimiento o control interno del caso.  '),
case_status   STRING  OPTIONS(description='Estado actual del caso de disputa (e.g., recibido, en revisión).  '),
dc   STRING  OPTIONS(description='Código que representa la condición de disputa'),
days_to_act   STRING  OPTIONS(description='Días restantes para actuar antes de vencer el plazo de respuesta.  '),
amount   STRING  OPTIONS(description='Monto disputado expresado en moneda local con código de divisa.  '),
pvc_id STRING  OPTIONS(description='Número de tarjeta del cliente involucrado en el contracargo.  '),
pvc_id_token STRING  OPTIONS(description='Token de la tarjeta utilizada en la transacción.  '),
member_case_status   STRING  OPTIONS(description='Estado del caso asignado por la entidad emisora.  '),
arn   STRING  OPTIONS(description='Número ARN (Acquirer Reference Number) que identifica la transacción.  '),
user BYTES  OPTIONS(description='Usuario o agente que está gestionando el caso.  '),
last_action   STRING  OPTIONS(description='Fecha y hora de la última acción registrada en el caso.  '),
bid_name   STRING  OPTIONS(description='Nombre del banco adquirente (BID) que procesó la transacción.  '),
fraud_cls   STRING  OPTIONS(description='Clasificación del caso según indicadores de fraude.  '),
mcc_code   STRING  OPTIONS(description='Código MCC que representa el giro o actividad del comercio.  '),
moto_ind   STRING  OPTIONS(description='Indicador si la transacción fue realizada por MOTO (Mail Order/Telephone Order).  '),
merchant_name   STRING  OPTIONS(description='Nombre del comercio donde se originó la transacción disputada.  '),
network_id   STRING  OPTIONS(description='Identificador de red en la que se procesó la transacción.  '),
jr   STRING  OPTIONS(description='Código de jurisdicción de la transacción.  '),
ind   STRING  OPTIONS(description='Indicador de si la transacción fue internacional, local u otro.  '),
reg_e_reg_z_exp_date   STRING  OPTIONS(description='Fecha de expiración del reglamento E/Reg Z aplicable al caso.  '),
process_date DATE NOT NULL OPTIONS(description='Fecha de foto/datos configurada en el ETL para la extracción de datos, corresponde a aperturas de comercios hasta el cierre del día anterior'),
record_source STRING NOT NULL OPTIONS(description='Dato de Auditoría: Descripción del aplicativo origen de los datos.'),
load_date DATETIME NOT NULL OPTIONS(description='Fecha y hora de inserción del registro en el modelo'),
creation_user STRING NOT NULL OPTIONS(description='Usuario que crea el registro en la BD')
)
PARTITION BY process_date
OPTIONS (description='Cola de trabajo que agrupa los casos en etapa de Pre-Filing que requieren una acción inmediata o respuesta por parte del banco/analista antes de enviarse a Visa.');
