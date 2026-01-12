# 📝 Changelog

Historial de cambios de AuditReady.

---

## [1.0.0] - 2025-01-XX

### ✨ Características Principales

- **Autenticación OAuth 2.0**: Google y Apple Sign-In con verificación server-side
- **Onboarding Fiscal**: Configuración de contexto fiscal (país, NIF, régimen)
- **Escaneo Inteligente**: IA contextual con validación fiscal por país
- **Auto-corrección**: Corrección automática de errores comunes (ej: NIF faltante)
- **Dashboard**: Métricas de integridad documental y salud fiscal
- **Validación Fiscal**: Reglas específicas por país (ES, MX, DE)

### 🔧 Backend

- Implementación completa de OAuth verification (Google/Apple)
- Base de datos PostgreSQL con schema completo
- Validación fiscal contextual por país
- Auto-corrección de documentos
- Dashboard con métricas
- Rate limiting y seguridad mejorada

### 📱 Frontend

- Implementación de OAuth real (Google/Apple)
- Pantalla de onboarding fiscal
- Dashboard con métricas e incidencias
- Pantalla de revisión con auto-corrección
- Navegación mejorada

### 🔒 Seguridad

- Verificación server-side de tokens OAuth
- Headers de seguridad configurados
- Sanitización de logs y errores
- Validación de entrada mejorada
- CORS estricto en producción

### 📚 Documentación

- README principal actualizado
- Guía de configuración completa (SETUP.md)
- Documentación de arquitectura (ARCHITECTURE.md)
- Auditoría de seguridad (SECURITY.md)
- Guía de despliegue (DEPLOYMENT.md)

---

## [0.x.x] - Versiones anteriores

Versiones anteriores corresponden a ReceiptData (pre-pivote).

---

**Formato basado en [Keep a Changelog](https://keepachangelog.com/)**

