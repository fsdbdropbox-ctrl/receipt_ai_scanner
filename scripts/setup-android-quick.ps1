# Script rápido para configurar Android SDK después de instalarlo
# Ejecutar después de instalar Android Studio o las command line tools

Write-Host "=== Configuración Rápida de Android SDK ===" -ForegroundColor Cyan

# Detectar ubicación del SDK
$possiblePaths = @(
    "$env:LOCALAPPDATA\Android\Sdk",
    "$env:ProgramFiles\Android\Android Studio\sdk",
    "$env:ProgramFiles(x86)\Android\android-sdk"
)

$sdkPath = $null
foreach ($path in $possiblePaths) {
    if (Test-Path $path) {
        $sdkPath = $path
        Write-Host "✅ SDK encontrado en: $sdkPath" -ForegroundColor Green
        break
    }
}

if (-not $sdkPath) {
    Write-Host "❌ Android SDK no encontrado" -ForegroundColor Red
    Write-Host "`nPor favor instala Android Studio primero:" -ForegroundColor Yellow
    Write-Host "https://developer.android.com/studio" -ForegroundColor Cyan
    exit 1
}

# Configurar variables de entorno
Write-Host "`nConfigurando variables de entorno..." -ForegroundColor Yellow

[System.Environment]::SetEnvironmentVariable("ANDROID_HOME", $sdkPath, "User")
[System.Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", $sdkPath, "User")

# Agregar al PATH
$currentPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
$pathsToAdd = @(
    "$sdkPath\platform-tools",
    "$sdkPath\emulator",
    "$sdkPath\tools\bin"
)

$newPath = $currentPath
foreach ($path in $pathsToAdd) {
    if (Test-Path $path) {
        if ($newPath -notlike "*$path*") {
            $newPath = "$path;$newPath"
        }
    }
}

[System.Environment]::SetEnvironmentVariable("PATH", $newPath, "User")

# Configurar Flutter
Write-Host "Configurando Flutter..." -ForegroundColor Yellow
flutter config --android-sdk $sdkPath

Write-Host "`n✅ Configuración completada!" -ForegroundColor Green
Write-Host "`nPróximos pasos:" -ForegroundColor Yellow
Write-Host "1. Cierra y vuelve a abrir esta terminal" -ForegroundColor White
Write-Host "2. Ejecuta: flutter doctor" -ForegroundColor White
Write-Host "3. Si hay problemas de licencias: sdkmanager --licenses" -ForegroundColor White
