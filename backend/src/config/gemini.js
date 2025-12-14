import { GoogleGenerativeAI } from '@google/generative-ai';

// GEMINI_API_KEY is validated in app.js before this module is used
export const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
// Use gemini-1.5-flash-latest for vision tasks (v1 API)
export const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash-latest' });

