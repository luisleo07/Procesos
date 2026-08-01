{
    "name": "pl_m_informacionclientes_sftp_synapse_prd",
    "properties": {
        "activities": [
            {
                "name": "Ruta_SFTP",
                "type": "SetVariable",
                "dependsOn": [],
                "policy": {
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "variableName": "vRutaSFTP",
                    "value": {
                        "value": "@concat('Prd/Ingesta/DataEntry/Planeamiento/Informacion_Carteras')\n",
                        "type": "Expression"
                    }
                }
            },
            {
                "name": "Ruta_ADLS",
                "type": "SetVariable",
                "dependsOn": [
                    {
                        "activity": "Ruta_SFTP",
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
                    "variableName": "vRutaADLS",
                    "value": {
                        "value": "@concat('DataEntry/Planeamiento/Informacion Carteras/')",
                        "type": "Expression"
                    }
                }
            },
            {
                "name": "Nombre_archivo",
                "type": "SetVariable",
                "dependsOn": [
                    {
                        "activity": "Ruta_ADLS",
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
                    "variableName": "vArchivoEntry",
                    "value": {
                        "value": "@concat(\n  'Informacion_cartera_',\n  formatDateTime(convertTimeZone(utcNow(), 'UTC', 'SA Pacific Standard Time'),'yyyyMM'),'.csv'\n)\n\n",
                        "type": "Expression"
                    }
                }
            },
            {
                "name": "Copy ADLS to Synapse",
                "type": "Copy",
                "dependsOn": [
                    {
                        "activity": "Copy SFTP to ADLS",
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
                        "type": "SqlDWSink",
                        "preCopyScript": "truncate table RAW.dataentry_planeamiento_informacion_carteras",
                        "disableMetricsCollection": false
                    },
                    "enableStaging": false,
                    "translator": {
                        "type": "TabularTranslator",
                        "mappings": [
                            {
                                "source": {
                                    "name": "nro_ruc",
                                    "type": "String",
                                    "physicalType": "String"
                                },
                                "sink": {
                                    "name": "nro_ruc",
                                    "type": "String",
                                    "physicalType": "varchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "segmento",
                                    "type": "String",
                                    "physicalType": "String"
                                },
                                "sink": {
                                    "name": "segmento",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "grupo_economico",
                                    "type": "String",
                                    "physicalType": "String"
                                },
                                "sink": {
                                    "name": "grupo_economico",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "ubicacion_cliente",
                                    "type": "String",
                                    "physicalType": "String"
                                },
                                "sink": {
                                    "name": "ubicacion_cliente",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "departamento_cliente",
                                    "type": "String",
                                    "physicalType": "String"
                                },
                                "sink": {
                                    "name": "departamento_cliente",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "kam",
                                    "type": "String",
                                    "physicalType": "String"
                                },
                                "sink": {
                                    "name": "kam",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "tipo_kam",
                                    "type": "String",
                                    "physicalType": "String"
                                },
                                "sink": {
                                    "name": "tipo_kam",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "head",
                                    "type": "String",
                                    "physicalType": "String"
                                },
                                "sink": {
                                    "name": "head",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "Oficina",
                                    "type": "String",
                                    "physicalType": "String"
                                },
                                "sink": {
                                    "name": "oficina",
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
                        "referenceName": "ds_sdls_generico_con_cabecera_csv_prd",
                        "type": "DatasetReference",
                        "parameters": {
                            "path": {
                                "value": "@variables('vRutaADLS')",
                                "type": "Expression"
                            },
                            "file": {
                                "value": "@variables('vArchivoEntry')",
                                "type": "Expression"
                            },
                            "delimitador": ";",
                            "comillas": "\""
                        }
                    }
                ],
                "outputs": [
                    {
                        "referenceName": "Syn_Table_As400",
                        "type": "DatasetReference",
                        "parameters": {
                            "Tabla": "dataentry_planeamiento_informacion_carteras",
                            "Esquema": "RAW"
                        }
                    }
                ]
            },
            {
                "name": "Copy SFTP to ADLS",
                "type": "Copy",
                "dependsOn": [
                    {
                        "activity": "Nombre_archivo",
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
                            "type": "SftpReadSettings",
                            "recursive": true,
                            "enablePartitionDiscovery": false,
                            "disableChunking": false
                        },
                        "formatSettings": {
                            "type": "DelimitedTextReadSettings"
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
                        "referenceName": "ds_sftp_generico_con_cabecera_csv_prd",
                        "type": "DatasetReference",
                        "parameters": {
                            "path": {
                                "value": "@variables('vRutaSFTP')",
                                "type": "Expression"
                            },
                            "file": {
                                "value": "@variables('vArchivoEntry')",
                                "type": "Expression"
                            },
                            "delimitador": ";",
                            "comillas": "\""
                        }
                    }
                ],
                "outputs": [
                    {
                        "referenceName": "ds_sdls_generico_con_cabecera_csv_prd",
                        "type": "DatasetReference",
                        "parameters": {
                            "path": {
                                "value": "@variables('vRutaADLS')",
                                "type": "Expression"
                            },
                            "file": {
                                "value": "@variables('vArchivoEntry')",
                                "type": "Expression"
                            },
                            "delimitador": ";",
                            "comillas": "\""
                        }
                    }
                ]
            }
        ],
        "variables": {
            "vRutaSFTP": {
                "type": "String"
            },
            "vRutaADLS": {
                "type": "String"
            },
            "vArchivoEntry": {
                "type": "String"
            }
        },
        "folder": {
            "name": "adls_Ingesta/DataEntry/Planeamiento"
        },
        "annotations": [],
        "lastPublishTime": "2026-05-22T16:19:25Z"
    },
    "type": "Microsoft.DataFactory/factories/pipelines"
}