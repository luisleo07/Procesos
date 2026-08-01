{
    "name": "pl_t_cs_desafiliaciones_operaciones_prd01",
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
                        "value": "@formatDateTime(addDays(utcNow(), 0), 'yyyyMMdd')",
                        "type": "Expression"
                    }
                }
            },
            {
                "name": "var_cs",
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
                    "variableName": "var_ruta_cs",
                    "value": {
                        "value": "@concat('Operaciones/Desafiliaciones/',substring(variables('var_fecha'),0,4),'/',substring(variables('var_fecha'),4,2))\n",
                        "type": "Expression"
                    }
                }
            },
            {
                "name": "copiar_reporte_adls",
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
                            "type": "GoogleCloudStorageReadSettings",
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
                        "referenceName": "ds_gcp_csv_generico_prd01",
                        "type": "DatasetReference",
                        "parameters": {
                            "par_bucket": "adls-reportes",
                            "par_ruta": {
                                "value": "@variables('var_ruta_cs')",
                                "type": "Expression"
                            },
                            "par_archivo": {
                                "value": "@variables('var_archivo')",
                                "type": "Expression"
                            },
                            "par_delimitador": ";",
                            "par_comillas": "\""
                        }
                    }
                ],
                "outputs": [
                    {
                        "referenceName": "ds_container_generico_con_cabecera_csv_prd",
                        "type": "DatasetReference",
                        "parameters": {
                            "path": {
                                "value": "@variables('var_ruta_ADLS')",
                                "type": "Expression"
                            },
                            "file": {
                                "value": "@variables('var_archivo')",
                                "type": "Expression"
                            },
                            "delimitador": ";",
                            "comillas": "\"",
                            "container": "adls-reportes"
                        }
                    }
                ]
            },
            {
                "name": "var_ruta_ADLS",
                "type": "SetVariable",
                "dependsOn": [
                    {
                        "activity": "var_cs",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    },
                    {
                        "activity": "var_sftp",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    },
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
                    "variableName": "var_ruta_ADLS",
                    "value": {
                        "value": "@concat('Operaciones/Desafiliaciones/',substring(variables('var_fecha'),0,4),'/',substring(variables('var_fecha'),4,2))",
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
                    "variableName": "var_archivo",
                    "value": {
                        "value": "@concat('Desafiliaciones_',variables('var_fecha'),'.csv')",
                        "type": "Expression"
                    }
                }
            },
            {
                "name": "var_sftp",
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
                    "variableName": "var_ruta_sftp_output",
                    "value": {
                        "value": "@concat('Prd/Reportes/Operaciones/Desafiliaciones')\n",
                        "type": "Expression"
                    }
                }
            },
            {
                "name": "copiar_reporte_sftp",
                "type": "Copy",
                "dependsOn": [
                    {
                        "activity": "copiar_reporte_adls",
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
                                "value": "@variables('var_ruta_ADLS')",
                                "type": "Expression"
                            },
                            "file": {
                                "value": "@variables('var_archivo')",
                                "type": "Expression"
                            },
                            "delimitador": ";",
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
                                "value": "@variables('var_ruta_sftp_output')",
                                "type": "Expression"
                            },
                            "file": {
                                "value": "@variables('var_archivo')",
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
            "var_fecha": {
                "type": "String"
            },
            "var_ruta_cs": {
                "type": "String"
            },
            "var_ruta_ADLS": {
                "type": "String"
            },
            "var_ruta_sftp_output": {
                "type": "String"
            },
            "var_archivo": {
                "type": "String"
            }
        },
        "folder": {
            "name": "adls_reportes/Operaciones/Desafiliaciones MC"
        },
        "annotations": [],
        "lastPublishTime": "2026-06-12T20:43:36Z"
    },
    "type": "Microsoft.DataFactory/factories/pipelines"
}