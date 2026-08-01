{
    "name": "pl_t_alerta_vencimiento_vistas_cs_adls_prd",
    "properties": {
        "activities": [
            {
                "name": "var_archivo",
                "type": "SetVariable",
                "dependsOn": [],
                "policy": {
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "variableName": "var_archivo",
                    "value": {
                        "value": "alerta_vencimiento_vistas.csv",
                        "type": "Expression"
                    }
                }
            },
            {
                "name": "var_ruta_origen",
                "type": "SetVariable",
                "dependsOn": [],
                "policy": {
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "variableName": "var_ruta_origen",
                    "value": {
                        "value": "Data/Vencimiento_Vistas",
                        "type": "Expression"
                    }
                }
            },
            {
                "name": "var_ruta_destino",
                "type": "SetVariable",
                "dependsOn": [],
                "policy": {
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "variableName": "var_ruta_destino",
                    "value": {
                        "value": "DataEntry/Data/Alertas vencimiento vistas/alerta_vencimiento_vistas",
                        "type": "Expression"
                    }
                }
            },
            {
                "name": "copiar_reporte_adls",
                "type": "Copy",
                "dependsOn": [
                    {
                        "activity": "var_archivo",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    },
                    {
                        "activity": "var_ruta_origen",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    },
                    {
                        "activity": "var_ruta_destino",
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
                                "value": "@variables('var_ruta_origen')",
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
                                "value": "@variables('var_ruta_destino')",
                                "type": "Expression"
                            },
                            "file": {
                                "value": "@variables('var_archivo')",
                                "type": "Expression"
                            },
                            "delimitador": ";",
                            "comillas": "\"",
                            "container": "adls-ingesta"
                        }
                    }
                ]
            }
        ],
        "variables": {
            "var_archivo": {
                "type": "String"
            },
            "var_ruta_origen": {
                "type": "String"
            },
            "var_ruta_destino": {
                "type": "String"
            }
        },
        "folder": {
            "name": "adls_reportes/Data/Alertas Vencimiento Vistas GCP"
        },
        "annotations": [],
        "lastPublishTime": "2026-07-13T17:29:05Z"
    },
    "type": "Microsoft.DataFactory/factories/pipelines"
}