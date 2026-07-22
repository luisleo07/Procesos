CREATE OR REPLACE TABLE prd-izipay-data-storage-pv.bi_riesgo.dv_contracargo_liquidacion (
process_date DATE NOT NULL OPTIONS(description='Fecha que indica cuando se procesó la transacción para que entre al proceso de liquidación (transacción confirmada)'),
pvc_id STRING  OPTIONS(description='Código único de la tarjeta utilizada en la transacción'),
cod_autorizacion STRING  OPTIONS(description='Código de autorización asignado por el emisor para validar la transacción. '),
cod_comercio STRING  OPTIONS(description='Código identificador del comercio donde se procesó la transacción.'),
fecha_transaccion DATE  OPTIONS(description='Fecha en la que se realizó la venta o consumo (en formato AAAAMMDD).'),
moneda STRING  OPTIONS(description='Moneda usada en la transacción (SOL PERUANO, DOLARES AMERICANOS).'),
cod_tipo_transaccion   STRING  OPTIONS(description='Código que identifica el tipo de transacción realizada(E.G., 076, 034,876).'),
nom_comercio STRING  OPTIONS(description='Nombre del comercio asociado a la transacción.'),
arn_ard STRING  OPTIONS(description='ARN (Acquirer Reference Number) original, número único de seguimiento de la transacción.'),
arn_ard_fuente  STRING  OPTIONS(description='Número ARN alternativo o fuente para trazabilidad.  '),
voucher STRING  OPTIONS(description='Número de comprobante o ticket generado en el punto de venta.'),
cod_respuesta_ecommerce STRING  OPTIONS(description='Código de respuesta de una transacción que pasó por el canal e-commerce.'),
cod_terminal STRING  OPTIONS(description='Código o número de terminal POS donde se procesó la transacción.'),
metodo_ingreso STRING  OPTIONS(description='Método de ingreso de la tarjeta (manual, chip, contactless, e-commerce, etc.).'),
referencia STRING  OPTIONS(description='Referencia adicional asociada a la transacción (puede ser un número de pedido, código externo, etc.).'),
mto_venta FLOAT64  OPTIONS(description='Monto total de la transacción realizada.'),
cod_usuario_aprobador STRING  OPTIONS(description='Código de usuario aprobador.'),
fecha_autorizacion DATE  OPTIONS(description='Fecha en la que la transacción fue autorizada.'),
hora_autorizacion STRING  OPTIONS(description='Hora específica en la que se emitió la autorización.'),
fecha_hora_autorizacion DATETIME  OPTIONS(description='Fecha y hora en la que la transacción fue autorizada.'),
record_source STRING NOT NULL OPTIONS(description='Dato de Auditoría: Descripción del aplicativo origen de los datos.'),
load_date DATETIME NOT NULL OPTIONS(description='Fecha y hora de inserción del registro en el modelo.'),
creation_user STRING NOT NULL OPTIONS(description='Usuario que crea el registro en la BD')
)
PARTITION BY process_date
CLUSTER BY moneda, cod_tipo_transaccion  , metodo_ingreso
OPTIONS (description='Tabla business que contiene la informacion de transacciones que entraron al proceso de liquidación, que fueron reportadas por un contracargo y que siguen las consideraciones de transformaciones establecidas por el equipo de Operaciones');
