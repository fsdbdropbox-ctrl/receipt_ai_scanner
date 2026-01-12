# 🔧 Guía de Configuración Completa

Esta guía te lleva paso a paso desde cero hasta tener AuditReady funcionando en producción.

---

## 📋 Índice

1. [Configuración de Base de Datos (Supabase)](#1-configuración-de-base-de-datos-supabase)
2. [Configuración de Backend (Railway)](#2-configuración-de-backend-railway)
3. [Configuración de OAuth (Google)](#3-configuración-de-oauth-google)
4. [Configuración de OAuth (Apple)](#4-configuración-de-oauth-apple)
5. [Verificación Final](#5-verificación-final)

---

## 1. Configuración de Base de Datos (Supabase)

### Paso 1.1: Crear Proyecto

1. Ve a [https://supabase.com](https://supabase.com)
2. Inicia sesión o crea una cuenta
3. Click en **"New Project"**
4. Completa:
   - **Name**: `auditready-prod`
   - **Database Password**: Genera una contraseña segura (guárdala)
   - **Region**: Elige la más cercana (ej: `West Europe` para España)
5. Click en **"Create new project"**
6. Espera 2-3 minutos

### Paso 1.2: Ejecutar Schema SQL

1. En Supabase, ve a **SQL Editor**
2. Click en **"New query"**
3. Abre `receipt_ai_scanner/backend/src/db/schema.sql`
4. **Copia TODO el contenido** del archivo
5. Pega en el editor SQL de Supabase
6. Click en **"Run"** (o `Ctrl+Enter`)

### Paso 1.3: Obtener Connection String

1. Ve a **Settings** → **Database**
2. Busca **"Connection string"**
3. Selecciona **"URI"** (no "Session mode")
4. Copia la connection string
5. **Reemplaza `[YOUR-PASSWORD]`** con tu contraseña
6. Guarda esta string completa (la usarás como `DATABASE_URL`)

---

## 2. Configuración de Backend (Railway)

### Paso 2.1: Crear Servicio

1. Ve a [Railway](https://railway.app)
2. Crea un nuevo proyecto
3. Conecta tu repositorio GitHub
4. Selecciona el directorio `receipt_ai_scanner/backend`

### Paso 2.2: Añadir Variables de Entorno

Ve a **Variables** y añade:

**Obligatorias:**
```bash
DATABASE_URL=postgresql://postgres:TU_PASSWORD@db.xxxxx.supabase.co:5432/postgres
JWT_SECRET=genera-una-string-aleatoria-de-32-caracteres-minimo
GEMINI_API_KEY=tu-gemini-api-key
REDIS_URL=tu-redis-url-de-upstash
STRIPE_SECRET_KEY=tu-stripe-secret-key
```

**Recomendadas:**
```bash
GOOGLE_CLIENT_ID=tu-google-client-id.apps.googleusercontent.com
STRIPE_WEBHOOK_SECRET=tu-stripe-webhook-secret
ALLOWED_ORIGINS=https://tu-dominio.com,https://api.tu-dominio.com
SENTRY_DSN=tu-sentry-dsn
NODE_ENV=production
```

**Cómo generar JWT_SECRET:**
- Opción 1: https://randomkeygen.com/ (usa "CodeIgniter Encryption Keys")
- Opción 2: `openssl rand -base64 32`

### Paso 2.3: Verificar Deployment

1. Railway debería hacer deploy automáticamente
2. Ve a **Deployments** → **View Logs**
3. Deberías ver: `Server listening on port 8080`
4. Prueba: `https://tu-backend.railway.app/health`
5. Debe devolver: `{"status": "ok", ...}`

---

## 3. Configuración de OAuth (Google)

### Paso 3.1: Crear OAuth Client en Google Cloud

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Crea/selecciona un proyecto
3. Ve a **APIs & Services** → **Credentials**
4. Click en **"Create Credentials"** → **"OAuth client ID"**
5. Si es la primera vez, configura OAuth consent screen:
   - User Type: **External**
   - App name: `AuditReady`
   - User support email: tu email
   - Developer contact: tu email
   - Click **"Save and Continue"** hasta completar

### Paso 3.2: Crear OAuth Client ID (Android)

1. En **Create OAuth client ID**:
   - Application type: **Android**
   - Name: `AuditReady Android`
   - Package name: `com.receiptdata.app`
   - SHA-1 certificate fingerprint: (ver abajo)
2. Click **"Create"**
3. Copia el **Client ID** (no el Secret)

### Paso 3.3: Obtener SHA-1 Fingerprint

**Para Debug (desarrollo):**
```powershell
cd receipt_ai_scanner/android
.\gradlew signingReport
```

Busca en la salida:
```
Variant: debug
SHA1: XX:XX:XX:XX:...  ← Copia este valor
```

**Para Release (producción):**
```powershell
keytool -list -v -keystore "ruta\a\tu\keystore.jks" -alias tu-alias
```

### Paso 3.4: Añadir SHA-1 en Google Cloud

1. Ve al OAuth Client ID que creaste
2. Click en **"Edit"**
3. Añade el SHA-1 en **"SHA-1 certificate fingerprints"**
4. Guarda

### Paso 3.5: Añadir Client ID en Railway

1. En Railway → Variables
2. Añade: `GOOGLE_CLIENT_ID=tu-client-id.apps.googleusercontent.com`

---

## 4. Configuración de OAuth (Apple)

### Paso 4.1: Configurar en Apple Developer

1. Ve a [Apple Developer Portal](https://developer.apple.com/)
2. Ve a **Certificates, Identifiers & Profiles**
3. Crea un **Service ID** para tu app
4. Configura **Sign in with Apple** en el Service ID
5. Añade tu dominio y redirect URLs

**Nota:** Apple Sign-In no requiere configuración adicional en el backend (usa claves públicas automáticamente).

---

## 5. Verificación Final

### Checklist

- [ ] Base de datos: 5 tablas creadas en Supabase
- [ ] Railway: Backend arranca sin errores
- [ ] Health check: `/health` devuelve `{"status": "ok"}`
- [ ] Variables: Todas las obligatorias configuradas
- [ ] Google OAuth: Client ID configurado y SHA-1 añadido
- [ ] Apple OAuth: Service ID configurado (si aplica)

### Pruebas

1. **Backend:**
   ```bash
   curl https://tu-backend.railway.app/health
   ```

2. **Frontend:**
   - Compila la app: `flutter build apk` (Android) o `flutter build ios` (iOS)
   - Prueba login con Google
   - Verifica que el backend valida el token correctamente

---

## 🐛 Troubleshooting

### Error: "Missing required environment variables"

→ Verifica que todas las variables obligatorias estén en Railway

### Error: "Connection refused" a PostgreSQL

→ Verifica que `DATABASE_URL` tenga el formato correcto y la contraseña sea válida

### Error: "Google token verification failed"

→ Verifica que `GOOGLE_CLIENT_ID` sea correcto y coincida con el de tu app

### Error: "JWT_SECRET is required in production"

→ Añade `JWT_SECRET` en Railway (mínimo 32 caracteres)

---

## 📚 Referencias

- [Supabase Docs](https://supabase.com/docs)
- [Railway Docs](https://docs.railway.app)
- [Google OAuth](https://developers.google.com/identity/protocols/oauth2)
- [Apple Sign In](https://developer.apple.com/sign-in-with-apple/)

---

**Última actualización:** 2025-01-XX

