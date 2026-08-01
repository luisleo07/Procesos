{
    "name": "pl_m_basero_sftp_to_adls_prd",
    "properties": {
        "activities": [
            {
                "name": "Ruta SFTP",
                "type": "SetVariable",
                "dependsOn": [
                    {
                        "activity": "var_anio",
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
                    "variableName": "vRutaSFTP",
                    "value": {
                        "value": "@concat('Prd/Ingesta/DataEntry/Riesgo y Cumplimiento/Lista RO')",
                        "type": "Expression"
                    }
                }
            },
            {
                "name": "Ruta ADLS_Reporte",
                "type": "SetVariable",
                "dependsOn": [
                    {
                        "activity": "Archivo Reporte SFTP",
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
                        "value": "@concat('DataEntry/Riesgo Operativo y Cumplimiento/Maestro/Lista_RO')",
                        "type": "Expression"
                    }
                }
            },
            {
                "name": "Archivo Reporte SFTP",
                "type": "SetVariable",
                "dependsOn": [
                    {
                        "activity": "Ruta SFTP",
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
                        "value": "@concat(\n  'base_ro_nombres_fraudulentos.csv'\n)",
                        "type": "Expression"
                    }
                }
            },
            {
                "name": "Copy SFTP to ADLS",
                "type": "Copy",
                "dependsOn": [
                    {
                        "activity": "Archivo ADLS",
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
                            "delimitador": ",",
                            "comillas": "\""
                        }
                    }
                ],
                "outputs": [
                    {
                        "referenceName": "ds_adls_generico_parquet",
                        "type": "DatasetReference",
                        "parameters": {
                            "path": {
                                "value": "@variables('vRutaADLS')",
                                "type": "Expression"
                            },
                            "file": {
                                "value": "@variables('vArchivoADLS')",
                                "type": "Expression"
                            },
                            "container": "adls-ingesta"
                        }
                    }
                ]
            },
            {
                "name": "Archivo ADLS",
                "type": "SetVariable",
                "dependsOn": [
                    {
                        "activity": "Ruta ADLS_Reporte",
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
                    "variableName": "vArchivoADLS",
                    "value": {
                        "value": "@concat(\n  'base_ro_nombres_fraudulentos.parquet'\n)",
                        "type": "Expression"
                    }
                }
            },
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
                    "variableName": "vFecha",
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
                    "variableName": "vAnio",
                    "value": {
                        "value": "@substring(variables('vFecha'),0,4)",
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
                    "variableName": "vMes",
                    "value": {
                        "value": "@substring(variables('vFecha'),4,2)",
                        "type": "Expression"
                    }
                }
            },
            {
                "name": "Ruta ADLS_Reporte_csv",
                "type": "SetVariable",
                "dependsOn": [
                    {
                        "activity": "Archivo Reporte SFTP",
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
                    "variableName": "vRutaADLS_CSV",
                    "value": {
                        "value": "@concat('DataEntry/Riesgo Operativo y Cumplimiento/Maestro/Lista_RO/', variables('vAnio'), '/', variables('vMes'))",
                        "type": "Expression"
                    }
                }
            },
            {
                "name": "Copy SFTP to ADLS_csv",
                "type": "Copy",
                "dependsOn": [
                    {
                        "activity": "Archivo ADLS_csv",
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
                            "delimitador": ",",
                            "comillas": "\""
                        }
                    }
                ],
                "outputs": [
                    {
                        "referenceName": "ds_container_generico_con_cabecera_csv_prd",
                        "type": "DatasetReference",
                        "parameters": {
                            "path": {
                                "value": "@variables('vRutaADLS_CSV')",
                                "type": "Expression"
                            },
                            "file": {
                                "value": "@variables('vArchivoADLS_CSV')",
                                "type": "Expression"
                            },
                            "delimitador": ",",
                            "comillas": "\"",
                            "container": "adls-ingesta"
                        }
                    }
                ]
            },
            {
                "name": "Archivo ADLS_csv",
                "type": "SetVariable",
                "dependsOn": [
                    {
                        "activity": "Ruta ADLS_Reporte_csv",
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
                    "variableName": "vArchivoADLS_CSV",
                    "value": {
                        "value": "@concat('base_ro_nombres_fraudulentos_', variables('vFecha'), '.csv')",
                        "type": "Expression"
                    }
                }
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
            },
            "vArchivoADLS": {
                "type": "String"
            },
            "vFecha": {
                "type": "String"
            },
            "vAnio": {
                "type": "String"
            },
            "vMes": {
                "type": "String"
            },
            "vRutaADLS_CSV": {
                "type": "String"
            },
            "vArchivoADLS_CSV": {
                "type": "String"
            }
        },
        "folder": {
            "name": "adls_Ingesta/DataEntry/Riesgo Operativo y Cumplimiento/Base RO nombres comerciales"
        },
        "annotations": [],
        "lastPublishTime": "2026-06-22T22:41:02Z"
    },
    "type": "Microsoft.DataFactory/factories/pipelines"
}