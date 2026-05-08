-- ═══════════════════════════════════════════════════════════════════════
--  TASKFLOW — ESQUEMA COMPLETO PostgreSQL
--  Responsable BD: Cristina
--  Incluye: auth, usuarios, proyectos, tareas, tiempo, preferencias, chat
-- ═══════════════════════════════════════════════════════════════════════

-- ─── EXTENSIONES ────────────────────────────────────────────────────────
CREATE EXTENSION IF NOT EXISTS "pgcrypto";   -- gen_random_uuid()

-- ─── ENUMS ──────────────────────────────────────────────────────────────
DO $$ BEGIN
  CREATE TYPE user_role      AS ENUM ('Admin','Gerente','Empleado');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE project_status AS ENUM ('Activo','Completado','Pausado','Cancelado');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE priority_level AS ENUM ('Alta','Media','Baja');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE task_column    AS ENUM ('todo','progress','review','done');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ─── TABLA: profiles (usuarios) ─────────────────────────────────────────
-- Nota: Supabase gestiona auth.users; profiles extiende con datos de la app
CREATE TABLE IF NOT EXISTS profiles (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email          VARCHAR(255) NOT NULL UNIQUE,
  password_hash  VARCHAR(255),                       -- bcrypt hash
  full_name      VARCHAR(120) NOT NULL,
  initials       VARCHAR(5)   NOT NULL,
  role           user_role    NOT NULL DEFAULT 'Empleado',
  organization   VARCHAR(80)  DEFAULT 'CreativeHub',
  phone          VARCHAR(30),                        -- Sáb 3 may: campo extra
  empresa        VARCHAR(80),                        -- Sáb 3 may: campo extra
  refresh_token  TEXT,                               -- Mié 30 abr: refresh JWT
  is_active      BOOLEAN      NOT NULL DEFAULT true,
  created_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- ─── TABLA: password_reset_tokens ───────────────────────────────────────
-- Sáb 3 may: recuperación de contraseña real
CREATE TABLE IF NOT EXISTS password_reset_tokens (
  id          SERIAL PRIMARY KEY,
  profile_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  token       VARCHAR(128) NOT NULL UNIQUE,          -- token seguro único
  expires_at  TIMESTAMPTZ  NOT NULL,                 -- 1 hora de vigencia
  used        BOOLEAN      NOT NULL DEFAULT false,
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- ─── TABLA: projects ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS projects (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name         VARCHAR(120) NOT NULL,
  description  TEXT,
  color        VARCHAR(10)  NOT NULL DEFAULT '#2462E9',
  status       project_status NOT NULL DEFAULT 'Activo',
  priority     priority_level NOT NULL DEFAULT 'Media',
  progress     SMALLINT     NOT NULL DEFAULT 0 CHECK (progress BETWEEN 0 AND 100),
  start_date   DATE         NOT NULL,
  end_date     DATE         NOT NULL,
  created_by   UUID         NOT NULL REFERENCES profiles(id),
  updated_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
  created_at   TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- ─── TABLA: project_members ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS project_members (
  project_id  UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  profile_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  role        user_role NOT NULL DEFAULT 'Empleado',
  joined_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (project_id, profile_id)
);

-- ─── TABLA: tasks ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS tasks (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id     UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  title          VARCHAR(200) NOT NULL,
  description    TEXT,
  column_status  task_column  NOT NULL DEFAULT 'todo',
  priority       priority_level NOT NULL DEFAULT 'Media',
  progress       SMALLINT     NOT NULL DEFAULT 0 CHECK (progress BETWEEN 0 AND 100),
  due_date       VARCHAR(20),           -- texto amigable: "30 Mar"
  due_date_iso   DATE,                  -- para ordenar/filtrar
  assigned_to    UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_by     UUID NOT NULL REFERENCES profiles(id),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── TABLA: comments ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS comments (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id     UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  author_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content     TEXT NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── TABLA: time_logs ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS time_logs (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id          UUID NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  project_id       UUID NOT NULL REFERENCES projects(id),
  profile_id       UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  started_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ended_at         TIMESTAMPTZ,
  duration_seconds INTEGER GENERATED ALWAYS AS (
    CASE WHEN ended_at IS NOT NULL
         THEN EXTRACT(EPOCH FROM (ended_at - started_at))::INTEGER
         ELSE NULL END
  ) STORED,
  is_active        BOOLEAN NOT NULL DEFAULT false,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── TABLA: notifications ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notifications (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recipient_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  sender_id     UUID REFERENCES profiles(id) ON DELETE SET NULL,
  type          VARCHAR(50) NOT NULL DEFAULT 'info',   -- info, warning, success
  message       TEXT NOT NULL,
  is_read       BOOLEAN NOT NULL DEFAULT false,
  link          VARCHAR(200),
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ─── TABLA: user_preferences (accesibilidad) ────────────────────────────
-- Jue 1 may + Lun 5 may: preferencias persistentes en BD
CREATE TABLE IF NOT EXISTS user_preferences (
  id               SERIAL PRIMARY KEY,
  profile_id       UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  alto_contraste   BOOLEAN NOT NULL DEFAULT false,
  fuente_dyslexic  BOOLEAN NOT NULL DEFAULT false,
  modo_enfoque     BOOLEAN NOT NULL DEFAULT false,
  tamano_fuente    VARCHAR(10) NOT NULL DEFAULT 'normal'
                   CHECK (tamano_fuente IN ('normal','grande','xl')),
  espaciado        VARCHAR(10) NOT NULL DEFAULT 'normal'
                   CHECK (espaciado IN ('normal','ampliado')),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(profile_id)
);

-- ─── TABLA: chat_messages ───────────────────────────────────────────────
-- Jue 1 may: historial de chat
CREATE TABLE IF NOT EXISTS chat_messages (
  id          SERIAL PRIMARY KEY,
  usuario_id  UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  mensaje     TEXT NOT NULL,
  fecha_hora  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ═══════════════════════════════════════════════════════════════════════
--  ÍNDICES — optimización de consultas frecuentes
-- ═══════════════════════════════════════════════════════════════════════
CREATE INDEX IF NOT EXISTS idx_tasks_project        ON tasks(project_id);
CREATE INDEX IF NOT EXISTS idx_tasks_assigned        ON tasks(assigned_to);
CREATE INDEX IF NOT EXISTS idx_tasks_col_status      ON tasks(column_status);
CREATE INDEX IF NOT EXISTS idx_tasks_due_date        ON tasks(due_date_iso);
CREATE INDEX IF NOT EXISTS idx_time_logs_profile     ON time_logs(profile_id);
CREATE INDEX IF NOT EXISTS idx_time_logs_task        ON time_logs(task_id);
CREATE INDEX IF NOT EXISTS idx_time_logs_active      ON time_logs(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_time_logs_started     ON time_logs(started_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_recip   ON notifications(recipient_id, is_read);
CREATE INDEX IF NOT EXISTS idx_proj_members_profile  ON project_members(profile_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_fecha   ON chat_messages(fecha_hora DESC);
CREATE INDEX IF NOT EXISTS idx_chat_messages_usuario ON chat_messages(usuario_id);
CREATE INDEX IF NOT EXISTS idx_user_prefs_profile    ON user_preferences(profile_id);
CREATE INDEX IF NOT EXISTS idx_pwd_reset_token       ON password_reset_tokens(token);
CREATE INDEX IF NOT EXISTS idx_pwd_reset_profile     ON password_reset_tokens(profile_id);
CREATE INDEX IF NOT EXISTS idx_profiles_email        ON profiles(email);

-- ═══════════════════════════════════════════════════════════════════════
--  VISTAS — usadas por la API
-- ═══════════════════════════════════════════════════════════════════════

-- Vista Kanban: tareas con datos de perfil asignado
CREATE OR REPLACE VIEW v_kanban_tasks AS
SELECT
  t.id, t.project_id, t.title, t.description,
<<<<<<< HEAD
  t.column_status, t.priority, t.progress,
=======
  t.column_status AS col, t.priority, t.progress,
>>>>>>> 60101becd975bbecfd68920d156d8c7b9898c7e5
  t.due_date, t.due_date_iso, t.assigned_to, t.created_by,
  t.updated_at, t.created_at,
  p.name        AS project_name,
  p.color       AS project_color,
<<<<<<< HEAD
  pf.full_name  AS assigned_name,
  pf.initials   AS assigned_initials
=======
  pf.full_name  AS assignee_name,
  pf.initials   AS assignee_initials
>>>>>>> 60101becd975bbecfd68920d156d8c7b9898c7e5
FROM tasks t
JOIN projects   p  ON p.id = t.project_id
LEFT JOIN profiles pf ON pf.id = t.assigned_to;

-- Vista resumen tiempo por usuario
CREATE OR REPLACE VIEW v_time_summary AS
SELECT
  tl.id, tl.profile_id, tl.task_id, tl.project_id,
  tl.started_at, tl.ended_at, tl.duration_seconds, tl.is_active,
  DATE(tl.started_at AT TIME ZONE 'America/Caracas') AS log_date,
  t.title  AS task_title,
  pj.name  AS project_name,
  pf.full_name AS user_name,
  pf.initials  AS user_initials
FROM time_logs tl
JOIN tasks    t  ON t.id  = tl.task_id
JOIN projects pj ON pj.id = tl.project_id
JOIN profiles pf ON pf.id = tl.profile_id;

-- Vista productividad por usuario
CREATE OR REPLACE VIEW v_user_task_summary AS
SELECT
  pf.id, pf.full_name, pf.initials, pf.role,
  COUNT(DISTINCT t.id)                                          AS total_tasks,
  COUNT(DISTINCT t.id) FILTER (WHERE t.column_status = 'done') AS done_tasks,
  COALESCE(SUM(tl.duration_seconds) FILTER (WHERE tl.duration_seconds IS NOT NULL), 0) AS total_seconds
FROM profiles pf
LEFT JOIN tasks     t  ON t.assigned_to = pf.id
LEFT JOIN time_logs tl ON tl.profile_id = pf.id
WHERE pf.is_active = true
GROUP BY pf.id, pf.full_name, pf.initials, pf.role;

-- ═══════════════════════════════════════════════════════════════════════
--  FUNCIONES ALMACENADAS
-- ═══════════════════════════════════════════════════════════════════════

-- Función: calcular progreso de proyecto automáticamente
CREATE OR REPLACE FUNCTION calc_project_progress(p_id UUID)
RETURNS SMALLINT AS $$
DECLARE v_pct SMALLINT;
BEGIN
  SELECT COALESCE(
    ROUND(
      COUNT(*) FILTER (WHERE column_status = 'done') * 100.0 / NULLIF(COUNT(*), 0)
    )::SMALLINT, 0
  ) INTO v_pct FROM tasks WHERE project_id = p_id;
  RETURN v_pct;
END;
$$ LANGUAGE plpgsql;

-- Trigger: actualizar progreso del proyecto al cambiar columna de tarea
CREATE OR REPLACE FUNCTION trg_update_project_progress()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE projects
  SET progress = calc_project_progress(COALESCE(NEW.project_id, OLD.project_id)),
      updated_at = NOW()
  WHERE id = COALESCE(NEW.project_id, OLD.project_id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_task_progress ON tasks;
CREATE TRIGGER trg_task_progress
AFTER INSERT OR UPDATE OF column_status OR DELETE ON tasks
FOR EACH ROW EXECUTE FUNCTION trg_update_project_progress();

-- ═══════════════════════════════════════════════════════════════════════
--  DATOS SEMILLA (SEED)
-- ═══════════════════════════════════════════════════════════════════════
-- Nota: las contraseñas son bcrypt de "12345678" (10 rounds)
-- En producción cambiar por passwords reales

INSERT INTO profiles (id, email, password_hash, full_name, initials, role, organization) VALUES
  ('11111111-0000-0000-0000-000000000001', 'v.fonseca@creativehub.com',
   '$2b$10$YKVaynrTtfZp1Fz3u6oZ9.EB2Qwb0KAq.8MFj7R1GxL1yJhLFoPi',
   'Valeria Fonseca', 'VF', 'Empleado', 'CreativeHub'),
  ('11111111-0000-0000-0000-000000000002', 'e.cornielis@creativehub.com',
   '$2b$10$YKVaynrTtfZp1Fz3u6oZ9.EB2Qwb0KAq.8MFj7R1GxL1yJhLFoPi',
   'Eduardo Cornielis', 'EC', 'Gerente', 'CreativeHub'),
  ('11111111-0000-0000-0000-000000000003', 'c.chirino@creativehub.com',
   '$2b$10$YKVaynrTtfZp1Fz3u6oZ9.EB2Qwb0KAq.8MFj7R1GxL1yJhLFoPi',
   'Cristina Chirino', 'CC', 'Empleado', 'CreativeHub'),
  ('11111111-0000-0000-0000-000000000004', 'a.melchor@creativehub.com',
   '$2b$10$YKVaynrTtfZp1Fz3u6oZ9.EB2Qwb0KAq.8MFj7R1GxL1yJhLFoPi',
   'Andrea Melchor', 'AM', 'Admin', 'CreativeHub')
ON CONFLICT (email) DO NOTHING;

-- Proyectos
INSERT INTO projects (id, name, description, color, status, priority, progress, start_date, end_date, created_by) VALUES
  ('22222222-0000-0000-0000-000000000001', 'TaskFlow MVP',
   'Plataforma web para CreativeHub. Centraliza proyectos, tiempo y reportes.',
   '#2462E9', 'Activo', 'Alta', 68, '2026-02-01', '2026-05-31',
   '11111111-0000-0000-0000-000000000002'),
  ('22222222-0000-0000-0000-000000000002', 'CreativeHub Intranet',
   'Portal interno con gestión documental y comunicación de equipo.',
   '#7C3AED', 'Activo', 'Media', 42, '2026-01-10', '2026-04-30',
   '11111111-0000-0000-0000-000000000004'),
  ('22222222-0000-0000-0000-000000000003', 'Rediseño Portal Web',
   'Modernización del portal público de CreativeHub.',
   '#D97706', 'Activo', 'Media', 18, '2026-03-01', '2026-06-30',
   '11111111-0000-0000-0000-000000000002'),
  ('22222222-0000-0000-0000-000000000004', 'App Gestión RRHH',
   'Aplicación móvil para gestión de recursos humanos.',
   '#94A3B8', 'Completado', 'Baja', 100, '2025-10-01', '2026-02-28',
   '11111111-0000-0000-0000-000000000004')
ON CONFLICT DO NOTHING;

-- Miembros
INSERT INTO project_members (project_id, profile_id, role) VALUES
  ('22222222-0000-0000-0000-000000000001', '11111111-0000-0000-0000-000000000001', 'Empleado'),
  ('22222222-0000-0000-0000-000000000001', '11111111-0000-0000-0000-000000000002', 'Gerente'),
  ('22222222-0000-0000-0000-000000000001', '11111111-0000-0000-0000-000000000003', 'Empleado'),
  ('22222222-0000-0000-0000-000000000001', '11111111-0000-0000-0000-000000000004', 'Admin'),
  ('22222222-0000-0000-0000-000000000002', '11111111-0000-0000-0000-000000000004', 'Admin'),
  ('22222222-0000-0000-0000-000000000002', '11111111-0000-0000-0000-000000000001', 'Empleado'),
  ('22222222-0000-0000-0000-000000000003', '11111111-0000-0000-0000-000000000004', 'Admin'),
  ('22222222-0000-0000-0000-000000000003', '11111111-0000-0000-0000-000000000003', 'Empleado'),
  ('22222222-0000-0000-0000-000000000004', '11111111-0000-0000-0000-000000000001', 'Empleado'),
  ('22222222-0000-0000-0000-000000000004', '11111111-0000-0000-0000-000000000002', 'Gerente')
ON CONFLICT DO NOTHING;

-- Tareas
INSERT INTO tasks (id, project_id, title, description, column_status, priority, progress, due_date, due_date_iso, assigned_to, created_by) VALUES
  ('33333333-0000-0000-0000-000000000001',
   '22222222-0000-0000-0000-000000000001',
   'Diseño de API REST',
   'Diseñar y documentar los endpoints principales de la API REST para auth y proyectos.',
   'progress', 'Alta', 60, '24 Mar', '2026-03-24',
   '11111111-0000-0000-0000-000000000001', '11111111-0000-0000-0000-000000000002'),
  ('33333333-0000-0000-0000-000000000002',
   '22222222-0000-0000-0000-000000000001',
   'Implementar RBAC backend',
   'Control de acceso por roles en Node.js.',
   'progress', 'Media', 30, '28 Mar', '2026-03-28',
   '11111111-0000-0000-0000-000000000002', '11111111-0000-0000-0000-000000000002'),
  ('33333333-0000-0000-0000-000000000003',
   '22222222-0000-0000-0000-000000000001',
   'Maquetado módulo login',
   'Login, registro y recuperación de contraseña.',
   'todo', 'Alta', 0, '26 Mar', '2026-03-26',
   '11111111-0000-0000-0000-000000000003', '11111111-0000-0000-0000-000000000002'),
  ('33333333-0000-0000-0000-000000000004',
   '22222222-0000-0000-0000-000000000001',
   'Integración notificaciones',
   'Sistema de alertas y notificaciones en tiempo real.',
   'todo', 'Media', 0, '02 Abr', '2026-04-02',
   '11111111-0000-0000-0000-000000000002', '11111111-0000-0000-0000-000000000002'),
  ('33333333-0000-0000-0000-000000000005',
   '22222222-0000-0000-0000-000000000002',
   'Documentación técnica API',
   'Documentar endpoints con Swagger.',
   'todo', 'Baja', 0, '10 Abr', '2026-04-10',
   '11111111-0000-0000-0000-000000000001', '11111111-0000-0000-0000-000000000004'),
  ('33333333-0000-0000-0000-000000000006',
   '22222222-0000-0000-0000-000000000001',
   'Setup base de datos',
   'Configurar PostgreSQL y schema.',
   'done', 'Alta', 100, '20 Mar', '2026-03-20',
   '11111111-0000-0000-0000-000000000002', '11111111-0000-0000-0000-000000000002'),
  ('33333333-0000-0000-0000-000000000007',
   '22222222-0000-0000-0000-000000000001',
   'Config entorno Node.js',
   'Instalar entorno desarrollo backend.',
   'done', 'Alta', 100, '18 Mar', '2026-03-18',
   '11111111-0000-0000-0000-000000000003', '11111111-0000-0000-0000-000000000002'),
  ('33333333-0000-0000-0000-000000000008',
   '22222222-0000-0000-0000-000000000002',
   'Testing módulo auth',
   'Pruebas unitarias auth.',
   'todo', 'Baja', 0, '30 Mar', '2026-03-30',
   '11111111-0000-0000-0000-000000000001', '11111111-0000-0000-0000-000000000004')
ON CONFLICT DO NOTHING;

-- Preferencias por defecto para cada perfil
INSERT INTO user_preferences (profile_id) VALUES
  ('11111111-0000-0000-0000-000000000001'),
  ('11111111-0000-0000-0000-000000000002'),
  ('11111111-0000-0000-0000-000000000003'),
  ('11111111-0000-0000-0000-000000000004')
ON CONFLICT (profile_id) DO NOTHING;
<<<<<<< HEAD
=======


ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS cedula VARCHAR(10);

ALTER TABLE profiles
ADD CONSTRAINT profiles_cedula_check
    CHECK (cedula ~ '^[0-9]{6,10}$');

ALTER TABLE profiles
ADD CONSTRAINT profiles_cedula_unique UNIQUE (cedula);
>>>>>>> 60101becd975bbecfd68920d156d8c7b9898c7e5
