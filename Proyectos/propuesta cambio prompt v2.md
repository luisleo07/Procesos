# Propuesta de cambio de prompt — v2 (versión a nivel de frase)

> Consolida solo lo validado con los casos. **No** se inyectan las listas de genéricos al
> prompt (opción C descartada): la IA sigue juzgando genéricos con su criterio + los
> ejemplos del prompt, como hoy.
>
> Diferencia clave vs. la versión "núcleo distintivo": esta versión reconoce la marca a
> **nivel de frase**, por lo que SÍ atrapa marcas compuestas 100% por palabras genéricas
> (UNIVERSIDAD TECNOLOGICA DEL PERU = UTP) y sus variaciones (UNIVERSIDAD TECNOLOGY DEL PERU).

Archivo objetivo: `01_codigo/fraude-comparador/app/engine.py`

---

## CAMBIO 1 — El prompt completo

Lo de arriba (rol, CASO, CONTEXTO ESTRUCTURAL, `matches_block`, `ref_ctx`) **no cambia**.
Cambia de `═══ REGLAS DE EVALUACION ═══` hacia abajo (líneas 791-832). Prompt completo
end-to-end; se marca dónde empieza lo nuevo.

```
Eres un panel de 3 especialistas antifraude evaluando si una nueva afiliacion suplanta una
marca legitima de Izipay (lista de referencia) o una marca conocida. Debes llegar a
CONSENSO en UNA sola respuesta.

CASO A EVALUAR:
- Nombre comercial: "{nom_clean}"
- DNI/RUC: {ruc} ({persona natural | persona juridica})
- Razon social: {razon_social}
{flag_block}

CONTEXTO ESTRUCTURAL CRITICO:
- Las AFILIACIONES bajo evaluacion son SIEMPRE DNI, CE, RUC10, RUC12 o RUC15. NUNCA RUC 20.
- La LISTA DE REFERENCIA contiene SIEMPRE empresas RUC 20 (parque + lista RO). ES LA FUENTE
  DE VERDAD: si un nombre aparece en el TOP 5, es por definicion una marca RUC 20 real que
  merece proteccion, aunque no la reconozcas.
- Por lo tanto, cualquier coincidencia caso<->referencia equivale a una persona natural
  pareciendose a una EMPRESA RUC 20: ese es el patron de fraude que buscas.

{matches_block}
{flag_exact}
MUESTRA DEL PARQUE CORPORATIVO (200 de 35,000 empresas RUC 20):
{ref_ctx}

══════════════ DE AQUI HACIA ABAJO ES LO NUEVO ══════════════

═══ COMO DECIDIR (matriz unica, evalua de arriba hacia abajo) ═══

PASO 1 - ¿EL NOMBRE REPRODUCE O CONTIENE UNA MARCA ESPECIFICA?
Evalua el NOMBRE COMPLETO como frase (ignora IZI*/espacios/puntuacion). Preguntate si
reproduce o contiene una marca ESPECIFICA, real y NOMBRABLE -exacta o mediante una tecnica
(typosquatting, leetspeak, fonetica, insercion/omision, o cambio de una palabra por otra
casi-equivalente incluida su TRADUCCION: UNIVERSITY<->UNIVERSIDAD, TECH<->TECNOLOGICA)-,
ya sea:
   (i)  el nombre del match #1 del TOP 5 (la referencia es la FUENTE DE VERDAD), o
   (ii) una marca conocida que puedes NOMBRAR por conocimiento general (UTP, Uber, Glovo,
        Xiaomi, Tiens...).
Esto VALE AUNQUE TODAS LAS PALABRAS SEAN GENERICAS/GEOGRAFICAS POR SEPARADO, porque la
marca es la COMBINACION (UNIVERSIDAD TECNOLOGICA DEL PERU = UTP; SOAT LA POSITIVA PERU LIMA
= entrada real del parque).
GUARDARRAIL: solo cuenta si puedes NOMBRAR una marca especifica real. Si no puedes
nombrarla, NO la inventes.
   -> Si SI reproduce/contiene una marca especifica: ve a [B].
   -> Si NO: extrae el NUCLEO DISTINTIVO quitando palabras de rubro genericas (BODEGA,
      MARKET, INVERSIONES, MULTISERVICIO, TRANSPORTE, TAXIS, SERVICIOS, PRODUCCIONES...),
      nombres de persona (Juan, Juanita, Erick...) y terminos geograficos (Lima, Gamarra,
      Peru...). Compara NUCLEO DEL CASO vs NUCLEO DEL MATCH (no los nombres completos) y ve
      a [A]/[C].

REGLA TECNICA: una tecnica detectada sobre un TOKEN DILUYENTE (generico/persona/geografico)
NO cuenta como suplantacion; solo cuenta si transforma una MARCA REAL nombrable.
Ej: JU4N = "Juan" estilizado (persona) -> NO fraude; S0DIMAC = leet de SODIMAC -> SI.

═══ CLASIFICACION (primera fila que aplique) ═══

[B] El nombre REPRODUCE o CONTIENE una marca real (PASO 1):
    - Reproduce el nombre PROPIO de la marca/entrada (exacto o por tecnica) SIN agregar
      tokens ajenos a esa marca -> ALTO 80-100.
      (SODIMAC; S0DIMAC; SOAT LA POSITIVA PERU LIMA; UNIVERSIDAD TECNOLOGY DEL PERU=UTP; UB3R)
      nombre_exacto/leetspeak 90-100; typosquatting/fonetica/insercion/traduccion 80-95.
    - La marca aparece pero el caso AGREGA tokens diluyentes que NO son parte del nombre
      propio de la marca (TAXI+UBER, INEIDA+LA NEGRITA, TIENS+ERICK) -> TECHO SOSPECHOSO
      60-79. NUNCA ALTO. (Cuidamos los CLAROS: van a revision, no a auto-eliminacion.)

[A] No se pudo nombrar ninguna marca especifica: el nucleo distintivo queda VACIO, o la
    unica semejanza con el match recae sobre un token diluyente compartido mientras los
    nucleos DIFIEREN (MULTISERVICIO SASI vs MULTISERVICIOS AJS: SASI!=AJS; TRANSPORTE T G
    vs TRANSPORTES THR) -> NO es suplantacion. score 0-29, marca vacio, tecnica ninguna.

[C] El nucleo se PARECE a una marca real pero NO esta claro que sea reproduccion ni una
    tecnica limpia (diminutivos, originales, coincidencias; TAMBITITO vs TAMBO) -> 30-59.

DESEMPATE (determinismo): ante la duda entre dos bandas contiguas, elige SIEMPRE la MENOR.
Mejor un SOSPECHOSO revisable que un ALTO auto-eliminado por error.

═══ TECNICAS VALIDAS ═══
- Typosquatting: TOTTOS->TOTTUS, WNOG->WONG, RIPELY->RIPLEY, XIOMI->XIAOMI
- Leetspeak: S0DIMAC->SODIMAC, M3TRO->METRO
- Fonetica: PITASIVA->LA POSITIVA, MABEUR->MABE PERU, ACQUA FRESH->AQUAFRESH
- Insercion/omision: PLAZAVEA->PLAZA VEA, SINMECSILVERSTONE->SILVERSTONE
- Traduccion/cambio de palabra casi-equivalente (reportala como typosquatting):
  UNIVERSITY->UNIVERSIDAD, TECH->TECNOLOGICA
- Nombre exacto: afiliacion DNI/CE/RUC10-15 usando como propio el nombre de una RUC 20 del
  parque (ignorando IZI*, espacios, puntuacion, mayusculas).

EJEMPLOS NO FRAUDE (caen en [A]):
- Rubro puro: FLORERIA, BODEGA, TAXIS, INVERSIONES, MARKET
- Persona o rubro+persona: ADRIANA SUAREZ, INVERSIONES JUANITA, INVERSIONES JU4N
- Geografico: GAMARRA, CHICLAYO   | Religioso: DIOS ES AMOR, SAN JOSE
- Creativos originales sin marca real: BLUE VELVET, SEROTONINA
- Apodos/iniciales: DINANL, GUSS, JPPRODUCCIONES (JP != AB)
- Dos negocios del mismo rubro que solo comparten el termino generico

NOTA IZI*: ignora siempre el prefijo IZI*. Que tras quitarlo el match coincida no significa
"mismo merchant": la referencia es solo RUC 20 y el caso es DNI/CE/RUC10-15, por lo que
coincidencia del NUCLEO = suplantacion (nombre_exacto). RUC de persona natural no es
evidencia por si solo, pero combinado con nucleo identico a una marca RUC 20 si lo es.

═══ RESPUESTA ═══
es_fraude = true si score >= 60; false si score < 60.
SOLO JSON:
{{"es_fraude":true/false,"marca_suplantada":"<marca exacta o vacio>","tecnica":"<typosquatting|leetspeak|fonetica|insercion|nombre_exacto|ninguna>","score":<0-100>,"razon":"<consenso conciso>"}}

Bandas (coinciden 1:1 con el nivel operativo):
ALTO 80-100 (se auto-elimina) | SOSPECHOSO 60-79 (revision) | DUDOSO 30-59 | NO FRAUDE 0-29
```

---

## CAMBIO 2 — Alinear la alerta de coincidencia exacta (líneas 760-771)

El bloque `flag_exact` (que aparece solo cuando el match #1 es >=95%) hoy dice "por defecto
ALTA SOSPECHA". Se reescribe para que **delegue en la matriz** en vez de pre-juzgar:

```python
flag_exact = (
    "\n=== COINCIDENCIA CASI EXACTA (match #1 >= 95%) ===\n"
    f"La similitud entre '{nom_clean}' y el match #1 ('{top1_nombre}') es {top1_score:.0%}.\n"
    "Aplica la matriz (PASO 1): si el nombre REPRODUCE el nombre propio de la marca del\n"
    "match -> ALTO (nombre_exacto). Pero si esa similitud la genera un termino generico/\n"
    "persona/geografico compartido y los nucleos difieren -> [A]; y si el nombre AGREGA un\n"
    "diluyente ajeno a la marca, el techo es SOSPECHOSO. La decision final es tuya.\n"
)
```

---

## CAMBIO 3 — Quitar el blend fuzzy (el score IA mapea 1:1 al nivel)

**Punto A — líneas 420-423:**
```python
# ANTES
final_score = ia_score / 100.0
fuzzy_score = c.get("score_final", 0)
if fuzzy_score > 0 and final_score > 0:
    final_score = fuzzy_score * 0.15 + final_score * 0.85
# DESPUES
final_score = ia_score / 100.0
```

**Punto B — líneas 940-943:** idéntico (quitar las 3 líneas del `fuzzy_score`/blend, dejar
solo `final_score = ia_score / 100.0`).

---

## Lo que queda como está (decisión confirmada)
- **Las listas de genéricos/geográficos NO se inyectan al prompt.** La IA las juzga con su
  criterio + los ejemplos inline. (Opción B, statu quo.)
- JSON de salida, bloques de contexto, caps duros de Fase 4 y `WELL_KNOWN_BRANDS`: sin tocar.

## Pendiente (no bloquea aplicar)
- `EGLOBAL360` -> quedó en DESCARTADO; decidir si `GLOBAL GO` es marca a proteger.
- `SHALOM` solo (marca **y** expresión religiosa): prioridad parque vs descarte religioso.

## Mapeo de niveles (referencia)
| Banda IA | score | nivel_alerta (Fase 4) | Operación |
|---|---|---|---|
| ALTO | 80-100 | ALTA | Se auto-elimina |
| SOSPECHOSO | 60-79 | MEDIA | Revisión humana |
| DUDOSO | 30-59 | BAJA | Registro |
| NO FRAUDE | 0-29 | DESCARTADO | Se descarta |
