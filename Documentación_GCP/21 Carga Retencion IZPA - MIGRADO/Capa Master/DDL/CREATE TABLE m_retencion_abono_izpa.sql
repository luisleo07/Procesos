CREATE OR REPLACE TABLE prd-izipay-data-storage-pv.master_risk.m_retencion_abono_izpa( 
process_date DATE NOT NULL OPTIONS(description= 'Fecha de foto/datos configurada en el ETL para la extracción de datos, corresponde a la foto del día anterior (D-1)'), 
cod_banco STRING  OPTIONS(description= 'Código de la entidad bancaria.'), 
nom_banco STRING  OPTIONS(description= 'Nombre de la entidad bancaria.'), 
party_id_izi STRING  OPTIONS(description= 'Código del Registro Único de Contribuyente (RUC) del titular o empresa.'), 
cod_comercio STRING  OPTIONS(description= 'Código de comercio'), 
razon_social BYTES  OPTIONS(description= 'Razón social de la empresa.'), 
nro_cuenta BYTES  OPTIONS(description= 'Número de cuenta bancaria asociada a la retención.'), 
mto_venta FLOAT64  OPTIONS(description= 'Monto retenido en la moneda original.'), 
mto_venta_sol FLOAT64  OPTIONS(description= 'Monto retenido convertido a soles.'), 
cod_moneda STRING  OPTIONS(description= 'Código de la moneda del comercio (604: soles / 804: dolares)'), 
tipo_cambio FLOAT64  OPTIONS(description= 'Tipo de cambio utilizado en la conversión (dolares/soles)'), 
cod_proc_retencion STRING  OPTIONS(description= 'Código o referencia de procesamiento de la retención.'), 
fecha_proceso DATE  OPTIONS(description= 'Fecha de procesamiento de la retención.'), 
fecha_abono DATE  OPTIONS(description= 'Fecha de abono o devolución de la retención.'), 
tipo_cuenta STRING  OPTIONS(description= 'Tipo de cuenta (CC: Cuenta Corriente, AH: Cuenta de ahorros)'), 
tercero_involucrado STRING  OPTIONS(description= 'Nombre o identificación del tercero involucrado en la retención.'), 
cod_cta_especial STRING  OPTIONS(description= 'Cod Est Abono'), 
cod_situacion STRING  OPTIONS(description= 'Situación (null: Pendiente, A: Anulado, B: Enviado al Banco)'), 
record_source STRING NOT NULL OPTIONS(description= 'Dato de Auditoría: Descripción del aplicativo origen de los datos.'), 
load_date TIMESTAMP NOT NULL OPTIONS(description= 'Fecha y hora de inserción del registro en el modelo'), 
creation_user STRING NOT NULL OPTIONS(description= 'Usuario que crea el registro en la BD'), 
PRIMARY KEY (cod_comercio) NOT ENFORCED
)
PARTITION BY process_date
CLUSTER BY nom_banco,party_id_izi,fecha_abono,tipo_cuenta
OPTIONS (description ='Tabla que contiene el reporte de retenciones de abonos a comercios por sospecha de fraude. Equivalente al reporte IZPA011 del AS400');