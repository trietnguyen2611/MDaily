import { extractTextFromImage, processReceiptWithAI } from './src/services/ai.ts';

async function test() {
  console.log('Testing...');
  // A tiny valid base64 image of letter A
  const img = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';
  try {
    const text = await extractTextFromImage(img);
    console.log('Extracted:', text);
  } catch(e) {
    console.error('Error:', e);
  }
}
test();
