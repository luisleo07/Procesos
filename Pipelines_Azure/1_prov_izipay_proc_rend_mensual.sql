{
    "name": "1_prov_izipay_proc_rend_mensual",
    "properties": {
        "activities": [
            {
                "name": "Periodo",
                "type": "Lookup",
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
                        "type": "SqlDWSource",
                        "sqlReaderQuery": "SELECT CONVERT(VARCHAR(8),DATEADD(DD,-4,DATEADD(HH,-5,GETDATE())),112) as fecha\n",
                        "queryTimeout": "02:00:00",
                        "partitionOption": "None"
                    },
                    "dataset": {
                        "referenceName": "AzureSynapseAnalyticsTable2",
                        "type": "DatasetReference"
                    }
                }
            },
            {
                "name": "SP_PROV_IZIPAY_PROC_REND_MENSUAL",
                "type": "SqlServerStoredProcedure",
                "dependsOn": [
                    {
                        "activity": "Archivo",
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
                    "storedProcedureName": "DWH.SP_LOAD_PROV_IZIPAY_PROC_REND_MENSUAL",
                    "storedProcedureParameters": {
                        "PeriodoProceso": {
                            "value": {
                                "value": "@substring(activity('Periodo').output.firstRow.fecha,0,6)",
                                "type": "Expression"
                            },
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
                "name": "Ruta",
                "type": "SetVariable",
                "dependsOn": [
                    {
                        "activity": "Periodo",
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
                    "variableName": "v_ruta",
                    "value": {
                        "value": "@concat('BCRP/PROC_REND/'\n,substring(activity('Periodo').output.firstRow.fecha,0,4),'/'\n,substring(activity('Periodo').output.firstRow.fecha,4,2))\n",
                        "type": "Expression"
                    }
                }
            },
            {
                "name": "Archivo",
                "type": "SetVariable",
                "dependsOn": [
                    {
                        "activity": "Ruta",
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
                    "variableName": "v_archivo",
                    "value": {
                        "value": "@concat('IZI_PROC_REND_00'\n,substring(activity('Periodo').output.firstRow.fecha,4,2)\n,substring(activity('Periodo').output.firstRow.fecha,0,4)\n,'.csv')",
                        "type": "Expression"
                    }
                }
            },
            {
                "name": "carga_adls",
                "type": "Copy",
                "dependsOn": [
                    {
                        "activity": "SP_PROV_IZIPAY_PROC_REND_MENSUAL",
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
                            "value": "@concat(\n    'SELECT\n        [Id Entidad],\n        [Nombre Entidad],\n        [Rol Entidad],\n        [Calidad Servicio],\n        [Año],\n        [Mes],\n        [Día],\n        [ICD],\n        [Func. Específica],\n        [Tipo ICD],\n        [Cant. Consultas Totales],\n        [Cant. Consultas Totales <= 3],\n        [Cant. Consultas Totales >= 7],\n        [ICD Resultado],\n        [Comentarios]\n    FROM [DWH].[BI_BCRP_PROV_IZIPAY_PROC_REND]\n    WHERE PROCESS_DATE = CONVERT(DATE, CONCAT(SUBSTRING(''',\n    activity('Periodo').output.firstRow.Fecha,\n    ''', 1, 6), ''01''))\n    AND [Día] = ''00'''\n)\n",
                            "type": "Expression"
                        },
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
                        "referenceName": "Syn_Table_As400",
                        "type": "DatasetReference",
                        "parameters": {
                            "Tabla": "BI_BCRP_PROV_IZIPAY_PROC_REND",
                            "Esquema": "DWH"
                        }
                    }
                ],
                "outputs": [
                    {
                        "referenceName": "ds_prod_syn_to_adls_csv",
                        "type": "DatasetReference",
                        "parameters": {
                            "Ruta": {
                                "value": "@variables('v_ruta')",
                                "type": "Expression"
                            },
                            "Nombre": {
                                "value": "@variables('v_archivo')",
                                "type": "Expression"
                            }
                        }
                    }
                ]
            },
            {
                "name": "carga_datamart",
                "type": "Copy",
                "dependsOn": [
                    {
                        "activity": "carga_adls",
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
                        "type": "BinarySource",
                        "storeSettings": {
                            "type": "AzureBlobFSReadSettings",
                            "recursive": true
                        },
                        "formatSettings": {
                            "type": "BinaryReadSettings"
                        }
                    },
                    "sink": {
                        "type": "BinarySink",
                        "storeSettings": {
                            "type": "SftpWriteSettings",
                            "operationTimeout": "01:00:00",
                            "useTempFileRename": true
                        }
                    },
                    "enableStaging": false
                },
                "inputs": [
                    {
                        "referenceName": "ADLS_Binary_Tables_reportes",
                        "type": "DatasetReference",
                        "parameters": {
                            "vRuta": {
                                "value": "@variables('v_ruta')",
                                "type": "Expression"
                            },
                            "vArchivo": {
                                "value": "@variables('v_archivo')",
                                "type": "Expression"
                            }
                        }
                    }
                ],
                "outputs": [
                    {
                        "referenceName": "SFTP_Local_Files",
                        "type": "DatasetReference",
                        "parameters": {
                            "vRuta": {
                                "value": "@variables('v_ruta')",
                                "type": "Expression"
                            },
                            "vArchivo": {
                                "value": "@variables('v_archivo')",
                                "type": "Expression"
                            }
                        }
                    }
                ]
            }
        ],
        "variables": {
            "v_fecha_inicial": {
                "type": "String"
            },
            "v_archivo": {
                "type": "String"
            },
            "v_ruta": {
                "type": "String"
            }
        },
        "folder": {
            "name": "adls_reportes/BCRP/PROC_REND"
        },
        "annotations": [],
        "lastPublishTime": "2026-03-04T14:47:41Z"
    },
    "type": "Microsoft.DataFactory/factories/pipelines"
}