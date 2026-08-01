{
    "name": "pl_t_adls_cargablacklist_prd01",
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
                        "value": "@formatDateTime(convertTimeZone(addDays(utcNow(),0),'UTC','SA Pacific Standard Time'), 'yyyyMMdd')",
                        "type": "Expression"
                    }
                }
            },
            {
                "name": "var_ruta_csv_input",
                "type": "SetVariable",
                "dependsOn": [
                    {
                        "activity": "var_archivo",
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
                    "variableName": "ruta_sftp",
                    "value": {
                        "value": "@concat('Prd\\Ingesta\\DataEntry\\Riesgo y Cumplimiento\\Blacklist')",
                        "type": "Expression"
                    }
                }
            },
            {
                "name": "copiar_csv_to_adls",
                "type": "Copy",
                "dependsOn": [
                    {
                        "activity": "var_ruta_ADLS",
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
                                "value": "@variables('ruta_sftp')",
                                "type": "Expression"
                            },
                            "file": {
                                "value": "@variables('var_archivo')",
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
                                "value": "@variables('var_ruta_ADLS')",
                                "type": "Expression"
                            },
                            "file": "blacklist.parquet",
                            "container": "adls-ingesta"
                        }
                    }
                ]
            },
            {
                "name": "var_ruta_ADLS",
                "type": "SetVariable",
                "dependsOn": [
                    {
                        "activity": "var_ruta_csv_input",
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
                    "variableName": "var_ruta_ADLS",
                    "value": {
                        "value": "@concat('DataEntry/Riesgo Operativo y Cumplimiento/Blacklist')",
                        "type": "Expression"
                    }
                }
            },
            {
                "name": "var_archivo",
                "type": "SetVariable",
                "dependsOn": [
                    {
                        "activity": "var_fecha",
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
                    "variableName": "var_archivo",
                    "value": {
                        "value": "@concat(substring(variables('var_fecha'),6 ,2),substring(variables('var_fecha'),4 ,2),substring(variables('var_fecha'),0 ,4),'_FTP_MC_LISTANEGRA_PMP_VISA.csv')",
                        "type": "Expression"
                    }
                }
            }
        ],
        "variables": {
            "var_fecha": {
                "type": "String"
            },
            "var_ruta_excel_input": {
                "type": "String"
            },
            "var_ruta_ADLS": {
                "type": "String"
            },
            "ruta_sftp": {
                "type": "String"
            },
            "var_archivo": {
                "type": "String"
            }
        },
        "folder": {
            "name": "adls_reportes/Riesgo Operativo y Cumplimiento/Cruce Blacklist"
        },
        "annotations": [],
        "lastPublishTime": "2026-06-15T15:48:19Z"
    },
    "type": "Microsoft.DataFactory/factories/pipelines"
}