# 🏗️ Arquitectura de AuditReady

Documentación técnica de la arquitectura del sistema.

---

## 📐 Visión General

AuditReady es una aplicación SaaS multi-plataforma (Android/iOS) con backend Node.js que proporciona:

- **Autenticación OAuth 2.0** (Google/Apple)
- **Validación fiscal contextual** por país
- **Almacenamiento persistente** en PostgreSQL
- **Procesamiento de IA** con Google Gemini
- **Monetización** mediante Stripe

---

## 🔄 Flujo de Datos

```
┌─────────────┐
│   Flutter   │
│    App      │
└──────┬──────┘
       │
       │ HTTPS/JWT
       │
┌──────▼──────────────────┐
│   Fastify Backend       │
│   (Node.js)             │
├─────────────────────────┤
│ • Auth (OAuth verify)   │
│ • Fiscal Validation     │
│ • Gemini AI Service     │
│ • Document Storage      │
└──────┬──────────────────┘
       │
       ├──────────┬──────────┬──────────┐
       │          │          │          │
┌──────▼──┐ ┌─────▼───┐ ┌───▼────┐ ┌───▼────┐
│PostgreSQL│ │  Redis  │ │ Gemini │ │ Stripe │
│(Supabase)│ │(Upstash)│ │   API  │ │   API  │
└──────────┘ └─────────┘ └────────┘ └────────┘
```

---

## 📱 Frontend (Flutter)

### Estructura

```
lib/
├── core/                    # Servicios core
│   ├── auth/               # Autenticación OAuth
│   ├── fiscal/             # Perfiles fiscales
│   ├── dashboard/          # Métricas
│   └── payments/           # Stripe
├── features/               # Pantallas
│   ├── auth/              # Login (Google/Apple)
│   ├── onboarding/        # Setup fiscal
│   ├── dashboard/         # Métricas e incidencias
│   ├── scan/              # Escaneo de documentos
│   └── review/            # Revisión y auto-corrección
└── shared/                 # Compartido
    ├── models/            # Modelos de datos
    └── widgets/           # Widgets reutilizables
```

### Estado

- **Provider**: Gestión de estado reactiva
- **SharedPreferences**: Almacenamiento local (tokens, usuario)
- **HTTP**: Comunicación con backend

---

## 🔧 Backend (Node.js/Fastify)

### Estructura

```
backend/src/
├── app.js                  # Entry point, configuración Fastify
├── config/                 # Configuración
│   ├── gemini.js          # Google Gemini client
│   ├── redis.js           # Redis client
│   └── sentry.js          # Error monitoring
├── db/                     # Base de datos
│   ├── pool.js            # PostgreSQL connection pool
│   └── schema.sql         # Database schema
├── middleware/            # Middleware
│   ├── auth.js            # Install ID auth (legacy)
│   ├── jwt-auth.js        # JWT authentication
│   ├── rateLimit.js       # Rate limiting
│   └── uploadValidation.js # File validation
├── routes/                 # API endpoints
│   ├── auth.js            # OAuth authentication
│   ├── fiscal-profile.js  # Fiscal profiles CRUD
│   ├── scan-invoice-v2.js # Enhanced scanning
│   ├── dashboard.js       # Metrics endpoint
│   └── stripe-webhook.js  # Payment webhooks
├── services/               # Business logic
│   ├── oauth-verification.js # OAuth token verification
│   ├── fiscal-rules.js    # Country-specific rules
│   ├── fiscal-validation.js # Document validation
│   └── gemini-service.js  # AI processing
└── utils/                  # Utilities
    ├── logger.js          # Logging (sanitized)
    └── parser.js           # JSON parsing
```

### Endpoints Principales

**Públicos:**
- `POST /api/auth/oauth` - Autenticación OAuth
- `GET /health` - Health check

**Protegidos (JWT):**
- `GET /api/fiscal-profile` - Obtener perfil fiscal
- `POST /api/fiscal-profile` - Crear/actualizar perfil
- `POST /api/v2/scan-invoice` - Escanear documento
- `POST /api/v2/documents/:id/fix` - Auto-corrección
- `GET /api/dashboard/metrics` - Métricas del dashboard

**Webhooks:**
- `POST /api/stripe-webhook` - Webhooks de Stripe

---

## 🗄️ Base de Datos (PostgreSQL)

### Schema

**Tablas principales:**

1. **users** - Usuarios OAuth
   - `id`, `email`, `oauth_provider`, `oauth_id`

2. **fiscal_profiles** - Perfiles fiscales
   - `user_id`, `country_code`, `tax_id`, `tax_regime`

3. **documents** - Documentos escaneados
   - `user_id`, `fiscal_profile_id`, `total`, `tax`, `vendor`, `validation_status`

4. **validation_flags** - Banderas de validación
   - `document_id`, `flag_code`, `severity`, `auto_fixable`

5. **collaborator_access** - Acceso de contables
   - `user_id`, `collaborator_email`, `token`, `expires_at`

### Índices

- `idx_documents_user_id`
- `idx_documents_validation_status`
- `idx_validation_flags_document_id`
- `idx_collaborator_access_token`

---

## 🔐 Seguridad

### Autenticación

- **OAuth 2.0**: Verificación server-side de tokens (Google/Apple)
- **JWT**: Tokens firmados para sesiones
- **Rate Limiting**: Protección contra abuso

### Validación

- **SQL Injection**: Parámetros preparados en todas las queries
- **XSS**: Sanitización de entrada
- **CORS**: Configuración estricta en producción
- **Headers**: Security headers (X-Content-Type-Options, X-Frame-Options, etc.)

### Logging

- **Sanitización**: Secrets nunca en logs
- **Stack traces**: Solo en desarrollo
- **IP hashing**: IPs no se exponen completas

---

## 🤖 Procesamiento de IA

### Google Gemini

- **Modelo**: `gemini-1.5-pro`
- **Temperatura**: 0 (determinista)
- **Contexto**: Inyecta reglas fiscales según país
- **Caché**: Redis para reducir costos

### Flujo de Escaneo

1. Usuario sube imagen
2. Validación de formato/tamaño
3. Procesamiento de imagen (Sharp)
4. Extracción con Gemini (contexto fiscal)
5. Validación fiscal (reglas por país)
6. Almacenamiento en PostgreSQL
7. Respuesta con datos extraídos y validación

---

## 💳 Monetización (Stripe)

- **Modelo**: Suscripción recurrente
- **Webhooks**: Idempotencia garantizada
- **Planes**: Free (5 scans/día) y Premium (1000 scans/mes)

---

## 📊 Monitoreo

- **Sentry**: Error tracking y performance
- **Logs**: Structured logging con sanitización
- **Health checks**: Endpoint `/health` para monitoring

---

## 🚀 Despliegue

- **Backend**: Railway (Node.js)
- **Base de datos**: Supabase (PostgreSQL)
- **Cache**: Upstash (Redis)
- **Frontend**: Play Store / App Store

---

**Última actualización:** 2025-01-XX
