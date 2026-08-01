{
    "name": "pl_t_adls_detalle_abono_apa_prd01",
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
                        "value": "@formatDateTime(addDays(utcNow(), 0), 'yyyyMMdd')\n",
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
                        "value": "@substring(variables('var_fecha'), 0, 4)\n",
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
                        "value": "@substring(variables('var_fecha'), 4, 2)\n",
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
                        "value": "@substring(variables('var_fecha'), 6, 2)\n",
                        "type": "Expression"
                    }
                }
            },
            {
                "name": "var_archivo_t_abono_detalle",
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
                    },
                    {
                        "activity": "var_dia",
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
                    "variableName": "var_archivo_t_abono_detalle",
                    "value": {
                        "value": "@concat('t_abono_detalle_',variables('var_anio'),variables('var_mes'),variables('var_dia'),'.parquet')",
                        "type": "Expression"
                    }
                }
            },
            {
                "name": "ruta_CS_t_abono_detalle",
                "type": "SetVariable",
                "dependsOn": [
                    {
                        "activity": "var_archivo_t_abono_detalle",
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
                    "variableName": "var_rutaCS_t_abono_detalle",
                    "value": {
                        "value": "@concat('Data/APA/t_abono_detalle/',variables('var_anio'),'/',variables('var_mes'))",
                        "type": "Expression"
                    }
                }
            },
            {
                "name": "var_ruta_ADLS_t_abono_detalle",
                "type": "SetVariable",
                "dependsOn": [
                    {
                        "activity": "var_archivo_t_abono_detalle",
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
                    "variableName": "var_rutaADLS_t_abono_detalle",
                    "value": {
                        "value": "@concat('GCP/Transaccional/APA/t_abono_detalle/',variables('var_anio'),'/',variables('var_mes'))",
                        "type": "Expression"
                    }
                }
            },
            {
                "name": "Cloud_Storage_to_ADLS_t_abono_detalle",
                "type": "Copy",
                "dependsOn": [
                    {
                        "activity": "ruta_CS_t_abono_detalle",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    },
                    {
                        "activity": "var_ruta_ADLS_t_abono_detalle",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    }
                ],
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
                    "enableStaging": false
                },
                "inputs": [
                    {
                        "referenceName": "ds_gcp_cs_to_adls_parquet_prd",
                        "type": "DatasetReference",
                        "parameters": {
                            "par_bucket": "adls-reportes",
                            "par_ruta": {
                                "value": "Data/APA/t_abono_detalle/2026/04\n",
                                "type": "Expression"
                            },
                            "par_filename": {
                                "value": "t_abono_detalle_20260430.parquet",
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
                                "value": "GCP/Transaccional/APA/t_abono_detalle/2026/04",
                                "type": "Expression"
                            },
                            "file": {
                                "value": "t_abono_detalle_20260430.parquet",
                                "type": "Expression"
                            },
                            "container": "adls-ingesta"
                        }
                    }
                ]
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
            "var_rutaCS_abono_finanzas": {
                "type": "String"
            },
            "var_rutaCS_abono_planemiento": {
                "type": "String"
            },
            "var_rutaADLS_abono_finanzas": {
                "type": "String"
            },
            "var_rutaADLS_abono_planeamiento": {
                "type": "String"
            },
            "var_archivo_abono_finanzas": {
                "type": "String"
            },
            "var_archivo_abono_planeamiento": {
                "type": "String"
            },
            "var_rutaCS_t_abono_detalle": {
                "type": "String"
            },
            "var_rutaADLS_t_abono_detalle": {
                "type": "String"
            },
            "var_archivo_t_abono_detalle": {
                "type": "String"
            }
        },
        "folder": {
            "name": "adls_Ingesta/Bigquery/APA/master_financial"
        },
        "annotations": [],
        "lastPublishTime": "2026-05-05T14:58:54Z"
    },
    "type": "Microsoft.DataFactory/factories/pipelines"
}