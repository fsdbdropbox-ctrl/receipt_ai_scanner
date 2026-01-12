# Estrategia Detallada: Publicación en Google Play Store

**Fecha:** Enero 2025  
**Estado Actual:** ReceiptData v1.0.0 - Backend desplegado, Frontend listo  
**Objetivo:** Publicación en Play Store con seguridad y cumplimiento completo

---

## 📊 Estado Actual

### ✅ Completado
- Backend desplegado en Railway
- Frontend Flutter funcional
- Sistema de autenticación (Install ID)
- Rate limiting y seguridad básica
- Integración con Stripe
- Monitoreo con Sentry

### ⚠️ Pendiente para Play Store
- Firma de aplicación (keystore)
- Configuración de seguridad Android
- Política de privacidad y términos
- Assets de Play Store (iconos, screenshots)
- Testing en dispositivos reales
- Optimización de rendimiento
- Cumplimiento de políticas de Google

---

## 🎯 Fases de Implementación

### FASE 1: Seguridad y Configuración Android (Semana 1-2)

#### 1.1. Configuración de Firma de Aplicación

**Objetivo:** Crear keystore para firmar la aplicación de producción

**Pasos:**

1. **Generar Keystore:**
```bash
cd receipt_ai_scanner/android
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**Información requerida:**
- Alias: `upload`
- Contraseña: **GUARDAR EN LUGAR SEGURO** (usar gestor de contraseñas)
- Validez: 10000 días (27+ años)
- Información: Nombre, organización, ciudad, país

2. **Crear archivo `key.properties`:**
```properties
storePassword=<password-del-keystore>
keyPassword=<password-de-la-key>
keyAlias=upload
storeFile=<ruta-absoluta-al-keystore>
```

3. **Configurar `android/app/build.gradle`:**
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing code ...

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

4. **Crear `android/app/proguard-rules.pro`:**
```proguard
# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# RevenueCat
-keep class com.revenuecat.** { *; }

# Sentry
-keep class io.sentry.** { *; }
```

**Seguridad:**
- ✅ `key.properties` en `.gitignore`
- ✅ Keystore en ubicación segura (no en repo)
- ✅ Backup del keystore en lugar seguro (si se pierde, no se puede actualizar la app)

#### 1.2. Configuración de Seguridad Android

**Actualizar `AndroidManifest.xml`:**

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.receiptdata.app">
    
    <!-- Permisos -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.CAMERA" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" 
        android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
    
    <application
        android:label="@string/app_name"
        android:name="${applicationName}"
        android:icon="@mipmap/launcher_icon"
        android:usesCleartextTraffic="false"
        android:networkSecurityConfig="@xml/network_security_config">
        
        <!-- ... existing code ... -->
        
        <!-- Security: Prevent screenshot in sensitive screens -->
        <meta-data
            android:name="android.app.prevent_screenshot"
            android:value="false" />
    </application>
</manifest>
```

**Crear `android/app/src/main/res/xml/network_security_config.xml`:**
```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>
    <domain-config cleartextTrafficPermitted="false">
        <domain includeSubdomains="true">receiptaiscanner-production.up.railway.app</domain>
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </domain-config>
</network-security-config>
```

**Actualizar `android/app/build.gradle`:**
```gradle
android {
    namespace = "com.receiptdata.app"  // Cambiar de com.example
    
    defaultConfig {
        applicationId = "com.receiptdata.app"  // ID único de Play Store
        minSdk = 21  // Android 5.0+
        targetSdk = 34  // Android 14
        versionCode = 1
        versionName = "1.0.0"
        
        // Security
        manifestPlaceholders = [
            'appAuthRedirectScheme': 'com.receiptdata.app'
        ]
    }
    
    buildTypes {
        release {
            // ... signing config ...
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
            
            // Obfuscación
            debuggable = false
        }
    }
}
```

#### 1.3. Configuración de Application ID

**Cambiar de `com.example.receipt_ai_scanner` a `com.receiptdata.app`:**

1. Actualizar `android/app/build.gradle` (ya hecho arriba)
2. Actualizar `android/app/src/main/AndroidManifest.xml` package
3. Actualizar `android/app/src/main/kotlin/.../MainActivity.kt` package
4. Verificar que no haya referencias hardcodeadas

---

### FASE 2: Políticas y Legal (Semana 2)

#### 2.1. Política de Privacidad

**Requisitos de Google Play:**
- URL pública accesible
- Explicar qué datos se recopilan
- Explicar cómo se usan los datos
- Explicar con quién se comparten
- Información de contacto

**Crear `web/privacy.html` completo:**

```html
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Política de Privacidad - ReceiptData</title>
</head>
<body>
    <h1>Política de Privacidad</h1>
    <p><strong>Última actualización:</strong> [FECHA]</p>
    
    <h2>1. Información que Recopilamos</h2>
    <ul>
        <li><strong>Install ID:</strong> Identificador único anónimo por instalación (hash SHA-256)</li>
        <li><strong>Imágenes:</strong> Solo procesadas temporalmente, no almacenadas permanentemente</li>
        <li><strong>Datos Extraídos:</strong> Total, fecha, proveedor, categoría (almacenados localmente)</li>
        <li><strong>Uso:</strong> Métricas de uso (número de escaneos, errores) para mejorar el servicio</li>
    </ul>
    
    <h2>2. Cómo Usamos la Información</h2>
    <ul>
        <li>Procesar imágenes con IA (Google Gemini) para extraer datos</li>
        <li>Mejorar la precisión del servicio</li>
        <li>Prevenir abuso (rate limiting)</li>
        <li>Proporcionar soporte técnico</li>
    </ul>
    
    <h2>3. Compartir Información</h2>
    <p>No vendemos ni compartimos datos personales. Solo compartimos con:</p>
    <ul>
        <li><strong>Google Gemini:</strong> Para procesamiento de imágenes (sujeto a política de Google)</li>
        <li><strong>Stripe:</strong> Para procesamiento de pagos (sujeto a política de Stripe)</li>
        <li><strong>Sentry:</strong> Para monitoreo de errores (sujeto a política de Sentry)</li>
    </ul>
    
    <h2>4. Seguridad</h2>
    <ul>
        <li>Comunicación encriptada (HTTPS)</li>
        <li>No almacenamiento permanente de imágenes</li>
        <li>Identificadores anónimos (no PII)</li>
    </ul>
    
    <h2>5. Sus Derechos</h2>
    <p>Puede solicitar eliminación de datos contactando: [EMAIL]</p>
    
    <h2>6. Contacto</h2>
    <p>Email: [EMAIL]</p>
</body>
</html>
```

**Desplegar en:**
- GitHub Pages
- Vercel/Netlify
- Firebase Hosting
- URL pública: `https://receiptdata.app/privacy` (o similar)

#### 2.2. Términos de Servicio

**Crear `web/terms.html` con:**
- Limitación de responsabilidad
- Uso aceptable
- Propiedad intelectual
- Modificaciones del servicio
- Ley aplicable

#### 2.3. Política de Reembolsos

**Para suscripciones:**
- Período de cancelación (según región)
- Proceso de reembolso
- Contacto para soporte

---

### FASE 3: Assets y Metadata (Semana 2-3)

#### 3.1. Iconos y Assets

**Requisitos de Play Store:**
- Icono: 512x512px (PNG, sin transparencia)
- Feature Graphic: 1024x500px
- Screenshots: Mínimo 2, máximo 8
  - Teléfono: 16:9 o 9:16, mínimo 320px, máximo 3840px
  - Tablet: 16:9 o 9:16

**Crear assets:**
```bash
# Usar flutter_launcher_icons (ya configurado en pubspec.yaml)
flutter pub run flutter_launcher_icons

# Verificar que se generaron correctamente
```

**Screenshots necesarios:**
1. Pantalla de inicio/scan
2. Resultado de escaneo
3. Historial
4. Paywall (si aplica)
5. Dashboard (si aplica)

#### 3.2. Descripción de Play Store

**Título (máx 50 caracteres):**
```
ReceiptData - Escáner de Facturas
```

**Descripción corta (máx 80 caracteres):**
```
Escanea recibos y facturas con IA. Extrae datos automáticamente.
```

**Descripción completa:**
```
ReceiptData convierte tus recibos y facturas en papel en datos estructurados en segundos.

✨ CARACTERÍSTICAS:
• Escaneo rápido con cámara o galería
• Extracción automática con IA (Google Gemini)
• Datos estructurados: total, fecha, proveedor, categoría
• Exportación a CSV
• Historial local de escaneos
• Soporte multiidioma

🔒 PRIVACIDAD:
• No almacenamos tus imágenes permanentemente
• Datos procesados de forma segura
• Identificadores anónimos

💼 PERFECTO PARA:
• Autónomos y freelancers
• Pequeñas empresas
• Gestión de gastos personales
• Preparación de impuestos

📊 EXPORTA:
• CSV para Excel/Google Sheets
• Datos listos para contabilidad

Actualiza a Premium para escaneos ilimitados y funciones avanzadas.
```

**Palabras clave (máx 50 caracteres):**
```
recibo, factura, escáner, OCR, gastos, contabilidad, CSV
```

#### 3.3. Categorización

- **Categoría principal:** Productividad / Negocios
- **Categoría secundaria:** Finanzas
- **Contenido:** Todos los públicos
- **Clasificación PEGI:** 3+

---

### FASE 4: Testing y Optimización (Semana 3-4)

#### 4.1. Testing en Dispositivos Reales

**Dispositivos mínimos a probar:**
- Android 5.0 (API 21) - Mínimo soportado
- Android 8.0 (API 26) - Versión común
- Android 11+ (API 30+) - Versiones modernas
- Diferentes tamaños de pantalla (teléfono, tablet)

**Checklist de testing:**
- [ ] Instalación desde APK
- [ ] Permisos (cámara, almacenamiento)
- [ ] Escaneo con cámara
- [ ] Selección de galería
- [ ] Procesamiento de imagen
- [ ] Visualización de resultados
- [ ] Exportación a CSV
- [ ] Historial
- [ ] Suscripción (Stripe/RevenueCat)
- [ ] Manejo de errores
- [ ] Sin conexión a internet
- [ ] Rotación de pantalla
- [ ] Notificaciones (si aplica)

#### 4.2. Optimización de Rendimiento

**Build de release:**
```bash
flutter build apk --release
# o para App Bundle (recomendado):
flutter build appbundle --release
```

**Verificaciones:**
- [ ] Tamaño del APK/AAB < 50MB (idealmente < 30MB)
- [ ] Tiempo de inicio < 3 segundos
- [ ] Sin memory leaks
- [ ] Proguard funcionando (verificar que no rompa funcionalidad)

**Análisis de tamaño:**
```bash
flutter build apk --release --analyze-size
```

#### 4.3. Testing de Seguridad

**Checklist:**
- [ ] HTTPS en todas las comunicaciones
- [ ] No hardcodeo de API keys
- [ ] Validación de inputs
- [ ] Rate limiting funcionando
- [ ] Sin datos sensibles en logs
- [ ] ProGuard/R8 activado
- [ ] Certificado pinning (opcional pero recomendado)

**Herramientas:**
- `adb logcat` para verificar logs
- `apktool` para verificar que no hay datos sensibles
- OWASP Mobile Security Testing Guide

---

### FASE 5: Configuración de Play Console (Semana 4)

#### 5.1. Crear Cuenta de Desarrollador

**Requisitos:**
- Cuenta de Google
- Pago único: $25 USD (única vez)
- Información personal/empresarial
- Formulario de impuestos (W-8BEN si no eres de EE.UU.)

**Pasos:**
1. Ir a https://play.google.com/console
2. Crear cuenta de desarrollador
3. Completar perfil
4. Pagar tarifa de registro

#### 5.2. Crear Aplicación

**Información requerida:**
- Nombre de la app
- Idioma predeterminado
- Tipo de app (App o Juego)
- Gratis o de pago
- Declaración de contenido

**Configuración inicial:**
- Application ID: `com.receiptdata.app` (debe coincidir con build.gradle)
- Versión: 1.0.0
- Estado: Borrador

#### 5.3. Configurar Store Listing

**Completar:**
- [ ] Título
- [ ] Descripción corta
- [ ] Descripción completa
- [ ] Icono (512x512)
- [ ] Feature graphic (1024x500)
- [ ] Screenshots (mínimo 2)
- [ ] Categoría
- [ ] Contacto (email, teléfono, sitio web)
- [ ] Política de privacidad (URL)

#### 5.4. Configurar Precios y Distribución

**Configuración:**
- [ ] Países de distribución (todos o seleccionados)
- [ ] Precio (gratis con compras in-app)
- [ ] Programas (Early Access, Beta Testing opcional)

#### 5.5. Configurar Contenido de la App

**Declaraciones:**
- [ ] Contenido apropiado para todos
- [ ] Permisos justificados
- [ ] Datos sensibles declarados
- [ ] Política de privacidad vinculada

**Permisos a declarar:**
- `CAMERA` - Para escanear recibos
- `READ_EXTERNAL_STORAGE` / `READ_MEDIA_IMAGES` - Para seleccionar imágenes
- `INTERNET` - Para comunicación con backend

**Justificación de permisos:**
- CAMERA: "Necesario para escanear recibos y facturas con la cámara del dispositivo"
- READ_MEDIA_IMAGES: "Necesario para seleccionar imágenes de recibos desde la galería"

---

### FASE 6: Build y Subida (Semana 4)

#### 6.1. Build Final

**Generar App Bundle (recomendado):**
```bash
cd receipt_ai_scanner
flutter build appbundle --release
```

**Output:** `build/app/outputs/bundle/release/app-release.aab`

**Verificar:**
- [ ] Tamaño < 50MB
- [ ] Versión correcta (versionCode y versionName)
- [ ] Application ID correcto
- [ ] Firma correcta

#### 6.2. Subir a Play Console

**Pasos:**
1. Ir a Play Console → Tu app → Producción
2. Crear nueva versión
3. Subir AAB
4. Completar notas de versión:
   ```
   Primera versión de ReceiptData
   
   • Escaneo de recibos y facturas con IA
   • Extracción automática de datos
   • Exportación a CSV
   • Historial local
   ```
5. Revisar y enviar para revisión

#### 6.3. Proceso de Revisión

**Tiempo estimado:** 1-7 días

**Google revisará:**
- Política de privacidad
- Permisos justificados
- Contenido apropiado
- Funcionalidad básica
- Cumplimiento de políticas

**Posibles problemas:**
- Política de privacidad incompleta
- Permisos no justificados
- Contenido inapropiado
- Bugs críticos

**Solución:**
- Responder a comentarios de Google
- Corregir problemas
- Reenviar para revisión

---

### FASE 7: Post-Lanzamiento (Semana 5+)

#### 7.1. Monitoreo

**Métricas a seguir:**
- Instalaciones
- Calificaciones y reseñas
- Crashes (Sentry)
- Rendimiento (Firebase Performance)
- Retención

**Herramientas:**
- Play Console Analytics
- Sentry (errores)
- Firebase Analytics (opcional)

#### 7.2. Respuesta a Reseñas

**Política:**
- Responder a todas las reseñas (especialmente negativas)
- Agradecer feedback positivo
- Ofrecer ayuda en problemas
- Tiempo de respuesta: < 48 horas

#### 7.3. Actualizaciones

**Ciclo de actualizaciones:**
- Correcciones críticas: Inmediato
- Mejoras menores: Mensual
- Nuevas features: Trimestral

**Proceso:**
1. Incrementar `versionCode` y `versionName`
2. Build y testing
3. Subir a Play Console
4. Staged rollout (10% → 50% → 100%)

---

## 🔒 Checklist de Seguridad Completo

### Backend
- [x] HTTPS obligatorio
- [x] Rate limiting
- [x] Validación de inputs
- [x] Secrets en variables de entorno
- [ ] Certificate pinning (recomendado)
- [ ] WAF (Web Application Firewall) - opcional

### Frontend
- [ ] ProGuard/R8 activado
- [ ] No hardcodeo de secrets
- [ ] Validación de inputs
- [ ] Network security config
- [ ] Cleartext traffic deshabilitado
- [ ] Certificate pinning (opcional)

### Datos
- [x] No almacenamiento permanente de imágenes
- [x] Identificadores anónimos
- [x] Política de privacidad
- [ ] GDPR compliance (si aplica)
- [ ] CCPA compliance (si aplica)

---

## 📋 Checklist Final Pre-Publicación

### Código
- [ ] Build de release exitoso
- [ ] ProGuard funcionando
- [ ] Sin errores de linting
- [ ] Tests pasando (si hay)
- [ ] Application ID único
- [ ] Versión correcta

### Assets
- [ ] Icono 512x512
- [ ] Feature graphic 1024x500
- [ ] Mínimo 2 screenshots
- [ ] Descripción completa
- [ ] Política de privacidad publicada

### Legal
- [ ] Política de privacidad
- [ ] Términos de servicio
- [ ] Política de reembolsos
- [ ] Contacto configurado

### Testing
- [ ] Probado en Android 5.0+
- [ ] Probado en diferentes dispositivos
- [ ] Sin crashes conocidos
- [ ] Permisos funcionando
- [ ] Flujo completo probado

### Play Console
- [ ] Cuenta de desarrollador creada
- [ ] App creada
- [ ] Store listing completo
- [ ] Contenido declarado
- [ ] Precios configurados
- [ ] AAB subido
- [ ] Enviado para revisión

---

## ⏱️ Timeline Estimado

| Fase | Duración | Dependencias |
|------|----------|--------------|
| Fase 1: Seguridad Android | 1-2 semanas | - |
| Fase 2: Políticas Legal | 1 semana | Fase 1 |
| Fase 3: Assets | 1 semana | - |
| Fase 4: Testing | 1-2 semanas | Fases 1-3 |
| Fase 5: Play Console | 3-5 días | Fases 1-4 |
| Fase 6: Build y Subida | 2-3 días | Fase 5 |
| Fase 7: Revisión Google | 1-7 días | Fase 6 |
| **TOTAL** | **4-6 semanas** | - |

---

## 🚨 Riesgos y Mitigación

### Riesgo 1: Rechazo de Google
**Probabilidad:** Media  
**Impacto:** Alto  
**Mitigación:**
- Revisar políticas antes de enviar
- Testing exhaustivo
- Política de privacidad completa

### Riesgo 2: Problemas de Seguridad
**Probabilidad:** Baja  
**Impacto:** Crítico  
**Mitigación:**
- Checklist de seguridad completo
- Testing de seguridad
- Code review

### Riesgo 3: Bugs en Producción
**Probabilidad:** Media  
**Impacto:** Medio  
**Mitigación:**
- Testing en múltiples dispositivos
- Staged rollout
- Monitoreo con Sentry

---

## 📚 Recursos Útiles

- [Google Play Console](https://play.google.com/console)
- [Políticas de Google Play](https://play.google.com/about/developer-content-policy/)
- [Guía de Publicación](https://developer.android.com/distribute/googleplay/start)
- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security/)

---

## 🎯 Próximos Pasos Inmediatos

1. **HOY:**
   - [ ] Generar keystore
   - [ ] Configurar `key.properties`
   - [ ] Actualizar `build.gradle` con signing

2. **Esta Semana:**
   - [ ] Completar política de privacidad
   - [ ] Crear assets (iconos, screenshots)
   - [ ] Testing en dispositivo real

3. **Próxima Semana:**
   - [ ] Crear cuenta de desarrollador
   - [ ] Configurar Play Console
   - [ ] Build final y subida

---

**Nota:** Este documento es un plan detallado. Ajustar según necesidades específicas y prioridades del proyecto.
