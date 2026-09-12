-- ══════════════════════════════════════════════════════════
-- DDL PostgreSQL — Log de consultas (traza)
-- Se crea automáticamente al arrancar la API
-- Incluido como referencia
-- ══════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS log_consultas_nomcom (
    id                  SERIAL PRIMARY KEY,
    origen              VARCHAR(50),
    usuario             VARCHAR(200),
    nombre_consultado   TEXT,
    nombre_normalizado  TEXT,
    cantidad_matches    INT DEFAULT 0,
    max_score           FLOAT DEFAULT 0,
    nivel_alerta_max    VARCHAR(20),
    ip_origen           VARCHAR(50),
    tiempo_respuesta_ms INT DEFAULT 0,
    fecha_consulta      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_log_fecha ON log_consultas_nomcom(fecha_consulta DESC);
CREATE INDEX IF NOT EXISTS idx_log_origen ON log_consultas_nomcom(origen);
