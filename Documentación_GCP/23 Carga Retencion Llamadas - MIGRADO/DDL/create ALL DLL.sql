CREATE OR REPLACE TABLE prd-izipay-data-storage-pv.master_risk.m_retencion_fraude_crm( 
process_date DATE NOT NULL OPTIONS(description= 'Fecha de foto/datos configurada en el ETL para la extracción de datos, corresponde a la foto del día anterior (D-1)'), 
titulo_caso STRING  OPTIONS(description= 'Título o resumen del caso de retención registrado en el CRM.'), 
cod_comercio STRING  OPTIONS(description= 'Código único del cliente o entidad asociada al caso.'), 
nom_comercio STRING  OPTIONS(description= 'Nombre del cliente o empresa relacionada con la retención.'), 
tipo_caso STRING  OPTIONS(description= 'Tipo de caso registrado'), 
origen_caso STRING  OPTIONS(description= 'Canal por el cual se originó el caso'), 
estado_caso STRING  OPTIONS(description= 'Estado actual del caso'), 
num_caso STRING  OPTIONS(description= 'Número de identificación único del caso dentro del CRM.'), 
nivel_prioridad_caso STRING  OPTIONS(description= 'Nivel de prioridad del caso'), 
nom_agente_caso BYTES  OPTIONS(description= 'Nombre del usuario o agente responsable del caso en el CRM.'), 
fecha_hora_creacion_caso TIMESTAMP  OPTIONS(description= 'Fecha y hora en la que se creó el caso.'), 
nom_usuario_mod_caso BYTES  OPTIONS(description= 'Nombre del usuario que realizó la última modificación en el caso.'), 
fecha_mod_caso TIMESTAMP  OPTIONS(description= 'Fecha en que se realizó la última modificación en el caso.'), 
record_source STRING NOT NULL OPTIONS(description= 'Dato de Auditoría: Descripción del aplicativo origen de los datos.'), 
load_date TIMESTAMP NOT NULL OPTIONS(description= 'Fecha y hora de inserción del registro en el modelo'), 
creation_user STRING NOT NULL OPTIONS(description= 'Usuario que crea el registro en la BD'), 
)
PARTITION BY process_date
CLUSTER BY cod_comercio,origen_caso,estado_caso,nivel_prioridad_caso
OPTIONS (description ='Tabla maestra que contiene informacion sobre casos resgitrados por sospecha de fraude en herramientas de CRM (Dyamics/Salesforce) que son monitoreados por el equipo de Riesgos');

