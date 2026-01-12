# 🔍 Verificar URL de Railway

## Problema

El backend no responde porque la URL no es correcta.

## Solución

### Paso 1: Obtener la URL Correcta de Railway

1. Ve a [Railway](https://railway.app)
2. Selecciona tu proyecto
3. Click en tu servicio (backend)
4. Ve a **Settings** → **Domains**
5. Copia la URL que aparece (ejemplo: `https://tu-proyecto-xxxx.up.railway.app`)

### Paso 2: Actualizar la URL en el Código

1. Abre `lib/shared/utils/constants.dart`
2. Busca la línea con `apiBaseUrl`
3. Cambia el `defaultValue` a tu URL de Railway:
   ```dart
   static const String apiBaseUrl = String.fromEnvironment(
     'API_BASE_URL',
     defaultValue: 'https://TU-URL-REAL-DE-RAILWAY.railway.app',
   );
   ```

### Paso 3: Verificar que el Backend Funciona

Abre en el navegador:
```
https://TU-URL-REAL-DE-RAILWAY.railway.app/health
```

Debería devolver:
```json
{
  "status": "ok",
  "timestamp": "...",
  "version": "1.0.0"
}
```

---

## Nota

La URL `receiptdata-production.up.railway.app` que estaba en el código es solo un ejemplo. Debes usar la URL real que Railway te proporciona.

