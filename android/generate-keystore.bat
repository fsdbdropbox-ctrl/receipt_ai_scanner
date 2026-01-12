@echo off
REM Script para generar keystore de producción (Windows)
REM Ejecutar: generate-keystore.bat

echo ==========================================
echo Generador de Keystore para ReceiptData
echo ==========================================
echo.

REM Solicitar información
set /p NAME="Nombre completo: "
set /p ORG="Organización: "
set /p CITY="Ciudad: "
set /p STATE="Estado/Provincia: "
set /p COUNTRY="Código de país (2 letras, ej: ES): "
set /p KEYSTORE_PASSWORD="Contraseña del keystore: "
set /p KEY_PASSWORD="Contraseña de la clave (puede ser la misma): "

REM Ruta del keystore (en el directorio home del usuario)
set KEYSTORE_PATH=%USERPROFILE%\upload-keystore.jks

echo.
echo Generando keystore en: %KEYSTORE_PATH%
echo.

keytool -genkey -v ^
  -keystore "%KEYSTORE_PATH%" ^
  -alias upload ^
  -keyalg RSA ^
  -keysize 2048 ^
  -validity 10000 ^
  -storepass "%KEYSTORE_PASSWORD%" ^
  -keypass "%KEY_PASSWORD%" ^
  -dname "CN=%NAME%, OU=%ORG%, O=%ORG%, L=%CITY%, ST=%STATE%, C=%COUNTRY%"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ Keystore generado exitosamente!
    echo.
    echo 📝 Próximos pasos:
    echo 1. Copia android\key.properties.example a android\key.properties
    echo 2. Edita android\key.properties con:
    echo    storePassword=%KEYSTORE_PASSWORD%
    echo    keyPassword=%KEY_PASSWORD%
    echo    keyAlias=upload
    echo    storeFile=%KEYSTORE_PATH%
    echo.
    echo ⚠️  IMPORTANTE:
    echo    - Guarda el keystore en un lugar seguro
    echo    - Si lo pierdes, NO podrás actualizar la app en Play Store
    echo    - Haz un backup del keystore
    echo.
) else (
    echo.
    echo ❌ Error al generar el keystore
    exit /b 1
)

pause
