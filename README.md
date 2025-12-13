# Receipt AI Scanner

AI-powered receipt and invoice scanner with automatic data extraction.

## Features

- 📸 Scan receipts and invoices from camera, gallery, or file
- 🤖 AI-powered data extraction (total, vendor, date, tax, category)
- 🌍 Multilingual support (EN, ES, DE, FR, IT)
- 💰 Premium subscription for unlimited scans
- 🔒 Privacy-focused (no data retention)

## Project Structure

```
receipt_ai_scanner/
├── lib/                    # Flutter app
│   ├── core/              # Core services and utilities
│   ├── features/          # Feature screens
│   └── shared/            # Shared models and widgets
└── backend/               # Node.js/Fastify API
    └── src/
        ├── config/        # Configuration
        ├── middleware/    # Auth, rate limiting
        ├── routes/        # API routes
        ├── services/      # Business logic
        └── utils/         # Utilities
```

## Setup

### Flutter App

1. Install dependencies:
```bash
cd receipt_ai_scanner
flutter pub get
```

2. Configure API URL (optional):
```bash
flutter run --dart-define=API_BASE_URL=https://receiptaiscanner-production.up.railway.app
```

### Backend

1. Install dependencies:
```bash
cd backend
npm install
```

2. Configure environment variables:
```bash
cp .env.example .env
# Edit .env with your keys
```

3. Start server:
```bash
npm start
```

## Environment Variables

- `GEMINI_API_KEY`: Google Gemini API key
- `REDIS_URL`: Redis connection URL (Upstash)
- `STRIPE_SECRET_KEY`: Stripe secret key
- `STRIPE_WEBHOOK_SECRET`: Stripe webhook secret
- `ALLOWED_ORIGINS`: Comma-separated list of allowed CORS origins
- `DAILY_FREE_LIMIT`: Daily free scan limit (default: 5)

## License

Private - All rights reserved

