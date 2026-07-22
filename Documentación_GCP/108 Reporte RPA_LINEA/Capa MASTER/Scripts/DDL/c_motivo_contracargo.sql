CREATE OR REPLACE TABLE prd-izipay-data-storage-pv.master_data.c_motivo_contracargo (
process_date DATE NOT NULL OPTIONS(description='Fecha de foto/datos configurada en el ETL para la extracción de datos, corresponde a aperturas de comercios hasta el cierre del día anterior'),
cod_contracargo STRING NOT NULL OPTIONS(description='Codigo de razón de contracargo'),
descripcion_motivo_contracargo STRING NOT NULL OPTIONS(description='Descripcion del codigo del motivo del contracargo'),
categoria_motivo_contracargo STRING NOT NULL OPTIONS(description='Categoría del motivo de contracargo'),
record_source STRING NOT NULL OPTIONS(description='Dato de Auditoría: Descripción del aplicativo origen de los datos.'),
load_date DATETIME NOT NULL OPTIONS(description='Fecha y hora de inserción del registro en el modelo'),
creation_user STRING NOT NULL OPTIONS(description='Usuario que crea el registro en la BD'),
PRIMARY KEY (cod_contracargo) NOT ENFORCED
)
PARTITION BY process_date
CLUSTER BY cod_contracargo
OPTIONS (description='Catalogo que contiene con los información de los motivos de contracargo (código de contracargo, descripción y categoría)');
