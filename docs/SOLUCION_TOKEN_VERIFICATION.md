# 🔧 Solución: "Token verification failed"

## Problema

Cuando intentas hacer login con Google o Apple, aparece el error:
```
Token verification failed. Please sign in again.
```

## Causa

El backend no puede verificar el token OAuth porque falta la configuración de `GOOGLE_CLIENT_ID` en Railway.

## Solución

### Paso 1: Obtener Google Client ID

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Selecciona tu proyecto
3. Ve a **APIs & Services** → **Credentials**
4. Busca tu **OAuth 2.0 Client ID** (tipo Android o Web)
5. Copia el **Client ID** (no el Client Secret)
   - Formato: `123456789-abcdefghijklmnop.apps.googleusercontent.com`

### Paso 2: Añadir en Railway

1. Ve a Railway → Tu servicio backend
2. Ve a **Variables**
3. Añade nueva variable:
   - **Nombre**: `GOOGLE_CLIENT_ID`
   - **Valor**: Pega el Client ID que copiaste
4. Guarda los cambios

### Paso 3: Verificar que Coincide

**IMPORTANTE:** El Client ID en Railway debe ser el mismo que el que usas en tu app Flutter.

**Para Android:**
- El Client ID debe ser del tipo "Android"
- El Package name debe ser: `com.receiptdata.app`
- El SHA-1 debe coincidir con el de tu keystore

**Para verificar en Flutter:**
- Revisa `lib/core/auth/auth_service.dart`
- El `GoogleSignIn` usa el Client ID del `google-services.json` o del `AndroidManifest.xml`

### Paso 4: Redeploy

Railway debería hacer redeploy automáticamente cuando añades una variable. Si no:
1. Ve a Railway → Deployments
2. Click en **Redeploy**

---

## Verificación

Después de añadir `GOOGLE_CLIENT_ID`:

1. Intenta hacer login de nuevo
2. Debería funcionar correctamente
3. Si sigue fallando, revisa los logs en Railway para ver el error específico

---

## Nota sobre Apple Sign-In

Apple Sign-In **NO requiere** configuración adicional en el backend porque usa claves públicas (JWKS) que se obtienen automáticamente.

Si Apple Sign-In falla, el problema está en la configuración del frontend (Xcode, bundle ID, etc.).

---

## Troubleshooting

### Error: "GOOGLE_CLIENT_ID environment variable is required"
- **Solución**: Añade `GOOGLE_CLIENT_ID` en Railway → Variables

### Error: "Invalid audience"
- **Solución**: El Client ID en Railway no coincide con el que se usó para generar el token. Verifica que sean el mismo.

### Error: "Token expired"
- **Solución**: Los tokens OAuth expiran. Intenta hacer login de nuevo.

---

**Última actualización:** 2025-01-12

