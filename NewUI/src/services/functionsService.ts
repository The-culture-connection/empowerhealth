import { httpsCallable } from 'firebase/functions';
import { functions } from '../config/firebase';

export class FunctionsService {
  // Generate learning content
  async generateLearningContent(params: {
    topic: string;
    week?: number;
    trimester?: string;
  }): Promise<any> {
    try {
      const generateLearningContent = httpsCallable(functions, 'generateLearningContent');
      const result = await generateLearningContent(params);
      return result.data;
    } catch (error: any) {
      throw new Error(`Error generating learning content: ${error.message}`);
    }
  }

  // Summarize visit notes
  async summarizeVisitNotes(params: {
    notes: string;
    userId: string;
  }): Promise<any> {
    try {
      const summarizeVisitNotes = httpsCallable(functions, 'summarizeVisitNotes');
      const result = await summarizeVisitNotes(params);
      return result.data;
    } catch (error: any) {
      throw new Error(`Error summarizing visit notes: ${error.message}`);
    }
  }

  // Generate birth plan
  async generateBirthPlan(params: {
    preferences: any;
    userId: string;
  }): Promise<any> {
    try {
      const generateBirthPlan = httpsCallable(functions, 'generateBirthPlan');
      const result = await generateBirthPlan(params);
      return result.data;
    } catch (error: any) {
      throw new Error(`Error generating birth plan: ${error.message}`);
    }
  }

  // Generate appointment checklist
  async generateAppointmentChecklist(params: {
    appointmentType: string;
    week?: number;
  }): Promise<any> {
    try {
      const generateAppointmentChecklist = httpsCallable(functions, 'generateAppointmentChecklist');
      const result = await generateAppointmentChecklist(params);
      return result.data;
    } catch (error: any) {
      throw new Error(`Error generating appointment checklist: ${error.message}`);
    }
  }

  // Analyze emotional content
  async analyzeEmotionalContent(params: {
    content: string;
    userId: string;
  }): Promise<any> {
    try {
      const analyzeEmotionalContent = httpsCallable(functions, 'analyzeEmotionalContent');
      const result = await analyzeEmotionalContent(params);
      return result.data;
    } catch (error: any) {
      throw new Error(`Error analyzing emotional content: ${error.message}`);
    }
  }

  // Generate rights content
  async generateRightsContent(params: {
    topic: string;
  }): Promise<any> {
    try {
      const generateRightsContent = httpsCallable(functions, 'generateRightsContent');
      const result = await generateRightsContent(params);
      return result.data;
    } catch (error: any) {
      throw new Error(`Error generating rights content: ${error.message}`);
    }
  }

  // Simplify text
  async simplifyText(params: {
    text: string;
  }): Promise<any> {
    try {
      const simplifyText = httpsCallable(functions, 'simplifyText');
      const result = await simplifyText(params);
      return result.data;
    } catch (error: any) {
      throw new Error(`Error simplifying text: ${error.message}`);
    }
  }
}

export const functionsService = new FunctionsService();
