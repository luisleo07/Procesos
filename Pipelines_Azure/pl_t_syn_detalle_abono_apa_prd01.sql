{
    "name": "pl_t_syn_detalle_abono_apa_prd01",
    "properties": {
        "activities": [
            {
                "name": "var_fecha",
                "type": "SetVariable",
                "dependsOn": [
                    {
                        "activity": "var_fecha_anterior",
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
                        "activity": "var_anio_anterior",
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
                        "activity": "var_mes_anterior",
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
                        "activity": "var_dia_anterior",
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
                "name": "var_fecha_anterior",
                "type": "SetVariable",
                "dependsOn": [],
                "policy": {
                    "secureOutput": false,
                    "secureInput": false
                },
                "userProperties": [],
                "typeProperties": {
                    "variableName": "var_fecha_anterior",
                    "value": {
                        "value": "@formatDateTime(addDays(utcNow(), -1), 'yyyyMMdd')\n",
                        "type": "Expression"
                    }
                }
            },
            {
                "name": "var_anio_anterior",
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
                    "variableName": "var_anio_anterior",
                    "value": {
                        "value": "@substring(variables('var_fecha_anterior'), 0, 4)\n",
                        "type": "Expression"
                    }
                }
            },
            {
                "name": "var_mes_anterior",
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
                    "variableName": "var_mes_anterior",
                    "value": {
                        "value": "@substring(variables('var_fecha_anterior'), 4, 2)\n",
                        "type": "Expression"
                    }
                }
            },
            {
                "name": "var_dia_anterior",
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
                    "variableName": "var_dia_anterior",
                    "value": {
                        "value": "@substring(variables('var_fecha_anterior'), 6, 2)\n",
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
                "name": "ADLS_to_SYN t_abono_detalle",
                "type": "Copy",
                "dependsOn": [
                    {
                        "activity": "var_ruta_ADLS_t_abono_detalle",
                        "dependencyConditions": [
                            "Succeeded"
                        ]
                    }
                ],
                "policy": {
                    "timeout": "7.00:00:00",
                    "retry": 0,
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
                        "disableMetricsCollection": false
                    },
                    "enableStaging": false,
                    "parallelCopies": 2,
                    "translator": {
                        "type": "TabularTranslator",
                        "mappings": [
                            {
                                "source": {
                                    "name": "process_date",
                                    "type": "DateTime",
                                    "physicalType": "DATE"
                                },
                                "sink": {
                                    "name": "process_date",
                                    "type": "Date",
                                    "physicalType": "date"
                                }
                            },
                            {
                                "source": {
                                    "name": "itc_company_id",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "itc_company_id",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "itc_company_name",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "itc_company_name",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "flujo",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "flujo",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "producto",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "producto",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cod_comercio",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cod_comercio",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cod_transaccion",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cod_transaccion",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "fecha_proceso",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "fecha_proceso",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cod_banco",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cod_banco",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "tipo_pago",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "tipo_pago",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cuenta_abono",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cuenta_abono",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "hash_cuenta_abono",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "hash_cuenta_abono",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cuenta_corriente",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cuenta_corriente",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "hash_cta_corriente",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "hash_cta_corriente",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cod_moneda",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cod_moneda",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "importe",
                                    "type": "Double",
                                    "physicalType": "DOUBLE"
                                },
                                "sink": {
                                    "name": "importe",
                                    "type": "Double",
                                    "physicalType": "float"
                                }
                            },
                            {
                                "source": {
                                    "name": "comision_abono",
                                    "type": "Double",
                                    "physicalType": "DOUBLE"
                                },
                                "sink": {
                                    "name": "comision_abono",
                                    "type": "Double",
                                    "physicalType": "float"
                                }
                            },
                            {
                                "source": {
                                    "name": "igv_comision",
                                    "type": "Double",
                                    "physicalType": "DOUBLE"
                                },
                                "sink": {
                                    "name": "igv_comision",
                                    "type": "Double",
                                    "physicalType": "float"
                                }
                            },
                            {
                                "source": {
                                    "name": "neto_1",
                                    "type": "Double",
                                    "physicalType": "DOUBLE"
                                },
                                "sink": {
                                    "name": "neto_1",
                                    "type": "Double",
                                    "physicalType": "float"
                                }
                            },
                            {
                                "source": {
                                    "name": "cobro_devolucion",
                                    "type": "Double",
                                    "physicalType": "DOUBLE"
                                },
                                "sink": {
                                    "name": "cobro_devolucion",
                                    "type": "Double",
                                    "physicalType": "float"
                                }
                            },
                            {
                                "source": {
                                    "name": "neto_2",
                                    "type": "Double",
                                    "physicalType": "DOUBLE"
                                },
                                "sink": {
                                    "name": "neto_2",
                                    "type": "Double",
                                    "physicalType": "float"
                                }
                            },
                            {
                                "source": {
                                    "name": "importe_retenido",
                                    "type": "Double",
                                    "physicalType": "DOUBLE"
                                },
                                "sink": {
                                    "name": "importe_retenido",
                                    "type": "Double",
                                    "physicalType": "float"
                                }
                            },
                            {
                                "source": {
                                    "name": "neto_2_dolar",
                                    "type": "Double",
                                    "physicalType": "DOUBLE"
                                },
                                "sink": {
                                    "name": "neto_2_dolar",
                                    "type": "Double",
                                    "physicalType": "float"
                                }
                            },
                            {
                                "source": {
                                    "name": "neto_3",
                                    "type": "Double",
                                    "physicalType": "DOUBLE"
                                },
                                "sink": {
                                    "name": "neto_3",
                                    "type": "Double",
                                    "physicalType": "float"
                                }
                            },
                            {
                                "source": {
                                    "name": "tipo_cambio",
                                    "type": "Double",
                                    "physicalType": "DOUBLE"
                                },
                                "sink": {
                                    "name": "tipo_cambio",
                                    "type": "Double",
                                    "physicalType": "float"
                                }
                            },
                            {
                                "source": {
                                    "name": "fecha_abono",
                                    "type": "DateTime",
                                    "physicalType": "DATE"
                                },
                                "sink": {
                                    "name": "fecha_abono",
                                    "type": "Date",
                                    "physicalType": "date"
                                }
                            },
                            {
                                "source": {
                                    "name": "tipo_cuenta",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "tipo_cuenta",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "pago_tercero",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "pago_tercero",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "ruc_tercero",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "ruc_tercero",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "nombre_tercero",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "nombre_tercero",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "tipo_doc",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "tipo_doc",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "tipo_ruc",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "tipo_ruc",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "nro_documento",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "nro_documento",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "situacion",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "situacion",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "usuario_actualiza",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "usuario_actualiza",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "mensaje",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "mensaje",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "fecha_abono_mod",
                                    "type": "DateTime",
                                    "physicalType": "DATE"
                                },
                                "sink": {
                                    "name": "fecha_abono_mod",
                                    "type": "Date",
                                    "physicalType": "date"
                                }
                            },
                            {
                                "source": {
                                    "name": "nro_dias_abono",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "nro_dias_abono",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "sist_comp_tercero",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "sist_comp_tercero",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cantidad",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cantidad",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "fac_estab",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "fac_estab",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "fecha_abono_referencial",
                                    "type": "DateTime",
                                    "physicalType": "DATE"
                                },
                                "sink": {
                                    "name": "fecha_abono_referencial",
                                    "type": "Date",
                                    "physicalType": "date"
                                }
                            },
                            {
                                "source": {
                                    "name": "nombre_cheque",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "nombre_cheque",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "agrupacion_abonos",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "agrupacion_abonos",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "fuerza_cuenta",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "fuerza_cuenta",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "nro_archivo_abono",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "nro_archivo_abono",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cci",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cci",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "tipo_doc_tercero",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "tipo_doc_tercero",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cuenta_especial",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cuenta_especial",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cod_padre",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cod_padre",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "tipo_facilitador",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "tipo_facilitador",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cod_estab_abono",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cod_estab_abono",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "nombre_comercial",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "nombre_comercial",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "cod_facilitador",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cod_facilitador",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "tipo_doc_identificador",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "tipo_doc_identificador",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "tipo_pendiente",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "tipo_pendiente",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "fecha_entrante_DCP",
                                    "type": "DateTime",
                                    "physicalType": "DATE"
                                },
                                "sink": {
                                    "name": "fecha_entrante_DCP",
                                    "type": "Date",
                                    "physicalType": "date"
                                }
                            },
                            {
                                "source": {
                                    "name": "ajuste_DCP",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "ajuste_DCP",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "motivo_DCP",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "motivo_DCP",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "observacion",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "observacion",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "impuesto_emisor",
                                    "type": "Double",
                                    "physicalType": "DOUBLE"
                                },
                                "sink": {
                                    "name": "impuesto_emisor",
                                    "type": "Double",
                                    "physicalType": "float"
                                }
                            },
                            {
                                "source": {
                                    "name": "cod_dcp",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "cod_dcp",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "ind_capt_proces",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "ind_capt_proces",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "filtro_abono",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "filtro_abono",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "importe_solarizado",
                                    "type": "Double",
                                    "physicalType": "DOUBLE"
                                },
                                "sink": {
                                    "name": "importe_solarizado",
                                    "type": "Double",
                                    "physicalType": "float"
                                }
                            },
                            {
                                "source": {
                                    "name": "dq_flag_ind",
                                    "type": "Boolean",
                                    "physicalType": "BOOLEAN"
                                },
                                "sink": {
                                    "name": "dq_flag_ind",
                                    "type": "Boolean",
                                    "physicalType": "bit"
                                }
                            },
                            {
                                "source": {
                                    "name": "dq_control_msg",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "dq_control_msg",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "dq_config_id",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "dq_config_id",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "start_date",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "start_date",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "end_date",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "end_date",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "flag_active",
                                    "type": "Boolean",
                                    "physicalType": "BOOLEAN"
                                },
                                "sink": {
                                    "name": "flag_active",
                                    "type": "Boolean",
                                    "physicalType": "bit"
                                }
                            },
                            {
                                "source": {
                                    "name": "record_source",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "record_source",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "load_date",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "load_date",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "creation_user",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "creation_user",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "producto_abono_det",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "producto_abono_det",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "tipo_abono",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "tipo_abono",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "detalle_abono",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "detalle_abono",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "flujo_fuente",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "flujo_fuente",
                                    "type": "String",
                                    "physicalType": "nvarchar"
                                }
                            },
                            {
                                "source": {
                                    "name": "flag_abono_comercio",
                                    "type": "String",
                                    "physicalType": "UTF8"
                                },
                                "sink": {
                                    "name": "flag_abono_comercio",
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
                ],
                "outputs": [
                    {
                        "referenceName": "Syn_Table_As400",
                        "type": "DatasetReference",
                        "parameters": {
                            "Tabla": "t_abono_detalle",
                            "Esquema": "PlanCom"
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
            "var_fecha_anterior": {
                "type": "String"
            },
            "var_anio_anterior": {
                "type": "String"
            },
            "var_mes_anterior": {
                "type": "String"
            },
            "var_dia_anterior": {
                "type": "String"
            },
            "var_archivo_t_abono_detalle": {
                "type": "String"
            },
            "var_rutaADLS_t_abono_detalle": {
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