# 🔍 Verificar Google Client ID

## Client ID que tienes configurado

```
967736229136-6trttcp44a4vhkc9g8st2dpj8430vbcl.apps.googleusercontent.com
```

## Verificación en Google Cloud Console

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. **APIs & Services** → **Credentials**
3. Busca el Client ID: `967736229136-6trttcp44a4vhkc9g8st2dpj8430vbcl.apps.googleusercontent.com`
4. Verifica que:
   - **Tipo**: Debe ser **Android** (NO Web)
   - **Package name**: `com.receiptdata.app`
   - **SHA-1**: Debe coincidir con el de tu keystore

## Verificación en Railway

1. Ve a Railway → Tu servicio → **Variables**
2. Verifica que `GOOGLE_CLIENT_ID` sea exactamente:
   ```
   967736229136-6trttcp44a4vhkc9g8st2dpj8430vbcl.apps.googleusercontent.com
   ```
3. **IMPORTANTE**: Sin espacios, sin comillas, exactamente como está arriba

## Problema Común: Tipo de Client ID Incorrecto

Si el Client ID en Google Cloud Console es de tipo **Web** en lugar de **Android**, no funcionará.

**Solución:**
1. Crea un nuevo OAuth Client ID de tipo **Android**
2. Package name: `com.receiptdata.app`
3. SHA-1: Obtén con `.\gradlew signingReport` en `android/`
4. Usa ese nuevo Client ID en Railway

## Verificar SHA-1

```powershell
cd receipt_ai_scanner/android
.\gradlew signingReport
```

Busca:
```
Variant: debug
SHA1: XX:XX:XX:XX:...
```

Este SHA-1 debe estar en Google Cloud Console para el Client ID.

## Logs de Debug

Después del deploy, cuando intentes hacer login, revisa los logs en Railway → View Logs. Deberías ver:

```
Attempting OAuth token verification {
  provider: 'google',
  hasGoogleClientId: true,
  googleClientIdPrefix: '967736229136-6trttcp44...'
}
```

Si ves un error de "Invalid audience", significa que el Client ID no coincide.

---

**Última actualización:** 2025-01-12

