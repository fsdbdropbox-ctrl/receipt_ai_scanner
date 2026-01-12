# Checklist Pre-Publicación Play Store

## ✅ Configuración Técnica (AUTOMATIZADO)

- [x] Application ID cambiado a `com.receiptdata.app`
- [x] `build.gradle` configurado con signing
- [x] `network_security_config.xml` creado
- [x] `AndroidManifest.xml` actualizado con permisos
- [x] `proguard-rules.pro` creado
- [x] `MainActivity.kt` movido a nuevo package
- [x] `strings.xml` con nombre de app
- [x] `.gitignore` actualizado (keystore excluido)
- [x] Política de privacidad HTML creada
- [x] Términos de servicio HTML creados

## 🔑 Keystore (MANUAL - REQUERIDO)

- [ ] **Generar keystore:**
  ```bash
  # Windows:
  android\generate-keystore.bat
  
  # Linux/Mac:
  bash android/generate-keystore.sh
  ```
- [ ] **Crear `android/key.properties`:**
  - Copiar `android/key.properties.example` a `android/key.properties`
  - Completar con contraseñas y ruta del keystore
- [ ] **Backup del keystore:**
  - Guardar en lugar seguro (cloud, USB, etc.)
  - ⚠️ Si se pierde, NO se puede actualizar la app

## 📱 Testing (MANUAL)

- [ ] Build de release exitoso:
  ```bash
  flutter build appbundle --release
  ```
- [ ] Probado en Android 5.0+ (mínimo)
- [ ] Probado en Android 11+ (moderno)
- [ ] Verificar permisos (cámara, almacenamiento)
- [ ] Verificar escaneo funciona
- [ ] Verificar suscripción funciona
- [ ] Verificar sin crashes
- [ ] Verificar tamaño APK/AAB < 50MB

## 📄 Legal (MANUAL)

- [ ] **Política de privacidad:**
  - [ ] Actualizar email de contacto en `web/privacy.html`
  - [ ] Desplegar en URL pública (GitHub Pages/Vercel/Netlify)
  - [ ] URL debe ser accesible antes de enviar a Play Store
  
- [ ] **Términos de servicio:**
  - [ ] Actualizar jurisdicción en `web/terms.html`
  - [ ] Actualizar email de contacto
  - [ ] Desplegar en URL pública

## 🎨 Assets Play Store (MANUAL)

- [ ] **Icono:**
  - [ ] 512x512px PNG (sin transparencia)
  - [ ] Generado con `flutter pub run flutter_launcher_icons`
  
- [ ] **Feature Graphic:**
  - [ ] 1024x500px
  
- [ ] **Screenshots (mínimo 2):**
  - [ ] Teléfono: 16:9 o 9:16
  - [ ] Mínimo 320px, máximo 3840px
  - [ ] Capturas de: pantalla principal, resultado, historial

- [ ] **Descripción:**
  - [ ] Título (máx 50 caracteres)
  - [ ] Descripción corta (máx 80 caracteres)
  - [ ] Descripción completa
  - [ ] Palabras clave

## 🏪 Play Console (MANUAL)

- [ ] **Cuenta de desarrollador:**
  - [ ] Crear en https://play.google.com/console
  - [ ] Pagar $25 USD (única vez)
  - [ ] Completar perfil

- [ ] **Crear aplicación:**
  - [ ] Application ID: `com.receiptdata.app`
  - [ ] Tipo: App
  - [ ] Gratis con compras in-app

- [ ] **Store Listing:**
  - [ ] Completar todos los campos
  - [ ] Subir icono y feature graphic
  - [ ] Subir screenshots
  - [ ] Agregar descripción
  - [ ] Categoría: Productividad / Negocios
  - [ ] Política de privacidad (URL)

- [ ] **Contenido:**
  - [ ] Declarar permisos (CAMERA, READ_MEDIA_IMAGES)
  - [ ] Justificar cada permiso
  - [ ] Declarar datos sensibles
  - [ ] Clasificación de contenido

- [ ] **Precios y distribución:**
  - [ ] Seleccionar países
  - [ ] Configurar precios (gratis)

## 📦 Build y Subida (MANUAL)

- [ ] **Build final:**
  ```bash
  flutter build appbundle --release
  ```
- [ ] **Verificar:**
  - [ ] Tamaño < 50MB
  - [ ] Versión correcta
  - [ ] Application ID correcto
  
- [ ] **Subir a Play Console:**
  - [ ] Ir a Producción → Crear nueva versión
  - [ ] Subir `app-release.aab`
  - [ ] Agregar notas de versión
  - [ ] Revisar y enviar

## ⏳ Revisión (AUTOMÁTICO - Google)

- [ ] Esperar aprobación (1-7 días)
- [ ] Responder comentarios si hay
- [ ] Publicación automática tras aprobación

---

## 🚨 Prioridades Críticas

1. **KEYSORE** - Sin esto, no se puede publicar
2. **POLÍTICA DE PRIVACIDAD** - Debe estar publicada antes de enviar
3. **TESTING** - Probar en dispositivo real antes de publicar
4. **ASSETS** - Mínimo icono y 2 screenshots

---

**Última actualización:** Enero 2025
