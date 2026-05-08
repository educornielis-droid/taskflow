# 🚀 Configuración de GitHub para TaskFlow

## Primer Push (Una sola vez)

### Opción 1: Con GitHub CLI (Recomendado)

```bash
cd C:\Users\crist\Downloads\taskflow_1\taskflow_final

# Inicializar git
git init
git config user.name "Cristina Cáceres"
git config user.email "lcaceres81@gmail.com"

# Agregar archivos
git add -A

# Primer commit
git commit -m "🎉 Inicial: Proyecto TaskFlow completo

- Autenticación JWT
- Tablero Kanban funcional
- Asistente Virtual inteligente
- Accesibilidad WCAG 2.1 AA
- Cronómetro y reportes"

# Conectar con GitHub
git remote add origin https://github.com/aria267-lab/proyecto-taskflow.git

# Push a main (o master, según tu rama principal)
git branch -M main
git push -u origin main
```

### Opción 2: Con GitHub Desktop

1. Abre GitHub Desktop
2. File → Add Local Repository
3. Selecciona la carpeta `C:\Users\crist\Downloads\taskflow_1\taskflow_final`
4. Click en "Publish repository"
5. Configura como pública/privada según prefieras

### Opción 3: Con Token de GitHub (SSH o HTTPS)

Si necesitas token:
1. GitHub → Settings → Developer settings → Personal access tokens
2. Copia el token
3. En Git Bash:
```bash
cd C:\Users\crist\Downloads\taskflow_1\taskflow_final
git remote add origin https://tu_token@github.com/aria267-lab/proyecto-taskflow.git
```

## Cambios Futuros (Automático)

Cada vez que hagas cambios, usa:

```bash
cd C:\Users\crist\Downloads\taskflow_1\taskflow_final

# Opción A: Script automático (si estás en Linux/Mac)
./PUSH_TO_GITHUB.sh "Descripción del cambio"

# Opción B: Manual (Windows)
git add -A
git commit -m "Descripción del cambio"
git push origin main
```

## Convención de Commits

```
🎨 Cambio de estilo (CSS, diseño)
✨ Nueva característica
🐛 Bug fix
🔧 Configuración
♿ Accesibilidad
📝 Documentación
🚀 Mejora de rendimiento
🔐 Seguridad
```

Ejemplo:
```bash
git commit -m "✨ Agregado modo oscuro a accesibilidad"
git commit -m "🐛 Arreglado error en tabla Kanban"
git commit -m "♿ Mejorado contraste en alto contraste"
```

## Verificar Status

```bash
# Ver cambios pendientes
git status

# Ver historial de commits
git log --oneline

# Ver última commit
git show
```

## Configuración Local (Una sola vez)

```bash
# Nombre de usuario
git config --global user.name "Cristina Cáceres"

# Email
git config --global user.email "lcaceres81@gmail.com"

# Recordar credenciales
git config --global credential.helper store
```

## ¿Problemas?

Si tienes error al hacer push:

```bash
# Actualizar cambios remotos
git pull origin main

# Resolver conflictos si hay
# (editar archivos conflictivos)

# Luego hacer commit y push
git add -A
git commit -m "Merge: resueltos conflictos"
git push origin main
```

---

**✅ Listo!** Ahora cada cambio que hagas se guardará en:
1. La carpeta local: `C:\Users\crist\Downloads\taskflow_1\taskflow_final`
2. GitHub: `https://github.com/aria267-lab/proyecto-taskflow`
