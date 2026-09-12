# Fraude Nombre Comercial — Mejoras al motor de detección
### De "¿por qué un comercio aparece un día y otro no?" a un sistema determinista, más preciso y auditable

---

## 1. Resumen ejecutivo

Partimos de una observación de negocio: **un mismo comercio aparecía como alerta un día y desaparecía al siguiente**, sin que cambiara la información. Eso generaba desconfianza en el reporte y riesgo de **dejar pasar fraudes**.

Investigamos la causa raíz, la corregimos en todas sus capas, y de paso mejoramos la calidad de detección. Hoy el motor es:

- **Determinista:** el mismo comercio da el mismo veredicto siempre (antes variaba al azar).
- **Más preciso:** recupera fraudes que antes se perdían y reduce falsos positivos.
- **Auditable:** ningún comercio "desaparece" sin dejar rastro del porqué.

Todo está **desplegado en producción** y validado con pruebas A/B.

---

## 2. El problema y la causa raíz

### Cómo funciona el flujo (contexto)
1. **Azure Synapse → ADLS → GCP:** cada día se cargan a `lista_afiliaciones_analizar` los comercios con apertura en una **ventana móvil de 3 días** `[hoy-3, hoy-1]`.
2. **fraude-traza** (11:15 a.m. Lima) lee esa lista y la manda al motor **fraude-comparador**.
3. **fraude-comparador** compara cada nombre contra el parque de marcas legítimas (RUC 20) y la IA decide si es suplantación.

### La causa raíz del "aparece un día y otro no"
El motor de IA corría con **`temperature = 1` (no determinista)**: con la misma entrada, la IA podía dar **veredictos distintos cada día**. Un comercio sospechoso podía salir ALTA un día y descartarse al siguiente, al azar.

**Agravante:** los casos que la IA descartaba **no se guardaban en ningún lado**. Si un día se descartaba por error, **desaparecía sin rastro** — imposible de auditar.

> **Caso testigo — TANIA → ANIA:** un comercio "TANIA" (persona natural) que suplanta el nombre de una empresa RUC 20 "ANIA". Apareció como ALTA el 23/06 pero **no** el 22/06, pese a estar en la lista ambos días. Misma entrada, distinto veredicto de la IA. Este caso confirmó el diagnóstico.

---

## 3. Cambios implementados

> Cada cambio nació de un caso concreto. Se listan en el orden en que se fueron descubriendo.

### 3.1. Determinismo del modelo (P0)
- **Problema:** `temperature = 1` → la IA cambiaba de opinión día a día.
- **Qué hicimos:** fijamos `temperature = 0` + `seed`. El modelo en producción (`gpt-5.1-chat`) **rechazaba** temperatura 0, así que migramos a **`gpt-4.1`**, que sí la acepta.
- **Resultado:** mismo comercio → mismo score → mismo veredicto. *(Probado: 3 corridas idénticas del caso TANIA.)*
- **Caso:** TANIA → ANIA.

### 3.2. Auditoría de descartados (P1)
- **Problema:** los comercios que la IA descartaba **no quedaban registrados** — desaparecían sin explicación.
- **Qué hicimos:** creamos la tabla **`auditoria_descartados_fraude_nomcom`**. Ahora **todo** comercio analizado queda registrado: si es alerta, en la tabla de resultados; si se descarta, en la de auditoría, **con el motivo** (lo que dijo la IA o qué regla lo filtró).
- **Resultado:** trazabilidad total. Nada desaparece. Podemos auditar cualquier decisión.
- **Caso:** TANIA desaparecía el 22/06 sin rastro; hoy quedaría registrada con su motivo.

### 3.3. Prompt v2 — matriz de decisión determinista
- **Problema:** el prompt original tenía reglas sueltas y la IA **dudaba en la "zona gris"** (palabras genéricas de rubro), cambiando de veredicto.
- **Qué hicimos:** reescribimos el prompt como una **matriz de decisión estructurada**:
  - **PASO 1:** ¿el nombre reproduce/contiene una marca específica? → si sí, ALTA/SOSPECHOSO; si no, se extrae el "núcleo distintivo" y se compara.
  - **Bandas claras** que mapean 1:1 al nivel operativo (ALTO/SOSPECHOSO/DUDOSO/NO FRAUDE).
  - Regla de desempate: ante la duda, **la banda menor** (mejor revisar que auto-eliminar).
- **Resultado:** decisiones consistentes y explicables en la zona gris.
- **Casos:** los ~11 comercios genéricos (MULTISERVICIO SASI, TRANSPORTE T G…) donde la IA antes se contradecía.

### 3.4. Eliminación de la "muestra de 200"
- **Problema:** el prompt incluía una muestra aleatoria de 200 marcas del parque, construida **sin orden fijo**. Cada corrida cambiaba la muestra → el prompt cambiaba → **la IA volteaba aunque la temperatura fuera 0**. Era una segunda fuente de no-determinismo.
- **Qué hicimos:** la eliminamos (el "TOP 5" de coincidencias ya le da a la IA el contexto que importa).
- **Resultado:** determinismo total + menos costo de tokens.
- **Caso:** la prueba entre días mostró fuzzy **idéntico** pero IA volteando — el culpable era esta muestra.

### 3.5. Detección robusta de marcas conocidas (P2.2 — "vía 2")
- **Problema:** marcas externas famosas (Yape, Movistar) se detectaban "de suerte". Si el match aproximado fallaba, se perdían.
- **Qué hicimos:** la verificación de marcas conocidas (`WELL_KNOWN_BRANDS`) ahora corre sobre **todos** los nombres, no solo algunos. Si un nombre contiene una marca conocida, se detecta **de forma determinista**.
- **Resultado:** las suplantaciones de marcas famosas se atrapan siempre.
- **Caso — HACK YAPE:** "HACK YAPE" suplanta a Yape. Un día salía ALTA y otro se perdía, porque el match aproximado se iba a otra entrada ("BACKUS YA…"). Ahora se detecta Yape de frente.

### 3.6. Orden estable de la referencia (ORDER BY)
- **Problema:** la lista de referencia se leía **sin orden fijo**. Cuando varias marcas empataban en similitud, **el "ganador" cambiaba entre corridas** → el match (y el veredicto) flipeaba.
- **Qué hicimos:** ordenamos la lectura de la referencia de forma estable.
- **Resultado:** el match deja de variar; el desempate es siempre igual.
- **Caso — HACK YAPE:** su match saltaba entre "YAPE" y "BACKUS YA" según el orden aleatorio.

### 3.7. Boost de token distintivo (P2.6 — "vía 1")
- **Problema:** cuando una marca aparece como **un token dentro de un nombre más largo** ("HACK **YAPE**"), el score se "diluía" — la marca no destacaba contra coincidencias casuales.
- **Qué hicimos:** si un token distintivo del comercio es **idéntico** a uno de la referencia, se le da un impulso al score, para que esa marca real domine.
- **Resultado:** "contiene una marca de la referencia" se detecta bien, no solo "se parece al nombre completo".
- **Caso — HACK YAPE:** las decenas de entradas "YAPE" del parque ahora dominan el match.

### 3.8. Nombres comerciales cortos de 3 letras (P2.5 + fixes)
- **Problema:** el sistema **descartaba todo nombre de 3 caracteres**, perdiendo marcas reales como **UTP** o **WIN**, y sin dejar rastro.
- **Qué hicimos (en capas):**
  - **fraude-traza:** el filtro pasó de "más de 3 letras" a "3 o más letras".
  - **fraude-comparador:** los nombres de 3 letras con match fuerte ahora **sí se evalúan** (antes se filtraban ciegamente).
  - **Fix de acrónimos deletreados:** "U S I L" (letras sueltas) antes no se reconocía; ahora se junta correctamente y se detecta como USIL.
  - **Override de match fuerte:** si hay una coincidencia casi exacta con una marca real del parque, **decide la IA**, no el pre-filtro automático.
  - **Verificación de marcas de 3 letras:** la capa de verificación final también exigía 4+ letras; la bajamos a 3, para que UTP **verifique** contra el parque y salga **ALTA** (antes salía BAJA por error).
- **Resultado:** comercios como **UTP, USIL, TIENDA UNO** ahora se detectan correctamente.
- **Casos:** UTP, USIL ("U S I L"), TIENDA UNO, WIN.

### 3.9. Acrónimos casi idénticos (Grupo B)
- **Problema:** un acrónimo que difiere en **una sola letra** de una marca real (ej. "LTP" vs "UTP") es un **borderline genuino** — ni claramente fraude ni claramente limpio.
- **Qué hicimos:** estos casos caen en **BAJA-revisable** (van a revisión manual), nunca a auto-eliminación ni a ALTA automática.
- **Resultado:** los casos ambiguos quedan para ojo humano, sin inflar falsos positivos.
- **Caso — LTP PERU** (se parece a UTP cambiando L↔U).

---

## 4. Resultados y validación

### Determinismo
- **Antes:** el mismo comercio podía salir ALTA un día y descartarse al siguiente.
- **Ahora:** veredicto **idéntico** corrida tras corrida (validado con pruebas repetidas y comparación entre días).

### Calidad de detección (prueba A/B con 50 casos reales seleccionados)
| Resultado | Detalle |
|---|---|
| **Frauds recuperados** | USIL, TIENDA UNO, CH IMPORTACIONES, HACK YAPE, UTP — antes se perdían |
| **Regresiones** | **Cero** — ningún fraude claro bajó de nivel |
| **Falsos positivos nuevos** | Ninguno en el set curado |

### Calidad a escala (prueba A/B con ~325 comercios del día)
- **v2 es más preciso:** menos alertas totales, descartando los **falsos positivos genéricos** que el sistema viejo sobre-marcaba.
- Los ~25 casos donde v2 "marca menos" son **todos falsos positivos del sistema viejo** (la IA confirmó que no había técnica de suplantación) — **no se perdió ningún fraude real**.

### Estado
- **En producción end-to-end** (fraude-comparador y fraude-traza).
- Modelo: `gpt-4.1` con temperatura 0.

---

## 5. Próximos pasos (mejoras identificadas)

### 5.1. Endurecer el boost de token (P2.6) — *prioridad media*
- **Qué pasa hoy:** el boost (3.7) a veces se dispara sobre **tokens compartidos que no son marcas**: nombres de persona (EDGAR, WALTER), apellidos (ZEBALLOS) o palabras comunes de negocio (IMPORTACIONES, CORPORACION). Eso genera **falsos positivos** (alertas de más).
- **Ejemplo:** "EDGAR GELDRES" se marcó ALTA porque comparte el nombre de pila "EDGAR" con otra persona del parque — no es una suplantación de marca.
- **La mejora:** excluir del boost los **nombres de persona, geográficos y palabras comunes de negocio**, para que solo se dispare con marcas realmente distintivas (Yape, Maybelline) y no con apellidos.
- **Impacto esperado:** mantiene la cobertura de marcas, elimina ~10 falsos positivos de cada ~325 comercios.

### 5.2. Reconciliación de resultados duplicados — *prioridad media*
- La tabla de resultados **acumula** (no reemplaza), y la ventana móvil de 3 días hace que cada comercio se analice 3 veces → ~2-3 filas por comercio, a veces con veredictos distintos.
- **La mejora:** una vista o regla que consolide el veredicto por comercio (ej. "una vez ALTA, siempre ALTA").

### 5.3. Robustez del scheduler — *prioridad baja*
- El pipeline diario tiene un tiempo límite de 180s; si se pasa, el scheduler reintenta y puede generar **batches duplicados** el mismo día.
- **La mejora:** ampliar el deadline o hacer el proceso idempotente.

### 5.4. Monitoreo de latencia de la fuente (DWH) — *vigilancia*
- Si un comercio se registra en el DWH (`te_parque`) con más de 3 días de retraso, **sale de la ventana antes de analizarse** → se perdería para siempre. Conviene una alerta sobre ese lag.

### 5.5. Cobertura de marcas de la referencia — *mejora continua*
- Para marcas importantes que no estén en la lista de marcas conocidas, conviene **curar/ampliar** esa lista (preciso) en vez de depender solo de heurísticas.

---

## 6. Anexo — decisiones técnicas clave

- **Migración de modelo `gpt-5.1-chat` → `gpt-4.1`:** necesaria porque 5.1-chat no permite temperatura 0 (requisito para el determinismo). Validado que 4.1 mantiene/mejora la detección. *(Recomendable visto bueno formal por ser cambio de modelo del motor.)*
- **Despliegue sin riesgo:** cada cambio se probó primero en una **revisión sin tráfico** (A/B contra producción) antes de promoverlo. Rollback disponible en todo momento.
- **Filosofía de los guardarraíles:** la IA propone, pero una capa de **verificación programática** confirma que la marca nombrada sea real (esté en el parque o sea una marca conocida) antes de disparar una alerta alta. Esto evita "alucinaciones" del modelo.

---

*Documento generado a partir del trabajo realizado sobre el motor Fraude Nombre Comercial. Para detalle de implementación (commits, revisiones de Cloud Run), ver el repositorio del proyecto.*
