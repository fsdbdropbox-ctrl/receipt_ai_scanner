# 🚀 Guía de Despliegue

Proceso completo de despliegue de AuditReady a producción.

---

## 📋 Pre-requisitos

- [x] Base de datos configurada en Supabase
- [x] Schema SQL ejecutado
- [x] Variables de entorno configuradas en Railway
- [x] OAuth configurado (Google/Apple)
- [x] Tests pasando

---

## 🔧 Backend (Railway)

### Paso 1: Verificar Variables

Asegúrate de tener todas las variables obligatorias:

```bash
DATABASE_URL=...
JWT_SECRET=...
GEMINI_API_KEY=...
REDIS_URL=...
STRIPE_SECRET_KEY=...
GOOGLE_CLIENT_ID=...
```

### Paso 2: Deploy

Railway hace deploy automático al hacer push a la rama principal.

**Verificar:**
1. Ve a Railway → Deployments
2. Verifica que el último deployment sea exitoso
3. Revisa los logs para errores

### Paso 3: Health Check

```bash
curl https://tu-backend.railway.app/health
```

Debería devolver:
```json
{
  "status": "ok",
  "timestamp": "...",
  "version": "1.0.0"
}
```

---

## 📱 Frontend (Flutter)

### Android

```bash
# Build APK
flutter build apk --release

# Build App Bundle (para Play Store)
flutter build appbundle --release
```

### iOS

```bash
# Build para iOS
flutter build ios --release
```

### Verificar

1. Instala la app en dispositivo real
2. Prueba login con Google
3. Verifica que el backend valida correctamente
4. Prueba flujo completo: Login → Onboarding → Dashboard

---

## ✅ Checklist Pre-Lanzamiento

### Backend

- [ ] Health check responde correctamente
- [ ] Variables de entorno configuradas
- [ ] Base de datos accesible
- [ ] Redis funcionando
- [ ] OAuth verificación funcionando
- [ ] Logs sin errores críticos

### Frontend

- [ ] OAuth real implementado (no mocks)
- [ ] Build exitoso (Android/iOS)
- [ ] Pruebas en dispositivo real
- [ ] Flujo completo funcionando

### Seguridad

- [ ] HTTPS configurado
- [ ] CORS configurado correctamente
- [ ] Secrets no expuestos
- [ ] Logs sanitizados

---

## 🐛 Troubleshooting

### Backend no arranca

1. Revisa logs en Railway
2. Verifica variables de entorno
3. Verifica que `DATABASE_URL` sea correcta

### OAuth falla

1. Verifica `GOOGLE_CLIENT_ID` en Railway
2. Verifica SHA-1 en Google Cloud Console
3. Verifica que el package name coincida

### Base de datos no conecta

1. Verifica `DATABASE_URL` en Railway
2. Verifica que la contraseña sea correcta
3. Verifica que Supabase permita conexiones externas

---

**Última actualización:** 2025-01-XX

