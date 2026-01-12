# Script para instalar componentes del Android SDK
# Ejecutar DESPUÉS de tener Android Studio o command line tools instalados

Write-Host "=== Instalación de Componentes Android SDK ===" -ForegroundColor Cyan

$sdkPath = "$env:LOCALAPPDATA\Android\Sdk"

# Buscar sdkmanager
$sdkmanagerPaths = @(
    "$sdkPath\cmdline-tools\latest\bin\sdkmanager.bat",
    "$sdkPath\tools\bin\sdkmanager.bat",
    "$env:ProgramFiles\Android\Android Studio\sdk\tools\bin\sdkmanager.bat"
)

$sdkmanager = $null
foreach ($path in $sdkmanagerPaths) {
    if (Test-Path $path) {
        $sdkmanager = $path
        Write-Host "✅ sdkmanager encontrado: $path" -ForegroundColor Green
        break
    }
}

if (-not $sdkmanager) {
    Write-Host "❌ sdkmanager no encontrado" -ForegroundColor Red
    Write-Host "`nPor favor instala Android Studio primero:" -ForegroundColor Yellow
    Write-Host "https://developer.android.com/studio" -ForegroundColor Cyan
    Write-Host "`nO descarga las command line tools:" -ForegroundColor Yellow
    Write-Host "https://developer.android.com/studio#command-tools" -ForegroundColor Cyan
    exit 1
}

# Aceptar licencias
Write-Host "`n1. Aceptando licencias..." -ForegroundColor Yellow
$licenses = "y" * 10  # 10 'y' para todas las licencias
$licenses | & $sdkmanager --licenses --sdk_root=$sdkPath

# Instalar componentes
Write-Host "`n2. Instalando componentes (esto puede tardar varios minutos)..." -ForegroundColor Yellow

$packages = @(
    "platform-tools",
    "platforms;android-34",
    "platforms;android-33",
    "build-tools;34.0.0",
    "build-tools;33.0.0"
)

foreach ($package in $packages) {
    Write-Host "  Instalando: $package" -ForegroundColor Gray
    & $sdkmanager $package --sdk_root=$sdkPath 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "    ✅ $package instalado" -ForegroundColor Green
    } else {
        Write-Host "    ⚠️ Error instalando $package" -ForegroundColor Yellow
    }
}

Write-Host "`n✅ Componentes instalados" -ForegroundColor Green

# Verificar
Write-Host "`n3. Verificando instalación..." -ForegroundColor Yellow
flutter doctor

Write-Host "`n=== Completado ===" -ForegroundColor Cyan
Write-Host "Si todo está bien, puedes hacer:" -ForegroundColor Yellow
Write-Host "  flutter build apk --debug" -ForegroundColor White
Write-Host "  flutter install" -ForegroundColor White
