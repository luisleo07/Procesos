CREATE OR REPLACE TABLE prd-izipay-data-storage-pv.bi_riesgo.dv_variacion_estado_comercio (
process_date DATE  OPTIONS(description='Fecha de foto con el que el comercio cerró su información dicho día'),
party_id_izi STRING NOT NULL OPTIONS(description='Código identificador del número de documento del cliente afiliado que identifica de manera única al comercio. Se utiliza como clave principal en los procesos de comparación entre el estado anterior y actual.'),
fecha_proceso_actual DATE  OPTIONS(description='Fecha de foto del cierre del mes m-1'),
fecha_proceso_anterior DATE  OPTIONS(description='Fecha de foto del cierre del mes m-2'),
cod_segmento_actual STRING NOT NULL OPTIONS(description='Indica la clasificación de cuenta especial asignada al cliente como resultado del proceso de evaluación actual. Permite comparar contra la cuenta especial anterior para identificar variaciones.'),
cod_segmento_anterior STRING  OPTIONS(description='Indica la clasificación de cuenta especial asignada al cliente antes de la evaluación en el periodo actual. Representa el estado previo utilizado como referencia para detectar cambios'),
cod_situacion_actual STRING NOT NULL OPTIONS(description='Situación actual del comercio según la última actualización disponible. Este valor refleja el estado operativo vigente al momento de ejecución del proceso.'),
cod_situacion_anterior STRING  OPTIONS(description='Situación del comercio en el mes anterior según la tabla de establecimientos transformados. Este valor refleja el estado operativo del comercio en el histórico.'),
tipo_cambio STRING NOT NULL OPTIONS(description='Resultado de la comparación entre el segmento y la situación del mes anterior versus el estado actual. Valores posibles: NUEVO, INACTIVO, CAMBIO_SEGMENTO, CAMBIO_SEGMENTO_NO_VALIDO, SIN_CAMBIO.'),
accion STRING NOT NULL OPTIONS(description='Acción a ejecutar según el tipo de cambio detectado en el comercio. Valores posibles: CARGAR, EXTRAER, MANTENER. Define la operación que debe realizarse en la plataforma de destino.'),
record_source STRING NOT NULL OPTIONS(description='Dato de Auditoría: Descripción del aplicativo origen de los datos.'),
load_date DATETIME NOT NULL OPTIONS(description='Fecha y hora de inserción del registro en el modelo'),
creation_user STRING NOT NULL OPTIONS(description='Usuario que crea el registro en la BD'),
PRIMARY KEY (party_id_izi) NOT ENFORCED
)
PARTITION BY process_date
CLUSTER BY cod_segmento_actual, cod_situacion_actual, tipo_cambio, accion
OPTIONS (description='Tabla que almacena las variaciones de segmentos de los comercios al cierre de cada mes y la acción que tomará el equipo de Fraude');
