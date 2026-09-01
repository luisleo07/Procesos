{
    "name": "pl_t_scoring_listas_sftp_to_adls_prd",
    "properties": {
        "activities": [
            {
                "name": "Lista Archivos",
                "type": "SetVariable",
                "dependsOn": [],
                "policy": {
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "variableName": "vArchivos",
                    "value": {
                        "value": "@createArray('Lista MCC GAR SBS.csv','Lista Pariente PEP.csv','Lista PEP.csv','Lista Restrictiva.csv','Lista ZG Riesgo.csv')",
                        "type": "Expression"
                    }
                }
            },
            {
                "name": "ForEach Archivo",
                "type": "ForEach",
                "dependsOn": [
                    {
                        "activity": "Lista Archivos",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    }
                ],
                "userProperties": [],
                "typeProperties": {
                    "items": {
                        "value": "@variables('vArchivos')",
                        "type": "Expression"
                    },
                    "isSequential": false,
                    "activities": [
                        {
                            "name": "Copy SFTP to ADLS",
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
                                    "referenceName": "ds_sftp_generico_con_cabecera_csv_prd",
                                    "type": "DatasetReference",
                                    "parameters": {
                                        "path": {
                                            "value": "Prd/Ingesta/DataEntry/Riesgo y Cumplimiento/Scoring Clientes",
                                            "type": "Expression"
                                        },
                                        "file": {
                                            "value": "@item()",
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
                                            "value": "DataEntry/Riesgo Opertativo y Cumplimiento/Scoring/",
                                            "type": "Expression"
                                        },
                                        "file": {
                                            "value": "@item()",
                                            "type": "Expression"
                                        },
                                        "delimitador": ",",
                                        "comillas": "\"",
                                        "container": "adls-ingesta"
                                    }
                                }
                            ]
                        }
                    ]
                }
            }
        ],
        "variables": {
            "vArchivos": {
                "type": "Array"
            }
        },
        "folder": {
            "name": "adls_reportes/Riesgo Operativo y Cumplimiento/Scoring"
        },
        "annotations": [],
        "lastPublishTime": "2026-06-23T22:00:42Z"
    },
    "type": "Microsoft.DataFactory/factories/pipelines"
}