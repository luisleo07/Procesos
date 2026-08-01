{
    "name": "pl_exec_select_prd01",
    "properties": {
        "activities": [
            {
                "name": "query_to_adls",
                "type": "Copy",
                "dependsOn": [
                    {
                        "activity": "cargar_csv_syn",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    }
                ],
                "policy": {
                    "timeout": "7.00:00:00",
                    "retry": 0,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "source": {
                        "type": "SqlDWSource",
                        "sqlReaderQuery": {
                            "value": "select\n\tcount(distinct nro_ruc)\nfrom dwh.te_parque with (nolock)\nwhere compania in ('PMP','IZIPAY')\nand nombre_producto not in ('Cajero Corresponsal','Interoperabilidad Visanet', 'IZIPAY YA', 'VENDEMAS')\nand flg_filtro = '0'\nand situac not in ('3', '9')\n",
                            "type": "Expression"
                        },
                        "queryTimeout": "05:00:00",
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
                        "referenceName": "Syn_Table_As400",
                        "type": "DatasetReference",
                        "parameters": {
                            "Tabla": "BI_MCESTAB",
                            "Esquema": "dwh"
                        }
                    }
                ],
                "outputs": [
                    {
                        "referenceName": "ds_sdls_generico_con_cabecera_csv_prd",
                        "type": "DatasetReference",
                        "parameters": {
                            "path": "reporte",
                            "file": "base_p400.csv",
                            "delimitador": ";",
                            "comillas": "\""
                        }
                    }
                ]
            },
            {
                "name": "cargar_csv_syn",
                "type": "Copy",
                "state": "Inactive",
                "onInactiveMarkAs": "Succeeded",
                "dependsOn": [],
                "policy": {
                    "timeout": "7.00:00:00",
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
                            "recursive": false,
                            "enablePartitionDiscovery": false
                        },
                        "formatSettings": {
                            "type": "DelimitedTextReadSettings"
                        }
                    },
                    "sink": {
                        "type": "SqlDWSink",
                        "tableOption": "autoCreate",
                        "disableMetricsCollection": false
                    },
                    "enableStaging": false,
                    "translator": {
                        "type": "TabularTranslator",
                        "mappings": [
                            {
                                "source": {
                                    "name": "cod_comercio",
                                    "type": "String",
                                    "physicalType": "String"
                                },
                                "sink": {
                                    "name": "cod_comercio",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            }
                        ],
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
                            "path": "mc2200",
                            "file": "cod_comercio_albert.csv",
                            "delimitador": ";",
                            "comillas": "\"",
                            "container": "tempdata"
                        }
                    }
                ],
                "outputs": [
                    {
                        "referenceName": "Syn_Table_As400",
                        "type": "DatasetReference",
                        "parameters": {
                            "Tabla": "comercios_as",
                            "Esquema": "stage"
                        }
                    }
                ]
            },
            {
                "name": "Script1",
                "type": "Script",
                "state": "Inactive",
                "onInactiveMarkAs": "Succeeded",
                "dependsOn": [],
                "policy": {
                    "timeout": "0.12:00:00",
                    "retry": 0,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "linkedServiceName": {
                    "referenceName": "AzureSynapseAnalytics1",
                    "type": "LinkedServiceReference"
                },
                "typeProperties": {
                    "scripts": [
                        {
                            "type": "Query",
                            "text": "drop table stage.comercios_dcc_marca"
                        }
                    ],
                    "scriptBlockExecutionTimeout": "02:00:00"
                }
            },
            {
                "name": "Bucle_mover_archivos_sftp",
                "type": "ForEach",
                "state": "Inactive",
                "onInactiveMarkAs": "Succeeded",
                "dependsOn": [],
                "userProperties": [],
                "typeProperties": {
                    "items": {
                        "value": "@variables('vPeriodos')",
                        "type": "Expression"
                    },
                    "isSequential": true,
                    "activities": [
                        {
                            "name": "AsignarPeriodo_copy1",
                            "type": "SetVariable",
                            "dependsOn": [],
                            "policy": {
                                "secureOutput": false,
                                "secureInput": false
                            },
                            "userProperties": [],
                            "typeProperties": {
                                "variableName": "vPeriodoActual",
                                "value": {
                                    "value": "@item()",
                                    "type": "Expression"
                                }
                            }
                        },
                        {
                            "name": "adls_to_sftp",
                            "type": "Copy",
                            "dependsOn": [
                                {
                                    "activity": "AsignarNombreArchivo_copy1",
                                    "dependencyConditions": [
                                        "Completed"
                                    ]
                                }
                            ],
                            "policy": {
                                "timeout": "7.00:00:00",
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
                                        "recursive": false,
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
                                    "referenceName": "ds_container_generico_con_cabecera_csv_prd",
                                    "type": "DatasetReference",
                                    "parameters": {
                                        "path": {
                                            "value": "@variables('vRutaADLS')",
                                            "type": "Expression"
                                        },
                                        "file": "@variables('vArchivo')",
                                        "delimitador": "|",
                                        "comillas": "\"",
                                        "container": "adls-ingesta"
                                    }
                                }
                            ],
                            "outputs": [
                                {
                                    "referenceName": "ds_sftp_generico_con_cabecera_csv_prd",
                                    "type": "DatasetReference",
                                    "parameters": {
                                        "path": {
                                            "value": "@variables('vRuta')",
                                            "type": "Expression"
                                        },
                                        "file": {
                                            "value": "@variables('vArchivo')",
                                            "type": "Expression"
                                        },
                                        "delimitador": "|",
                                        "comillas": "\""
                                    }
                                }
                            ]
                        },
                        {
                            "name": "AsignarNombreArchivo_copy1",
                            "type": "SetVariable",
                            "dependsOn": [
                                {
                                    "activity": "AsignarPeriodo_copy1",
                                    "dependencyConditions": [
                                        "Completed"
                                    ]
                                }
                            ],
                            "policy": {
                                "secureOutput": false,
                                "secureInput": false
                            },
                            "userProperties": [],
                            "typeProperties": {
                                "variableName": "vArchivo",
                                "value": {
                                    "value": "@concat('Peajes_Offline_', substring(variables('vPeriodoActual'),0 , 4),substring(variables('vPeriodoActual'),5 , 2),'.csv')\n\n",
                                    "type": "Expression"
                                }
                            }
                        }
                    ]
                }
            },
            {
                "name": "cd_detalle_transacciones_copy1",
                "type": "Copy",
                "state": "Inactive",
                "onInactiveMarkAs": "Succeeded",
                "dependsOn": [],
                "policy": {
                    "timeout": "7.00:00:00",
                    "retry": 0,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "source": {
                        "type": "SqlDWSource",
                        "sqlReaderQuery": {
                            "value": "EXEC STAGE.sp_load_itc_t_transaction '20250101', '20250301'",
                            "type": "Expression"
                        },
                        "queryTimeout": "05:00:00",
                        "partitionOption": "None"
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
                        "referenceName": "Syn_Table_As400",
                        "type": "DatasetReference",
                        "parameters": {
                            "Tabla": "detalle_transacciones_hist",
                            "Esquema": "dwh"
                        }
                    }
                ],
                "outputs": [
                    {
                        "referenceName": "ds_adls_ingesta_parquet",
                        "type": "DatasetReference",
                        "parameters": {
                            "Ruta": "intercorp/trx",
                            "Nombre": "202508.parquet"
                        }
                    }
                ]
            },
            {
                "name": "Copy data MCFU110",
                "type": "Copy",
                "state": "Inactive",
                "onInactiveMarkAs": "Succeeded",
                "dependsOn": [],
                "policy": {
                    "timeout": "7.00:00:00",
                    "retry": 3,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "source": {
                        "type": "Db2Source",
                        "query": {
                            "value": "SELECT\nFECPRO, \ncount(*)\nFROM LIBPMPDATA.MCFS0399\ngroup by FECPRO\norder by fecpro desc",
                            "type": "Expression"
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
                    "parallelCopies": 3,
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
                        "referenceName": "db2_as400_tablas",
                        "type": "DatasetReference"
                    }
                ],
                "outputs": [
                    {
                        "referenceName": "Adls_as400_cubo_parqt",
                        "type": "DatasetReference",
                        "parameters": {
                            "Ruta": "As-400/Transaccional/SWFT425",
                            "Nombre": "SWFT425_251201.snappy"
                        }
                    }
                ]
            },
            {
                "name": "Copy data MCFU110_copy1",
                "type": "Copy",
                "state": "Inactive",
                "onInactiveMarkAs": "Succeeded",
                "dependsOn": [],
                "policy": {
                    "timeout": "7.00:00:00",
                    "retry": 3,
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
                        "tableOption": "autoCreate",
                        "disableMetricsCollection": false
                    },
                    "enableStaging": false,
                    "parallelCopies": 2,
                    "translator": {
                        "type": "TabularTranslator",
                        "mappings": [
                            {
                                "source": {
                                    "name": "FXOPER",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "FXOPER",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "FXTARJ",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "FXTARJ",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "FXDE07",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "FXDE07",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "FXDE11",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "FXDE11",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "FXDE04",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "FXDE04",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "FXDE49",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "FXDE49",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "FXTICA",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "FXTICA",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "FXAMON",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "FXAMON",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "FXNREF",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "FXNREF",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "FXIMDC",
                                    "type": "Decimal",
                                    "physicalType": "DECIMAL",
                                    "scale": 18,
                                    "precision": 38
                                },
                                "sink": {
                                    "name": "FXIMDC",
                                    "type": "Decimal",
                                    "physicalType": "decimal"
                                }
                            },
                            {
                                "source": {
                                    "name": "FXMODC",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "FXMODC",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "FXEXDC",
                                    "type": "Decimal",
                                    "physicalType": "DECIMAL",
                                    "scale": 18,
                                    "precision": 38
                                },
                                "sink": {
                                    "name": "FXEXDC",
                                    "type": "Decimal",
                                    "physicalType": "decimal"
                                }
                            },
                            {
                                "source": {
                                    "name": "FXRMDC",
                                    "type": "Decimal",
                                    "physicalType": "DECIMAL",
                                    "scale": 18,
                                    "precision": 38
                                },
                                "sink": {
                                    "name": "FXRMDC",
                                    "type": "Decimal",
                                    "physicalType": "decimal"
                                }
                            }
                        ],
                        "typeConversion": true,
                        "typeConversionSettings": {
                            "allowDataTruncation": true,
                            "treatBooleanAsNumber": false
                        }
                    }
                },
                "inputs": [
                    {
                        "referenceName": "Adls_as400_cubo_parqt",
                        "type": "DatasetReference",
                        "parameters": {
                            "Ruta": {
                                "value": "As-400/Transaccional/SWFT425",
                                "type": "Expression"
                            },
                            "Nombre": {
                                "value": "SWFT425_251201.snappy",
                                "type": "Expression"
                            }
                        }
                    }
                ],
                "outputs": [
                    {
                        "referenceName": "Syn_Table_As400",
                        "type": "DatasetReference",
                        "parameters": {
                            "Tabla": "SWFT425",
                            "Esquema": "RAW"
                        }
                    }
                ]
            },
            {
                "name": "Create_MCFT005E",
                "description": "Se consultas las tablas MCFS068, MCFS005AL, ENFS068 (devoluciones AX) del delta para completar periodos",
                "type": "SqlServerStoredProcedure",
                "state": "Inactive",
                "onInactiveMarkAs": "Succeeded",
                "dependsOn": [],
                "policy": {
                    "timeout": "0.12:00:00",
                    "retry": 0,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "storedProcedureName": "stage.sp_load_itc_t_transaction",
                    "storedProcedureParameters": {
                        "FechaProcesoInicio": {
                            "value": "20260101",
                            "type": "String"
                        },
                        "FechaProcesoFin": {
                            "value": "20260131",
                            "type": "String"
                        }
                    }
                },
                "linkedServiceName": {
                    "referenceName": "ProdASynapseAnalytics",
                    "type": "LinkedServiceReference"
                }
            },
            {
                "name": "Transacciones_Izipay",
                "type": "ExecutePipeline",
                "state": "Inactive",
                "onInactiveMarkAs": "Succeeded",
                "dependsOn": [
                    {
                        "activity": "Create_MCFT005E",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    }
                ],
                "policy": {
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "pipeline": {
                        "referenceName": "insert_transacciones_izipay",
                        "type": "PipelineReference"
                    },
                    "waitOnCompletion": true
                }
            },
            {
                "name": "Copy data SWFT425",
                "type": "Copy",
                "state": "Inactive",
                "onInactiveMarkAs": "Succeeded",
                "dependsOn": [],
                "policy": {
                    "timeout": "7.00:00:00",
                    "retry": 0,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "source": {
                        "type": "Db2Source",
                        "query": {
                            "value": "select pefabo, count(*) conteo, sum(penet3) monto_soles, sum(pen2us) monto_dolares\nfrom libmcp.mcfs044tpg\ngroup by pefabo",
                            "type": "Expression"
                        }
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
                    "parallelCopies": 4,
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
                        "referenceName": "db2_as400_tablas",
                        "type": "DatasetReference"
                    }
                ],
                "outputs": [
                    {
                        "referenceName": "ds_container_generico_con_cabecera_csv_prd",
                        "type": "DatasetReference",
                        "parameters": {
                            "path": "mc2200",
                            "file": "conteo_mcfs044tpg.csv",
                            "delimitador": "|",
                            "comillas": "\"",
                            "container": "tempdata"
                        }
                    }
                ]
            },
            {
                "name": "Copy SWFT425 to Synapse",
                "type": "Copy",
                "state": "Inactive",
                "onInactiveMarkAs": "Succeeded",
                "dependsOn": [],
                "policy": {
                    "timeout": "7.00:00:00",
                    "retry": 3,
                    "retryIntervalInSeconds": 180,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "source": {
                        "type": "ParquetSource",
                        "storeSettings": {
                            "type": "AzureBlobFSReadSettings",
                            "recursive": false,
                            "enablePartitionDiscovery": false
                        },
                        "formatSettings": {
                            "type": "ParquetReadSettings"
                        }
                    },
                    "sink": {
                        "type": "SqlDWSink",
                        "preCopyScript": "truncate table [RAW].[SWFT425]",
                        "disableMetricsCollection": false
                    },
                    "enableStaging": false,
                    "parallelCopies": 2,
                    "translator": {
                        "type": "TabularTranslator",
                        "mappings": [
                            {
                                "source": {
                                    "name": "FXOPER",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "FXOPER",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "FXTARJ",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "FXTARJ",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "FXDE07",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "FXDE07",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "FXDE11",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "FXDE11",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "FXDE04",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "FXDE04",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "FXDE49",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "FXDE49",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "FXTICA",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "FXTICA",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "FXAMON",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "FXAMON",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "FXNREF",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "FXNREF",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "FXIMDC",
                                    "type": "Decimal",
                                    "physicalType": "DECIMAL",
                                    "scale": 18,
                                    "precision": 38
                                },
                                "sink": {
                                    "name": "FXIMDC",
                                    "type": "Decimal",
                                    "physicalType": "decimal",
                                    "scale": 18,
                                    "precision": 38
                                }
                            },
                            {
                                "source": {
                                    "name": "FXMODC",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "FXMODC",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "FXEXDC",
                                    "type": "Decimal",
                                    "physicalType": "DECIMAL",
                                    "scale": 18,
                                    "precision": 38
                                },
                                "sink": {
                                    "name": "FXEXDC",
                                    "type": "Decimal",
                                    "physicalType": "decimal",
                                    "scale": 18,
                                    "precision": 38
                                }
                            },
                            {
                                "source": {
                                    "name": "FXRMDC",
                                    "type": "Decimal",
                                    "physicalType": "DECIMAL",
                                    "scale": 18,
                                    "precision": 38
                                },
                                "sink": {
                                    "name": "FXRMDC",
                                    "type": "Decimal",
                                    "physicalType": "decimal",
                                    "scale": 18,
                                    "precision": 38
                                }
                            },
                            {
                                "source": {
                                    "name": "DEPF21",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "DEPF21",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "DEPF22",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "DEPF22",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "DEPF23",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "DEPF23",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            }
                        ],
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
                            "path": "As-400/Maestros/SWFT425",
                            "file": "SWFT425.snappy",
                            "container": "ingesta"
                        }
                    }
                ],
                "outputs": [
                    {
                        "referenceName": "Syn_Table_As400",
                        "type": "DatasetReference",
                        "parameters": {
                            "Tabla": "SWFT425",
                            "Esquema": "RAW"
                        }
                    }
                ]
            },
            {
                "name": "cargar_csv_syn_copy1",
                "type": "Copy",
                "state": "Inactive",
                "onInactiveMarkAs": "Succeeded",
                "dependsOn": [],
                "policy": {
                    "timeout": "7.00:00:00",
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
                            "recursive": false,
                            "enablePartitionDiscovery": false
                        },
                        "formatSettings": {
                            "type": "ParquetReadSettings"
                        }
                    },
                    "sink": {
                        "type": "SqlDWSink",
                        "tableOption": "autoCreate",
                        "disableMetricsCollection": false
                    },
                    "enableStaging": false,
                    "translator": {
                        "type": "TabularTranslator",
                        "mappings": [
                            {
                                "source": {
                                    "name": "cTxMerchantId",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxMerchantId",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxTerminalNum",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxTerminalNum",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxTxnNumber",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxTxnNumber",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "fTxTxnDate",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "fTxTxnDate",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "hTxTxnHour",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "hTxTxnHour",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxCompany",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxCompany",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxStatus",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxStatus",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxSettleStatus",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxSettleStatus",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxBatchId",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxBatchId",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxType",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxType",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxForm",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxForm",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxResultId",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxResultId",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxResultExt",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxResultExt",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "nTxRRN",
                                    "type": "Decimal",
                                    "physicalType": "DECIMAL",
                                    "scale": 0,
                                    "precision": 12
                                },
                                "sink": {
                                    "name": "nTxRRN",
                                    "type": "Decimal",
                                    "physicalType": "decimal"
                                }
                            },
                            {
                                "source": {
                                    "name": "nTxAutorization",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "nTxAutorization",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxCurrency",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxCurrency",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "nTxAmount",
                                    "type": "Decimal",
                                    "physicalType": "DECIMAL",
                                    "scale": 2,
                                    "precision": 12
                                },
                                "sink": {
                                    "name": "nTxAmount",
                                    "type": "Decimal",
                                    "physicalType": "decimal"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxPaymentType",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxPaymentType",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxDiffPayType",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxDiffPayType",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "nTxDiffPayMonth",
                                    "type": "Decimal",
                                    "physicalType": "DECIMAL",
                                    "scale": 0,
                                    "precision": 2
                                },
                                "sink": {
                                    "name": "nTxDiffPayMonth",
                                    "type": "Decimal",
                                    "physicalType": "decimal"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxDiffPayMFree",
                                    "type": "Decimal",
                                    "physicalType": "DECIMAL",
                                    "scale": 0,
                                    "precision": 2
                                },
                                "sink": {
                                    "name": "cTxDiffPayMFree",
                                    "type": "Decimal",
                                    "physicalType": "decimal"
                                }
                            },
                            {
                                "source": {
                                    "name": "nTxCardNumber",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "nTxCardNumber",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "dTxSitCpyCompany",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "dTxSitCpyCompany",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxOrigTxnNumber",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxOrigTxnNumber",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "fTxOrigTxnDate",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "fTxOrigTxnDate",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "fTxSettlementDate",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "fTxSettlementDate",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxGroupId",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxGroupId",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxAcquirerId",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxAcquirerId",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxHost",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxHost",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxHostServ",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxHostServ",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxTerminalType",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxTerminalType",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "dTxAddData",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "dTxAddData",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxAccountType",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxAccountType",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxReadType",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxReadType",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "nTxIVA",
                                    "type": "Decimal",
                                    "physicalType": "DECIMAL",
                                    "scale": 2,
                                    "precision": 12
                                },
                                "sink": {
                                    "name": "nTxIVA",
                                    "type": "Decimal",
                                    "physicalType": "decimal"
                                }
                            },
                            {
                                "source": {
                                    "name": "nTxServicios",
                                    "type": "Decimal",
                                    "physicalType": "DECIMAL",
                                    "scale": 2,
                                    "precision": 12
                                },
                                "sink": {
                                    "name": "nTxServicios",
                                    "type": "Decimal",
                                    "physicalType": "decimal"
                                }
                            },
                            {
                                "source": {
                                    "name": "nTxPropina",
                                    "type": "Decimal",
                                    "physicalType": "DECIMAL",
                                    "scale": 2,
                                    "precision": 12
                                },
                                "sink": {
                                    "name": "nTxPropina",
                                    "type": "Decimal",
                                    "physicalType": "decimal"
                                }
                            },
                            {
                                "source": {
                                    "name": "nTxIntereses",
                                    "type": "Decimal",
                                    "physicalType": "DECIMAL",
                                    "scale": 2,
                                    "precision": 12
                                },
                                "sink": {
                                    "name": "nTxIntereses",
                                    "type": "Decimal",
                                    "physicalType": "decimal"
                                }
                            },
                            {
                                "source": {
                                    "name": "nTxMontoFijo",
                                    "type": "Decimal",
                                    "physicalType": "DECIMAL",
                                    "scale": 2,
                                    "precision": 12
                                },
                                "sink": {
                                    "name": "nTxMontoFijo",
                                    "type": "Decimal",
                                    "physicalType": "decimal"
                                }
                            },
                            {
                                "source": {
                                    "name": "nTxCargoAdic",
                                    "type": "Decimal",
                                    "physicalType": "DECIMAL",
                                    "scale": 2,
                                    "precision": 12
                                },
                                "sink": {
                                    "name": "nTxCargoAdic",
                                    "type": "Decimal",
                                    "physicalType": "decimal"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxCodProd1",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxCodProd1",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "nTxMontoProd1",
                                    "type": "Decimal",
                                    "physicalType": "DECIMAL",
                                    "scale": 2,
                                    "precision": 12
                                },
                                "sink": {
                                    "name": "nTxMontoProd1",
                                    "type": "Decimal",
                                    "physicalType": "decimal"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxCodProd2",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxCodProd2",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "nTxMontoProd2",
                                    "type": "Decimal",
                                    "physicalType": "DECIMAL",
                                    "scale": 2,
                                    "precision": 12
                                },
                                "sink": {
                                    "name": "nTxMontoProd2",
                                    "type": "Decimal",
                                    "physicalType": "decimal"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxCodProd3",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxCodProd3",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "nTxMontoProd3",
                                    "type": "Decimal",
                                    "physicalType": "DECIMAL",
                                    "scale": 2,
                                    "precision": 12
                                },
                                "sink": {
                                    "name": "nTxMontoProd3",
                                    "type": "Decimal",
                                    "physicalType": "decimal"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxCodProd4",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxCodProd4",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "nTxMontoProd4",
                                    "type": "Decimal",
                                    "physicalType": "DECIMAL",
                                    "scale": 2,
                                    "precision": 12
                                },
                                "sink": {
                                    "name": "nTxMontoProd4",
                                    "type": "Decimal",
                                    "physicalType": "decimal"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxCodProd5",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxCodProd5",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "nTxMontoProd5",
                                    "type": "Decimal",
                                    "physicalType": "DECIMAL",
                                    "scale": 2,
                                    "precision": 12
                                },
                                "sink": {
                                    "name": "nTxMontoProd5",
                                    "type": "Decimal",
                                    "physicalType": "decimal"
                                }
                            },
                            {
                                "source": {
                                    "name": "nTxCashBack",
                                    "type": "Decimal",
                                    "physicalType": "DECIMAL",
                                    "scale": 2,
                                    "precision": 12
                                },
                                "sink": {
                                    "name": "nTxCashBack",
                                    "type": "Decimal",
                                    "physicalType": "decimal"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxBusiness",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxBusiness",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxService",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxService",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxCodOperador",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxCodOperador",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxCreateUser",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxCreateUser",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "fTxCreateDate",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "fTxCreateDate",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "hTxCreateTime",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "hTxCreateTime",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxModifyUser",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxModifyUser",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "fTxModifyDate",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "fTxModifyDate",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "hTxModifyTime",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "hTxModifyTime",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "nTxGenCounter",
                                    "type": "Decimal",
                                    "physicalType": "DECIMAL",
                                    "scale": 0,
                                    "precision": 16
                                },
                                "sink": {
                                    "name": "nTxGenCounter",
                                    "type": "Decimal",
                                    "physicalType": "decimal"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxIdPropina",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxIdPropina",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxPropina",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxPropina",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxMozo",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxMozo",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "nTxAmountQuota",
                                    "type": "Decimal",
                                    "physicalType": "DECIMAL",
                                    "scale": 2,
                                    "precision": 12
                                },
                                "sink": {
                                    "name": "nTxAmountQuota",
                                    "type": "Decimal",
                                    "physicalType": "decimal"
                                }
                            },
                            {
                                "source": {
                                    "name": "fTxExpDateQuota",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "fTxExpDateQuota",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxCurrencyQuota",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxCurrencyQuota",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "fTxExpDateCard",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "fTxExpDateCard",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxPrintData",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxPrintData",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "ctxRUC",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "ctxRUC",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "ctxLiteral",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "ctxLiteral",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "nTxChangeType",
                                    "type": "Decimal",
                                    "physicalType": "DECIMAL",
                                    "scale": 4,
                                    "precision": 8
                                },
                                "sink": {
                                    "name": "nTxChangeType",
                                    "type": "Decimal",
                                    "physicalType": "decimal"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxMessageHost",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxMessageHost",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxTerminalSerial",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxTerminalSerial",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxTxnNumberAS",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxTxnNumberAS",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxAplicacion",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxAplicacion",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxCardSign",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxCardSign",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxPin",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxPin",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxNumOfCopies",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxNumOfCopies",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxExtornokey",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxExtornokey",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "nTxCardNumber2",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "nTxCardNumber2",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxAccountType2",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxAccountType2",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxTxnGroup",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxTxnGroup",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxTerminalMode",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxTerminalMode",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxMerchantChain",
                                    "type": "Int64",
                                    "physicalType": "INT64"
                                },
                                "sink": {
                                    "name": "cTxMerchantChain",
                                    "type": "Int64",
                                    "physicalType": "bigint"
                                }
                            },
                            {
                                "source": {
                                    "name": "nTxCardNumber3",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "nTxCardNumber3",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxCompanyLocal",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxCompanyLocal",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "nTxProcessingTime",
                                    "type": "Decimal",
                                    "physicalType": "DECIMAL",
                                    "scale": 0,
                                    "precision": 3
                                },
                                "sink": {
                                    "name": "nTxProcessingTime",
                                    "type": "Decimal",
                                    "physicalType": "decimal"
                                }
                            },
                            {
                                "source": {
                                    "name": "nTxConnectionTime",
                                    "type": "Decimal",
                                    "physicalType": "DECIMAL",
                                    "scale": 0,
                                    "precision": 3
                                },
                                "sink": {
                                    "name": "nTxConnectionTime",
                                    "type": "Decimal",
                                    "physicalType": "decimal"
                                }
                            },
                            {
                                "source": {
                                    "name": "nTxSavedAmount",
                                    "type": "Decimal",
                                    "physicalType": "DECIMAL",
                                    "scale": 2,
                                    "precision": 12
                                },
                                "sink": {
                                    "name": "nTxSavedAmount",
                                    "type": "Decimal",
                                    "physicalType": "decimal"
                                }
                            },
                            {
                                "source": {
                                    "name": "nTxDiscountPercentage",
                                    "type": "Decimal",
                                    "physicalType": "DECIMAL",
                                    "scale": 2,
                                    "precision": 12
                                },
                                "sink": {
                                    "name": "nTxDiscountPercentage",
                                    "type": "Decimal",
                                    "physicalType": "decimal"
                                }
                            },
                            {
                                "source": {
                                    "name": "fTxTxnDateHour",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "fTxTxnDateHour",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxflag_copiap",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxflag_copiap",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxClientName",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxClientName",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxTagsEmv",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxTagsEmv",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxFlagOnlineEmv",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxFlagOnlineEmv",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxAplLabelEmv",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxAplLabelEmv",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxCriptoDeclinaEmv",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxCriptoDeclinaEmv",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxCodProdPuntos",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxCodProdPuntos",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "hTxOrigTxnHour",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "hTxOrigTxnHour",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "nTxOrigAmount",
                                    "type": "Decimal",
                                    "physicalType": "DECIMAL",
                                    "scale": 2,
                                    "precision": 12
                                },
                                "sink": {
                                    "name": "nTxOrigAmount",
                                    "type": "Decimal",
                                    "physicalType": "decimal"
                                }
                            },
                            {
                                "source": {
                                    "name": "nTxCardNumberEnc",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "nTxCardNumberEnc",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "nTxPinVerificado",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "nTxPinVerificado",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "hTxConvInfo",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "hTxConvInfo",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "hTxPMenInfo",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "hTxPMenInfo",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "hTxPReqInfo",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "hTxPReqInfo",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "hTxIniValTermInfo",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "hTxIniValTermInfo",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "hTxRespValTermInfo",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "hTxRespValTermInfo",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "hTxPMenAplInfo",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "hTxPMenAplInfo",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "hTxPMenProc",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "hTxPMenProc",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "hTxObtieneRtraceProc",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "hTxObtieneRtraceProc",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "hTxRespRtraceProc",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "hTxRespRtraceProc",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "hTxEjecutaIniProc",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "hTxEjecutaIniProc",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "hTxRespEjecutaIniProc",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "hTxRespEjecutaIniProc",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "hTxEnviaReqIntH",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "hTxEnviaReqIntH",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "hTxRespIntH",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "hTxRespIntH",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "hTxGuardarTrx",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "hTxGuardarTrx",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxServerName",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxServerName",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxTraceUnique",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxTraceUnique",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxCurrencyDCC",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxCurrencyDCC",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "nTxAmountDCC",
                                    "type": "Decimal",
                                    "physicalType": "DECIMAL",
                                    "scale": 2,
                                    "precision": 12
                                },
                                "sink": {
                                    "name": "nTxAmountDCC",
                                    "type": "Decimal",
                                    "physicalType": "decimal"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxChangeTypeDCC",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxChangeTypeDCC",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxCodeDCC",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxCodeDCC",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "ctxFlagDCC",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "ctxFlagDCC",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxGlosaCurrencyDCC",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxGlosaCurrencyDCC",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "ctxExpoDCC",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "ctxExpoDCC",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "ctxGMAmountDCC",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "ctxGMAmountDCC",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxIdWallet",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxIdWallet",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxflagImpresion",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxflagImpresion",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "ctxFlagTrxOffline",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "ctxFlagTrxOffline",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "nTxOfflineAutorization",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "nTxOfflineAutorization",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxOfflineTraceUnique",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxOfflineTraceUnique",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxResponseCodeHost",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxResponseCodeHost",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxIdTurnoCaja",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxIdTurnoCaja",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "ctxAmountTipOFF",
                                    "type": "Decimal",
                                    "physicalType": "DECIMAL",
                                    "scale": 2,
                                    "precision": 12
                                },
                                "sink": {
                                    "name": "ctxAmountTipOFF",
                                    "type": "Decimal",
                                    "physicalType": "decimal"
                                }
                            },
                            {
                                "source": {
                                    "name": "cTxAidEmv",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cTxAidEmv",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "TAR_DIG",
                                    "type": "Int32",
                                    "physicalType": "INT32"
                                },
                                "sink": {
                                    "name": "TAR_DIG",
                                    "type": "Int32",
                                    "physicalType": "int"
                                }
                            }
                        ],
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
                            "path": "Mc_Center_Adq/Transaccional/tptransaction_log/2026/01",
                            "file": "tptransaction_log_20260129.parquet",
                            "container": "adls-ingesta"
                        }
                    }
                ],
                "outputs": [
                    {
                        "referenceName": "Syn_Table_As400",
                        "type": "DatasetReference",
                        "parameters": {
                            "Tabla": "Temporal_tp_transactionlog_a",
                            "Esquema": "RAW"
                        }
                    }
                ]
            },
            {
                "name": "Copy tpTransactionLog to adls",
                "type": "Copy",
                "state": "Inactive",
                "onInactiveMarkAs": "Succeeded",
                "dependsOn": [
                    {
                        "activity": "cargar_csv_syn_copy1",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    }
                ],
                "policy": {
                    "timeout": "7.00:00:00",
                    "retry": 3,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "source": {
                        "type": "SqlDWSource",
                        "sqlReaderQuery": "select * from RAW.Temporal_tp_transactionlog_a",
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
                    "parallelCopies": 4,
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
                        "referenceName": "AzureSynapseAnalyticsTable1",
                        "type": "DatasetReference"
                    }
                ],
                "outputs": [
                    {
                        "referenceName": "adls_tpTransactionLog_a",
                        "type": "DatasetReference",
                        "parameters": {
                            "Ruta": {
                                "value": "Mc_Center_SQL/Adquiriente/Transaccional/2026/01",
                                "type": "Expression"
                            },
                            "Archivo": {
                                "value": "tpTransactionLog_260129.csv",
                                "type": "Expression"
                            }
                        }
                    }
                ]
            },
            {
                "name": "Syn to Parquet",
                "type": "Copy",
                "state": "Inactive",
                "onInactiveMarkAs": "Succeeded",
                "dependsOn": [],
                "policy": {
                    "timeout": "7.00:00:00",
                    "retry": 0,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "source": {
                        "type": "SqlDWSource",
                        "sqlReaderQuery": "Select * from raw.dataentry_planeamiento_informacion_carteras",
                        "queryTimeout": "02:00:00",
                        "partitionOption": "None"
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
                    "parallelCopies": 4,
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
                        "referenceName": "AzureSynapseAnalyticsTable1",
                        "type": "DatasetReference"
                    }
                ],
                "outputs": [
                    {
                        "referenceName": "ds_adls_generico_parquet",
                        "type": "DatasetReference",
                        "parameters": {
                            "path": "GCP/Maestro/Planeamiento Informacion Carteras",
                            "file": "planeamiento_informacion_carteras.snappy",
                            "container": "adls-ingesta"
                        }
                    }
                ]
            },
            {
                "name": "Consultas AS400",
                "type": "Copy",
                "state": "Inactive",
                "onInactiveMarkAs": "Succeeded",
                "dependsOn": [],
                "policy": {
                    "timeout": "7.00:00:00",
                    "retry": 3,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "source": {
                        "type": "Db2Source",
                        "query": "SELECT * \nfrom PEDROG.MCFS044_A"
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
                    "parallelCopies": 3,
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
                        "referenceName": "db2_as400_tablas",
                        "type": "DatasetReference"
                    }
                ],
                "outputs": [
                    {
                        "referenceName": "ds_container_generico_con_cabecera_csv_prd",
                        "type": "DatasetReference",
                        "parameters": {
                            "path": "reporte",
                            "file": "conteo_pedrog2_mcfs068s.csv",
                            "delimitador": "|",
                            "comillas": "\"",
                            "container": "ingesta"
                        }
                    }
                ]
            },
            {
                "name": "Create_resumen_transacciones",
                "description": "Se inserta en la tabla resumen los resultados del día",
                "type": "SqlServerStoredProcedure",
                "state": "Inactive",
                "onInactiveMarkAs": "Succeeded",
                "dependsOn": [],
                "policy": {
                    "timeout": "0.12:00:00",
                    "retry": 0,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "storedProcedureName": "[DWH].[Create_resumen_transacciones_hist]",
                    "storedProcedureParameters": {
                        "date": {
                            "value": {
                                "value": "@concat('20260401')",
                                "type": "Expression"
                            },
                            "type": "String"
                        },
                        "datefin": {
                            "value": {
                                "value": "@concat('20260412')",
                                "type": "Expression"
                            },
                            "type": "String"
                        }
                    }
                },
                "linkedServiceName": {
                    "referenceName": "AzureSynapseAnalytics1",
                    "type": "LinkedServiceReference"
                }
            },
            {
                "name": "sap to csv",
                "type": "Copy",
                "state": "Inactive",
                "onInactiveMarkAs": "Succeeded",
                "dependsOn": [],
                "policy": {
                    "timeout": "7.00:00:00",
                    "retry": 0,
                    "retryIntervalInSeconds": 30,
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "source": {
                        "type": "SapHanaSource",
                        "query": {
                            "value": "select top 100 * from \"SBO_PMP_PRD\".\"LibroMayor\"",
                            "type": "Expression"
                        },
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
                        "referenceName": "ds_saphana_prd",
                        "type": "DatasetReference"
                    }
                ],
                "outputs": [
                    {
                        "referenceName": "ds_container_generico_con_cabecera_csv_prd",
                        "type": "DatasetReference",
                        "parameters": {
                            "path": "Reporte",
                            "file": "muestra_pmp_CL_View_SSNN.csv",
                            "delimitador": ";",
                            "comillas": "\"",
                            "container": "adls-ingesta"
                        }
                    }
                ]
            }
        ],
        "variables": {
            "vPeriodos": {
                "type": "Array",
                "defaultValue": [
                    "2024-01",
                    "2024-02",
                    "2024-03",
                    "2024-04",
                    "2024-05",
                    "2024-06",
                    "2024-07",
                    "2024-08",
                    "2024-09",
                    "2024-10",
                    "2024-11",
                    "2024-12",
                    "2025-01",
                    "2025-02",
                    "2025-03",
                    "2025-04",
                    "2025-05",
                    "2025-06",
                    "2025-07"
                ]
            },
            "vPeriodoActual": {
                "type": "String"
            },
            "vArchivo": {
                "type": "String"
            },
            "vRuta": {
                "type": "String",
                "defaultValue": "Finanzas/Peajes_Ofline"
            },
            "vRutaADLS": {
                "type": "String",
                "defaultValue": "reporte/peajes_offline"
            }
        },
        "folder": {
            "name": "MC2200 - Rodrigo Narvaez"
        },
        "annotations": [],
        "lastPublishTime": "2026-07-21T03:00:59Z"
    },
    "type": "Microsoft.DataFactory/factories/pipelines"
}