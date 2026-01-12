#!/bin/bash
# Script para generar keystore de producción
# Ejecutar: bash generate-keystore.sh

echo "=========================================="
echo "Generador de Keystore para ReceiptData"
echo "=========================================="
echo ""

# Solicitar información
read -p "Nombre completo: " NAME
read -p "Organización: " ORG
read -p "Ciudad: " CITY
read -p "Estado/Provincia: " STATE
read -p "Código de país (2 letras, ej: ES): " COUNTRY
read -sp "Contraseña del keystore: " KEYSTORE_PASSWORD
echo ""
read -sp "Contraseña de la clave (puede ser la misma): " KEY_PASSWORD
echo ""

# Ruta del keystore
KEYSTORE_PATH="$HOME/upload-keystore.jks"

echo ""
echo "Generando keystore en: $KEYSTORE_PATH"
echo ""

keytool -genkey -v \
  -keystore "$KEYSTORE_PATH" \
  -alias upload \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -storepass "$KEYSTORE_PASSWORD" \
  -keypass "$KEY_PASSWORD" \
  -dname "CN=$NAME, OU=$ORG, O=$ORG, L=$CITY, ST=$STATE, C=$COUNTRY"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Keystore generado exitosamente!"
    echo ""
    echo "📝 Próximos pasos:"
    echo "1. Copia android/key.properties.example a android/key.properties"
    echo "2. Edita android/key.properties con:"
    echo "   storePassword=$KEYSTORE_PASSWORD"
    echo "   keyPassword=$KEY_PASSWORD"
    echo "   keyAlias=upload"
    echo "   storeFile=$KEYSTORE_PATH"
    echo ""
    echo "⚠️  IMPORTANTE:"
    echo "   - Guarda el keystore en un lugar seguro"
    echo "   - Si lo pierdes, NO podrás actualizar la app en Play Store"
    echo "   - Haz un backup del keystore"
    echo ""
else
    echo ""
    echo "❌ Error al generar el keystore"
    exit 1
fi
