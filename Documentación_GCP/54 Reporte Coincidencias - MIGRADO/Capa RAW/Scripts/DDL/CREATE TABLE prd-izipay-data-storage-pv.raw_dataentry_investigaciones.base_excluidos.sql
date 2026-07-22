CREATE OR REPLACE TABLE prd-izipay-data-storage-pv.raw_dataentry_investigaciones.base_excluidos (
codigo STRING  OPTIONS(description='Código que se debe excluir del reporte de coincidencias BL'),
process_date DATE NOT NULL OPTIONS(description='Fecha de foto/datos configurada en el ETL para la extracción de datos, corresponde a aperturas de comercios hasta el cierre del día anterior'),
record_source STRING NOT NULL OPTIONS(description='Dato de Auditoría: Descripción del aplicativo origen de los datos.'),
load_date DATETIME NOT NULL OPTIONS(description='Fecha y hora de inserción del registro en el modelo'),
creation_user STRING NOT NULL OPTIONS(description='Usuario que crea el registro en la BD'),
PRIMARY KEY (codigo) NOT ENFORCED
)
PARTITION BY process_date
OPTIONS (description='Lista de códigos que el equipo de investigaciones determinó que no deben estar en la black list, debido a que no generan sospecha de fraude');
