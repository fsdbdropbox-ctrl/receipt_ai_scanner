# 🔄 Guía de Migración: ReceiptData → AuditReady

Esta guía te explica cómo migrar tu base de datos y configuración de **ReceiptData** (versión antigua) a **AuditReady 1.0**.

---

## 📋 Resumen de Cambios

### Base de Datos
- **Antes:** Schema simple para escaneo básico
- **Ahora:** Schema completo con OAuth, perfiles fiscales, validación y colaboradores

### Variables de Entorno
- **Faltan:** `DATABASE_URL`, `JWT_SECRET` (¡CRÍTICAS!)
- **No se usan:** `DAILY_FREE_LIMIT`, `MONTHLY_PREMIUM_LIMIT`, `FRONTEND_URL`, `STRIPE_PRICE_ID`
- **Se mantienen:** `GEMINI_API_KEY`, `REDIS_URL`, `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `SENTRY_DSN`, `ALLOWED_ORIGINS`, `NODE_ENV`, `PORT`

---

## 🔧 Paso 1: Actualizar Base de Datos en Supabase

### Opción A: Usar la misma base de datos (Recomendado si no tienes datos importantes)

1. Ve a **Supabase** → Tu proyecto → **SQL Editor**
2. Ejecuta este script para **limpiar tablas antiguas** (si existen):

```sql
-- ⚠️ ADVERTENCIA: Esto elimina todas las tablas antiguas
-- Solo ejecuta si no necesitas los datos antiguos

DROP TABLE IF EXISTS collaborator_access CASCADE;
DROP TABLE IF EXISTS validation_flags CASCADE;
DROP TABLE IF EXISTS documents CASCADE;
DROP TABLE IF EXISTS fiscal_profiles CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Eliminar función y triggers antiguos si existen
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;
```

3. Ejecuta el **nuevo schema** completo:
   - Abre `receipt_ai_scanner/backend/src/db/schema.sql`
   - Copia TODO el contenido
   - Pégalo en el SQL Editor de Supabase
   - Click en **"Run"**

4. Verifica que aparezcan estas **5 tablas nuevas**:
   - ✅ `users`
   - ✅ `fiscal_profiles`
   - ✅ `documents`
   - ✅ `validation_flags`
   - ✅ `collaborator_access`

### Opción B: Crear nueva base de datos (Si quieres mantener la antigua)

1. En Supabase, crea un **nuevo proyecto** llamado `auditready-prod`
2. Ejecuta el schema nuevo (`backend/src/db/schema.sql`)
3. Usa la nueva `DATABASE_URL` en Railway

---

## 🔑 Paso 2: Añadir Variables Faltantes en Railway

Ve a **Railway** → Tu servicio → **Variables** y añade:

### 🔴 OBLIGATORIAS (El backend NO arranca sin estas):

```bash
DATABASE_URL=postgresql://postgres:TU_PASSWORD@db.xxxxx.supabase.co:5432/postgres
```

**Cómo obtenerla:**
1. En Supabase → **Settings** → **Database**
2. Copia la **Connection string** (URI)
3. Reemplaza `[YOUR-PASSWORD]` con tu contraseña de Supabase
4. Pégala en Railway como `DATABASE_URL`

```bash
JWT_SECRET=genera-una-string-aleatoria-de-32-caracteres-minimo
```

**Cómo generarla:**
- Opción 1: https://randomkeygen.com/ (usa "CodeIgniter Encryption Keys")
- Opción 2: En terminal: `openssl rand -base64 32`
- **IMPORTANTE:** Debe ser mínimo 32 caracteres, aleatoria y segura

---

## 🧹 Paso 3: Limpiar Variables No Usadas (Opcional)

Estas variables ya **NO se usan** en AuditReady 1.0, puedes eliminarlas de Railway:

- ❌ `DAILY_FREE_LIMIT` (ahora se gestiona en el código)
- ❌ `MONTHLY_PREMIUM_LIMIT` (ahora se gestiona en el código)
- ❌ `FRONTEND_URL` (no se usa en el backend)
- ❌ `STRIPE_PRICE_ID` (no se usa en el código actual)

**Puedes dejarlas** si planeas usarlas más adelante, pero no son necesarias.

---

## ✅ Paso 4: Verificar Configuración

### Checklist de Variables en Railway:

- [ ] `DATABASE_URL` ✅ (nueva, de Supabase)
- [ ] `JWT_SECRET` ✅ (nueva, generada)
- [ ] `GEMINI_API_KEY` ✅ (ya la tienes)
- [ ] `REDIS_URL` ✅ (ya la tienes)
- [ ] `STRIPE_SECRET_KEY` ✅ (ya la tienes)
- [ ] `STRIPE_WEBHOOK_SECRET` ✅ (ya la tienes)
- [ ] `SENTRY_DSN` ✅ (opcional, ya la tienes)
- [ ] `ALLOWED_ORIGINS` ✅ (ya la tienes)
- [ ] `NODE_ENV=production` ✅ (ya la tienes)
- [ ] `PORT` ✅ (Railway lo asigna automáticamente)

### Verificar Base de Datos:

1. En Supabase → **Table Editor**
2. Deberías ver **5 tablas**:
   - `users`
   - `fiscal_profiles`
   - `documents`
   - `validation_flags`
   - `collaborator_access`

---

## 🚀 Paso 5: Probar el Backend

1. En Railway, ve a **Deployments**
2. Debería aparecer un nuevo deployment automático
3. Ve a **View Logs**
4. Deberías ver:
   ```
   Server listening on port 8080
   Environment: production
   ```
5. Si ves errores sobre `DATABASE_URL` o `JWT_SECRET`, añádelas en Variables
6. Prueba el health check:
   - Abre: `https://tu-backend.railway.app/health`
   - Debería devolver: `{"status": "ok", ...}`

---

## ⚠️ Notas Importantes

### Sobre los Datos Antiguos

- **Si tenías datos en ReceiptData:** La nueva estructura es completamente diferente (OAuth en lugar de Install ID, perfiles fiscales, etc.)
- **No hay migración automática** de datos antiguos
- **Recomendación:** Si no necesitas los datos antiguos, usa la Opción A (limpiar y empezar de cero)

### Sobre las Variables

- **`DATABASE_URL`** y **`JWT_SECRET`** son **OBLIGATORIAS**
- Sin ellas, el backend **no arranca** (por diseño de seguridad)
- Las demás variables son opcionales pero recomendadas

---

## 🐛 Troubleshooting

### Error: "Missing required environment variables: DATABASE_URL"
→ Añade `DATABASE_URL` en Railway → Variables

### Error: "JWT_SECRET is required in production"
→ Añade `JWT_SECRET` en Railway → Variables (mínimo 32 caracteres)

### Error: "Connection refused" a PostgreSQL
→ Verifica que `DATABASE_URL` tenga el formato correcto y la contraseña sea válida

### Las tablas no aparecen en Supabase
→ Verifica que ejecutaste el schema completo (`backend/src/db/schema.sql`)

### Backend arranca pero da errores 500
→ Revisa los logs en Railway → View Logs para ver el error específico

---

## 📝 Resumen Rápido

1. ✅ Ejecuta el nuevo schema en Supabase (`backend/src/db/schema.sql`)
2. ✅ Añade `DATABASE_URL` en Railway (de Supabase)
3. ✅ Añade `JWT_SECRET` en Railway (genera una nueva)
4. ✅ Verifica que el backend arranca sin errores
5. ✅ Prueba el health check

---

**¡Listo!** Con estos pasos, tu backend estará actualizado a AuditReady 1.0. 🚀
