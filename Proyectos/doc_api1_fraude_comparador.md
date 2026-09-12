# API fraude-comparador — Descripción funcional

## Datos del servicio

| Campo | Valor |
|---|---|
| **Nombre servicio** | `fraude-comparador` |
| **Versión** | v5.6.0 |
| **Proyecto GCP** | `dev-izipay-advanced-analytics` |
| **Región** | `us-central1` |
| **URL nueva** | `https://fraude-comparador-dl7olq7kiq-uc.a.run.app` |
| **URL antigua** | `https://fraude-comparador-322392286721.us-central1.run.app` (mismo servicio, ambas funcionan) |
| **Imagen** | `us-central1-docker.pkg.dev/dev-izipay-advanced-analytics/backoffice-api/fraude-comparador:v5.6.0` |
| **Revisión activa** | `fraude-comparador-00032-taw` (2026-05-27, 100% tráfico) |
| **Rollback** | `fraude-comparador-00030-dow` (v5.5.0, tag `v55`, 0% tráfico) |

---

## ¿Qué hace?

Detecta si un comercio afiliado a Izipay está **suplantando una marca conocida** (fraude de nombre comercial).

Recibe dos listas:
- **Afiliaciones:** comercios nuevos/activos de Izipay
- **Referencia:** parque corporativo (~35,000 empresas RUC 20 conocidas)

Y las compara en **3 fases en serie**:

---

## Fase 1 — Fuzzy matching (paralelo, rápido)

Para cada afiliación busca los 5 comercios más similares del parque de referencia usando 3 técnicas en paralelo:

- **Texto normalizado:** sin tildes, sin stopwords, con leet map (0→o, 1→i, 3→e, etc.)
- **Fonético:** ph→f, v→b, ll→y, rr→r, h→(vacío), etc.
- **Sin espacios:** para detectar casos como "PLAZAVEA" → "PLAZA VEA"

Score combinado por candidato:
```
score = sintáctico×0.35 + semántico×0.40 + fuzzy×0.25
```

Usa hasta 8 workers en paralelo (ThreadPoolExecutor).

---

## Fase 2 — Pre-clasificación programática (sin IA)

Descarta casos obvios **sin gastar llamadas a IA**:

| Motivo de descarte | Ejemplo |
|---|---|
| Nombres genéricos de rubro | BODEGA, FARMACIA, RESTAURANT |
| Nombre de persona usando su propio nombre | DIANA SOLEDAD (persona natural, RUC 10) |
| Expresiones religiosas | DIOS ES AMOR, SAN JOSE |
| Nombres geográficos solos | GAMARRA, MIRAFLORES |
| Solo números | 12345 |
| Nombre muy corto | AB |
| Nombres prueba/test | PRUEBA, DEMO, QA |
| Combinación genérica | BODEGA LIMA, TIENDA ANA |

Los que sobreviven pasan a Fase 3.

---

## Fase 3 — IA "Junta Médica" (Azure OpenAI GPT-4.1)

Por cada caso que pasó el pre-filtro, llama a GPT-4.1 con un prompt de **panel de 3 especialistas antifraude** que evalúa:

- ¿El nombre suplanta intencionalmente una marca real y específica?
- ¿Qué marca exacta se suplanta?
- ¿Qué técnica usa?

**Técnicas detectadas:**
- `typosquatting`: TOTTOS→TOTTUS, WNOG→WONG, RIPELY→RIPLEY
- `leetspeak`: S0DIMAC→SODIMAC, M3TRO→METRO
- `fonetica`: PITASIVA→LA POSITIVA, ACQUA FRESH→AQUAFRESH
- `insercion`: PLAZAVEA→PLAZA VEA, SINMECSILVERSTONE→SILVERSTONE
- `nombre_exacto`: persona natural usando nombre de empresa RUC 20

**Respuesta IA:** `es_fraude`, `marca_suplantada`, `tecnica`, `score 0-100`, `razon`

**Verificación post-IA (reglas duras):**
- Si la IA no puede nombrar una marca específica → score máximo 20
- Si no identifica técnica → score máximo 40
- La marca suplantada debe estar en el parque de referencia o en la lista `WELL_KNOWN_BRANDS`

**Score final:**
```
score_final = fuzzy×0.15 + IA×0.85
```

**Niveles de alerta:**
| Score | Nivel |
|---|---|
| ≥ 0.80 | ALTA |
| ≥ 0.60 | MEDIA |
| ≥ 0.30 | BAJA |
| < 0.30 | DESCARTADO |

---

## Endpoints

| Endpoint | Método | Descripción |
|---|---|---|
| `/health` | GET | Estado del servicio e IA habilitada |
| `/compare-json` | POST | Entrada JSON directo — v5.3, rápido (usado por fraude-traza) |
| `/upload-and-compare` | POST | Entrada Excel/CSV — flujo legacy del frontend web |
| `/status/{job_id}` | GET | Progreso del job en tiempo real |
| `/results/{job_id}` | GET | Resultados completos del job |
| `/download/{job_id}` | GET | Descarga Excel con alertas |
| `/resume/{job_id}` | POST | Reanuda un job interrumpido |
| `/cancel/{job_id}` | POST | Cancela un job en curso |
| `/jobs` | GET | Lista los últimos 20 jobs |

---

## Frontend web

Tiene un frontend en `/static/index.html` que permite:
- Subir 2 archivos Excel (Referencia + Afiliaciones)
- Monitorear el progreso del job en tiempo real
- Descargar los resultados en Excel

Usa el endpoint legacy `POST /upload-and-compare`.

El endpoint `POST /compare-json` (v5.3) fue agregado para que **fraude-traza** lo llame directamente vía JSON, eliminando la serialización Excel que tomaba ~45 minutos.

---

## Archivos del proyecto

```
01_codigo/fraude-comparador/
├── _imagen.txt          # Tag de imagen Docker
└── app/
    ├── main.py          # FastAPI — endpoints y parsers Excel/CSV
    ├── engine.py        # Motor de comparación — fuzzy + IA
    ├── Dockerfile
    ├── requirements.txt
    └── static/
        └── index.html   # Frontend web
```

---

# Historial — Incidente mayo 2026 y mejoras v5.5.0

## Contexto del incidente

El 26 de mayo, el equipo de Riesgo Operativo (RO) reportó discrepancias en el reporte de afiliaciones del 13-14-15 de mayo:

- **Universo:** RO trabajó con 620 registros; Data procesó 635.
- **Detecciones:** RO confirmó 26 casos de fraude; el modelo Data detectó solo 15 (10 ALTA, 1 MEDIA, 4 BAJA).
- **Alineamiento:** solo 10 casos coincidieron en ambos reportes (38%).
- **Hallazgo crítico:** 9 casos que debieron detectarse (Fritz Sports, Shalom, Universidad Tecnológica del Perú, etc.) NO se identificaron por el modelo.

### Casos no detectados (16 del email de Jürgen)

| Código | Nombre Comercial |
|---|---|
| 5947068 | IZI*HEALTHY PETS AUXILIO VETERINARIO |
| 5947075 | IZI*ESSENZA PE |
| 5947106 | IZI*I FRITZ SPORT |
| 5947145 | IZI*GOLDENSHOTS SAC |
| 5947154 | IZI*SHALOM EMPRESARIAI |
| 5947197 | IZI*SHALOMEMPRESSARIALSAC |
| 5947219 | IZI*SHALOM EXPRESS |
| 5947272 | IZI*APOTEK IMPORT SAC |
| 5947418 | IZI*APOTEK IMPORTA SAC |
| 5947514 | IZI*STRONG FIT COMPANY |
| 5947561 | IZI*CNC SAC EEUU |
| 5947588 | IZI*UNIVERSIDAD TECNOLOGICA PERU |
| 5947600 | IZI*CENTRO DE ESTUDIOS LIMA (en el email aparece como UTP — error de mapeo) |
| 5947713 | IZI*IFRITZ SPORT |
| 5947870 | IZI*SHALONEXPRES |
| 5947872 | IZI*UNIVERSIDAD TECNOLOGICA PERU |

## Diagnóstico — 3 causas raíz

### Causa #1 — Lista de referencia contaminada con afiliaciones IZI* *(la principal)*

La lista de referencia (101k registros) contenía entradas con prefijo `IZI*`, **incluyendo las propias afiliaciones bajo análisis**. Como `normalize_text` quita el prefijo `IZI*`, la afiliación se encontraba a sí misma como Top-1 con score 1.00 en Fase 1.

Ejemplo (caso `5947106 I FRITZ SPORT`):

```
Top-5 que recibía la IA:
  1. score=1.00 → IZI*I FRITZ SPORT  ← la propia afiliación
  2. score=0.96 → IZI*FR!TZ SPORT
  3. score=0.96 → IZI*FR1TZ SPORT
  4. score=0.96 → IZI*FRITZ SP0RT
  5. score=0.96 → IZI*FRI TZ SPORT

FRITZ SPORT (la marca real, sí presente en la referencia) quedaba fuera del Top-5.
```

Consecuencia:
- El prompt etiquetaba el Top-5 como "PARQUE CORPORATIVO RUC 20", pero en realidad eran otras afiliaciones IZI*.
- La IA no recibía el contexto correcto para identificar la marca real suplantada.
- La regla de oro (cap 20 si no se nombra marca específica) terminaba descartando los casos.

### Causa #2 — Dedup colapsa registros con RUC vacío

El dedup en `engine.py:465` usaba `key = nom_comercio.upper() + "|" + ruc.strip()`. Como **todos los RUCs venían `None`** en el archivo de afiliaciones, el key se reducía a solo el nombre. Resultado:

| Nombre | Afiliaciones en archivo | Procesadas tras dedup |
|---|---|---|
| UNIVERSIDAD TECNOLOGICA PERU | 3 (5947588, 5947589, 5947872) | **1** (solo la primera sobrevive) |
| EMBALAJES LUCILA | 5 | 1 |
| COURIER OLY | 3 | 1 |
| SYSTEM 94, DEJA VU | 3 c/u | 1 c/u |
| +17 nombres con 2 ocurrencias | 34 | 17 |

~30 afiliaciones se perdían silenciosamente sin procesarse.

### Causa #3 — RUC = None deshabilita reglas secundarias *(impacto menor en este incidente)*

Con RUC vacío:
- `is_person_ruc()` siempre retorna `False` → el prompt informa "persona juridica" cuando podría ser persona natural.
- El FLAG `persona_con_sufijo_corp` (señal anti-fraude clásica para casos como SHALOMEMPRESSARIALSAC) nunca se activa.
- No es la causa principal de los 16 falsos negativos pero contribuye al ruido.

## Fixes implementados en v5.5.0

### Fix 1 — Dedup por `cod_comercio` ([engine.py:464-471](01_codigo/fraude-comparador/app/engine.py#L464-L471))

```python
seen = set()
afil_dedup = []
for a in afil_rows:
    cod = (a[3] or "").strip()
    if cod and cod in seen:
        continue
    if cod:
        seen.add(cod)
    afil_dedup.append(a)
```

El `cod_comercio` es único por afiliación, así que el dedup solo aplica cuando el mismo código llega dos veces (verdadero duplicado).

### Fix 2 — Prompt IA reforzado con contexto estructural

Cuatro cambios en el prompt enviado a Azure OpenAI:

**a) Bloque `CONTEXTO ESTRUCTURAL CRITICO`** — la IA ahora sabe explícitamente que:
- Las afiliaciones son SIEMPRE DNI / CE / RUC10 / RUC12 / RUC15 (NUNCA RUC 20)
- La referencia es SIEMPRE RUC 20 (parque corporativo + lista RO)
- Cualquier coincidencia entre el caso y la referencia equivale a una persona no-corporativa pareciéndose a una empresa RUC 20 — el patrón de fraude exacto

**b) Bloque condicional `ALERTA DE COINCIDENCIA CASI EXACTA`** — cuando `fuzzy_top1 >= 0.95`, se inyecta un aviso destacado advirtiendo a la IA que es match casi exacto y debe tratarse como ALTA SOSPECHA por defecto (técnica `nombre_exacto`), con decisión final del modelo.

**c) Técnica `nombre_exacto` reforzada** — ahora cubre explícitamente variaciones cosméticas (prefijo `IZI*`, espacios, puntuación, mayúsculas). Si tras ignorar `IZI*` y normalizar el nombre coincide al 100% con una RUC 20, debe puntuar 80-100.

**d) Línea sobre `IZI*` matizada** — antes decía solo "IGNORAR"; ahora aclara que coincidencia 100% tras quitar IZI* NO significa "es el mismo merchant", sino que es suplantación (porque la referencia es solo RUC 20 y el caso es DNI/CE/RUC10-15).

## Mejora pendiente — Opción C (no implementada)

Solución de fondo que NO se aplicó por requerir más trabajo de datos + cambios al prompt + engine:

**Clasificar la referencia en 2 orígenes distintos:**
- `marca_legitima` → parque corporativo RUC 20 + lista RO validada
- `afiliacion_historica` → afiliaciones IZI* previas ya aceptadas

**Cambios necesarios:**
- Esquema BD: agregar columna `origen` en `fraude.upload_referencia`
- Pipeline de carga: marcar cada entrada con su origen
- Fase 1: hacer fuzzy contra ambas, pero retornarlas etiquetadas
- Prompt: etiquetar como "parque corporativo" solo a `marca_legitima`; las `afiliacion_historica` se incluyen como contexto separado ("este nombre se parece a afiliaciones IZI* previas ya aceptadas — investiga si son el mismo merchant")

**Beneficios esperados:**
- La IA dejaría de confundirse cuando el Top-5 está dominado por afiliaciones IZI*
- Habilitaría detección del patrón "persona natural se afilia con nombre idéntico a otra afiliación previa" (lo que probablemente vio Jürgen en GOLDENSHOTS y CNC EEUU)
- Eliminaría falsos negativos cuando una marca real está en la referencia pero queda fuera del Top-5 por desplazamiento

## Resultados post-deploy v5.5.0

Re-corrida del job de mayo (mismos archivos de entrada) contra la revisión v5.5.0:

**Detección de los 16 casos del email:**
- ✅ **14 de 16 detectados como ALTA** (vs. 0 antes):
  HEALTHY PETS, ESSENZA PE, I FRITZ SPORT, SHALOM EMPRESARIAI, SHALOMEMPRESSARIALSAC, SHALOM EXPRESS, APOTEK IMPORT, APOTEK IMPORTA, STRONG FIT COMPANY, UTP (5947588), IFRITZ SPORT, SHALONEXPRES, UTP (5947872), y SHALON EXPRES variantes.
- ❌ **2 no detectados:** GOLDENSHOTS (5947145) y CNC EEUU (5947561) — explicación abajo.

**Verificación del fix de dedup:**
- ✅ Los 3 UTP duplicados (5947588, 5947589, 5947872) ahora se procesan independientemente. Antes solo 5947589 sobrevivía.

**Falsos positivos conocidos siguen contenidos:**
- DANISA → BAJA (score 0.4316)
- CARLOS JUNIOR S → BAJA (score 0.4128)

**Casos adicionales detectados que antes pasaban desapercibidos:**
PERU IMPORT (x2), ELKIN JOYERIA, MAPITRAVEL, AQUASHOES, ZETO SUSHI BAR, CONSORCIO DE IPHONE, DELIZIE, GRACCO, TERRA VIVA, NATURA LIFE, BAVARIA YACHTS, DASHBOUTIQUE, SERVICIOS DIGITALES, entre otros.

**Casos a revisar manualmente con RO** (posibles falsos positivos del modelo nuevo):
- `5947474 OLY COURIER`, `5947475 COURIER OLY` → ALTA, pero Jürgen ya los marcó como falsos positivos en su email original.
- `5947502 NATURA LIFE`, `5947647 BAVARIA YACHTS`, `5947868 PERU IMPORT` → ALTA pero podrían ser comercios genéricos legítimos. Decisión queda en RO con su contexto.

## GOLDENSHOTS y CNC EEUU — diagnóstico CORREGIDO (resuelto en v5.6.0)

> ⚠️ **Corrección importante:** una versión previa de este documento afirmaba que GOLDENSHOTS y CNC EEUU "no eran marcas reales, solo comercios genéricos". **Eso era falso.** `GOLDENSHOTS SAC` y `CNC SAC EEUU` **SÍ están en la lista de referencia como empresas RUC 20 legítimas** — son marcas de Izipay que debían protegerse. Las afiliaciones `5947145` y `5947561` (DNI/RUC10-15) las estaban suplantando, y el fuzzy las enganchó bien (0.93 y 0.90). El fallo estaba en la **capa de IA**.

### Causa raíz real (no era el fuzzy)

El prompt de Karl exigía como criterio principal que el nombre suplantara una marca *"ESPECÍFICA, REAL y **CONOCIDA**"*, y la regla de oro caía a score ≤20 *"si no puedes nombrar la marca específica y real"*.

GPT-4.1 **no reconoce** "GOLDENSHOTS SAC" ni "CNC SAC EEUU" como marcas famosas (a diferencia de Fritz Sport, Tottus, UTP). Por eso concluía "no hay marca conocida suplantada" → `es_fraude=false`, `marca=""`, score ≤20 → **DESCARTADO**.

El cuello de botella era 100% ese razonamiento: la IA juzgaba "marca real" = "marca que yo reconozco", **no** "marca presente en la referencia". El dato frustrante: la verificación post-IA ([engine.py:328-339](01_codigo/fraude-comparador/app/engine.py#L328-L339)) ya aceptaba cualquier marca que estuviera en el parque — pero la IA nunca llegaba a nombrarla. El flag `≥0.95` tampoco los rescataba (quedaban en 0.93 y 0.90).

### Fix v5.6.0 — Prompt reencuadrado a 2 vías

El fraude ahora se confirma si se cumple **CUALQUIERA** de dos vías ([engine.py:715-746](01_codigo/fraude-comparador/app/engine.py#L715-L746)):

- **VÍA 1 (prioritaria) — fuente de verdad:** si el caso coincide alto (≥85%) con un comercio del TOP 5 (parque RUC 20 / lista RO) y no es genérico/persona/geográfico → es suplantación. **No requiere que la IA reconozca la marca.** La referencia ES la fuente de verdad.
- **VÍA 2 (complementaria) — criterio de Karl:** suplanta una marca CONOCIDA nacional/internacional, aunque NO esté en la referencia (Aquafresh, Xiaomi, etc.).

La REGLA DE ORO se suavizó: cap 20 solo si fallan **ambas** vías.

### Resultado verificado (re-corrida mayo, 2026-05-27)

- ✅ **GOLDENSHOTS (5947145) → ALTA (0.9471)** — antes DESCARTADO.
- ✅ **CNC EEUU (5947561) → ALTA (0.9425)** — antes DESCARTADO.
- ✅ Los 14 casos previos siguen ALTA; aparecen detecciones nuevas legítimas (Movistar, Indriver, Bitel, La Positiva, DULCE MICKEY→Disney, etc.).

### Trade-off asumido: precisión vs. recall

La Vía 1 es más sensible y **subió el volumen de ALTA** (aprox. 2×). Costo conocido:
- **Falsos positivos que regresaron / aparecieron:** DANISA→DANICA (0.8991, RO ya lo validó como FP — en v5.5.0 estaba BAJA), SANTA NITA→SANTA ANITA (geográfico), NOMASA→MASA, PINK C Y J→PINK, NARAYAQ→NARA, OLY/OLVA COURIER.
- La IA tiende a "fabricar" una técnica para casi cualquier coincidencia con el parque.

**Decisión (2026-05-27):** se priorizó **recall** (no perder casos). Se migró v5.6.0 al 100% y **el equipo de Riesgo Operativo triagea manualmente** el exceso de ALTA. Rollback instantáneo disponible a v5.5.0 (`fraude-comparador-00030-dow`).

**Mejora pendiente si el ruido es inmanejable:** endurecer las guardas de calidad del match en la Vía 1 (exigir nombre distintivo y casi idéntico, prohibir técnica fabricada en matches flojos) — NO subir el umbral del 85%, porque CNC se sostiene en ~0.84 y se perdería. Sería v5.6.1.

## Historial de versiones

| Versión | Fecha | Cambios principales |
|---|---|---|
| v5.3.0 | abr 2026 | Endpoint `POST /compare-json` para consumo desde fraude-traza |
| v5.4.0 | abr 2026 | Checkpointing inline en Fase 4 (apply_phase4_inline) |
| v5.5.0 | 27 may 2026 | Fix dedup por cod_comercio + prompt con contexto estructural + flag de coincidencia casi exacta. Resuelve incidente de mayo. |
| v5.6.0 | 27 may 2026 | Prompt reencuadrado a 2 vías (fuente de verdad + marca conocida). Detecta GOLDENSHOTS y CNC EEUU (RUC 20 poco conocidas). Sube recall; RO triagea el exceso de FP. |