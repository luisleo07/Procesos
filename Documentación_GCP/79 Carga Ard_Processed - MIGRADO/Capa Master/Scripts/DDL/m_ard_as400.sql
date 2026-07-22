CREATE OR REPLACE TABLE prd-izipay-data-storage-pv.master_risk.m_ard_as400 (
process_date DATE NOT NULL OPTIONS(description='Fecha que indica cuando se procesó la transacción para que entre al proceso de liquidación (transacción confirmada)'),
pvc_id STRING  OPTIONS(description='Código único de la tarjeta utilizada en la transacción'),
cod_autorizacion STRING  OPTIONS(description='Código de autorización asignado por el emisor para validar la transacción. '),
cod_comercio STRING  OPTIONS(description='Código identificador del comercio donde se procesó la transacción.'),
tipo_canal STRING  OPTIONS(description='Indicador de comercio electrónico (ECI – Electronic Commerce Indicator) que clasifica el tipo de canal digital utilizado.'),
fecha_transaccion DATE  OPTIONS(description='Fecha en la que se realizó la venta o consumo (en formato AAAAMMDD).'),
cod_moneda STRING  OPTIONS(description='Código numérico de la moneda usada en la transacción (e.g., 604 = Soles).'),
cod_tipo_transaccion   STRING  OPTIONS(description='Código que identifica el tipo de transacción realizada(E.G., 076, 034,876).'),
nom_comercio STRING  OPTIONS(description='Nombre del comercio asociado a la transacción.'),
arn_original STRING  OPTIONS(description='ARN (Acquirer Reference Number) original, número único de seguimiento de la transacción.'),
arn_devolucion STRING  OPTIONS(description='Número ARN asociado a una retención o a una devolución.'),
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
CLUSTER BY tipo_canal, cod_moneda, cod_tipo_transaccion  , metodo_ingreso
OPTIONS (description='Tabla que contiene la informacion de transacciones que entraron al proceso de liquidación y que fueron reportadas por un contracargo. Es un equivalente al repore de ARD generado por el AS400');
