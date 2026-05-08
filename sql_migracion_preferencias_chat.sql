-- ═══════════════════════════════════════════════════════════════
-- MIGRACIÓN: Tablas user_preferences y chat_messages
-- Ejecutar en Supabase SQL Editor o psql local
-- Responsable: Cristina (Jueves 1 mayo + Lunes 5 mayo)
-- ═══════════════════════════════════════════════════════════════

-- Tabla: preferencias de accesibilidad por usuario
CREATE TABLE IF NOT EXISTS user_preferences (
  id            SERIAL PRIMARY KEY,
  profile_id    UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  alto_contraste  BOOLEAN NOT NULL DEFAULT false,
  fuente_dyslexic BOOLEAN NOT NULL DEFAULT false,
  modo_enfoque    BOOLEAN NOT NULL DEFAULT false,
  tamano_fuente   VARCHAR(10) NOT NULL DEFAULT 'normal' CHECK (tamano_fuente IN ('normal','grande','xl')),
  updated_at    TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(profile_id)
);

-- Tabla: mensajes del chat
CREATE TABLE IF NOT EXISTS chat_messages (
  id          SERIAL PRIMARY KEY,
  usuario_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  mensaje     TEXT NOT NULL,
  fecha_hora  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_chat_messages_fecha ON chat_messages(fecha_hora DESC);
CREATE INDEX IF NOT EXISTS idx_chat_messages_usuario ON chat_messages(usuario_id);
CREATE INDEX IF NOT EXISTS idx_user_preferences_profile ON user_preferences(profile_id);

-- Comentario: ejecutar este script en Supabase > SQL Editor
