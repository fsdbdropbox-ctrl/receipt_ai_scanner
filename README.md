# AuditReady 1.0

**Plataforma SaaS de pre-contabilidad y organización fiscal**

AuditReady es una aplicación móvil que digitaliza, valida y organiza documentos fiscales con IA contextual, garantizando la integridad documental antes de que lleguen al contable.

---

## 🚀 Inicio Rápido

### Requisitos Previos

- Flutter SDK 3.0+
- Node.js 18+
- PostgreSQL (Supabase)
- Redis (Upstash)
- Cuentas de: Google Cloud, Apple Developer (para OAuth)

### Instalación

```bash
# Clonar repositorio
git clone <repo-url>
cd receipt_ai_scanner

# Frontend (Flutter)
flutter pub get

# Backend (Node.js)
cd backend
npm install
```

### Configuración

Ver [docs/SETUP.md](docs/SETUP.md) para configuración completa.

---

## 📱 Características Principales

- **🔐 Autenticación OAuth**: Google y Apple Sign-In
- **📋 Onboarding Fiscal**: Configuración de contexto fiscal (país, NIF, régimen)
- **📸 Escaneo Inteligente**: IA contextual que valida documentos según reglas fiscales
- **✅ Validación Automática**: Detección de errores formales y semánticos
- **🔧 Auto-corrección**: Corrección automática de errores comunes (ej: NIF faltante)
- **📊 Dashboard**: Métricas de integridad documental y salud fiscal
- **👥 Colaboración**: Invitación de contables mediante magic links

---

## 🏗️ Arquitectura

```
receipt_ai_scanner/
├── lib/                    # Flutter app
│   ├── core/              # Servicios core (auth, fiscal, dashboard)
│   ├── features/          # Pantallas (auth, onboarding, dashboard, scan, review)
│   └── shared/            # Modelos y widgets compartidos
├── backend/               # Node.js/Fastify API
│   └── src/
│       ├── config/        # Configuración (Gemini, Redis, Sentry)
│       ├── db/            # PostgreSQL (schema, pool)
│       ├── middleware/    # Auth, rate limiting, validación
│       ├── routes/        # API endpoints
│       ├── services/      # Lógica de negocio (OAuth, fiscal, Gemini)
│       └── utils/         # Utilidades
└── docs/                  # Documentación
```

---

## 🔧 Configuración de Producción

### Variables de Entorno (Railway)

**Obligatorias:**
- `DATABASE_URL` - PostgreSQL connection string (Supabase)
- `JWT_SECRET` - Secret para tokens JWT (mínimo 32 caracteres)
- `GEMINI_API_KEY` - Google Gemini API key
- `REDIS_URL` - Redis connection URL (Upstash)
- `STRIPE_SECRET_KEY` - Stripe secret key

**Recomendadas:**
- `GOOGLE_CLIENT_ID` - Para verificación OAuth de Google
- `STRIPE_WEBHOOK_SECRET` - Para webhooks de Stripe
- `ALLOWED_ORIGINS` - Orígenes permitidos para CORS
- `SENTRY_DSN` - Para monitoreo de errores

### Base de Datos (Supabase)

1. Crear proyecto en Supabase
2. Ejecutar `backend/src/db/schema.sql` en SQL Editor
3. Verificar que se crearon 5 tablas:
   - `users`
   - `fiscal_profiles`
   - `documents`
   - `validation_flags`
   - `collaborator_access`

### OAuth (Google Cloud Console)

1. Crear OAuth 2.0 Client ID (Android)
2. Añadir Package Name: `com.receiptdata.app`
3. Añadir SHA-1 fingerprint (debug y release)
4. Copiar Client ID a Railway como `GOOGLE_CLIENT_ID`

Ver [docs/SETUP.md](docs/SETUP.md) para detalles completos.

---

## 📚 Documentación

- **[SETUP.md](docs/SETUP.md)** - Guía completa de configuración
- **[ARCHITECTURE.md](docs/ARCHITECTURE.md)** - Arquitectura del sistema
- **[SECURITY.md](docs/SECURITY.md)** - Auditoría de seguridad
- **[DEPLOYMENT.md](docs/DEPLOYMENT.md)** - Guía de despliegue

---

## 🧪 Testing

```bash
# Backend tests
cd backend
npm test

# Flutter tests
flutter test
```

---

## 📄 Licencia

Private - All rights reserved

---

## 🆘 Soporte

Para problemas o preguntas, contacta: support@receiptdata.app
