CREATE OR REPLACE TABLE prd-izipay-data-storage-pv.raw_dataentry_operaciones.marguesi_terminal_desuso (
marguesi_desuso STRING  OPTIONS(description='Código izipay del activo fijo antiguo que ya no se utiliza en la actualdiad'),
process_date DATE NOT NULL OPTIONS(description='Fecha en la que se procesó la que se insertó el registro a la BD'),
record_source STRING NOT NULL OPTIONS(description='Dato de Auditoría: Descripción del aplicativo origen de los datos.'),
load_date DATETIME NOT NULL OPTIONS(description='Fecha y hora de inserción del registro en el modelo'),
creation_user STRING NOT NULL OPTIONS(description='Usuario que crea el registro en la BD')
)
OPTIONS (description='Catálogo que indica los marguesí de terminales antiguos que ya se dejaron de usar, pero deben ser mapeados y utilizados en el proceso del maestro de terminales');

CREATE OR REPLACE TABLE prd-izipay-data-storage-pv.raw_dataentry_operaciones.modelo_terminal_desuso (
modelo_desuso STRING  OPTIONS(description='Modelo de terminal antiguos que ya no se utilizan en el proceso del maestro de terminales'),
process_date DATE NOT NULL OPTIONS(description='Fecha en la que se procesó la que se insertó el registro a la BD'),
record_source STRING NOT NULL OPTIONS(description='Dato de Auditoría: Descripción del aplicativo origen de los datos.'),
load_date DATETIME NOT NULL OPTIONS(description='Fecha y hora de inserción del registro en el modelo'),
creation_user STRING NOT NULL OPTIONS(description='Usuario que crea el registro en la BD')
)
OPTIONS (description='Catálogo que indica los modelos de terminales antiguos que ya se dejaron de usar, pero deben ser mapeados y utilizados en el proceso del maestro de terminales');

CREATE OR REPLACE TABLE prd-izipay-data-storage-pv.raw_dataentry_operaciones.modelo_terminal_pinpad (
modelo_pinpad STRING  OPTIONS(description='Modelo de terminales que son POS tipo Pinpad'),
process_date DATE NOT NULL OPTIONS(description='Fecha en la que se procesó la que se insertó el registro a la BD'),
record_source STRING NOT NULL OPTIONS(description='Dato de Auditoría: Descripción del aplicativo origen de los datos.'),
load_date DATETIME NOT NULL OPTIONS(description='Fecha y hora de inserción del registro en el modelo'),
creation_user STRING NOT NULL OPTIONS(description='Usuario que crea el registro en la BD')
)
OPTIONS (description='Catálogo que indica los terminales que son pinpad');

CREATE OR REPLACE TABLE prd-izipay-data-storage-pv.raw_dataentry_operaciones.modelos_old_terminal_desuso (
modelo_mcc STRING  OPTIONS(description='Modelo del terminal en el mccenter'),
modelo_terminal STRING  OPTIONS(description='Modelo del terminal'),
marca STRING  OPTIONS(description='Marca del terminal'),
pci STRING  OPTIONS(description='Indicador del PCI'),
ctls STRING  OPTIONS(description='Indicador de Software y Hardware'),
modelo_corto STRING  OPTIONS(description='Modelo corto delterminal'),
medio STRING  OPTIONS(description='Medio'),
process_date DATE NOT NULL OPTIONS(description='Fecha en la que se procesó la que se insertó el registro a la BD'),
record_source STRING NOT NULL OPTIONS(description='Dato de Auditoría: Descripción del aplicativo origen de los datos.'),
load_date DATETIME NOT NULL OPTIONS(description='Fecha y hora de inserción del registro en el modelo'),
creation_user STRING NOT NULL OPTIONS(description='Usuario que crea el registro en la BD')
)
OPTIONS (description='Catálogo de terminales antiguos que no se usan, pero se deben mapear para el proceso del maestro de terminales');


