{
    "name": "pl_t_scoring_bases_cs_to_sftp_prd",
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
                "name": "var_ruta_gcp",
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
                    "variableName": "var_ruta_gcp",
                    "value": {
                        "value": "@concat('Riesgo_y_Cumplimiento/',substring(variables('var_fecha'),0,4),'/',substring(variables('var_fecha'),4,2))",
                        "type": "Expression"
                    }
                }
            },
            {
                "name": "var_ruta_sftp",
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
                    "variableName": "var_ruta_sftp",
                    "value": {
                        "value": "@concat('Prd/Reportes/Riesgo y Cumplimiento/Reporte Scoring')",
                        "type": "Expression"
                    }
                }
            },
            {
                "name": "var_nombres",
                "type": "SetVariable",
                "dependsOn": [
                    {
                        "activity": "var_ruta_sftp",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    },
                    {
                        "activity": "var_ruta_gcp",
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
                    "variableName": "var_archivos",
                    "value": {
                        "value": "@createArray(\n  concat('Scoring_de_Riesgos_Persona_Natural_', variables('var_fecha'), '.csv.gz'),\n  concat('Scoring_de_Riesgos_Persona_Juridica_', variables('var_fecha'), '.csv.gz')\n)",
                        "type": "Expression"
                    }
                }
            },
            {
                "name": "ForEach Archivo",
                "type": "ForEach",
                "dependsOn": [
                    {
                        "activity": "var_nombres",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    }
                ],
                "userProperties": [],
                "typeProperties": {
                    "items": {
                        "value": "@variables('var_archivos')",
                        "type": "Expression"
                    },
                    "isSequential": false,
                    "activities": [
                        {
                            "name": "copiar_gcp_a_sftp",
                            "type": "Copy",
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
                                    "referenceName": "ds_gcp_csv_generico_prd01",
                                    "type": "DatasetReference",
                                    "parameters": {
                                        "par_bucket": "adls-reportes",
                                        "par_ruta": {
                                            "value": "@variables('var_ruta_gcp')",
                                            "type": "Expression"
                                        },
                                        "par_archivo": {
                                            "value": "@item()",
                                            "type": "Expression"
                                        },
                                        "par_delimitador": ";",
                                        "par_comillas": "\""
                                    }
                                }
                            ],
                            "outputs": [
                                {
                                    "referenceName": "ds_sftp_generico_con_cabecera_csv_prd",
                                    "type": "DatasetReference",
                                    "parameters": {
                                        "path": {
                                            "value": "@variables('var_ruta_sftp')",
                                            "type": "Expression"
                                        },
                                        "file": {
                                            "value": "@item()",
                                            "type": "Expression"
                                        },
                                        "delimitador": ";",
                                        "comillas": "\""
                                    }
                                }
                            ]
                        }
                    ]
                }
            }
        ],
        "variables": {
            "var_fecha": {
                "type": "String"
            },
            "var_ruta_gcp": {
                "type": "String"
            },
            "var_ruta_sftp": {
                "type": "String"
            },
            "var_archivos": {
                "type": "Array"
            }
        },
        "folder": {
            "name": "adls_reportes/Riesgo Operativo y Cumplimiento/Scoring"
        },
        "annotations": [],
        "lastPublishTime": "2026-06-23T21:59:23Z"
    },
    "type": "Microsoft.DataFactory/factories/pipelines"
}