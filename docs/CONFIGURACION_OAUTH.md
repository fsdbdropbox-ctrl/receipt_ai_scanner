# 🔐 Configuración de OAuth: Google y Apple

Esta guía explica cómo configurar la verificación OAuth para Google y Apple en AuditReady.

---

## 📋 Resumen

La verificación OAuth ha sido **implementada** en el backend. Ahora el servidor verifica que los tokens OAuth sean válidos antes de autenticar usuarios, previniendo ataques de autenticación falsa.

---

## ✅ Lo que ya está implementado

### Backend
- ✅ Verificación de tokens Google usando `google-auth-library`
- ✅ Verificación de tokens Apple usando JWKS (claves públicas de Apple)
- ✅ Validación de `oauthId` y `email` contra el token verificado
- ✅ Manejo de errores seguro

### Frontend
- ⚠️ Aún usa tokens mock (necesita implementación real)

---

## 🔧 Configuración Requerida

### 1. Google OAuth

**Variable de entorno necesaria:**
```bash
GOOGLE_CLIENT_ID=tu-google-client-id.apps.googleusercontent.com
```

**Cómo obtenerlo:**

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Crea un nuevo proyecto o selecciona uno existente
3. Ve a **APIs & Services** → **Credentials**
4. Click en **Create Credentials** → **OAuth client ID**
5. Selecciona **Web application** (o **iOS/Android** según tu caso)
6. Configura:
   - **Name**: `AuditReady`
   - **Authorized redirect URIs**: (no necesario para mobile, pero puedes añadir tu backend URL)
7. Copia el **Client ID** (no el Client Secret)
8. Añádelo en Railway como `GOOGLE_CLIENT_ID`

**Nota:** Para aplicaciones móviles, también puedes crear un OAuth client ID de tipo "iOS" o "Android" con el bundle ID de tu app.

---

### 2. Apple OAuth

**No requiere configuración adicional en el backend.**

Apple usa claves públicas (JWKS) que se obtienen automáticamente desde `https://appleid.apple.com/auth/keys`.

**Lo que SÍ necesitas hacer en el frontend:**

1. Configurar Apple Sign-In en tu app Flutter
2. Obtener el token ID de Apple
3. Enviar el token al backend

**Configuración en Apple Developer:**

1. Ve a [Apple Developer Portal](https://developer.apple.com/)
2. Ve a **Certificates, Identifiers & Profiles**
3. Crea un **Service ID** para tu app
4. Configura **Sign in with Apple** en el Service ID
5. Añade tu dominio y redirect URLs

---

## 🚀 Añadir Variables en Railway

1. Ve a **Railway** → Tu servicio → **Variables**
2. Añade:

```bash
GOOGLE_CLIENT_ID=tu-google-client-id.apps.googleusercontent.com
```

**Nota:** Esta variable es **recomendada** pero no obligatoria. El backend funcionará sin ella, pero la verificación de Google fallará si no está configurada.

---

## 🧪 Cómo Funciona

### Flujo de Verificación

1. **Cliente (Flutter)** obtiene token OAuth de Google/Apple
2. **Cliente** envía token al backend: `POST /api/auth/oauth`
3. **Backend** verifica el token:
   - **Google**: Usa `google-auth-library` para verificar el ID token
   - **Apple**: Verifica la firma JWT usando las claves públicas de Apple
4. **Backend** extrae `oauthId` y `email` del token verificado
5. **Backend** compara con los valores enviados por el cliente
6. Si todo es correcto, crea/actualiza el usuario y devuelve JWT

### Seguridad

- ✅ **Tokens verificados**: No se aceptan tokens falsos
- ✅ **Email verificado**: Se usa el email del token (más confiable)
- ✅ **OAuth ID verificado**: Se compara con el token verificado
- ✅ **Errores sanitizados**: No se exponen detalles internos

---

## ⚠️ Notas Importantes

### Google

- El `GOOGLE_CLIENT_ID` debe coincidir con el que usas en tu app Flutter
- Para apps móviles, puedes usar el mismo Client ID o crear uno específico
- El backend verifica que el token sea válido y no haya expirado

### Apple

- Apple puede no incluir el email en el token (privacy feature)
- Si el email no está en el token, el backend usa el email del request body
- El token debe ser válido y no expirado
- La verificación usa las claves públicas de Apple (automático)

---

## 🐛 Troubleshooting

### Error: "GOOGLE_CLIENT_ID environment variable is required"

**Solución:** Añade `GOOGLE_CLIENT_ID` en Railway → Variables

### Error: "Google token verification failed"

**Posibles causas:**
- Token expirado (los tokens OAuth expiran)
- Token inválido o malformado
- `GOOGLE_CLIENT_ID` no coincide con el usado en la app
- Token no es un ID token válido

**Solución:**
- Verifica que `GOOGLE_CLIENT_ID` sea correcto
- Asegúrate de que el cliente esté enviando un ID token válido (no un access token)

### Error: "Apple token verification failed"

**Posibles causas:**
- Token expirado
- Token inválido o malformado
- Token no es un ID token válido de Apple

**Solución:**
- Verifica que el cliente esté enviando un ID token válido de Apple
- Asegúrate de que la app esté configurada correctamente en Apple Developer

### Error: "OAuth ID mismatch"

**Causa:** El `oauthId` enviado por el cliente no coincide con el del token verificado.

**Solución:** Verifica que el cliente esté extrayendo correctamente el `oauthId` del token.

---

## 📝 Próximos Pasos

### Frontend (Flutter)

Necesitas implementar la obtención real de tokens OAuth:

1. **Google Sign-In:**
   - Usa `google_sign_in` package
   - Obtén el ID token: `GoogleSignInAccount.idToken`
   - Envía el token al backend

2. **Apple Sign-In:**
   - Usa `sign_in_with_apple` package
   - Obtén el ID token: `AuthorizationCredentialAppleID.identityToken`
   - Envía el token al backend

**Ejemplo de código (pseudo):**
```dart
// Google
final GoogleSignInAccount? account = await GoogleSignIn().signIn();
final GoogleSignInAuthentication auth = await account!.authentication;
final String idToken = auth.idToken!;

// Apple
final credential = await SignInWithApple.getAppleIDCredential(
  scopes: [AppleIDAuthorizationScopes.email],
);
final String idToken = credential.identityToken!;
```

---

## ✅ Checklist

- [ ] `GOOGLE_CLIENT_ID` añadido en Railway
- [ ] Google OAuth configurado en Google Cloud Console
- [ ] Apple Sign-In configurado en Apple Developer (si usas Apple)
- [ ] Frontend implementa obtención real de tokens OAuth
- [ ] Pruebas de autenticación realizadas

---

## 📚 Referencias

- [Google OAuth 2.0](https://developers.google.com/identity/protocols/oauth2)
- [Apple Sign In](https://developer.apple.com/sign-in-with-apple/)
- [google-auth-library](https://github.com/googleapis/google-auth-library-nodejs)
- [jwks-rsa](https://github.com/auth0/node-jwks-rsa)

---

**Última actualización:** 2025-01-XX

