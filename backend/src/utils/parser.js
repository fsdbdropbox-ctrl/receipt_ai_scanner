export function parseJSON(text) {
  let cleaned = text.trim();
  
  // Remove markdown code blocks
  if (cleaned.startsWith('```')) {
    const lines = cleaned.split('\n');
    if (lines[0].includes('json')) {
      lines.shift();
    }
    if (lines[lines.length - 1].trim() === '```') {
      lines.pop();
    }
    cleaned = lines.join('\n').trim();
  }

  // Try direct parse
  try {
    return JSON.parse(cleaned);
  } catch (_) {}

  // Find JSON object boundaries
  const startIndex = cleaned.indexOf('{');
  if (startIndex === -1) {
    throw new Error('No JSON object found');
  }

  let braceCount = 0;
  let endIndex = startIndex;

  for (let i = startIndex; i < cleaned.length; i++) {
    if (cleaned[i] === '{') {
      braceCount++;
    } else if (cleaned[i] === '}') {
      braceCount--;
      if (braceCount === 0) {
        endIndex = i + 1;
        break;
      }
    }
  }

  if (braceCount !== 0) {
    throw new Error('Unbalanced braces in JSON');
  }

  const jsonStr = cleaned.substring(startIndex, endIndex);
  return JSON.parse(jsonStr);
}

