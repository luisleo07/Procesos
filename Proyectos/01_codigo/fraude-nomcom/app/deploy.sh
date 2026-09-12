#!/bin/bash
set -e

# ══════════════════════════════════════════════════════════
# DEPLOY — Fraude NomCom API v1.1  |  Cloud Run + BigQuery + PostgreSQL + Azure OpenAI
# ══════════════════════════════════════════════════════════

PROJECT="dev-izipay-advanced-analytics"
REGION="us-central1"
SERVICE_NAME="fraude-nomcom"
BQ_PROJECT="dev-izipay-data-storage"
BQ_DATASET="master_party"
INSTANCE="n8n-pgsql"
DB_NAME="backoffice_test"
DB_USER="postgres"
DB_PASS="<<DB_PASSWORD>>"
AZURE_ENDPOINT="https://dev-aif-chat-ai-postventa.cognitiveservices.azure.com"
AZURE_KEY="<<AZURE_OPENAI_API_KEY>>"
AZURE_VERSION="2025-01-01-preview"
AZURE_MODEL="gpt-4.1"
SA="dev-izipay-iexpress-api-segmen@dev-izipay-advanced-analytics.iam.gserviceaccount.com"

IMAGE="${REGION}-docker.pkg.dev/${PROJECT}/backoffice-api/${SERVICE_NAME}:latest"
DB_HOST=$(gcloud sql instances describe "$INSTANCE" --project="$PROJECT" --format="value(ipAddresses[0].ipAddress)")

echo "════════════════════════════════════════"
echo "  SERVICE : $SERVICE_NAME (v1.1)"
echo "  IMAGE   : $IMAGE"
echo "  BQ      : $BQ_PROJECT.$BQ_DATASET"
echo "  DB      : $DB_HOST:5432/$DB_NAME"
echo "════════════════════════════════════════"

# ── PASO 1: Verificar tablas BigQuery ─────────────────────
echo ""
echo "▶ PASO 1 — Verificando tablas BigQuery..."

# Solo crear si no existen (las que ya existen se quedan)
for TBL in lista_afiliaciones_analizar lista_referencia_nomcom resultado_analisis_nomcom log_consultas_nomcom; do
  if bq show "${BQ_PROJECT}:${BQ_DATASET}.${TBL}" > /dev/null 2>&1; then
    echo "  ✓ $TBL ya existe"
  else
    echo "  Creando $TBL..."
    case $TBL in
      lista_afiliaciones_analizar)
        bq query --use_legacy_sql=false --project_id="$BQ_PROJECT" '
        CREATE TABLE `dev-izipay-data-storage.master_party.lista_afiliaciones_analizar` (
          cod_comercio STRING NOT NULL, nom_comercio STRING NOT NULL,
          tipo_documento STRING, fecha_apertura_comercio DATE, fecha_carga TIMESTAMP)' ;;
      lista_referencia_nomcom)
        bq query --use_legacy_sql=false --project_id="$BQ_PROJECT" '
        CREATE TABLE `dev-izipay-data-storage.master_party.lista_referencia_nomcom` (
          id INT64 NOT NULL, nombre_comercial STRING NOT NULL, razon_social STRING,
          origen STRING NOT NULL, activo BOOL NOT NULL, fecha_actualizacion TIMESTAMP NOT NULL)' ;;
      resultado_analisis_nomcom)
        bq query --use_legacy_sql=false --project_id="$BQ_PROJECT" '
        CREATE TABLE `dev-izipay-data-storage.master_party.resultado_analisis_nomcom` (
          id STRING NOT NULL, id_batch STRING NOT NULL, cod_comercio STRING,
          nom_comercio STRING NOT NULL, nom_comercio_norm STRING,
          nombre_referencia_match STRING, origen_referencia STRING,
          score_sintactico FLOAT64, score_semantico FLOAT64, score_ia FLOAT64, score_final FLOAT64,
          nivel_alerta STRING, metodo_deteccion STRING, detalle_ia STRING,
          origen STRING, fecha_analisis TIMESTAMP NOT NULL)' ;;
      log_consultas_nomcom)
        bq query --use_legacy_sql=false --project_id="$BQ_PROJECT" '
        CREATE TABLE `dev-izipay-data-storage.master_party.log_consultas_nomcom` (
          id STRING NOT NULL, origen STRING, usuario STRING,
          nombre_consultado STRING, nombre_normalizado STRING,
          cantidad_matches INT64, max_score FLOAT64, nivel_alerta_max STRING,
          ip_origen STRING, tiempo_respuesta_ms INT64, fecha_consulta TIMESTAMP NOT NULL)' ;;
    esac
    echo "  ✓ $TBL creada"
  fi
done

# ── PASO 2: Docker build & push ──────────────────────────
echo ""
echo "▶ PASO 2 — Build y Push de imagen Docker..."
gcloud auth configure-docker "${REGION}-docker.pkg.dev" --quiet
docker build --no-cache --platform linux/amd64 -t "$IMAGE" .
docker push "$IMAGE"
echo "  ✓ Imagen publicada"

# ── PASO 3: Deploy Cloud Run ─────────────────────────────
echo ""
echo "▶ PASO 3 — Deploy a Cloud Run..."
gcloud run deploy "$SERVICE_NAME" \
    --image="$IMAGE" \
    --platform=managed --region="$REGION" --project="$PROJECT" \
    --allow-unauthenticated --port=8080 \
    --memory=1Gi --cpu=1 --min-instances=1 --max-instances=3 --timeout=120 \
    --service-account="$SA" \
    --set-env-vars="DB_HOST=${DB_HOST},DB_PORT=5432,DB_NAME=${DB_NAME},DB_USER=${DB_USER},DB_PASSWORD=${DB_PASS},BQ_PROJECT=${BQ_PROJECT},BQ_DATASET=${BQ_DATASET},BQ_TABLE_REF=lista_referencia_nomcom,BQ_TABLE_AFIL=lista_afiliaciones_analizar,BQ_TABLE_RESULT=resultado_analisis_nomcom,BQ_TABLE_LOG=log_consultas_nomcom,SYNC_INTERVAL_SECONDS=1800,AZURE_OPENAI_ENDPOINT=${AZURE_ENDPOINT},AZURE_OPENAI_API_KEY=${AZURE_KEY},AZURE_OPENAI_API_VERSION=${AZURE_VERSION},AZURE_OPENAI_MODEL=${AZURE_MODEL}" \
    --quiet

URL=$(gcloud run services describe "$SERVICE_NAME" --region="$REGION" --project="$PROJECT" --format="value(status.url)")

echo ""
echo "════════════════════════════════════════"
echo "  ✅ DEPLOY COMPLETADO v1.1"
echo ""
echo "  🌐 Frontend : $URL/"
echo "  📊 API Docs : $URL/docs"
echo "  💚 Health   : $URL/health"
echo "════════════════════════════════════════"
