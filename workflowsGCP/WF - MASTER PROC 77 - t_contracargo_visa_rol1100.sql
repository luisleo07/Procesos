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
          - bq_project_id: ${args.bq_project_id}
          - var_project_operation: ${args.var_project_operation}
          - var_project_sensitive: ${args.var_project_sensitive}
          - var_project_storage: ${args.var_project_storage}
          - var_dataset_master_stage_risk: master_stage_risk
          - var_name_prc: prc_load_t_contracargo_visa_rol1100

    - createMap:
        assign:
          - procedures:
              t_contracargo_visa_rol1100:
                name: ${var_project_operation + "." + var_dataset_master_stage_risk + "." + var_name_prc}

    - 01_prc_load_table_t_contracargo_visa_rol1100:
        steps:
          - invoque_prc_load_table_t_contracargo_visa_rol1100:
              call: SyncBigQueryJob
              args:
                query_pt1: ${"CALL `" + procedures.t_contracargo_visa_rol1100.name + "`('"
                  + var_project_operation + "', '"
                  + var_project_storage + "', '"
                  + var_project_sensitive + "');"}
                project_id: ${bq_project_id}
              result: queryResult01

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
