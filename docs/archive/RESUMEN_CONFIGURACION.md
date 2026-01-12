# 📋 Resumen Ejecutivo: Configuración de AuditReady 1.0

## ✅ Estado Actual

- ✅ **Frontend (Flutter)**: Compilado y ejecutándose en emulador
- ✅ **Backend (Node.js)**: Código completo, listo para desplegar
- ✅ **Base de Datos**: Schema SQL listo para ejecutar
- ⚠️ **OAuth**: Implementado con mock (funciona para testing, necesita configuración real para producción)

---

## 🎯 Lo que DEBES hacer TÚ (No puedo hacerlo automáticamente)

### 1️⃣ **Supabase (Base de Datos PostgreSQL)**

**Tiempo estimado: 10 minutos**

1. Ve a https://supabase.com y crea un proyecto
2. Copia la **Connection String** (formato: `postgresql://postgres:PASSWORD@db.xxxxx.supabase.co:5432/postgres`)
3. Ve a **SQL Editor** en Supabase
4. Abre el archivo: `receipt_ai_scanner/backend/src/db/schema.sql`
5. **Copia TODO el contenido** y pégalo en el SQL Editor
6. Click en **"Run"**
7. Verifica que aparezcan 5 tablas en **Table Editor**

**📄 Guía completa**: Ver `docs/CONFIGURACION_SUPABASE_RAILWAY.md` (sección 1)

---

### 2️⃣ **Railway (Backend API)**

**Tiempo estimado: 15 minutos**

1. Ve a https://railway.app y conecta tu repositorio de GitHub
2. Crea un nuevo proyecto desde tu repo `receipt_ai_scanner`
3. Configura el **Root Directory** como `backend`
4. Añade estas **Variables de Entorno** (en Railway → Variables):

#### 🔴 OBLIGATORIAS:

```bash
DATABASE_URL=postgresql://postgres:TU_PASSWORD@db.xxxxx.supabase.co:5432/postgres
JWT_SECRET=genera-una-string-aleatoria-de-32-caracteres-minimo
GEMINI_API_KEY=tu-api-key-de-google-gemini
REDIS_URL=redis://default:password@redis.railway.app:6379
STRIPE_SECRET_KEY=sk_test_... o sk_live_...
```

#### 🟡 RECOMENDADAS:

```bash
STRIPE_WEBHOOK_SECRET=whsec_...
ALLOWED_ORIGINS=https://tu-dominio.com
NODE_ENV=production
```

5. Railway desplegará automáticamente
6. Verifica que el backend arranque (ve a **View Logs**)
7. Prueba: `https://tu-backend.railway.app/health` (debe devolver `{"status": "ok"}`)

**📄 Guía completa**: Ver `docs/CONFIGURACION_SUPABASE_RAILWAY.md` (sección 2)

---

### 3️⃣ **Actualizar Frontend con URL del Backend**

**Tiempo estimado: 2 minutos**

1. Abre `receipt_ai_scanner/lib/shared/utils/constants.dart`
2. Cambia la línea 14:
   ```dart
   defaultValue: 'https://tu-backend.railway.app', // ← Pega aquí la URL de Railway
   ```
3. O compila con:
   ```bash
   flutter build apk --dart-define=API_BASE_URL=https://tu-backend.railway.app
   ```

---

### 4️⃣ **Obtener las API Keys Necesarias**

#### Google Gemini API Key (para escaneo IA)
1. Ve a https://makersuite.google.com/app/apikey
2. Click en **"Get API Key"**
3. Copia la key y pégala en Railway como `GEMINI_API_KEY`

#### Stripe Keys (para pagos)
1. Ve a https://dashboard.stripe.com
2. **Developers** → **API keys**
3. Copia `STRIPE_SECRET_KEY` (empieza con `sk_test_` o `sk_live_`)
4. Para webhook: **Developers** → **Webhooks** → Crea endpoint → Copia `STRIPE_WEBHOOK_SECRET`

#### Redis (para rate limiting)
- **Opción A**: En Railway, click **"New"** → **"Database"** → **"Add Redis"** (Railway lo configura automáticamente)
- **Opción B**: Usa Redis Cloud (gratis): https://redis.com/try-free/

#### JWT Secret (para autenticación)
- Genera una string aleatoria de 32+ caracteres
- Puedes usar: https://randomkeygen.com/ (usa "CodeIgniter Encryption Keys")

---

## 📝 Checklist Rápido

Marca cada paso cuando lo completes:

- [ ] Proyecto creado en Supabase
- [ ] Schema SQL ejecutado (5 tablas visibles)
- [ ] `DATABASE_URL` copiada de Supabase
- [ ] Proyecto creado en Railway
- [ ] Backend desplegado en Railway
- [ ] `DATABASE_URL` añadida en Railway Variables
- [ ] `JWT_SECRET` generado y añadido
- [ ] `GEMINI_API_KEY` obtenida y añadida
- [ ] `REDIS_URL` configurada (Redis en Railway o externo)
- [ ] `STRIPE_SECRET_KEY` añadida
- [ ] Health check funciona: `/health` devuelve `{"status": "ok"}`
- [ ] Frontend actualizado con URL de Railway
- [ ] App compilada y probada en emulador

---

## 🚨 Problemas Comunes

### "Missing required environment variables"
→ Añade todas las variables obligatorias en Railway → Variables

### "Connection refused" a PostgreSQL
→ Verifica que `DATABASE_URL` tenga el formato correcto y la contraseña sea válida

### Backend no arranca
→ Revisa los logs en Railway → View Logs

### Health check no responde
→ Verifica que el servicio esté desplegado (Railway → Deployments)

---

## 📚 Documentación Completa

Para instrucciones detalladas paso a paso, consulta:
- **`docs/CONFIGURACION_SUPABASE_RAILWAY.md`** - Guía completa con screenshots y troubleshooting

---

## 🎉 Una vez completado

Cuando hayas configurado todo:

1. ✅ La app Flutter se conectará al backend en Railway
2. ✅ El backend guardará datos en Supabase
3. ✅ Podrás hacer login (mock), configurar perfil fiscal, escanear facturas, etc.
4. ⚠️ OAuth real (Google/Apple) requiere configuración adicional (ver sección 5.3 de la guía completa)

---

**¿Necesitas ayuda?** Revisa los logs en Railway y Supabase para ver errores específicos.
