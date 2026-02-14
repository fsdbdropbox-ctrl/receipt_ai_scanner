# 🔧 Solución: Token "mock-token" o Token Verification Failed

## Problema

Cuando intentas hacer login con Google, el backend recibe un token "mock-token" (10 caracteres) en lugar de un token real de Google, causando el error "Token verification failed".

## Causa

El `serverClientId` en el código Flutter debe ser un **Client ID de tipo Web**, no Android.

Para Google Sign-In en Android, hay dos tipos de Client IDs:
- **Android Client ID**: Se usa para la autenticación nativa de Android (ya configurado)
- **Web Client ID**: Se usa como `serverClientId` para obtener el ID token que se envía al backend (FALTA)

## Solución

### Paso 1: Crear Client ID de tipo Web en Google Cloud Console

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Selecciona tu proyecto
3. Ve a **APIs & Services** → **Credentials**
4. Click en **"Create Credentials"** → **"OAuth client ID"**
5. Selecciona **Application type: Web application**
6. Configura:
   - **Name**: `AuditReady Web Client`
   - **Authorized JavaScript origins**: (opcional, para web)
   - **Authorized redirect URIs**: (opcional, para web)
7. Click **"Create"**
8. **Copia el Client ID** (formato: `123456789-abcdefghijklmnop.apps.googleusercontent.com`)

### Paso 2: Actualizar el código Flutter

✅ **YA CONFIGURADO** - El código ya tiene el Web Client ID configurado:
- Client ID: `967736229136-jccfe2msg2trmhb65mmp3h156ofiqb8m.apps.googleusercontent.com`
- Ubicación: `lib/core/auth/auth_service.dart` línea 18

### Paso 3: Actualizar Railway

1. Ve a Railway → Tu servicio backend → **Variables**
2. Actualiza `GOOGLE_CLIENT_ID` con el **mismo Client ID de tipo Web** que usaste en Flutter
3. Guarda los cambios (Railway hará redeploy automáticamente)

### Paso 4: Verificar

1. Recompila la app Flutter
2. Intenta hacer login con Google
3. El token debería ser un JWT largo (>100 caracteres), no "mock-token"

## Verificación

Después de aplicar estos cambios:

1. **En Flutter logs**, deberías ver:
   ```
   🔑 Google Sign-In Info:
      ID Token length: 800+ (no 10)
      ID Token: eyJhbGciOiJSUzI1NiIsImtpZCI6Ij...
   ```

2. **En Railway logs**, deberías ver:
   ```
   Attempting OAuth token verification {
     provider: 'google',
     tokenPrefix: 'eyJhbGciOiJSUzI1NiIsImtpZCI6Ij...',
     hasGoogleClientId: true
   }
   Google token verified successfully
   ```

## Nota Importante

- El **Android Client ID** se usa para la autenticación nativa
- El **Web Client ID** se usa como `serverClientId` para obtener el ID token
- Ambos deben estar en el mismo proyecto de Google Cloud Console
- El `GOOGLE_CLIENT_ID` en Railway debe ser el **Web Client ID**, no el Android

---

**Última actualización:** 2026-01-12

