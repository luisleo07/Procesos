# API fraude-traza — Estado y referencia operativa

## Datos del servicio

| Campo | Valor |
|---|---|
| **Nombre servicio** | `fraude-traza` |
| **Proyecto GCP** | `dev-izipay-advanced-analytics` |
| **Región** | `us-central1` |
| **URL** | `https://fraude-traza-dl7olq7kiq-uc.a.run.app` |
| **Imagen** | `us-central1-docker.pkg.dev/dev-izipay-advanced-analytics/backoffice-api/fraude-traza:v2.0.5-no-id` |
| **Service account** | `dev-izipay-iexpress-api-segmen@dev-izipay-advanced-analytics.iam.gserviceaccount.com` |

---

## Permisos requeridos (resuelto el 2026-05-26)

La service account necesita acceso al proyecto `dev-izipay-data-storage`. Sin estos permisos el pipeline falla con error 403.

- **Rol otorgado:** `BigQuery Data Editor`
- **Nivel:** dataset `dev-izipay-data-storage:raw_riesgo_operativo`
- **Tabla crítica:** `raw_riesgo_operativo.lista_afiliaciones_analizar`

> El usuario `mc2139@izipay.pe` NO tiene permisos de admin en `dev-izipay-data-storage`.
> Los permisos IAM de ese proyecto deben gestionarlos otro admin con acceso.

---

## Endpoints principales

| Endpoint | Descripción |
|---|---|
| `GET /health` | Verifica conexión a Postgres y cuenta batch runs |
| `GET /batches` | Lista batch runs con filtros de fecha y estado |
| `GET /batch/{id_batch}` | Detalle de un batch y sus resultados |
| `GET /batch/{id_batch}/logs` | Logs de un batch |
| `GET /alertas` | Alertas ALTA/MEDIA sin revisar |
| `GET /traza/{cod_comercio}` | Historial completo de un comercio |
| `GET /stats` | Estadísticas de los últimos N días |
| `POST /pipeline/run` | Ejecuta el pipeline de detección de fraude |
| `POST /alertas/{id}/revision` | Registra revisión de una alerta |
| `POST /sync` | Sincroniza datos desde BigQuery a Postgres |

---

## Comandos Cloud Shell

### Verificar estado del servicio
```bash
curl https://fraude-traza-dl7olq7kiq-uc.a.run.app/health
```

### Correr el pipeline
```bash
curl -X POST "https://fraude-traza-dl7olq7kiq-uc.a.run.app/pipeline/run?origen=PIPELINE_DIARIO"
```

### Ver logs del servicio
```bash
gcloud run services logs read fraude-traza \
  --region us-central1 \
  --project dev-izipay-advanced-analytics \
  --limit 50
```

### Obtener URL del servicio
```bash
gcloud run services describe fraude-traza \
  --region us-central1 \
  --project dev-izipay-advanced-analytics \
  --format='value(status.url)'
```

---

## Resumen de servicios deployados en Cloud Run (proyecto dev-izipay-advanced-analytics)

Listado completo al 2026-05-26:

| Servicio | URL |
|---|---|
| api-unhush-ruc | https://api-unhush-ruc-dl7olq7kiq-uc.a.run.app |
| backoffice-api | https://backoffice-api-dl7olq7kiq-uc.a.run.app |
| bq-proxy | https://bq-proxy-dl7olq7kiq-uc.a.run.app |
| calculadora-especial | https://calculadora-especial-dl7olq7kiq-uc.a.run.app |
| calculator-demo | https://calculator-demo-dl7olq7kiq-uc.a.run.app |
| chat-analyzer | https://chat-analyzer-dl7olq7kiq-uc.a.run.app |
| chatbot-postventa-v2-karl | https://chatbot-postventa-v2-karl-dl7olq7kiq-uc.a.run.app |
| chatbot-test-runner | https://chatbot-test-runner-dl7olq7kiq-uc.a.run.app |
| coupon-poc | https://coupon-poc-dl7olq7kiq-uc.a.run.app |
| dashboard-segmentos | https://dashboard-segmentos-dl7olq7kiq-uc.a.run.app |
| dev-api-send-logs-gfs-gbq-v1 | https://dev-api-send-logs-gfs-gbq-v1-dl7olq7kiq-uc.a.run.app |
| dev-chat-izipay-postventa-genai-api | https://dev-chat-izipay-postventa-genai-api-dl7olq7kiq-uc.a.run.app |
| dev-ibk-front-precios-api-v1 | https://dev-ibk-front-precios-api-v1-dl7olq7kiq-uc.a.run.app |
| dev-izi-chatbot-genai-api-v1 | https://dev-izi-chatbot-genai-api-v1-dl7olq7kiq-uc.a.run.app |
| dev-izi-chatbot-posventa-genai-api-v1 | https://dev-izi-chatbot-posventa-genai-api-v1-dl7olq7kiq-uc.a.run.app |
| dev-izi-cyber-api-v1 | https://dev-izi-cyber-api-v1-dl7olq7kiq-uc.a.run.app |
| dev-izi-express-api-v1 | https://dev-izi-express-api-v1-dl7olq7kiq-uc.a.run.app |
| dev-izi-express-api-v2 | https://dev-izi-express-api-v2-dl7olq7kiq-uc.a.run.app |
| dev-izi-hashing-api-v1 | https://dev-izi-hashing-api-v1-dl7olq7kiq-uc.a.run.app |
| ficha-inteligente | https://ficha-inteligente-dl7olq7kiq-uc.a.run.app |
| fraude-analyst | https://fraude-analyst-dl7olq7kiq-uc.a.run.app |
| fraude-comparador | https://fraude-comparador-dl7olq7kiq-uc.a.run.app |
| fraude-comparador-v6 | https://fraude-comparador-v6-dl7olq7kiq-uc.a.run.app |
| fraude-engine | https://fraude-engine-dl7olq7kiq-uc.a.run.app |
| fraude-evolver | https://fraude-evolver-dl7olq7kiq-uc.a.run.app |
| fraude-nomcom | https://fraude-nomcom-dl7olq7kiq-uc.a.run.app |
| fraude-quality-gate | https://fraude-quality-gate-dl7olq7kiq-uc.a.run.app |
| fraude-traza | https://fraude-traza-dl7olq7kiq-uc.a.run.app |
| fraude-validator | https://fraude-validator-dl7olq7kiq-uc.a.run.app |
| iexpress-platform-test | https://iexpress-platform-test-dl7olq7kiq-uc.a.run.app |
| izipay-devtools | https://izipay-devtools-dl7olq7kiq-uc.a.run.app |
| prd-izi-chatbot-genai-api-v1 | https://prd-izi-chatbot-genai-api-v1-dl7olq7kiq-uc.a.run.app |
| prd-izipay-express-api-v1 | https://prd-izipay-express-api-v1-dl7olq7kiq-uc.a.run.app |
