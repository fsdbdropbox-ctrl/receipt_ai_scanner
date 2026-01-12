# Monitoring Setup

## Sentry Configuration

### Backend

Sentry is configured in `backend/src/config/sentry.js` and initialized in `backend/src/app.js`.

**Environment Variables:**
- `SENTRY_DSN` - Your Sentry DSN (required for monitoring)
- `NODE_ENV` - Environment (production/development)

**Features:**
- Automatic error tracking
- Performance monitoring (10% sample rate in production)
- Profiling (10% sample rate in production)
- Context tagging (path, method, installId)

### Frontend

Sentry is initialized in `lib/main.dart` using `SentryFlutter`.

**Environment Variables:**
- `SENTRY_DSN` - Your Sentry DSN (optional, can be empty)
- `ENVIRONMENT` - Environment (defaults to 'production')

**Features:**
- Automatic error tracking
- Performance monitoring (10% sample rate)
- Context tagging (error_type, error_code, scan context)

### Setting Up Sentry

1. Create a Sentry account at https://sentry.io
2. Create a new project
3. Copy your DSN
4. Set environment variables:
   - Backend (Railway): `SENTRY_DSN=your-dsn-here`
   - Frontend (build): `--dart-define=SENTRY_DSN=your-dsn-here`

### What Gets Tracked

**Backend:**
- Unhandled exceptions in routes
- API errors
- Request context (path, method, installId)

**Frontend:**
- Scan errors
- Unexpected exceptions
- Error context (locale, image size, error type)

### Viewing Errors

1. Go to your Sentry dashboard
2. Navigate to Issues
3. Filter by environment, tags, etc.

### Performance Monitoring

Sentry automatically tracks:
- API response times
- Database query times
- External API calls (Gemini)

Sample rates are set to 10% in production to reduce overhead.

