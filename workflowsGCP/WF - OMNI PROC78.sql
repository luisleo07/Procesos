main:
    params: [args]
    #{
    # "bq_project_id": "dev-izipay-data-operation",
    # "process_date": "CURRENT_DATE('America/Lima')-1",
    # "var_connection": "'azure-eastus2.dev-bq-omni-izipay-azure-saizipaydatamarts'",
    # "var_project_operation": "dev-izipay-data-operation",
    # "var_ruta": "'azure://saizipaydatamarts.blob.core.windows.net/adls-ingesta/As400/Maestro/'"
    #}
    steps:
    - initVariables:
        assign:
            - bq_project_id: ${args.bq_project_id}
            - var_location: US
            - var_project_operation: ${args.var_project_operation}
            - var_connection: ${args.var_connection}
            - var_process_date: ${args.process_date}
            - var_ruta: ${args.var_ruta}
			- var_dataset_bq_omni_izipay_izipay_azure: bq_omni_izipay_azure_saizipaydatamarts
			- var_name_prc: prc_load_table_bqomni_dataentry_operaciones_transaccional

    - createMap:
        assign:
            - procedures:
                rol500_incoming:
                    name: ${var_project_operation + "." + var_dataset_bq_omni_izipay_izipay_azure + "." + var_name_prc}
                    table: rol500_incoming
                rol500_outgoing:
                    name: ${var_project_operation + "." + var_dataset_bq_omni_izipay_izipay_azure + "." + var_name_prc}
                    table: rol500_outgoing

    # =====================================================
    # SP 1: rol500_incoming
    # =====================================================

    - buildQuery107:
        assign:
            - query107: ${"CALL `" +
                procedures.rol500_incoming.name +
                "`('" +
                var_project_operation + "','" +
                var_dataset_bq_omni_izipay_izipay_azure + "','" +
                procedures.rol500_incoming.table + "'," +
                var_ruta + "," +
                var_connection +
                ");"}


    # =====================================================
    # SP 2: rol500_outgoing
    # =====================================================

    - buildQuery108:
        assign:
            - query108: ${"CALL `" +
                procedures.rol500_outgoing.name +
                "`('" +
                var_project_operation + "','" +
                var_dataset_bq_omni_izipay_izipay_azure + "','" +
                procedures.rol500_outgoing.table + "'," +
                var_ruta + "," +
                var_connection +
                ");"}

    - returnOutput:
        return: "SUCCESS"


SyncBigQueryJob:
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
            call: BigQueryJobState
            args:
                job_id: ${jobQueryResponse.jobReference.jobId}
                project_id: ${project_id}
                location: ${location}
            result: BigQueryJobStateResponse

        - SyncBigQueryJobResponse:
            return: ${BigQueryJobStateResponse}


BigQueryJobState:
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
                raise: ${jobGetResponse}

        - BigQueryJobStateResponse:
            return: ${jobGetResponse}