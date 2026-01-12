# Guía para Generar Assets de Play Store

## Assets Necesarios

### 1. Feature Graphic (1024x500px) ✅ Template Creado

**Ubicación:** `assets/play_store/feature_graphic.png`

**Requisitos:**
- Tamaño: 1024x500px
- Formato: PNG
- Contenido: Logo de ReceiptData + texto descriptivo
- Estilo: Moderno, limpio, con el color azul (#2563EB)

**Cómo crear:**
1. Usar el icono `assets/app_icon.png` como base
2. Agregar texto: "ReceiptData - Escanea y Organiza tus Recibos"
3. Usar herramienta como Canva, Figma, o Photoshop
4. Exportar como PNG 1024x500px

### 2. Screenshots (Mínimo 2, recomendado 4-8)

**Tamaños requeridos:**
- Teléfono: 1080x1920px (o proporción 9:16)
- Tablet (opcional): 1200x1920px

**Screenshots recomendados:**
1. **Pantalla principal** - Mostrando la interfaz de escaneo
2. **Historial** - Mostrando recibos escaneados
3. **Resultado de escaneo** - Mostrando datos extraídos
4. **Paywall/Suscripción** - Mostrando opciones premium

**Cómo capturar:**
```bash
# Con dispositivo conectado:
adb shell screencap -p /sdcard/screenshot1.png
adb pull /sdcard/screenshot1.png assets/play_store/screenshots/

# O usar el emulador de Android Studio
# Herramientas → Screenshot
```

**Editar screenshots:**
- Agregar marcos de teléfono (opcional)
- Agregar texto descriptivo (opcional)
- Asegurar que se vean bien en diferentes tamaños

### 3. Icono de App (512x512px) ✅ Ya Generado

**Ubicación:** `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`

**Estado:** ✅ Ya generado con `flutter_launcher_icons`

### 4. Banner Promocional (Opcional)

**Tamaño:** 180x120px
**Uso:** Para promociones en Play Store

---

## Scripts de Ayuda

### Generar Screenshots Automáticamente

**Windows:**
```powershell
# Conecta dispositivo y ejecuta:
adb devices
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png assets/play_store/screenshots/screenshot_$(Get-Date -Format 'yyyyMMdd_HHmmss').png
```

**Linux/Mac:**
```bash
adb devices
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png "assets/play_store/screenshots/screenshot_$(date +%Y%m%d_%H%M%S).png"
```

---

## Estructura de Carpetas Recomendada

```
receipt_ai_scanner/
├── assets/
│   ├── app_icon.png (ya existe)
│   └── play_store/
│       ├── feature_graphic.png (crear)
│       └── screenshots/
│           ├── screenshot_1_main.png
│           ├── screenshot_2_history.png
│           ├── screenshot_3_result.png
│           └── screenshot_4_paywall.png
```

---

## Herramientas Recomendadas

1. **Canva** - Para crear feature graphic fácilmente
2. **Figma** - Para diseño profesional
3. **Android Studio** - Para capturar screenshots del emulador
4. **ADB** - Para capturar screenshots de dispositivo real

---

## Checklist

- [ ] Feature graphic creado (1024x500px)
- [ ] Mínimo 2 screenshots capturados
- [ ] Screenshots editados y optimizados
- [ ] Icono verificado (512x512px)
- [ ] Todos los assets en formato PNG
- [ ] Tamaños verificados antes de subir

---

**Nota:** Los screenshots deben mostrarse en dispositivos reales o emuladores con la app funcionando. No se pueden generar automáticamente sin la app corriendo.
