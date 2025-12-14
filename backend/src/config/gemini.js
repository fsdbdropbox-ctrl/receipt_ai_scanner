import { GoogleGenerativeAI } from '@google/generative-ai';

// GEMINI_API_KEY is validated in app.js before this module is used
export const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
// Use gemini-2.5-flash for vision tasks (gemini-1.5 is deprecated)
export const model = genAI.getGenerativeModel({ model: 'gemini-2.5-flash' });

