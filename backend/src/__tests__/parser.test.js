import { test } from 'node:test';
import assert from 'node:assert';
import { parseJSON } from '../utils/parser.js';

test('parseJSON should parse valid JSON object', () => {
  const jsonStr = '{"total": 10.99, "vendor": "Test Store"}';
  const result = parseJSON(jsonStr);
  
  assert.deepStrictEqual(result, {
    total: 10.99,
    vendor: 'Test Store',
  });
});

test('parseJSON should parse JSON with markdown code blocks', () => {
  const jsonStr = '```json\n{"total": 10.99}\n```';
  const result = parseJSON(jsonStr);
  
  assert.deepStrictEqual(result, { total: 10.99 });
});

test('parseJSON should extract JSON from text with surrounding content', () => {
  const jsonStr = 'Some text before {"total": 10.99} some text after';
  const result = parseJSON(jsonStr);
  
  assert.deepStrictEqual(result, { total: 10.99 });
});

test('parseJSON should handle nested JSON objects', () => {
  const jsonStr = '{"data": {"total": 10.99, "tax": 1.10}}';
  const result = parseJSON(jsonStr);
  
  assert.deepStrictEqual(result, {
    data: {
      total: 10.99,
      tax: 1.10,
    },
  });
});

test('parseJSON should throw error for invalid JSON', () => {
  const invalidJson = '{invalid json}';
  
  assert.throws(() => {
    parseJSON(invalidJson);
  });
});

test('parseJSON should handle null values', () => {
  const jsonStr = '{"total": null, "vendor": "Test"}';
  const result = parseJSON(jsonStr);
  
  assert.deepStrictEqual(result, {
    total: null,
    vendor: 'Test',
  });
});
