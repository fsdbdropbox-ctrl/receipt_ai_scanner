import 'dart:convert';

class RobustJsonParser {
  static dynamic tryParse(String text) {
    // Remove markdown code blocks if present
    String cleaned = text.trim();
    if (cleaned.startsWith('```')) {
      final lines = cleaned.split('\n');
      if (lines.first.contains('json')) {
        lines.removeAt(0);
      }
      if (lines.last.trim() == '```') {
        lines.removeLast();
      }
      cleaned = lines.join('\n').trim();
    }

    // Try direct parse first
    try {
      return jsonDecode(cleaned);
    } catch (_) {}

    // Try to find JSON object boundaries
    final startIndex = cleaned.indexOf('{');
    if (startIndex == -1) {
      throw const FormatException('No JSON object found');
    }

    int braceCount = 0;
    int endIndex = startIndex;

    for (int i = startIndex; i < cleaned.length; i++) {
      if (cleaned[i] == '{') {
        braceCount++;
      } else if (cleaned[i] == '}') {
        braceCount--;
        if (braceCount == 0) {
          endIndex = i + 1;
          break;
        }
      }
    }

    if (braceCount != 0) {
      throw const FormatException('Unbalanced braces in JSON');
    }

    final jsonStr = cleaned.substring(startIndex, endIndex);
    return jsonDecode(jsonStr);
  }
}

