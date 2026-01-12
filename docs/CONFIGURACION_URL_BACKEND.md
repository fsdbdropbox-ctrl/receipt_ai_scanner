# 🔧 Configuración de URL del Backend

## Para Desarrollo Local (Emulador)

Si estás probando en el emulador Android y el backend está en Railway:

1. **Obtén la URL de Railway:**
   - Ve a Railway → Tu servicio → **Settings** → **Domains**
   - Copia la URL (ej: `https://receiptdata-production.up.railway.app`)

2. **Actualiza `lib/shared/utils/constants.dart`:**
   ```dart
   static const String apiBaseUrl = String.fromEnvironment(
     'API_BASE_URL',
     defaultValue: 'https://tu-backend.railway.app', // ← Pega aquí tu URL de Railway
   );
   ```

3. **O compila con la URL:**
   ```bash
   flutter run -d emulator-5554 --dart-define=API_BASE_URL=https://tu-backend.railway.app
   ```

## Para Backend Local

Si quieres correr el backend localmente:

1. **Inicia el backend:**
   ```bash
   cd backend
   npm start
   ```

2. **Actualiza `constants.dart`:**
   ```dart
   defaultValue: 'http://10.0.2.2:8080', // Android emulator localhost
   ```

3. **Asegúrate de tener todas las variables de entorno configuradas en el backend**

---

**Nota:** `10.0.2.2` es la IP especial que el emulador Android usa para acceder al localhost de tu máquina.

