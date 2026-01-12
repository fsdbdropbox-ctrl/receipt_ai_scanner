# DNS Configuration for receiptdata.app

## Overview

This guide explains how to configure DNS for the ReceiptData domain.

## DNS Records to Configure

### 1. Frontend (receiptdata.app)

For Cloudflare Pages:
```
Type: CNAME
Name: @
Value: receiptdata.pages.dev  (or your Cloudflare Pages domain)
Proxy: Yes (orange cloud)
```

For www subdomain:
```
Type: CNAME
Name: www
Value: receiptdata.app
Proxy: Yes
```

### 2. API Backend (api.receiptdata.app)

Point to Railway:
```
Type: CNAME
Name: api
Value: receiptaiscanner-production.up.railway.app
Proxy: No (gray cloud) - Railway handles SSL
```

### 3. Email (MX Records)

If using email forwarding from Porkbun:
```
Type: MX
Name: @
Value: fwd1.porkbun.com
Priority: 10

Type: MX
Name: @
Value: fwd2.porkbun.com
Priority: 20
```

For SPF (prevent spoofing):
```
Type: TXT
Name: @
Value: v=spf1 include:_spf.porkbun.com ~all
```

## Steps to Configure

### In Porkbun:

1. Go to **Domain Management** → **receiptdata.app**
2. Click **DNS** tab
3. Add the records above

### In Railway:

1. Go to your project settings
2. Add custom domain: `api.receiptdata.app`
3. Railway will provide verification steps
4. Wait for SSL certificate (automatic)

### In Cloudflare Pages:

1. Go to **Workers & Pages** → Your project
2. **Custom domains** → Add `receiptdata.app`
3. Follow verification steps

## Environment Variables to Update

### Railway Backend:
```
ALLOWED_ORIGINS=https://receiptdata.app,https://www.receiptdata.app
FRONTEND_URL=https://receiptdata.app
```

### Flutter Build:
```bash
flutter build web --dart-define=API_BASE_URL=https://api.receiptdata.app
```

## Verification

After setup, verify:

1. https://receiptdata.app loads the app
2. https://api.receiptdata.app/health returns `{"status":"ok"}`
3. https://receiptdata.app/privacy loads privacy policy
4. https://receiptdata.app/terms loads terms of service

## SSL/HTTPS

- `.app` domains REQUIRE HTTPS (HSTS preloaded)
- Porkbun includes free Let's Encrypt SSL
- Railway auto-provisions SSL for custom domains
- Cloudflare Pages provides SSL automatically

## Troubleshooting

### "SSL Error" or "Connection Refused"
- Wait 5-30 minutes for SSL provisioning
- Ensure CNAME is correct

### "502 Bad Gateway"
- Check Railway deployment is running
- Verify CNAME points to correct Railway domain

### "CORS Error"
- Update `ALLOWED_ORIGINS` in Railway
- Redeploy backend

## Timeline

- DNS propagation: 5 minutes to 48 hours
- SSL provisioning: 5-30 minutes
- Full setup: Usually < 1 hour

