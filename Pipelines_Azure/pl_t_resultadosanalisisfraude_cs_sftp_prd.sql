{
    "name": "pl_t_resultadosanalisisfraude_cs_sftp_prd",
    "properties": {
        "activities": [
            {
                "name": "var_fecha",
                "type": "SetVariable",
                "dependsOn": [],
                "policy": {
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "variableName": "var_fecha",
                    "value": {
                        "value": "@formatDateTime(convertTimeZone(utcNow(),'UTC','SA Pacific Standard Time'),'yyyyMMdd')",
                        "type": "Expression"
                    }
                }
            },
            {
                "name": "var_anio",
                "type": "SetVariable",
                "dependsOn": [
                    {
                        "activity": "var_fecha",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    }
                ],
                "policy": {
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "variableName": "var_anio",
                    "value": {
                        "value": "@substring(variables('var_fecha'),0,4)",
                        "type": "Expression"
                    }
                }
            },
            {
                "name": "var_mes",
                "type": "SetVariable",
                "dependsOn": [
                    {
                        "activity": "var_fecha",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    }
                ],
                "policy": {
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "variableName": "var_mes",
                    "value": {
                        "value": "@substring(variables('var_fecha'),4,2)",
                        "type": "Expression"
                    }
                }
            },
            {
                "name": "var_dia",
                "type": "SetVariable",
                "dependsOn": [
                    {
                        "activity": "var_fecha",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    }
                ],
                "policy": {
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "variableName": "var_dia",
                    "value": {
                        "value": "@substring(variables('var_fecha'),6,2)",
                        "type": "Expression"
                    }
                }
            },
            {
                "name": "ruta_GCS",
                "type": "SetVariable",
                "dependsOn": [
                    {
                        "activity": "var_anio",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    },
                    {
                        "activity": "var_mes",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    }
                ],
                "policy": {
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "variableName": "var_rutaGCS_compraya",
                    "value": {
                        "value": "@concat('Riesgos/Fraude Nombre Comercial/',variables('var_anio'),'/',variables('var_mes'))",
                        "type": "Expression"
                    }
                }
            },
            {
                "name": "ruta_ADLS",
                "type": "SetVariable",
                "dependsOn": [
                    {
                        "activity": "ruta_GCS",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    }
                ],
                "policy": {
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "variableName": "var_rutaADLS_compraya",
                    "value": {
                        "value": "@concat('Bigquery/Fraude_comercial/',variables('var_anio'),'/',variables('var_mes'))",
                        "type": "Expression"
                    }
                }
            },
            {
                "name": "ruta_SFTP",
                "type": "SetVariable",
                "dependsOn": [
                    {
                        "activity": "ruta_ADLS",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    }
                ],
                "policy": {
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "variableName": "var_rutaSFTP_compraya",
                    "value": {
                        "value": "@concat('Prd/Reportes/Riesgo y Cumplimiento/Reporte de Coincidencias en Nombres Comerciales/',variables('var_anio'),'/',variables('var_mes'))",
                        "type": "Expression"
                    }
                }
            },
            {
                "name": "archivo",
                "type": "SetVariable",
                "dependsOn": [
                    {
                        "activity": "ruta_SFTP",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    }
                ],
                "policy": {
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "variableName": "var_archivo_compraya",
                    "value": {
                        "value": "@concat('resultado_analisis_fraude_nomcom_',variables('var_fecha'),'.parquet')",
                        "type": "Expression"
                    }
                }
            },
            {
                "name": "archivo_sftp",
                "type": "SetVariable",
                "dependsOn": [
                    {
                        "activity": "archivo",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    }
                ],
                "policy": {
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "variableName": "var_archivo_csv_compraya",
                    "value": {
                        "value": "@concat('resultados_analisis_fraude_',variables('var_fecha'),'.csv')",
                        "type": "Expression"
                    }
                }
            },
            {
                "name": "GCS_to_ADLS_compraya",
                "type": "Copy",
                "dependsOn": [
                    {
                        "activity": "archivo",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    }
                ],
                "policy": {
                    "timeout": "0.12:00:00",
                    "retry": 0,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "source": {
                        "type": "ParquetSource",
                        "storeSettings": {
                            "type": "GoogleCloudStorageReadSettings",
                            "recursive": false,
                            "enablePartitionDiscovery": false
                        },
                        "formatSettings": {
                            "type": "ParquetReadSettings"
                        }
                    },
                    "sink": {
                        "type": "ParquetSink",
                        "storeSettings": {
                            "type": "AzureBlobFSWriteSettings"
                        },
                        "formatSettings": {
                            "type": "ParquetWriteSettings"
                        }
                    },
                    "enableStaging": false,
                    "translator": {
                        "type": "TabularTranslator",
                        "typeConversion": true,
                        "typeConversionSettings": {
                            "allowDataTruncation": true,
                            "treatBooleanAsNumber": false
                        }
                    }
                },
                "inputs": [
                    {
                        "referenceName": "ds_gcp_cs_to_adls_parquet_dev",
                        "type": "DatasetReference",
                        "parameters": {
                            "par_bucket": "dev-reportes",
                            "par_ruta": {
                                "value": "@variables('var_rutaGCS_compraya')",
                                "type": "Expression"
                            },
                            "par_filename": {
                                "value": "@variables('var_archivo_compraya')",
                                "type": "Expression"
                            }
                        }
                    }
                ],
                "outputs": [
                    {
                        "referenceName": "ds_adls_generico_parquet",
                        "type": "DatasetReference",
                        "parameters": {
                            "path": {
                                "value": "@variables('var_rutaADLS_compraya')",
                                "type": "Expression"
                            },
                            "file": {
                                "value": "@variables('var_archivo_compraya')",
                                "type": "Expression"
                            },
                            "container": "adls-ingesta"
                        }
                    }
                ]
            },
            {
                "name": "adls csv to sftp",
                "type": "Copy",
                "dependsOn": [
                    {
                        "activity": "syn to adls csv",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    }
                ],
                "policy": {
                    "timeout": "0.12:00:00",
                    "retry": 0,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "source": {
                        "type": "DelimitedTextSource",
                        "storeSettings": {
                            "type": "AzureBlobFSReadSettings",
                            "recursive": true,
                            "enablePartitionDiscovery": false
                        },
                        "formatSettings": {
                            "type": "DelimitedTextReadSettings"
                        }
                    },
                    "sink": {
                        "type": "DelimitedTextSink",
                        "storeSettings": {
                            "type": "SftpWriteSettings",
                            "operationTimeout": "01:00:00",
                            "useTempFileRename": true
                        },
                        "formatSettings": {
                            "type": "DelimitedTextWriteSettings",
                            "quoteAllText": true,
                            "fileExtension": ".csv"
                        }
                    },
                    "enableStaging": false,
                    "translator": {
                        "type": "TabularTranslator",
                        "typeConversion": true,
                        "typeConversionSettings": {
                            "allowDataTruncation": true,
                            "treatBooleanAsNumber": false
                        }
                    }
                },
                "inputs": [
                    {
                        "referenceName": "ds_container_generico_con_cabecera_csv_prd",
                        "type": "DatasetReference",
                        "parameters": {
                            "path": {
                                "value": "@variables('var_ruta_adls_csv')",
                                "type": "Expression"
                            },
                            "file": {
                                "value": "@variables('var_archivo_csv_compraya')",
                                "type": "Expression"
                            },
                            "delimitador": "|",
                            "comillas": "\"",
                            "container": "adls-reportes"
                        }
                    }
                ],
                "outputs": [
                    {
                        "referenceName": "ds_sftp_generico_con_cabecera_csv_prd",
                        "type": "DatasetReference",
                        "parameters": {
                            "path": {
                                "value": "@variables('var_rutaSFTP_compraya')",
                                "type": "Expression"
                            },
                            "file": {
                                "value": "@variables('var_archivo_csv_compraya')",
                                "type": "Expression"
                            },
                            "delimitador": "|",
                            "comillas": "\""
                        }
                    }
                ]
            },
            {
                "name": "create table",
                "type": "Script",
                "dependsOn": [
                    {
                        "activity": "archivo_sftp",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    },
                    {
                        "activity": "GCS_to_ADLS_compraya",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    }
                ],
                "policy": {
                    "timeout": "0.12:00:00",
                    "retry": 0,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "linkedServiceName": {
                    "referenceName": "ProdASynapseAnalytics",
                    "type": "LinkedServiceReference"
                },
                "typeProperties": {
                    "scripts": [
                        {
                            "type": "Query",
                            "text": "IF OBJECT_ID('raw.dataentry_cs_resultadofraude', 'U') IS NOT NULL\n    DROP TABLE raw.dataentry_cs_resultadofraude;\n\nCREATE TABLE raw.dataentry_cs_resultadofraude (\n    cod_comercio            NVARCHAR(255),\n    nom_comercio            NVARCHAR(255),\n    nom_comercio_norm       NVARCHAR(255),\n    nombre_referencia_match NVARCHAR(255),\n    origen_referencia       NVARCHAR(255),\n    score_sintactico        FLOAT,\n    score_semantico         FLOAT,\n    score_ia                FLOAT,\n    score_final             FLOAT,\n    nivel_alerta            NVARCHAR(255)\n);"
                        }
                    ],
                    "scriptBlockExecutionTimeout": "02:00:00"
                }
            },
            {
                "name": "adls parquet to syn",
                "type": "Copy",
                "dependsOn": [
                    {
                        "activity": "create table",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    }
                ],
                "policy": {
                    "timeout": "0.12:00:00",
                    "retry": 0,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "source": {
                        "type": "ParquetSource",
                        "storeSettings": {
                            "type": "AzureBlobFSReadSettings",
                            "recursive": true,
                            "enablePartitionDiscovery": false
                        },
                        "formatSettings": {
                            "type": "ParquetReadSettings"
                        }
                    },
                    "sink": {
                        "type": "SqlDWSink",
                        "preCopyScript": "truncate table raw.dataentry_cs_resultadofraude",
                        "writeBehavior": "Insert",
                        "sqlWriterUseTableLock": false,
                        "disableMetricsCollection": false
                    },
                    "enableStaging": false,
                    "translator": {
                        "type": "TabularTranslator",
                        "typeConversion": true,
                        "typeConversionSettings": {
                            "allowDataTruncation": true,
                            "treatBooleanAsNumber": false
                        }
                    }
                },
                "inputs": [
                    {
                        "referenceName": "ds_adls_generico_parquet",
                        "type": "DatasetReference",
                        "parameters": {
                            "path": {
                                "value": "@variables('var_rutaADLS_compraya')",
                                "type": "Expression"
                            },
                            "file": {
                                "value": "@variables('var_archivo_compraya')",
                                "type": "Expression"
                            },
                            "container": "adls-ingesta"
                        }
                    }
                ],
                "outputs": [
                    {
                        "referenceName": "Syn_Table_As400",
                        "type": "DatasetReference",
                        "parameters": {
                            "Tabla": "dataentry_cs_resultadofraude",
                            "Esquema": "raw"
                        }
                    }
                ]
            },
            {
                "name": "syn to adls csv",
                "type": "Copy",
                "dependsOn": [
                    {
                        "activity": "ruta adls csv",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    }
                ],
                "policy": {
                    "timeout": "0.12:00:00",
                    "retry": 0,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "source": {
                        "type": "SqlDWSource",
                        "sqlReaderQuery": "SELECT\n    a.cod_comercio,\n    b.nro_ruc,\n    b.raz_soc,\n    a.nom_comercio,\n    a.nom_comercio_norm,\n    a.nombre_referencia_match,\n    a.origen_referencia,\n    b.situac,\n    b.tipo_documento,\n    b.fech_ape,\n    b.tipo_producto        AS tipo_comercio,\n    c.mailcom,\n    c.mailrleg,\n    a.score_sintactico,\n    a.score_semantico,\n    a.score_ia,\n    a.score_final,\n    a.nivel_alerta\nFROM raw.dataentry_cs_resultadofraude a\nLEFT JOIN dwh.te_parque b      ON b.codigo = a.cod_comercio\nLEFT JOIN dwh.bi_mcestab c     ON c.codigo = b.codigo;",
                        "queryTimeout": "02:00:00",
                        "partitionOption": "None"
                    },
                    "sink": {
                        "type": "DelimitedTextSink",
                        "storeSettings": {
                            "type": "AzureBlobFSWriteSettings"
                        },
                        "formatSettings": {
                            "type": "DelimitedTextWriteSettings",
                            "quoteAllText": true,
                            "fileExtension": ".txt"
                        }
                    },
                    "enableStaging": false,
                    "translator": {
                        "type": "TabularTranslator",
                        "typeConversion": true,
                        "typeConversionSettings": {
                            "allowDataTruncation": true,
                            "treatBooleanAsNumber": false
                        }
                    }
                },
                "inputs": [
                    {
                        "referenceName": "AzureSynapseAnalyticsTable3",
                        "type": "DatasetReference"
                    }
                ],
                "outputs": [
                    {
                        "referenceName": "ds_container_generico_con_cabecera_csv_prd",
                        "type": "DatasetReference",
                        "parameters": {
                            "path": {
                                "value": "@variables('var_ruta_adls_csv')",
                                "type": "Expression"
                            },
                            "file": {
                                "value": "@variables('var_archivo_csv_compraya')",
                                "type": "Expression"
                            },
                            "delimitador": "|",
                            "comillas": "\"",
                            "container": "adls-reportes"
                        }
                    }
                ]
            },
            {
                "name": "ruta adls csv",
                "type": "SetVariable",
                "dependsOn": [
                    {
                        "activity": "adls parquet to syn",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    }
                ],
                "policy": {
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "variableName": "var_ruta_adls_csv",
                    "value": {
                        "value": "@concat('Riesgo Opertativo y Cumplimiento/Transaccional/Fraude nombre comercial/',variables('var_anio'),'/',variables('var_mes'))",
                        "type": "Expression"
                    }
                }
            }
        ],
        "variables": {
            "var_fecha": {
                "type": "String"
            },
            "var_anio": {
                "type": "String"
            },
            "var_mes": {
                "type": "String"
            },
            "var_dia": {
                "type": "String"
            },
            "var_rutaGCS_compraya": {
                "type": "String"
            },
            "var_rutaADLS_compraya": {
                "type": "String"
            },
            "var_rutaSFTP_compraya": {
                "type": "String"
            },
            "var_archivo_compraya": {
                "type": "String"
            },
            "var_archivo_csv_compraya": {
                "type": "String"
            },
            "var_ruta_adls_csv": {
                "type": "String"
            }
        },
        "folder": {
            "name": "adls_reportes/Riesgo Operativo y Cumplimiento/Fraude Nombre Comercial"
        },
        "annotations": [],
        "lastPublishTime": "2026-04-24T21:34:58Z"
    },
    "type": "Microsoft.DataFactory/factories/pipelines"
}