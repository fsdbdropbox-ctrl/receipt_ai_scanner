# Cache Implementation

## Gemini Response Cache

The backend now includes caching for Gemini API responses to reduce costs and improve response times.

### How It Works

1. **Cache Key Generation:** SHA-256 hash of the image buffer
2. **Storage:** Redis with 24-hour TTL
3. **Cache Hit:** Returns cached response immediately
4. **Cache Miss:** Calls Gemini API and stores result

### Configuration

**Environment Variable:**
- `ENABLE_GEMINI_CACHE` - Set to 'false' to disable (default: enabled)

### Cache Strategy

**Key Format:** `gemini:cache:{sha256_hash}`

**TTL:** 24 hours (86400 seconds)

**Benefits:**
- Reduces Gemini API costs for duplicate images
- Faster response times for cached requests
- Automatic expiration (no manual cleanup needed)

### Cache Behavior

- **Cache Hit:** Instant response (~1ms vs ~3-5s API call)
- **Cache Miss:** Normal API call, result is cached
- **Cache Error:** Non-fatal, falls back to API call

### Monitoring Cache Performance

Check Redis keys:
```bash
redis-cli KEYS "gemini:cache:*"
redis-cli TTL "gemini:cache:{hash}"
```

### When Cache is Useful

- Users scanning the same receipt multiple times
- Testing/debugging (same test images)
- Batch processing similar receipts

### When Cache is Less Useful

- Unique receipts (each scan is different)
- Very diverse user base

### Estimated Savings

If 20% of scans are duplicates:
- 20% cost reduction on Gemini API
- 20% faster response times for cached requests

