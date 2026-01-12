# Setup Rápido de Android SDK

## Estado Actual

✅ **Variables de entorno configuradas**  
✅ **Flutter configurado para usar el SDK**  
❌ **Componentes del SDK faltantes**

---

## Solución Rápida

### Opción 1: Android Studio (MÁS FÁCIL - Recomendado)

1. **Descargar:**
   ```
   https://developer.android.com/studio
   ```

2. **Instalar:**
   - Ejecuta el instalador
   - Marca "Android SDK" durante la instalación
   - Acepta la ubicación por defecto

3. **Configurar SDK:**
   - Abre Android Studio
   - `File` → `Settings` → `Appearance & Behavior` → `System Settings` → `Android SDK`
   - Pestaña **SDK Platforms:**
     - ✅ Android 14.0 (API 34)
     - ✅ Android 13.0 (API 33)
   - Pestaña **SDK Tools:**
     - ✅ Android SDK Build-Tools
     - ✅ Android SDK Platform-Tools
     - ✅ Android Emulator (opcional)
   - Click **Apply** y espera

4. **Verificar:**
   ```powershell
   flutter doctor
   ```
   Debería mostrar: `[√] Android toolchain`

---

### Opción 2: Command Line Tools (Sin Android Studio)

1. **Descargar:**
   - Ve a: https://developer.android.com/studio#command-tools
   - Descarga "Command line tools only" para Windows

2. **Instalar:**
   ```powershell
   # Extrae el ZIP
   # Mueve el contenido a:
   C:\Users\Fernando\AppData\Local\Android\Sdk\cmdline-tools\latest\
   ```

3. **Instalar componentes:**
   ```powershell
   cd receipt_ai_scanner
   .\scripts\instalar-componentes-sdk.ps1
   ```

---

## Después de Instalar

### Verificar:
```powershell
flutter doctor
```

### Build de prueba:
```powershell
cd receipt_ai_scanner
flutter build apk --debug
```

### Instalar en dispositivo:
```powershell
# Conectar dispositivo Android con USB debugging
flutter devices  # Ver dispositivos disponibles
flutter install  # Instalar app
```

---

## Crear Emulador (Opcional)

### Con Android Studio:
1. `Tools` → `Device Manager`
2. `Create Device`
3. Selecciona dispositivo (ej: Pixel 5)
4. Selecciona imagen (Android 14)
5. `Finish`

### Con Command Line:
```powershell
# Instalar imagen del sistema
sdkmanager "system-images;android-34;google_apis;x86_64"

# Crear AVD
avdmanager create avd -n Pixel5_API34 -k "system-images;android-34;google_apis;x86_64" -d "pixel_5"

# Listar emuladores
flutter emulators

# Iniciar emulador
flutter emulators --launch Pixel5_API34
```

---

## Conectar Dispositivo Físico

1. **Habilitar USB Debugging:**
   - `Settings` → `About phone`
   - Toca 7 veces en "Build number"
   - `Settings` → `Developer options`
   - Activa "USB debugging"

2. **Conectar y verificar:**
   ```powershell
   adb devices
   # Debería mostrar tu dispositivo
   
   flutter devices
   flutter install
   ```

---

## Próximos Pasos

Una vez que `flutter doctor` muestre `[√] Android toolchain`:

1. **Build de release:**
   ```powershell
   flutter build appbundle --release
   ```

2. **Testing:**
   ```powershell
   flutter test
   flutter install
   ```

3. **Listo para Play Store!**
