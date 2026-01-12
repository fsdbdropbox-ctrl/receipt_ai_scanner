# Guía de Testing - ReceiptData

**Estado:** ✅ Android SDK instalado y listo

---

## 🚀 Testing Rápido

### Opción 1: Dispositivo Físico (Recomendado)

#### 1. Habilitar USB Debugging

En tu teléfono Android:
1. `Settings` → `About phone`
2. Toca 7 veces en "Build number"
3. Ve a `Settings` → `Developer options`
4. Activa "USB debugging"
5. Conecta el teléfono por USB

#### 2. Verificar Conexión

```powershell
cd receipt_ai_scanner
adb devices
```

Debería mostrar tu dispositivo:
```
List of devices attached
ABC123XYZ    device
```

#### 3. Instalar y Probar

```powershell
# Ver dispositivos disponibles
flutter devices

# Instalar app
flutter install

# O build e instalar
flutter build apk --debug
flutter install
```

---

### Opción 2: Emulador Android

#### Crear Emulador

**Con Android Studio (si lo tienes):**
1. Abre Android Studio
2. `Tools` → `Device Manager`
3. `Create Device`
4. Selecciona dispositivo (ej: Pixel 5)
5. Selecciona imagen (Android 14)
6. `Finish`

**O con command line:**
```powershell
# Instalar imagen del sistema
sdkmanager "system-images;android-34;google_apis;x86_64"

# Crear AVD
avdmanager create avd -n Pixel5_API34 -k "system-images;android-34;google_apis;x86_64" -d "pixel_5"
```

#### Iniciar Emulador

```powershell
# Listar emuladores
flutter emulators

# Iniciar emulador
flutter emulators --launch Pixel5_API34

# O con Android Studio: Tools → Device Manager → Play button
```

#### Instalar App

```powershell
flutter install
```

---

## 🧪 Checklist de Testing

### Funcionalidades Básicas

- [ ] **App inicia correctamente**
  - Sin crashes
  - UI se carga bien
  - Permisos solicitados correctamente

- [ ] **Escaneo de recibos**
  - Cámara funciona
  - Galería funciona
  - Selección de archivo funciona
  - Procesamiento de imagen funciona

- [ ] **Extracción de datos**
  - Datos extraídos correctamente
  - Campos editables funcionan
  - Guardado funciona

- [ ] **Historial**
  - Lista de escaneos se muestra
  - Búsqueda funciona
  - Exportación funciona (CSV)

- [ ] **Suscripción**
  - Paywall se muestra
  - Compra funciona (test mode)
  - Estado premium se actualiza

- [ ] **Permisos**
  - Cámara
  - Almacenamiento
  - Internet

### Testing de Release

```powershell
# Build de release
flutter build appbundle --release

# Verificar tamaño
# Debe ser < 50MB para Play Store

# Instalar en dispositivo
flutter install --release
```

---

## 🐛 Solución de Problemas

### Dispositivo no detectado

```powershell
# Reiniciar ADB
adb kill-server
adb start-server
adb devices

# Verificar USB debugging está activado
# Probar otro cable USB
# Probar otro puerto USB
```

### Build falla

```powershell
# Limpiar build
flutter clean
flutter pub get

# Rebuild
flutter build apk --debug
```

### Emulador lento

- Habilita aceleración de hardware en BIOS
- Aumenta RAM del emulador (Android Studio → AVD Manager → Edit)
- Usa dispositivo físico si es posible

---

## 📊 Comandos Útiles

```powershell
# Ver dispositivos
flutter devices
adb devices

# Logs en tiempo real
flutter logs
adb logcat

# Limpiar y rebuild
flutter clean
flutter pub get
flutter build apk --debug

# Instalar directamente
flutter install

# Ver información del dispositivo
adb shell getprop ro.build.version.release
adb shell getprop ro.product.model
```

---

## ✅ Listo para Play Store

Una vez que todo funciona:

1. **Build final:**
   ```powershell
   flutter build appbundle --release
   ```

2. **Verificar:**
   - Tamaño < 50MB
   - Versión correcta en `pubspec.yaml`
   - Application ID: `com.receiptdata.app`

3. **Subir a Play Console:**
   - Ubicación: `build\app\outputs\bundle\release\app-release.aab`

---

**¡Listo para testing!** 🎉
