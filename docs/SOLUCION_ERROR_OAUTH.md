# 🔧 Solución: Error "Route POST:/auth/oauth not found"

## Problema

Cuando intentas hacer login con Google o Apple, aparece el error:
```
Error: Exception: Route POST:/auth/oauth not found
```

## Causa

El frontend está intentando conectarse a una URL incorrecta del backend, o el backend no está accesible.

## Solución

### Paso 1: Obtener la URL Correcta de Railway

1. Ve a [Railway](https://railway.app)
2. Selecciona tu proyecto `receiptdata.app`
3. Ve a **Settings** → **Domains**
4. Copia la URL que aparece (ej: `https://receiptdata-production.up.railway.app`)

### Paso 2: Actualizar la URL en Flutter

**Opción A: Actualizar el código (recomendado para producción)**

1. Abre `lib/shared/utils/constants.dart`
2. Busca la línea con `apiBaseUrl`
3. Cambia el `defaultValue` a tu URL de Railway:
   ```dart
   static const String apiBaseUrl = String.fromEnvironment(
     'API_BASE_URL',
     defaultValue: 'https://TU-URL-DE-RAILWAY.railway.app', // ← Pega aquí tu URL
   );
   ```

**Opción B: Compilar con la URL (para testing rápido)**

```bash
flutter run -d emulator-5554 --dart-define=API_BASE_URL=https://TU-URL-DE-RAILWAY.railway.app
```

### Paso 3: Verificar que el Backend Funciona

1. Abre en el navegador: `https://TU-URL-DE-RAILWAY.railway.app/health`
2. Deberías ver: `{"status": "ok", ...}`
3. Si no funciona, verifica los logs en Railway → View Logs

### Paso 4: Verificar Variables de Entorno en Railway

Asegúrate de tener estas variables en Railway → Variables:

- ✅ `DATABASE_URL`
- ✅ `JWT_SECRET`
- ✅ `GEMINI_API_KEY`
- ✅ `REDIS_URL`
- ✅ `STRIPE_SECRET_KEY`
- ✅ `GOOGLE_CLIENT_ID` (para verificación OAuth)

---

## Verificación Rápida

**Prueba el endpoint directamente:**

```bash
curl -X POST https://TU-URL-DE-RAILWAY.railway.app/api/auth/oauth \
  -H "Content-Type: application/json" \
  -d '{
    "provider": "google",
    "token": "test",
    "email": "test@test.com",
    "oauthId": "test123"
  }'
```

**Si funciona:** Deberías recibir un error de verificación OAuth (esperado con token de prueba), pero NO un "Route not found".

**Si no funciona:** El backend no está corriendo o la URL es incorrecta.

---

## Nota sobre Desarrollo Local

Si quieres usar el backend local en lugar de Railway:

1. Inicia el backend localmente:
   ```bash
   cd backend
   npm start
   ```

2. Actualiza `constants.dart`:
   ```dart
   defaultValue: 'http://10.0.2.2:8080', // Android emulator localhost
   ```

3. Asegúrate de tener todas las variables de entorno configuradas localmente.

---

**Última actualización:** 2025-01-XX

