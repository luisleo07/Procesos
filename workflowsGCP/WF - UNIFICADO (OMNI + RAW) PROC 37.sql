#dataentry_transaccional
main:
    params: [args]
	# model_input:
	#{
	#"bq_project_id": "dev-izipay-data-operation",
	#"flag_reproceso_table_01": "'0'",
	#"flag_reproceso_table_02": "'0'",
	#"flag_reproceso_table_03": "'0'",
	#"flag_reproceso_table_04": "'0'",
	#"ruta_reproceso_table_01": "'azure://saizipaydatamarts.blob.core.windows.net/adls-ingesta/As400/Maestro/'",
	#"ruta_reproceso_table_02": "'azure://saizipaydatamarts.blob.core.windows.net/adls-ingesta/As400/Maestro/'",
	#"ruta_reproceso_table_03": "'azure://saizipaydatamarts.blob.core.windows.net/adls-ingesta/As400/Maestro/'",
	#"ruta_reproceso_table_04": "'azure://saizipaydatamarts.blob.core.windows.net/adls-ingesta/As400/Maestro/'",
	#"var_connection": "azure-eastus2.dev-bq-omni-izipay-azure-saizipaydatamarts",
	#"var_project_operation": "dev-izipay-data-operation",
	#"var_project_sensitive": "dev-izipay-data-storage",
	#"var_project_storage": "dev-izipay-data-storage"
	#}	
    steps:
    - initVariables:
        assign:
            #proyecto de la facturacion
            - bq_project_id: ${args.bq_project_id}

            #Variables Globales de los SP
            - var_project_operation: ${args.var_project_operation}
            - var_project_storage: ${args.var_project_storage}
            - var_project_sensitive: ${args.var_project_sensitive}

            #BigLake variables globales
            - var_location: azure-eastus2
            - var_dataset_bq_omni_izipay_azure: bq_omni_izipay_azure_saizipaydatamarts
            - var_connection: ${args.var_connection}
            - var_ruta: azure://saizipaydatamarts.blob.core.windows.net/adls-ingesta/As400/Maestro/
            - var_name_prc_biglake: prc_load_table_bqomni_as400_maestro
            - var_prc_biglake_full : ${var_project_operation + "." + var_dataset_bq_omni_izipay_azure + "." + var_name_prc_biglake}

            #tabla01
            - var_flag_reproceso_table_01: ${args.flag_reproceso_table_01} 
            - var_ruta_reproceso_table_01: ${args.ruta_reproceso_table_01}
            #tabla02
            - var_flag_reproceso_table_02: ${args.flag_reproceso_table_02} 
            - var_ruta_reproceso_table_02: ${args.ruta_reproceso_table_02}
			#tabla03
            - var_flag_reproceso_table_03: ${args.flag_reproceso_table_03} 
            - var_ruta_reproceso_table_03: ${args.ruta_reproceso_table_03}
			#tabla04
            - var_flag_reproceso_table_04: ${args.flag_reproceso_table_04} 
            - var_ruta_reproceso_table_04: ${args.ruta_reproceso_table_04}

            #RAW Variables globales
            - var_dataset_raw_stage_as400: raw_stage_as400
            - var_dataset_raw_dataentry: raw_as400
            - var_name_prc_01: prc_load_as400_mcft006
            - var_name_prc_02: prc_load_as400_mcfs006
            - var_name_prc_03: prc_load_as400_izft076
            - var_name_prc_04: prc_load_as400_mcfv102

    - createMap:
        assign:
            - procedures:
            #variables call stored procedure           
                stored_procedure_01:
                    name: ${var_project_operation + "." + var_dataset_raw_stage_as400 + "." + var_name_prc_01}
                    table_01: mcft006

                stored_procedure_02:
                    name: ${var_project_operation + "." + var_dataset_raw_stage_as400 + "." + var_name_prc_02}
                    table_02: mcfs006

                stored_procedure_03:
                    name: ${var_project_operation + "." + var_dataset_raw_stage_as400 + "." + var_name_prc_03}
                    table_03: izft076

                stored_procedure_04:
                    name: ${var_project_operation + "." + var_dataset_raw_stage_as400 + "." + var_name_prc_04}
                    table_04: mcfv102

    - Parallel_procedures_T1:
        parallel:
            branches:
                - prc_load_table_m_as400_table_01:
                    steps:
                        - invoque_prc_load_table_m_biglake_as400_table_01:
                            call: SyncBigQueryJob_BL
                            args:
                                query_pt1: ${
                                    "CALL `" + var_prc_biglake_full + "`('" 
                                    + var_project_operation + "','" 
                                    + var_dataset_bq_omni_izipay_azure + "','"
                                    + procedures.stored_procedure_01.table_01 + "','"
                                    + var_ruta + "','"
                                    + var_connection + "');"
                                    }
                                location: ${var_location}
                                project_id: ${bq_project_id}
                            result: BigLakeResult01
                        - invoque_prc_load_table_t_raw_dataentry_table_01:
                            call: SyncBigQueryJob_RAW
                            args:
                                query_pt1: ${
                                    "CALL `" + procedures.stored_procedure_01.name + "`('" 
                                    + var_project_operation + "','"
                                    + var_project_storage + "','" 
                                    + var_project_sensitive + "');"
                                    }
                                project_id: ${bq_project_id}
                            result: RawResult01

                - prc_load_table_m_as400_table_02:
                    steps:
                        - invoque_prc_load_table_m_biglake_as400_table_02:
                            call: SyncBigQueryJob_BL
                            args:
                                query_pt1: ${
                                    "CALL `" + var_prc_biglake_full + "`('" 
                                    + var_project_operation + "','" 
                                    + var_dataset_bq_omni_izipay_azure + "','"
                                    + procedures.stored_procedure_02.table_02 + "','"
                                    + var_ruta + "','"
                                    + var_connection + "');"
                                    }
                                location: ${var_location}
                                project_id: ${bq_project_id}
                            result: BigLakeResult02
                        - invoque_prc_load_table_t_raw_dataentry_table_02:
                            call: SyncBigQueryJob_RAW
                            args:
                                query_pt1: ${
                                    "CALL `" + procedures.stored_procedure_02.name + "`('" 
                                    + var_project_operation + "','"
                                    + var_project_storage + "','" 
                                    + var_project_sensitive + "');"
                                    }
                                project_id: ${bq_project_id}
                            result: RawResult02

                - prc_load_table_m_as400_table_03:
                    steps:
                        - invoque_prc_load_table_m_biglake_as400_table_03:
                            call: SyncBigQueryJob_BL
                            args:
                                query_pt1: ${
                                    "CALL `" + var_prc_biglake_full + "`('" 
                                    + var_project_operation + "','" 
                                    + var_dataset_bq_omni_izipay_azure + "','"
                                    + procedures.stored_procedure_03.table_03 + "','"
                                    + var_ruta + "','"
                                    + var_connection + "');"
                                    }
                                location: ${var_location}
                                project_id: ${bq_project_id}
                            result: BigLakeResult02
                        - invoque_prc_load_table_t_raw_dataentry_table_03:
                            call: SyncBigQueryJob_RAW
                            args:
                                query_pt1: ${
                                    "CALL `" + procedures.stored_procedure_03.name + "`('" 
                                    + var_project_operation + "','"
                                    + var_project_storage + "','" 
                                    + var_project_sensitive + "');"
                                    }
                                project_id: ${bq_project_id}
                            result: RawResult03

                - prc_load_table_m_as400_table_04:
                    steps:
                        - invoque_prc_load_table_m_biglake_as400_table_04:
                            call: SyncBigQueryJob_BL
                            args:
                                query_pt1: ${
                                    "CALL `" + var_prc_biglake_full + "`('" 
                                    + var_project_operation + "','" 
                                    + var_dataset_bq_omni_izipay_azure + "','"
                                    + procedures.stored_procedure_04.table_04 + "','"
                                    + var_ruta + "','"
                                    + var_connection + "');"
                                    }
                                location: ${var_location}
                                project_id: ${bq_project_id}
                            result: BigLakeResult02
                        - invoque_prc_load_table_t_raw_dataentry_table_04:
                            call: SyncBigQueryJob_RAW
                            args:
                                query_pt1: ${
                                    "CALL `" + procedures.stored_procedure_04.name + "`('" 
                                    + var_project_operation + "','"
                                    + var_project_storage + "','" 
                                    + var_project_sensitive + "');"
                                    }
                                project_id: ${bq_project_id}
                            result: RawResult04
							
    - returnOutput:
        return: "SUCCESS"
SyncBigQueryJob_BL:
    params: [query_pt1, project_id, location]
    steps:
        - JobQuery:
            call: googleapis.bigquery.v2.jobs.query
            args:
                projectId: ${project_id}
                body:
                    query: ${query_pt1}
                    useLegacySql: false
                    location: ${location}
            result: jobQueryResponse
        - JobWait:
            call: BigQueryJobState_BL
            args:
                job_id: ${jobQueryResponse.jobReference.jobId}
                project_id: ${project_id}
                location: ${location}
            result: BigQueryJobStateResponse
        - SyncBigQueryJobResponse:
            return: ${BigQueryJobStateResponse}

BigQueryJobState_BL:
    params: [job_id, project_id, location]
    steps:
        - Sleep:
            call: sys.sleep
            args:
                seconds: 30    
        - JobInfo:
            call: googleapis.bigquery.v2.jobs.get
            args:
                jobId: ${job_id}
                projectId: ${project_id}
                location: ${location}
            result: jobGetResponse
        - JobRunningCheck:
            switch:
              - condition: ${jobGetResponse.status.state == "RUNNING"}
                next: Sleep          
              - condition: ${jobGetResponse.status.state == "DONE"}
                next: WorkflowDone            
        - WorkflowDone:
            switch:
              - condition: ${"errorResult" in jobGetResponse.status}
                next: BigQueryJobStateResponse
            #    raise: ${jobGetResponse}
        - BigQueryJobStateResponse:
            return: ${jobGetResponse}

SyncBigQueryJob_RAW:
    params: [query_pt1, project_id]
    steps:
        - JobQuery:
            call: googleapis.bigquery.v2.jobs.query
            args:
                projectId: ${project_id}
                body:
                    query: ${query_pt1}
                    useLegacySql: false
            result: jobQueryResponse
        - JobWait:
            call: BigQueryJobState_RAW
            args:
                job_id: ${jobQueryResponse.jobReference.jobId}
                project_id: ${project_id}
            result: BigQueryJobStateResponse
        - SyncBigQueryJobResponse:
            return: ${BigQueryJobStateResponse}

BigQueryJobState_RAW:
    params: [job_id, project_id]
    steps:
        - Sleep:
            call: sys.sleep
            args:
                seconds: 30    
        - JobInfo:
            call: googleapis.bigquery.v2.jobs.get
            args:
                jobId: ${job_id}
                projectId: ${project_id}
            result: jobGetResponse
        - JobRunningCheck:
            switch:
              - condition: ${jobGetResponse.status.state == "RUNNING"}
                next: Sleep          
              - condition: ${jobGetResponse.status.state == "DONE"}
                next: WorkflowDone            
        - WorkflowDone:
            switch:
              - condition: ${"errorResult" in jobGetResponse.status}
                next: BigQueryJobStateResponse
        - BigQueryJobStateResponse:
            return: ${jobGetResponse}