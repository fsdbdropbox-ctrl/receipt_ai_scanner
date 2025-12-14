# Arquitectura del Proyecto

## Visión General

Receipt AI Scanner es una aplicación multiplataforma (Web, iOS, Android) que escanea recibos y facturas usando IA (Google Gemini) para extraer información estructurada.

## Stack Tecnológico

### Frontend (Flutter)
- **Framework:** Flutter 3.x
- **State Management:** Provider + ChangeNotifier
- **HTTP Client:** `http` package
- **Storage:** `shared_preferences`
- **Payments:** RevenueCat (mobile), Stripe Checkout (web)

### Backend (Node.js/Fastify)
- **Runtime:** Node.js 20.x
- **Framework:** Fastify 4.x
- **IA:** Google Gemini 2.5 Flash
- **Database/Cache:** Redis (Upstash)
- **Payments:** Stripe
- **Image Processing:** Sharp

## Arquitectura del Frontend

### Estructura de Carpetas

```
lib/
├── main.dart                 # Entry point
├── core/                     # Lógica de negocio (independiente de UI)
│   ├── ai/                   # Servicio de escaneo con IA
│   ├── auth/                 # Identificación de instalación
│   ├── errors/               # Manejo de errores
│   ├── file_picker/          # Selección de archivos (multiplataforma)
│   ├── payments/             # Gestión de suscripciones
│   └── utils/                # Utilidades
├── features/                 # Features de la aplicación
│   ├── scan/                 # Escaneo de recibos
│   ├── result/               # Visualización de resultados
│   └── paywall/              # Pantalla de suscripción
└── shared/                   # Código compartido
    ├── models/               # Modelos de datos
    ├── utils/                # Utilidades compartidas
    └── widgets/              # Widgets reutilizables
```

### Patrones de Diseño

1. **Feature-Driven Development**
   - Cada feature tiene su carpeta con View y ViewModel
   - Separación clara de responsabilidades

2. **Provider Pattern**
   - ViewModels extienden `ChangeNotifier`
   - Inyección de dependencias a través del constructor

3. **Conditional Imports**
   - Código específico de plataforma usando `if (dart.library.io)` y `if (dart.library.html)`
   - Permite compartir código entre plataformas

4. **Repository Pattern**
   - Servicios encapsulan la lógica de acceso a datos
   - Abstracción de la fuente de datos (API, storage local)

## Arquitectura del Backend

### Estructura de Carpetas

```
backend/src/
├── app.js                    # Configuración principal de Fastify
├── config/                   # Configuración de servicios externos
│   ├── gemini.js            # Cliente de Gemini AI
│   └── redis.js             # Cliente de Redis
├── middleware/               # Middleware personalizado
│   ├── auth.js              # Autenticación por Install ID
│   └── rateLimit.js         # Rate limiting
├── routes/                   # Endpoints de la API
│   ├── scan-invoice.js      # Escaneo de recibos
│   ├── me.js                # Información del usuario
│   ├── create-checkout-session.js  # Creación de sesión Stripe
│   └── stripe-webhook.js    # Webhook de Stripe
├── services/                 # Lógica de negocio
│   ├── gemini-service.js    # Integración con Gemini
│   ├── image-processor.js   # Procesamiento de imágenes
│   ├── quota-service.js     # Gestión de cuotas
│   └── user-service.js      # Gestión de usuarios
└── utils/                    # Utilidades
    ├── crypto.js            # Funciones criptográficas
    ├── logger.js            # Logging personalizado
    └── parser.js            # Parsing de JSON robusto
```

### Patrones de Diseño

1. **Layered Architecture**
   - **Routes:** Manejo de HTTP (request/response)
   - **Services:** Lógica de negocio
   - **Config:** Configuración de dependencias externas

2. **Middleware Pattern**
   - Autenticación y rate limiting como middleware reutilizable
   - Hooks de Fastify para logging y timing

3. **Error Handling**
   - Try-catch en todas las rutas
   - Logging detallado de errores
   - Códigos de estado HTTP apropiados

## Flujo de Datos

### Escaneo de Recibo

```
1. Usuario selecciona imagen (cámara/galería/archivo)
   ↓
2. Frontend: InvoiceImagePicker obtiene bytes
   ↓
3. Frontend: ScanViewModel llama a InvoiceScannerService
   ↓
4. HTTP POST /api/scan-invoice (multipart/form-data)
   ↓
5. Backend: Middleware valida Install ID
   ↓
6. Backend: Verifica cuota disponible
   ↓
7. Backend: Procesa imagen con Sharp (resize, optimización)
   ↓
8. Backend: Consume cuota en Redis
   ↓
9. Backend: Envía imagen a Gemini AI
   ↓
10. Backend: Parsea respuesta JSON de Gemini
   ↓
11. Backend: Retorna datos estructurados + cuota actualizada
   ↓
12. Frontend: Actualiza ScanViewModel con resultado
   ↓
13. Frontend: Navega a ResultView mostrando datos extraídos
```

### Suscripción Premium

```
1. Usuario hace clic en "Upgrade"
   ↓
2. Frontend: WebPlanService.createCheckoutSession()
   ↓
3. HTTP POST /api/create-checkout-session
   ↓
4. Backend: Crea sesión de Stripe Checkout con 7 días de trial
   ↓
5. Frontend: Redirige a Stripe Checkout
   ↓
6. Usuario completa pago en Stripe
   ↓
7. Stripe envía webhook a /api/stripe-webhook
   ↓
8. Backend: Valida firma del webhook
   ↓
9. Backend: Actualiza estado premium en Redis
   ↓
10. Usuario vuelve a la app (ya es premium)
```

## Seguridad

1. **Autenticación**
   - Install ID único por instalación
   - Hash SHA-256 para anonimato

2. **Rate Limiting**
   - Límite de requests por IP
   - Prevención de abuso

3. **Validación**
   - Validación de imágenes (tamaño, formato)
   - Sanitización de inputs
   - Validación de webhooks de Stripe (firma)

4. **Privacidad**
   - No se almacenan imágenes permanentemente
   - Solo se procesan y eliminan

## Escalabilidad

### Frontend
- Estado local con Provider (no necesita servidor de estado)
- Caché de preferencias locales
- Lazy loading de imágenes

### Backend
- Stateless: cada request es independiente
- Redis para cuotas (escalable horizontalmente)
- Fastify: alto rendimiento, bajo overhead
- Procesamiento asíncrono de imágenes

### Mejoras Futuras
1. **Caché:** Redis para respuestas de Gemini (mismos recibos)
2. **Queue:** Sistema de colas para procesamiento batch
3. **CDN:** Servir assets estáticos desde CDN
4. **Monitoring:** Métricas y alertas (DataDog, Sentry)

## Consideraciones de Rendimiento

1. **Imágenes**
   - Compresión automática con Sharp
   - Límite de tamaño (5MB)
   - Conversión a JPEG optimizado

2. **API Externa (Gemini)**
   - Timeout configurado
   - Retry logic (futuro)
   - Rate limiting para evitar costos excesivos

3. **Redis**
   - TTL automático para cuotas diarias
   - Operaciones atómicas (INCR, EXPIRE)

