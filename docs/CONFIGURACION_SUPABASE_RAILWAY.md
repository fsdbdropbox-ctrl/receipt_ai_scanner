# 🔧 Guía de Configuración: Supabase + Railway

Esta guía te explica paso a paso cómo configurar la base de datos PostgreSQL en Supabase y el backend en Railway para **AuditReady 1.0**.

---

## 📋 Índice

1. [Configuración de Supabase (PostgreSQL)](#1-configuración-de-supabase-postgresql)
2. [Configuración de Railway (Backend)](#2-configuración-de-railway-backend)
3. [Variables de Entorno Requeridas](#3-variables-de-entorno-requeridas)
4. [Verificación y Testing](#4-verificación-y-testing)

---

## 1. Configuración de Supabase (PostgreSQL)

### Paso 1.1: Crear Proyecto en Supabase

1. Ve a [https://supabase.com](https://supabase.com)
2. Inicia sesión o crea una cuenta
3. Click en **"New Project"**
4. Completa:
   - **Name**: `auditready-prod` (o el nombre que prefieras)
   - **Database Password**: Genera una contraseña segura (guárdala, la necesitarás)
   - **Region**: Elige la más cercana (ej: `West Europe` para España)
   - **Pricing Plan**: Free tier es suficiente para empezar
5. Click en **"Create new project"**
6. Espera 2-3 minutos a que se cree el proyecto

### Paso 1.2: Obtener la Connection String

1. En el dashboard de Supabase, ve a **Settings** → **Database**
2. Busca la sección **"Connection string"**
3. Selecciona **"URI"** (no "Session mode")
4. Copia la connection string. Se verá así:
   ```
   postgresql://postgres:[YOUR-PASSWORD]@db.xxxxx.supabase.co:5432/postgres
   ```
5. **Reemplaza `[YOUR-PASSWORD]`** con la contraseña que generaste en el Paso 1.1
6. Guarda esta string completa, la usarás como `DATABASE_URL` en Railway

### Paso 1.3: Ejecutar el Schema SQL

1. En Supabase, ve a **SQL Editor** (icono de terminal en el menú lateral)
2. Click en **"New query"**
3. Abre el archivo `receipt_ai_scanner/backend/src/db/schema.sql` en tu editor
4. **Copia TODO el contenido** del archivo `schema.sql`
5. Pega el contenido en el editor SQL de Supabase
6. Click en **"Run"** (o presiona `Ctrl+Enter`)
7. Deberías ver: **"Success. No rows returned"**

### Paso 1.4: Verificar las Tablas

1. En Supabase, ve a **Table Editor**
2. Deberías ver estas 5 tablas:
   - ✅ `users`
   - ✅ `fiscal_profiles`
   - ✅ `documents`
   - ✅ `validation_flags`
   - ✅ `collaborator_access`

Si todas aparecen, ¡la base de datos está lista! ✅

---

## 2. Configuración de Railway (Backend)

### Paso 2.1: Crear Proyecto en Railway

1. Ve a [https://railway.app](https://railway.app)
2. Inicia sesión con GitHub (recomendado)
3. Click en **"New Project"**
4. Selecciona **"Deploy from GitHub repo"**
5. Conecta tu repositorio de GitHub (si no lo tienes, primero haz push del código)
6. Selecciona el repositorio `receipt_ai_scanner` (o el nombre que tenga)

### Paso 2.2: Configurar el Servicio Node.js

1. Railway detectará automáticamente que es un proyecto Node.js
2. Si no, click en **"New"** → **"GitHub Repo"** y selecciona tu repo
3. Railway creará un servicio automáticamente
4. Ve a **Settings** del servicio
5. Configura:
   - **Root Directory**: `backend` (importante: apunta a la carpeta backend)
   - **Build Command**: `npm install` (Railway lo hace automático, pero verifica)
   - **Start Command**: `npm start`

### Paso 2.3: Configurar Variables de Entorno

En Railway, ve a **Variables** del servicio y añade todas las variables de la sección 3.

---

## 3. Variables de Entorno Requeridas

### 🔴 OBLIGATORIAS (sin estas, el backend no arranca)

Copia estas variables en Railway → Variables:

```bash
# Base de Datos PostgreSQL (de Supabase)
DATABASE_URL=postgresql://postgres:TU_PASSWORD@db.xxxxx.supabase.co:5432/postgres

# JWT para autenticación (genera uno seguro)
JWT_SECRET=tu-secret-jwt-super-seguro-minimo-32-caracteres-aleatorios

# Google Gemini API (para escaneo IA)
GEMINI_API_KEY=tu-api-key-de-google-gemini

# Redis (para rate limiting y cache)
REDIS_URL=redis://default:password@redis.railway.app:6379

# Stripe (para pagos)
STRIPE_SECRET_KEY=sk_live_... o sk_test_...
```

### 🟡 RECOMENDADAS (funcionalidad adicional)

```bash
# Stripe Webhook (para recibir eventos de pago)
STRIPE_WEBHOOK_SECRET=whsec_...

# CORS (dominios permitidos en producción)
ALLOWED_ORIGINS=https://tu-dominio.com,https://app.tu-dominio.com

# Sentry (monitoreo de errores)
SENTRY_DSN=https://xxx@xxx.ingest.sentry.io/xxx

# Entorno
NODE_ENV=production

# Puerto (Railway lo asigna automáticamente, pero puedes forzarlo)
PORT=8080
```

### 📝 Cómo Obtener Cada Variable

#### `DATABASE_URL`
- Ya la obtuviste en el **Paso 1.2 de Supabase**
- Formato: `postgresql://postgres:PASSWORD@db.xxxxx.supabase.co:5432/postgres`

#### `JWT_SECRET`
- Genera una string aleatoria segura de al menos 32 caracteres
- Puedes usar: `openssl rand -base64 32` (en terminal)
- O genera una en: https://randomkeygen.com/ (usa "CodeIgniter Encryption Keys")

#### `GEMINI_API_KEY`
1. Ve a [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Click en **"Get API Key"**
3. Crea un nuevo proyecto o selecciona uno existente
4. Copia la API key generada

#### `REDIS_URL`
**Opción A: Redis en Railway (Recomendado)**
1. En Railway, click en **"New"** → **"Database"** → **"Add Redis"**
2. Railway creará un servicio Redis automáticamente
3. Ve a **Variables** del servicio Redis
4. Copia la variable `REDIS_URL` que Railway genera automáticamente
5. Pégala en las variables del servicio backend

**Opción B: Redis Cloud (Alternativa)**
1. Ve a [Redis Cloud](https://redis.com/try-free/)
2. Crea una cuenta gratuita
3. Crea una base de datos
4. Copia la connection string

#### `STRIPE_SECRET_KEY` y `STRIPE_WEBHOOK_SECRET`
1. Ve a [Stripe Dashboard](https://dashboard.stripe.com)
2. Ve a **Developers** → **API keys**
3. Copia la **Secret key** (empieza con `sk_test_` o `sk_live_`)
4. Para el webhook:
   - Ve a **Developers** → **Webhooks**
   - Click en **"Add endpoint"**
   - URL: `https://tu-backend.railway.app/api/stripe-webhook`
   - Selecciona eventos: `customer.subscription.created`, `customer.subscription.updated`, `customer.subscription.deleted`
   - Copia el **Signing secret** (empieza con `whsec_`)

#### `ALLOWED_ORIGINS`
- Lista de dominios separados por comas
- Ejemplo: `https://auditready.app,https://app.auditready.app`
- En desarrollo, puedes dejarlo vacío (el backend permite todos los orígenes)

#### `SENTRY_DSN` (Opcional)
1. Ve a [Sentry.io](https://sentry.io)
2. Crea un proyecto Node.js
3. Copia el DSN que te proporcionan

---

## 4. Verificación y Testing

### Paso 4.1: Verificar que el Backend Arranca

1. En Railway, ve a **Deployments**
2. Deberías ver un deployment en progreso
3. Cuando termine, click en el servicio → **"View Logs"**
4. Deberías ver:
   ```
   Server listening on port 8080
   Environment: production
   ```
5. Si ves errores sobre variables faltantes, añádelas en **Variables**

### Paso 4.2: Probar el Health Check

1. Railway te da una URL pública (ej: `https://tu-backend.railway.app`)
2. Abre en el navegador: `https://tu-backend.railway.app/health`
3. Deberías ver:
   ```json
   {
     "status": "ok",
     "timestamp": "2025-01-14T...",
     "version": "1.0.0"
   }
   ```

### Paso 4.3: Verificar Conexión a Base de Datos

1. En Railway logs, NO deberías ver errores de conexión a PostgreSQL
2. Si ves `Missing required environment variables: DATABASE_URL`, añade la variable
3. Si ves errores de conexión, verifica que:
   - La `DATABASE_URL` esté correcta (con la contraseña)
   - El proyecto de Supabase esté activo
   - La IP de Railway esté permitida en Supabase (por defecto, todas las IPs están permitidas)

### Paso 4.4: Probar OAuth (Mock)

1. El endpoint `/api/auth/oauth` está implementado con mock
2. Puedes probarlo con Postman o curl:
   ```bash
   curl -X POST https://tu-backend.railway.app/api/auth/oauth \
     -H "Content-Type: application/json" \
     -d '{
       "provider": "google",
       "token": "mock-token",
       "email": "test@example.com",
       "oauthId": "mock-oauth-id"
     }'
   ```
3. Deberías recibir un JWT token y datos de usuario

---

## 5. Configuración Adicional (Opcional)

### 5.1: Dominio Personalizado en Railway

1. En Railway, ve a **Settings** → **Domains**
2. Click en **"Generate Domain"** o **"Custom Domain"**
3. Si usas dominio personalizado, configura DNS:
   - Tipo: `CNAME`
   - Nombre: `api` (o el subdominio que quieras)
   - Valor: La URL que Railway te da

### 5.2: Actualizar Frontend con la URL del Backend

1. En Flutter, actualiza `lib/shared/utils/constants.dart`:
   ```dart
   static const String apiBaseUrl = String.fromEnvironment(
     'API_BASE_URL',
     defaultValue: 'https://tu-backend.railway.app', // ← Cambia esto
   );
   ```
2. O compila con:
   ```bash
   flutter build apk --dart-define=API_BASE_URL=https://tu-backend.railway.app
   ```

### 5.3: Configurar Google Sign-In y Apple Sign-In

**Google Sign-In:**
1. Ve a [Google Cloud Console](https://console.cloud.google.com)
2. Crea un proyecto o selecciona uno
3. Ve a **APIs & Services** → **Credentials**
4. Click en **"Create Credentials"** → **"OAuth 2.0 Client ID"**
5. Tipo: **Android** (para la app)
6. Package name: `com.receiptdata.app` (o el que tengas en `android/app/build.gradle`)
7. SHA-1: Obtén con `keytool -list -v -keystore android/app/debug.keystore`
8. Copia el **Client ID** y úsalo en el código Flutter

**Apple Sign-In:**
1. Ve a [Apple Developer](https://developer.apple.com)
2. Crea un App ID con "Sign in with Apple" habilitado
3. Configura el servicio en Xcode (solo para iOS)

---

## 6. Checklist Final

Antes de considerar la configuración completa, verifica:

- [ ] Base de datos PostgreSQL creada en Supabase
- [ ] Schema SQL ejecutado correctamente (5 tablas visibles)
- [ ] `DATABASE_URL` configurada en Railway
- [ ] `JWT_SECRET` generado y configurado
- [ ] `GEMINI_API_KEY` configurada
- [ ] `REDIS_URL` configurada (Redis en Railway o externo)
- [ ] `STRIPE_SECRET_KEY` configurada
- [ ] Backend arranca sin errores (ver logs en Railway)
- [ ] Health check responde: `/health` devuelve `{"status": "ok"}`
- [ ] Frontend apunta a la URL correcta del backend

---

## 7. Troubleshooting

### Error: "Missing required environment variables"
- **Solución**: Añade todas las variables obligatorias en Railway → Variables

### Error: "Connection refused" a PostgreSQL
- **Solución**: Verifica que `DATABASE_URL` tenga el formato correcto y la contraseña sea válida

### Error: "JWT secret must be provided"
- **Solución**: Añade `JWT_SECRET` en Railway → Variables

### Backend no arranca
- **Solución**: Revisa los logs en Railway → View Logs para ver el error específico

### Health check no responde
- **Solución**: Verifica que el servicio esté desplegado y corriendo (ver Deployments)

---

## 📞 Soporte

Si tienes problemas, revisa:
1. Los logs de Railway (View Logs)
2. Los logs de Supabase (Logs Explorer)
3. La documentación de Railway: https://docs.railway.app
4. La documentación de Supabase: https://supabase.com/docs

---

**¡Listo!** Con estos pasos, tu backend estará funcionando y conectado a la base de datos. 🚀
