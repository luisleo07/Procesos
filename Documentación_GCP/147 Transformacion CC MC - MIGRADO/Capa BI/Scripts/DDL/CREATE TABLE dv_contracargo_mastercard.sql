CREATE OR REPLACE TABLE prd-izipay-data-storage-pv.bi_riesgo.dv_contracargo_mastercard (
process_date DATE NOT NULL OPTIONS(description='Fecha de foto/datos configurada en el ETL para la extracción de datos, corresponde a aperturas de comercios hasta el cierre del día anterior'),
tipo_intercambio STRING  OPTIONS(description='Indica si es intercambio es Local (L) o Internacional (I)'),
bin STRING  OPTIONS(description='Bin de 9 de la tarjeta'),
fecha_ingreso DATE  OPTIONS(description='Fecha de ingreso del contracargo'),
cod_ica_emisor STRING  OPTIONS(description='Codigo ICA del emisor'),
cod_ica_adq STRING  OPTIONS(description='Codigo ICA del adquirente (Izipay = 007963)'),
cod_mti STRING  OPTIONS(description='MTI codigo interno'),
cod_funcion STRING  OPTIONS(description='Codigo Fun indica la etapa del contracargo'),
tarjeta_enmascarada STRING  OPTIONS(description='Tarjeta enmascarada de la transacción'),
cod_tipo_contracargo STRING  OPTIONS(description='Tipo contracargo'),
cod_moneda STRING  OPTIONS(description='Codigo de la moneda del contracargo'),
mto_contracargo FLOAT64  OPTIONS(description='Importe del contracargo'),
cod_autorizacion_trx STRING  OPTIONS(description='Codigo de autorizacion de la transaccion'),
nro_referencia_acq STRING  OPTIONS(description='ARD de la transaccion'),
cod_comercio STRING  OPTIONS(description='Codigo del comercio'),
nom_comercio STRING  OPTIONS(description='Nombre del comercio'),
nro_control STRING  OPTIONS(description='Número de control del contracargo'),
cod_razon STRING  OPTIONS(description='Codigo de razon, indica el motivo del contracargo'),
pais_emisor STRING  OPTIONS(description='País del emisor'),
mensaje_emisor STRING  OPTIONS(description='Mensaje del emisor'),
estado_contracargo STRING  OPTIONS(description='Estado del contracargo'),
fecha_estado_contracargo DATE  OPTIONS(description='Fecha de estado del contracargo'),
cod_gestor STRING  OPTIONS(description='Codigo MC del usuario gestor'),
obs_regularizacion STRING  OPTIONS(description='Observacion en caso de regularizaciones'),
mto_contracargo_sol FLOAT64  OPTIONS(description='Importe en soles del contracargo'),
ind_unicidad_contracargo STRING  OPTIONS(description='Valor que indica si el registro del contracargo es único o si hay repetidos'),
record_source STRING NOT NULL OPTIONS(description='Dato de Auditoría: Descripción del aplicativo origen de los datos.'),
load_date DATETIME NOT NULL OPTIONS(description='Fecha y hora de inserción del registro en el modelo'),
creation_user STRING NOT NULL OPTIONS(description='Usuario que crea el registro en la BD')
)
PARTITION BY process_date
CLUSTER BY bin, fecha_ingreso, cod_comercio, pais_emisor
OPTIONS (description='Tabla que contiene todos los contracargos Mastercard con los datos y columnas transformados según las reglas de negocio');
