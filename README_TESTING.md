# Testing Guide

## Backend Tests

### Running Tests

```bash
cd backend
npm test
```

### Test Structure

Tests use Node.js built-in `node:test` module (no external dependencies needed).

**Location:** `backend/src/__tests__/`

**Current Tests:**
- `parser.test.js` - JSON parsing utilities

### Writing New Tests

```javascript
import { test } from 'node:test';
import assert from 'node:assert';
import { functionToTest } from '../path/to/module.js';

test('should do something', () => {
  const result = functionToTest();
  assert.strictEqual(result, expected);
});
```

## Frontend Tests

### Running Tests

```bash
flutter test
```

### Test Structure

**Location:** `test/`

**Current Tests:**
- `core/ai/invoice_scanner_service_test.dart` - Scanner service tests
- `features/scan/scan_view_model_test.dart` - ViewModel tests
- `widget_test.dart` - Basic widget test

### Writing New Tests

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_ai_scanner/path/to/widget.dart';

void main() {
  testWidgets('should display something', (WidgetTester tester) async {
    await tester.pumpWidget(MyWidget());
    expect(find.text('Expected Text'), findsOneWidget);
  });
}
```

## Integration Tests

Integration tests should test the full flow from API call to UI update.

**Note:** Integration tests require a running backend or mocked API responses.

## Test Coverage

Current coverage is minimal. To improve:

1. Add tests for all service methods
2. Add tests for error handling
3. Add integration tests for API endpoints
4. Add widget tests for UI components

