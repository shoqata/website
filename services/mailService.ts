
import { db } from './firebase';
import { collection, addDoc, serverTimestamp } from '@/services/supabase-bridge';

interface EmailAttachment {
  filename: string;
  content: string; // base64 string
  encoding?: 'base64'; // Default is base64 for the extension
}

interface EmailOptions {
  to: string | string[];
  subject: string;
  html: string;
  text?: string;
  attachments?: EmailAttachment[];
  template?: {
    name: string;
    data: any;
  };
}

/**
 * Sends an email by writing a document to the 'mail' collection.
 * The Firebase "Trigger Email" extension must be installed and configured with SMTP.
 */
export const sendEmail = async (options: EmailOptions) => {
  try {
    await addDoc(collection(db, 'mail'), {
      to: options.to,
      message: {
        subject: options.subject,
        html: options.html,
        text: options.text || options.html.replace(/<[^>]*>?/gm, ''), // Simple strip tags for fallback
        attachments: options.attachments || []
      },
      createdAt: serverTimestamp(),
    });
    return { success: true };
  } catch (error) {
    console.error("Error queuing email:", error);
    throw error;
  }
};
