# 🚀 Deploy en Railway - Guía Rápida

## Problema: "Route GET:/ not found"

Si ves este error, significa que el backend necesita un nuevo deploy con los últimos cambios.

---

## Solución: Hacer Deploy en Railway

### Opción 1: Deploy Automático (Recomendado)

Railway hace deploy automático cuando haces push a GitHub:

1. **Commit y push los cambios:**
   ```bash
   git add .
   git commit -m "Add root route and fix OAuth"
   git push
   ```

2. **Railway detectará el push automáticamente** y hará deploy

3. **Verifica el deploy:**
   - Ve a Railway → Deployments
   - Espera a que aparezca "Deployed successfully"
   - Revisa los logs para asegurarte de que no hay errores

### Opción 2: Deploy Manual

1. Ve a Railway → Tu servicio
2. Click en **"Deploy"** → **"Redeploy"**
3. Espera a que termine

---

## Verificación Post-Deploy

### 1. Health Check

Abre en el navegador:
```
https://TU-URL-DE-RAILWAY.railway.app/health
```

Debería devolver:
```json
{
  "status": "ok",
  "timestamp": "...",
  "version": "1.0.0"
}
```

### 2. Root Endpoint

Abre:
```
https://TU-URL-DE-RAILWAY.railway.app/
```

Debería devolver información del servicio (nuevo endpoint añadido).

### 3. OAuth Endpoint

Prueba:
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

Debería devolver un error de verificación OAuth (esperado), pero NO "Route not found".

---

## Cambios Realizados

- ✅ Añadida ruta raíz (`/`) que devuelve información del servicio
- ✅ Ruta `/api/auth/oauth` verificada y funcionando
- ✅ Todos los tests pasando

---

## Si el Error Persiste

1. **Verifica los logs en Railway:**
   - Ve a Railway → View Logs
   - Busca errores sobre variables de entorno faltantes
   - Verifica que el servidor arranque correctamente

2. **Verifica variables de entorno:**
   - Asegúrate de tener todas las obligatorias configuradas
   - Ver `docs/SETUP.md` para la lista completa

3. **Verifica la URL:**
   - Asegúrate de que la URL en `constants.dart` sea correcta
   - Debe coincidir exactamente con la URL de Railway

---

**Última actualización:** 2025-01-XX

