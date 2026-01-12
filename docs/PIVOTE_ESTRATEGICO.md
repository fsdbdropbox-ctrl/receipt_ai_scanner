# Pivote Estratégico: ReceiptData → AuditReady

## Resumen Ejecutivo

Este documento describe la transformación de ReceiptData de una herramienta de escaneo/OCR puntual a **AuditReady**, una plataforma SaaS de pre-contabilidad y organización financiera.

**Fecha del Pivote:** Enero 2026  
**Versión de Especificación:** v33.0  
**Estado:** En Planificación

---

## Cambio de Propuesta de Valor

### Antes (ReceiptData)
- **Propuesta:** Escáner de recibos con OCR
- **Modelo:** Utilidad transaccional puntual
- **Autenticación:** Anónima (Install ID)
- **Almacenamiento:** Local (SharedPreferences)
- **Enfoque:** Extracción de datos básicos

### Después (AuditReady)
- **Propuesta:** Plataforma de pre-contabilidad y organización fiscal
- **Modelo:** Sistema continuo de gestión documental
- **Autenticación:** OAuth 2.0 obligatorio (Apple/Google)
- **Almacenamiento:** PostgreSQL + Cloud Storage (S3/R2)
- **Enfoque:** Integridad documental, validación formal y semántica

---

## Principios Estratégicos

### 1. De "Escáner" a "Bóveda"
El acceso no es solo login; es el contrato de seguridad. Se elimina el escaneo anónimo. El usuario debe percibir que entra en una "bóveda administrativa", no en una utilidad desechable.

### 2. Protocolo de Copy Seguro
**Eliminado:**
- ❌ "Ahorra impuestos"
- ❌ "Deducible"
- ❌ Cualquier afirmación sobre deducibilidad fiscal

**Implementado:**
- ✅ "Prepara tus impuestos"
- ✅ "Documento Completo"
- ✅ "Integridad Documental"
- ✅ Lenguaje estrictamente sobre organización administrativa

### 3. No Sustituir al Asesor Fiscal
La plataforma actúa como una **capa previa** de organización, validación formal y preparación documental. No asume funciones de gestoría ni asesoramiento fiscal.

---

## Arquitectura Técnica

### Base de Datos: PostgreSQL

#### Esquema Principal

```sql
-- Usuarios
users (id, email, oauth_provider, oauth_id, two_factor_enabled, created_at)

-- Perfiles Fiscales
fiscal_profiles (
  id, user_id, country_code, tax_regime, activity_sector, 
  tax_id, created_at, updated_at
)

-- Documentos
documents (
  id, user_id, fiscal_profile_id,
  total, tax, vendor, invoice_date, currency, category,
  validation_status, validation_errors, semantic_warnings,
  file_url, file_hash, mime_type,
  scanned_at, reviewed_at, archived_at, confidence,
  created_at, updated_at
)

-- Accesos de Colaboradores (Contables)
collaborator_access (
  id, user_id, collaborator_email, access_level, 
  token, expires_at, created_at
)
```

### Almacenamiento en la Nube

- **Proveedor:** AWS S3 o Cloudflare R2
- **Estructura:** `{userId}/{documentId}/{hash}.jpg`
- **Seguridad:** 
  - Encriptación en reposo (AES-256)
  - URLs firmadas temporales
  - Políticas de acceso privado

### Autenticación

- **OAuth 2.0:** Apple Sign In, Google Sign In
- **2FA:** Opcional pero recomendado
- **Sesiones:** JWT con refresh tokens
- **Migración:** Plan para usuarios existentes con Install ID

---

## IA Contextual por Jurisdicción

### Sistema de Prompts Dinámicos

La IA deja de ser genérica y se adapta al contexto fiscal del usuario:

```javascript
// Ejemplo: España (ES)
{
  taxIdLabel: 'NIF/CIF',
  taxIdFormat: '8 dígitos + letra (NIF) o letra + 8 dígitos (CIF)',
  dateFormat: 'DD/MM/YYYY',
  requiredFields: ['tax_id', 'vendor', 'date', 'total', 'tax_rate'],
  taxLabels: ['IVA', 'IGIC', 'IPS'],
  validationRules: {
    nifFormat: /^[A-Z]?\d{8}[A-Z]$/,
    taxRates: [0.04, 0.10, 0.21]
  }
}
```

### Validación Formal y Semántica

1. **Validación Formal:**
   - Campos obligatorios según jurisdicción
   - Coherencia matemática (base + IVA = total)
   - Formato de identificadores fiscales
   - Fechas válidas

2. **Validación Semántica:**
   - Coherencia entre categoría de gasto y actividad del usuario
   - Detección de gastos atípicos
   - Señalización de elementos que requieren revisión profesional

3. **Estados de Validación:**
   - `pending`: Pendiente de validación
   - `valid`: Formalmente válido
   - `warning`: Avisos no críticos
   - `error`: Errores que requieren corrección

---

## Flujos de Usuario

### 1. Onboarding

1. **Registro OAuth** (Apple/Google)
2. **Perfilado Fiscal:**
   - País de residencia fiscal
   - Régimen profesional (autónomo, sociedad, personal)
   - Sector de actividad
   - NIF/CIF (opcional en registro)
3. **Tutorial:** Explicación de conceptos clave (integridad, incidencias)

### 2. Ingesta Multicanal

**Menú de Captura (Overlay):**
- Escanear (cámara especializada)
- Fototeca (lote de imágenes)
- Importar PDF (con opción de separar páginas)

**Características:**
- Procesamiento en segundo plano
- Toast notifications para seguimiento
- Resumen de lote con estado de cada documento

### 3. Dashboard

**Métricas Clave:**
- **Integridad Documental:** % de documentos listos para archivo
- **Cola de Incidencias:** Agrupación por causa raíz
- **Resumen por Periodo:** Totales, categorías, tendencias

**Indicadores de Acción:**
- Documentos incompletos
- Inconsistencias detectadas
- Elementos pendientes de revisión

### 4. Auditoría Expandida (Review)

**Campos Críticos:**
- NIF Emisor
- NIF Receptor
- Desglose: Base Imponible + Cuota IVA + Tipo (%)
- Etiquetas: Clasificación analítica (Proyecto, Cliente)

**Interfaz:**
- Vista previa del documento original
- Panel de datos extraídos
- Alertas de incidencias formales
- Acciones de corrección

### 5. Archivo Fiscal

**Estados:**
- **Completo:** Formalmente válido, archivado
- **Incompleto:** Falta dato, requiere acción
- **Pendiente:** En revisión

**Organización:**
- Por periodo (mes/año)
- Por categoría
- Por estado de validación
- Búsqueda y filtros

### 6. Exportación

**Formatos:**
- Excel/CSV (datos estructurados)
- Originales (ZIP con imágenes/PDFs)
- Resumen PDF (reporte consolidado)

**Destinatarios:**
- Contable/Asesor (acceso colaborativo)
- Exportación directa para importación en sistemas contables

---

## Modelo de Negocio

### Suscripción Recurrente

**Justificación:**
- No por número de escaneos
- Por valor continuo de:
  - Custodia documental
  - Organización histórica
  - Validación avanzada
  - Colaboración con contables

**Planes (Propuesta):**
- **Básico:** Hasta 50 documentos/mes
- **Profesional:** Ilimitado + colaboración
- **Empresarial:** Múltiples usuarios + API

---

## Mitigación Legal

### Lenguaje y Estados

1. **Eliminación de Afirmaciones Fiscales:**
   - No mencionar "deducible"
   - No calcular deducciones
   - No asesorar sobre cumplimiento

2. **Estados de Incertidumbre:**
   - `requiresProfessionalReview`
   - `atypicalExpense`
   - `incompleteDocumentation`
   - `ambiguousClassification`

3. **Disclaimers:**
   - En onboarding
   - En pantallas de validación
   - En exportaciones

### Ejemplo de Disclaimer

> "Esta herramienta facilita la organización y validación administrativa de documentos. NO constituye asesoramiento fiscal, legal o contable. Las validaciones son de carácter técnico y administrativo. Consulte con su asesor fiscal para decisiones sobre deducibilidad y cumplimiento normativo."

---

## Plan de Migración

### Fase 1: Fundación (2-3 semanas)
- [ ] Implementar PostgreSQL y migraciones
- [ ] Sistema de autenticación OAuth básico
- [ ] Modelos de datos (users, fiscal_profiles, documents)

### Fase 2: Core Features (3-4 semanas)
- [ ] Almacenamiento en la nube (S3/R2)
- [ ] Sistema de prompts contextuales
- [ ] Validación formal básica

### Fase 3: Experiencia de Usuario (2-3 semanas)
- [ ] Onboarding y perfilado fiscal
- [ ] Dashboard con métricas básicas
- [ ] Vista de revisión de documentos

### Fase 4: Validación Avanzada (2 semanas)
- [ ] Validación semántica
- [ ] Sistema de incidencias
- [ ] Exportación para contables

### Fase 5: Refinamiento (1-2 semanas)
- [ ] Optimizaciones de performance
- [ ] Tests end-to-end
- [ ] Documentación y migración de datos existentes

---

## Consideraciones Técnicas

### Migración de Datos
- Plan para usuarios existentes con `Install ID`
- Conversión de historial local a PostgreSQL
- Preservación de documentos escaneados

### Compatibilidad
- Mantener endpoints antiguos durante transición
- Versionado de API
- Comunicación clara de cambios

### Costos
- Almacenamiento en la nube (estimación por usuario)
- PostgreSQL (managed service recomendado)
- OAuth providers (gratis hasta cierto volumen)

### Seguridad
- Encriptación en reposo y en tránsito
- Auditoría de accesos
- Cumplimiento GDPR/LOPD
- Backup y disaster recovery

### Performance
- Índices en PostgreSQL
- CDN para documentos
- Caché de validaciones
- Optimización de queries

---

## Referencias

- **Especificación Visual:** `docs/AUDITREADY_SPEC_V33.html`
- **Arquitectura Actual:** `ARCHITECTURE.md`
- **Informe Estratégico Original:** (documento compartido por usuario)

---

## Notas de Implementación

Este pivote requiere una transformación profunda pero estructurada. La especificación visual (v33) proporciona una guía detallada de la experiencia de usuario objetivo.

**Próximos Pasos:**
1. Revisar y aprobar el plan de migración
2. Configurar entorno de desarrollo con PostgreSQL
3. Implementar Fase 1 (Fundación)
4. Iterar basándose en feedback y pruebas