<<<<<<< HEAD
# TaskFlow - Gestor de Proyectos y Tareas

Un sistema completo de gestión de proyectos con tablero Kanban, cronómetro integrado, asistente virtual inteligente y múltiples funcionalidades de accesibilidad.

## 🚀 Características Principales

### Core
- ✅ **Autenticación JWT** - Registro, login, recuperación de contraseña
- ✅ **Proyectos** - Crear, editar, gestionar con múltiples usuarios
- ✅ **Tablero Kanban** - Drag & drop en tiempo real (To Do, Progress, Review, Done)
- ✅ **Tareas** - Crear, editar, comentar, asignar con prioridades (Alta, Media, Baja)
- ✅ **Cronómetro** - Registrar tiempo en tareas, histórico de horas
- ✅ **Dashboard** - Resumen de actividad y métricas
- ✅ **Reportes** - Analytics por usuario y proyecto

### Asistente Virtual Inteligente
- ✅ Categorías de ayuda con dropdown de preguntas
- ✅ Búsqueda inteligente (acentos, faltas, palabras clave)
- ✅ Interfaz colapsable con filtros

### Accesibilidad (WCAG 2.1 AA)
- ✅ Alto contraste mejorado
- ✅ Tamaños de fuente escalables (12px - 18px)
- ✅ Espaciado de letras ampliado
- ✅ Fuente OpenDyslexic
- ✅ Modo Enfoque para TDAH
- ✅ Indicadores de foco visibles
- ✅ Compatibilidad ARIA

## 🏗️ Stack Tecnológico

**Frontend:** HTML5, CSS3, Vanilla JavaScript
**Backend:** Node.js, Express, PostgreSQL
**Auth:** JWT + Bcrypt
**Infraestructura:** Supabase + RLS

## 📁 Estructura

```
taskflow_final/
├── public/           # Frontend
│   ├── index.html
│   ├── CSS/
│   │   ├── style.css
│   │   └── assistant.css
│   └── JS/
│       ├── script.js
│       └── assistant.js
├── src/              # Backend
│   ├── app.js
│   ├── server.js
│   ├── db.js
│   ├── middlewares/auth.js
│   └── routes/
├── package.json
└── .gitignore
```

## 🚀 Instalación

```bash
git clone https://github.com/aria267-lab/proyecto-taskflow.git
cd proyecto-taskflow
npm install
npm start
```

## 👥 Roles

- **Admin** - Acceso total
- **Gerente** - Crear proyectos, asignar tareas
- **Empleado** - Completar tareas

## 📝 Licencia

MIT License

## 👨‍💻 Autor

Cristina Cáceres - lcaceres81@gmail.com
=======
# TaskFlow — Backend conectado a Supabase

## Archivos modificados
- `src/app.js`      → API REST completa (proyectos, tareas, cronómetro, comentarios, reportes)
- `src/server.js`   → Servidor limpio
- `public/script.js`→ Frontend conectado a la API (sin localStorage para datos)
- `.env`            → Credenciales Supabase (ya configuradas)

## Iniciar
```bash
npm install
npm start         # producción
npm run dev       # desarrollo con nodemon
```
Abre: http://localhost:3000

## Lo que funciona con la BD
| Acción              | Endpoint                        |
|---------------------|---------------------------------|
| Ver proyectos       | GET /api/proyectos              |
| Crear proyecto      | POST /api/proyectos             |
| Ver tareas Kanban   | GET /api/tareas                 |
| Crear tarea         | POST /api/tareas                |
| Mover columna       | PATCH /api/tareas/:id/mover     |
| Editar tarea        | PUT /api/tareas/:id             |
| Eliminar tarea      | DELETE /api/tareas/:id          |
| Comentarios         | GET/POST /api/tareas/:id/comentarios |
| Cronómetro iniciar  | POST /api/tiempos/iniciar       |
| Cronómetro detener  | PATCH /api/tiempos/detener      |
| Historial tiempo    | GET /api/tiempos                |
| Dashboard resumen   | GET /api/dashboard/:profile_id  |
| Reportes usuarios   | GET /api/reportes/usuarios      |

## Flujo de login
El login autentica contra los perfiles en la BD de Supabase.
Usa los emails de los perfiles seed: `v.fonseca@creativehub.com`, etc.
(En producción conectar con Supabase Auth)
>>>>>>> 60101becd975bbecfd68920d156d8c7b9898c7e5
