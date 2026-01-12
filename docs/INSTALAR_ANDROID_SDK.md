# Guía de Instalación de Android SDK

## Opción 1: Android Studio (Recomendado - Más Fácil)

### Pasos:

1. **Descargar Android Studio:**
   - Ve a: https://developer.android.com/studio
   - Descarga el instalador para Windows
   - Ejecuta el instalador

2. **Durante la instalación:**
   - Asegúrate de marcar "Android SDK"
   - Acepta la ubicación por defecto: `C:\Users\Fernando\AppData\Local\Android\Sdk`

3. **Después de instalar:**
   - Abre Android Studio
   - Ve a: `File` → `Settings` → `Appearance & Behavior` → `System Settings` → `Android SDK`
   - En la pestaña **SDK Platforms**, instala:
     - Android 14.0 (API 34) ✅
     - Android 13.0 (API 33) ✅
   - En la pestaña **SDK Tools**, asegúrate de tener:
     - Android SDK Build-Tools ✅
     - Android SDK Platform-Tools ✅
     - Android Emulator ✅
   - Click en **Apply** y espera a que descargue

4. **Configurar Flutter:**
   ```powershell
   flutter config --android-sdk "$env:LOCALAPPDATA\Android\Sdk"
   flutter doctor
   ```

---

## Opción 2: Command Line Tools (Sin Android Studio)

### Instalación Automática (Script):

```powershell
# Ejecutar en PowerShell como administrador
cd receipt_ai_scanner
.\scripts\install-android-sdk.ps1
```

### Instalación Manual:

1. **Descargar Command Line Tools:**
   - Ve a: https://developer.android.com/studio#command-tools
   - Descarga "Command line tools only" para Windows
   - Extrae el ZIP

2. **Instalar:**
   ```powershell
   # Crear directorios
   New-Item -ItemType Directory -Path "$env:LOCALAPPDATA\Android\Sdk\cmdline-tools\latest" -Force
   
   # Mover archivos extraídos a: ...\Sdk\cmdline-tools\latest\
   
   # Configurar variables de entorno
   [System.Environment]::SetEnvironmentVariable("ANDROID_HOME", "$env:LOCALAPPDATA\Android\Sdk", "User")
   [System.Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", "$env:LOCALAPPDATA\Android\Sdk", "User")
   
   # Agregar al PATH
   $sdkPath = "$env:LOCALAPPDATA\Android\Sdk"
   $currentPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
   $newPath = "$sdkPath\cmdline-tools\latest\bin;$sdkPath\platform-tools;$sdkPath\emulator;$currentPath"
   [System.Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
   ```

3. **Instalar componentes:**
   ```powershell
   # Aceptar licencias
   sdkmanager --licenses
   
   # Instalar componentes
   sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0" "emulator"
   ```

---

## Verificar Instalación

```powershell
# Verificar variables de entorno
echo $env:ANDROID_HOME
echo $env:ANDROID_SDK_ROOT

# Verificar Flutter
flutter doctor

# Debería mostrar:
# [√] Android toolchain - develop for Android devices
```

---

## Crear Emulador (Opcional)

### Opción A: Con Android Studio
1. Abre Android Studio
2. `Tools` → `Device Manager`
3. `Create Device`
4. Selecciona un dispositivo (ej: Pixel 5)
5. Selecciona una imagen del sistema (ej: Android 14)
6. Click `Finish`

### Opción B: Con Command Line
```powershell
# Listar imágenes disponibles
sdkmanager --list | Select-String "system-images"

# Instalar imagen
sdkmanager "system-images;android-34;google_apis;x86_64"

# Crear AVD
avdmanager create avd -n Pixel5_API34 -k "system-images;android-34;google_apis;x86_64" -d "pixel_5"
```

---

## Conectar Dispositivo Físico

1. **Habilitar USB Debugging:**
   - En tu teléfono Android: `Settings` → `About phone`
   - Toca 7 veces en "Build number"
   - Ve a `Settings` → `Developer options`
   - Activa "USB debugging"

2. **Conectar:**
   ```powershell
   # Verificar conexión
   adb devices
   
   # Debería mostrar tu dispositivo
   ```

---

## Próximos Pasos

Una vez instalado el SDK:

```powershell
# Configurar Flutter
flutter config --android-sdk "$env:LOCALAPPDATA\Android\Sdk"

# Verificar
flutter doctor

# Build de prueba
cd receipt_ai_scanner
flutter build apk --debug

# Instalar en dispositivo/emulador
flutter install
```

---

## Solución de Problemas

### Flutter no encuentra el SDK:
```powershell
flutter config --android-sdk "$env:LOCALAPPDATA\Android\Sdk"
```

### Variables de entorno no se cargan:
- Cierra y vuelve a abrir la terminal
- O reinicia la computadora

### Error de licencias:
```powershell
sdkmanager --licenses
# Presiona 'y' para cada licencia
```
