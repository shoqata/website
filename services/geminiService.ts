
import { GoogleGenAI } from "@google/genai";

export const generateSocialMediaContent = async (topic: string, tone: string, language: string) => {
  const ai = new GoogleGenAI({ apiKey: process.env.API_KEY });
  const response = await ai.models.generateContent({
    model: 'gemini-3-flash-preview',
    contents: `Write a humanitarian social media post for ${language} about: ${topic}. The tone should be ${tone}. Include relevant hashtags for Instagram and Facebook.`,
    config: {
      temperature: 0.7,
    }
  });
  return response.text;
};

export const analyzeImageAndSuggestPost = async (imageBase64: string) => {
  const ai = new GoogleGenAI({ apiKey: process.env.API_KEY });
  
  // Base64 data usually contains the prefix "data:image/jpeg;base64,"
  const cleanBase64 = imageBase64.split(',')[1] || imageBase64;

  const imagePart = {
    inlineData: {
      mimeType: 'image/jpeg',
      data: cleanBase64,
    },
  };
  
  const textPart = {
    text: "Analyze this humanitarian activity image and write a compelling Instagram caption. Also suggest alt text for accessibility and 5 relevant hashtags. Respond in German/Albanian mixed for diaspora context."
  };

  const response = await ai.models.generateContent({
    model: 'gemini-3-flash-preview',
    contents: { parts: [imagePart, textPart] },
  });

  return response.text;
};

export const generateImagePrompt = async (postContent: string) => {
  const ai = new GoogleGenAI({ apiKey: process.env.API_KEY });
  const response = await ai.models.generateContent({
    model: 'gemini-3-flash-preview',
    contents: `Generate a detailed artistic prompt for an image generation tool based on this social media post: "${postContent}". The style should be professional, warm, and authentic humanitarian photography.`,
  });
  return response.text;
};

export const analyzeReceiptImage = async (imageBase64: string) => {
  const ai = new GoogleGenAI({ apiKey: process.env.API_KEY });
  const cleanBase64 = imageBase64.split(',')[1] || imageBase64;

  const imagePart = {
    inlineData: {
      mimeType: 'image/jpeg',
      data: cleanBase64,
    },
  };

  const prompt = `
    Analyze this receipt/invoice image. Extract the following information in JSON format:
    {
      "vendor": "Name of the vendor/shop",
      "amount": number (total amount),
      "currency": "Currency Code (CHF, EUR, etc)",
      "date": "YYYY-MM-DD",
      "description": "Short description of items purchased (e.g. 'Office Supplies', 'Catering')",
      "suggestedAccountCode": "Suggest a Swiss accounting code (4 digits) based on context (e.g. 4000 for Material, 6000 for Rent, 6500 for Admin, 6570 for Postage, 6700 for Advertising)"
    }
    Only return valid JSON. If values are missing, use reasonable defaults or empty strings.
  `;

  const response = await ai.models.generateContent({
    model: 'gemini-3-flash-preview',
    contents: { parts: [imagePart, { text: prompt }] },
    config: {
        responseMimeType: 'application/json'
    }
  });

  return response.text;
};
