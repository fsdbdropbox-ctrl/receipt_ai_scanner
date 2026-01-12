# Script para instalar Android SDK en Windows
# Ejecutar como administrador si es necesario

Write-Host "=== Instalación de Android SDK ===" -ForegroundColor Cyan

$sdkPath = "$env:LOCALAPPDATA\Android\Sdk"
$toolsPath = "$sdkPath\cmdline-tools"

# Crear directorios
New-Item -ItemType Directory -Path $sdkPath -Force | Out-Null
New-Item -ItemType Directory -Path $toolsPath -Force | Out-Null

Write-Host "`n1. Descargando Android Command Line Tools..." -ForegroundColor Yellow

# URL de las command line tools (última versión)
$toolsUrl = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"
$toolsZip = "$env:TEMP\android-cmdline-tools.zip"
$latestPath = "$toolsPath\latest"

try {
    # Descargar
    Write-Host "Descargando desde: $toolsUrl" -ForegroundColor Gray
    Invoke-WebRequest -Uri $toolsUrl -OutFile $toolsZip -UseBasicParsing
    
    # Extraer
    Write-Host "Extrayendo..." -ForegroundColor Gray
    Expand-Archive -Path $toolsZip -DestinationPath $toolsPath -Force
    
    # Mover a carpeta 'latest'
    $extracted = Get-ChildItem -Path $toolsPath -Directory | Where-Object { $_.Name -like "cmdline-tools*" } | Select-Object -First 1
    if ($extracted) {
        Move-Item -Path $extracted.FullName -Destination $latestPath -Force
    }
    
    Remove-Item $toolsZip -Force
    
    Write-Host "✅ Command Line Tools instaladas" -ForegroundColor Green
} catch {
    Write-Host "❌ Error descargando tools: $_" -ForegroundColor Red
    Write-Host "`nInstalación manual:" -ForegroundColor Yellow
    Write-Host "1. Descarga: https://developer.android.com/studio#command-tools" -ForegroundColor Gray
    Write-Host "2. Extrae en: $toolsPath\latest" -ForegroundColor Gray
    exit 1
}

# Configurar variables de entorno
Write-Host "`n2. Configurando variables de entorno..." -ForegroundColor Yellow

$env:ANDROID_HOME = $sdkPath
$env:ANDROID_SDK_ROOT = $sdkPath
$env:PATH = "$toolsPath\latest\bin;$sdkPath\platform-tools;$sdkPath\emulator;$env:PATH"

# Configurar para usuario actual (persistente)
[System.Environment]::SetEnvironmentVariable("ANDROID_HOME", $sdkPath, "User")
[System.Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $sdkPath, "User")

$currentPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
if ($currentPath -notlike "*$toolsPath\latest\bin*") {
    $newPath = "$toolsPath\latest\bin;$sdkPath\platform-tools;$sdkPath\emulator;$currentPath"
    [System.Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
}

Write-Host "✅ Variables de entorno configuradas" -ForegroundColor Green
Write-Host "   ANDROID_HOME: $sdkPath" -ForegroundColor Gray

# Aceptar licencias
Write-Host "`n3. Aceptando licencias..." -ForegroundColor Yellow
& "$toolsPath\latest\bin\sdkmanager.bat" --licenses --sdk_root=$sdkPath | ForEach-Object {
    if ($_ -match "y/n") {
        "y"
    } else {
        $_
    }
} | & "$toolsPath\latest\bin\sdkmanager.bat" --licenses --sdk_root=$sdkPath

# Instalar componentes necesarios
Write-Host "`n4. Instalando componentes del SDK..." -ForegroundColor Yellow
Write-Host "Esto puede tardar varios minutos..." -ForegroundColor Gray

$packages = @(
    "platform-tools",
    "platforms;android-34",
    "platforms;android-33",
    "build-tools;34.0.0",
    "emulator",
    "system-images;android-34;google_apis;x86_64"
)

foreach ($package in $packages) {
    Write-Host "Instalando: $package" -ForegroundColor Gray
    & "$toolsPath\latest\bin\sdkmanager.bat" $package --sdk_root=$sdkPath 2>&1 | Out-Null
}

Write-Host "✅ Componentes instalados" -ForegroundColor Green

# Configurar Flutter
Write-Host "`n5. Configurando Flutter..." -ForegroundColor Yellow
flutter config --android-sdk $sdkPath
Write-Host "✅ Flutter configurado" -ForegroundColor Green

Write-Host "`n=== Instalación completada ===" -ForegroundColor Cyan
Write-Host "`nPróximos pasos:" -ForegroundColor Yellow
Write-Host "1. Cierra y vuelve a abrir la terminal para que las variables de entorno se carguen" -ForegroundColor White
Write-Host "2. Ejecuta: flutter doctor" -ForegroundColor White
Write-Host "3. Crea un emulador: flutter emulators --create" -ForegroundColor White
Write-Host "`nO conecta un dispositivo Android físico con USB debugging habilitado" -ForegroundColor White
