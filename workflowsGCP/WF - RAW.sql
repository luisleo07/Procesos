main:
    params: [args]
    # model_input:
    #{
    #    "bq_project_id": "dev-izipay-data-operation",
    #    "var_project_operation": "dev-izipay-data-operation",
    #    "var_project_storage": "dev-izipay-data-storage",
    #    "var_project_sensitive": "dev-izipay-data-storage"
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

            - var_dataset_raw_stage_as400: raw_stage_as400
            - var_name_prc_load_as400_mcft107: prc_load_as400_mcft107
            - var_name_prc_load_as400_mcfs108: prc_load_as400_mcfs108


    - createMap:
        assign:
            - procedures:
            #variables call stored procedure           
                mcft107: 
                    name: ${var_project_operation + "." + var_dataset_raw_stage_as400 + "." + var_name_prc_load_as400_mcft107}

                mcfs108: 
                    name: ${var_project_operation + "." + var_dataset_raw_stage_as400 + "." + var_name_prc_load_as400_mcfs108}

    - Parallel_procedures_T1:
        parallel:
            branches:
            - 01_prc_load_cybersource_mcft107:
                steps:
                    - invoque_prc_load_cybersource_mcft107:
                        call: SyncBigQueryJob
                        args:
                            query_pt1: ${
                                "CALL `" + procedures.mcft107.name + "`('" 
                                + var_project_operation + "','" 
                                + var_project_storage + "','" 
                                + var_project_sensitive + "');"
                                }
                            project_id: ${bq_project_id}
                        result: queryResult01
                        
            - 02_prc_load_cybersource_mcfs108:
                steps:
                    - invoque_prc_load_cybersource_mcfs108:
                        call: SyncBigQueryJob
                        args:
                            query_pt1: ${
                                "CALL `" + procedures.mcfs108.name + "`('" 
                                + var_project_operation + "','" 
                                + var_project_storage + "','"
                                + var_project_sensitive + "');"
                                }
                            project_id: ${bq_project_id}
                        result: queryResult02
    - returnOutput:
        return: "SUCCESS"
SyncBigQueryJob:
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
            call: BigQueryJobState
            args:
                job_id: ${jobQueryResponse.jobReference.jobId}
                project_id: ${project_id}
            result: BigQueryJobStateResponse
        - SyncBigQueryJobResponse:
            return: ${BigQueryJobStateResponse}
BigQueryJobState:
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
                raise: ${jobGetResponse}
        - BigQueryJobStateResponse:
            return: ${jobGetResponse}    