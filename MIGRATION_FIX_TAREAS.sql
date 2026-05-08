-- ═══════════════════════════════════════════════════════════════════════
--  MIGRATION: FIX TAREAS ERROR 500
--  Fecha: 2026-05-06
--  Objetivo: Arreglar error 500 en POST /api/tareas
-- ═══════════════════════════════════════════════════════════════════════

-- 1. RECREAR VISTA v_kanban_tasks CON NOMBRES CORRECTOS
-- El problema anterior: column_status se devolvía como 'col'
-- Ahora: devuelve los nombres exactos que espera el frontend

DROP VIEW IF EXISTS v_kanban_tasks CASCADE;

CREATE VIEW v_kanban_tasks AS
SELECT
  t.id, t.project_id, t.title, t.description,
  t.column_status, t.priority, t.progress,
  t.due_date, t.due_date_iso, t.assigned_to, t.created_by,
  t.updated_at, t.created_at,
  p.name        AS project_name,
  p.color       AS project_color,
  pf.full_name  AS assigned_name,
  pf.initials   AS assigned_initials
FROM tasks t
JOIN projects   p  ON p.id = t.project_id
LEFT JOIN profiles pf ON pf.id = t.assigned_to;

-- 2. VERIFICAR QUE LA TABLA TASKS TIENE LA ESTRUCTURA CORRECTA
-- Si falta alguna columna, descomentar y ejecutar:
/*
ALTER TABLE tasks
ADD COLUMN IF NOT EXISTS column_status task_column NOT NULL DEFAULT 'todo';

ALTER TABLE tasks
ADD COLUMN IF NOT EXISTS priority priority_level NOT NULL DEFAULT 'Media';

ALTER TABLE tasks
ADD COLUMN IF NOT EXISTS progress SMALLINT NOT NULL DEFAULT 0;

ALTER TABLE tasks
ADD COLUMN IF NOT EXISTS due_date VARCHAR(20);

ALTER TABLE tasks
ADD COLUMN IF NOT EXISTS due_date_iso DATE;

ALTER TABLE tasks
ADD COLUMN IF NOT EXISTS assigned_to UUID REFERENCES profiles(id) ON DELETE SET NULL;

ALTER TABLE tasks
ADD COLUMN IF NOT EXISTS created_by UUID NOT NULL REFERENCES profiles(id);
*/

-- 3. VERIFICAR FOREIGN KEYS
-- Asegurar que no hay problemas con referencias
/*
SELECT constraint_name, table_name, column_name, referenced_table_name
FROM information_schema.key_column_usage
WHERE table_name = 'tasks' AND column_name IN ('project_id', 'assigned_to', 'created_by');
*/

-- 4. ÍNDICES (para optimización)
CREATE INDEX IF NOT EXISTS idx_tasks_project        ON tasks(project_id);
CREATE INDEX IF NOT EXISTS idx_tasks_assigned       ON tasks(assigned_to);
CREATE INDEX IF NOT EXISTS idx_tasks_col_status     ON tasks(column_status);
CREATE INDEX IF NOT EXISTS idx_tasks_due_date       ON tasks(due_date_iso);

-- ═══════════════════════════════════════════════════════════════════════
--  CAMBIOS EN EL BACKEND (app.js)
-- ═══════════════════════════════════════════════════════════════════════

/*
El endpoint POST /api/tareas en app.js se ha actualizado para:

1. Validar explícitamente los valores de enum:
   - column_status: debe ser 'todo', 'progress', 'review' o 'done'
   - priority: debe ser 'Alta', 'Media' o 'Baja'

2. Castear correctamente los tipos en PostgreSQL:
   - $4::task_column  (en lugar de solo $4)
   - $5::priority_level (en lugar de solo $5)

3. Loguear los errores en la consola:
   - console.error('ERROR creando tarea:', e.message);

Este cambio debería resolver el error 500.

El código actualizado es:

app.post('/api/tareas', verifyToken, async (req, res) => {
  const { project_id, title, description, column_status, priority, due_date, due_date_iso, assigned_to, created_by } = req.body;
  if (!project_id || !title) return res.status(400).json({ error: 'project_id y title requeridos.' });
  const creatorId = created_by || req.user.id;
  const colStatus = column_status || 'todo';
  const prio = priority || 'Media';
  // Validar enums
  const validCols = ['todo','progress','review','done'];
  const validPrios = ['Alta','Media','Baja'];
  if (!validCols.includes(colStatus)) return res.status(400).json({ error: 'column_status inválido (debe ser: todo, progress, review, done)' });
  if (!validPrios.includes(prio)) return res.status(400).json({ error: 'priority inválido (debe ser: Alta, Media, Baja)' });
  try {
    const { rows } = await pool.query(
      \`INSERT INTO tasks (project_id,title,description,column_status,priority,due_date,due_date_iso,assigned_to,created_by)
       VALUES ($1,$2,$3,$4::task_column,$5::priority_level,$6,$7,$8,$9) RETURNING *\`,
      [project_id, title.trim(), description||null, colStatus, prio, due_date||null, due_date_iso||null, assigned_to||null, creatorId]
    );
    res.status(201).json(rows[0]);
  } catch (e) {
    console.error('ERROR creando tarea:', e.message);
    res.status(500).json({ error: e.message });
  }
});
*/

-- ═══════════════════════════════════════════════════════════════════════
--  VERIFICACIÓN POST-MIGRACIÓN
-- ═══════════════════════════════════════════════════════════════════════

-- Verificar que la vista devuelve los datos correctos:
-- SELECT * FROM v_kanban_tasks LIMIT 5;

-- Verificar tipos de datos en tasks:
-- \d tasks

-- Si todo está bien, intentar crear una tarea via API:
-- POST http://localhost:3000/api/tareas
-- Headers: Authorization: Bearer <token>, Content-Type: application/json
-- Body: {
--   "project_id": "uuid-del-proyecto",
--   "title": "Mi tarea de prueba",
--   "column_status": "todo",
--   "priority": "Media"
-- }
