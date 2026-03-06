/**
 * Documentation Management
 * Handles upload, retrieval, and versioning of admin documents
 */

import { 
  doc, 
  getDoc, 
  setDoc, 
  collection,
  addDoc,
  serverTimestamp,
  getDocs,
  query,
  orderBy,
  limit
} from 'firebase/firestore';
import { ref, uploadBytes, getDownloadURL, deleteObject } from 'firebase/storage';
import { firestore, storage } from '../firebase/firebase';

export type DocumentType = 'privacy_policy' | 'terms_of_service' | 'contact_support';

interface DocumentMetadata {
  title: string;
  content: string; // Markdown/text content
  contentType: 'text' | 'file'; // Track if it's text or file-based
  storagePath?: string; // Optional, for file-based docs
  publicUrl?: string; // Optional, for file-based docs
  updatedAt: any;
  updatedBy: string;
  version: number;
}

interface DocumentHistory {
  version: number;
  content?: string; // Text content
  storagePath?: string; // File path (if file-based)
  publicUrl?: string; // File URL (if file-based)
  updatedAt: any;
  updatedBy: string;
  notes?: string;
}

const DOCUMENT_IDS: Record<string, DocumentType> = {
  'Privacy Policy': 'privacy_policy',
  'Terms & Conditions': 'terms_of_service',
  'Contact / Support': 'contact_support',
};

/**
 * Save a new version of a document (text-based)
 */
export async function saveDocument(
  docType: DocumentType,
  content: string,
  updatedBy: string,
  notes?: string
): Promise<void> {
  const docId = docType;

  // Get current document to increment version
  const docRef = doc(firestore, 'admin_documents', docId);
  const docSnap = await getDoc(docRef);
  const currentVersion = docSnap.exists() ? (docSnap.data().version || 0) : 0;

  // Update document metadata
  const metadata: DocumentMetadata = {
    title: getDocumentTitle(docType),
    content,
    contentType: 'text',
    updatedAt: serverTimestamp(),
    updatedBy,
    version: currentVersion + 1,
  };

  await setDoc(docRef, metadata);

  // Add to history
  const historyRef = collection(firestore, 'admin_documents', docId, 'history');
  const historyEntry: any = {
    version: currentVersion + 1,
    content,
    updatedAt: serverTimestamp(),
    updatedBy,
  };
  
  // Only include notes if it has a value (Firestore doesn't allow undefined)
  if (notes && notes.trim()) {
    historyEntry.notes = notes;
  }
  
  await addDoc(historyRef, historyEntry);

  // Log audit event
  await logAuditEvent({
    action: 'document_updated',
    documentType: docType,
    version: currentVersion + 1,
    performedBy: updatedBy,
  });
}

/**
 * Upload a new version of a document (file-based - kept for backwards compatibility)
 */
export async function uploadDocument(
  docType: DocumentType,
  file: File,
  updatedBy: string,
  notes?: string
): Promise<void> {
  const docId = docType;
  const timestamp = Date.now();
  const fileExt = file.name.split('.').pop();
  const storagePath = `admin_documents/${docId}/${timestamp}.${fileExt}`;
  const storageRef = ref(storage, storagePath);

  // Upload file to Storage
  await uploadBytes(storageRef, file);
  const publicUrl = await getDownloadURL(storageRef);

  // Get current document to increment version
  const docRef = doc(firestore, 'admin_documents', docId);
  const docSnap = await getDoc(docRef);
  const currentVersion = docSnap.exists() ? (docSnap.data().version || 0) : 0;

  // Update document metadata
  const metadata: DocumentMetadata = {
    title: getDocumentTitle(docType),
    content: '', // Empty for file-based
    contentType: 'file',
    storagePath,
    publicUrl,
    updatedAt: serverTimestamp(),
    updatedBy,
    version: currentVersion + 1,
  };

  await setDoc(docRef, metadata);

  // Add to history
  const historyRef = collection(firestore, 'admin_documents', docId, 'history');
  const historyEntry: any = {
    version: currentVersion + 1,
    storagePath,
    publicUrl,
    updatedAt: serverTimestamp(),
    updatedBy,
  };
  
  // Only include notes if it has a value (Firestore doesn't allow undefined)
  if (notes && notes.trim()) {
    historyEntry.notes = notes;
  }
  
  await addDoc(historyRef, historyEntry);

  // Log audit event
  await logAuditEvent({
    action: 'document_uploaded',
    documentType: docType,
    version: currentVersion + 1,
    performedBy: updatedBy,
  });
}

/**
 * Get current document metadata
 */
export async function getDocument(docType: DocumentType): Promise<DocumentMetadata | null> {
  const docRef = doc(firestore, 'admin_documents', docType);
  const docSnap = await getDoc(docRef);
  
  if (!docSnap.exists()) {
    return null;
  }

  const data = docSnap.data();
  return {
    ...data,
    updatedAt: data.updatedAt?.toDate(),
  } as DocumentMetadata;
}

/**
 * Get document history
 */
export async function getDocumentHistory(
  docType: DocumentType,
  limitCount: number = 10
): Promise<DocumentHistory[]> {
  const historyRef = collection(firestore, 'admin_documents', docType, 'history');
  const q = query(historyRef, orderBy('version', 'desc'), limit(limitCount));
  const snapshot = await getDocs(q);

  return snapshot.docs.map((doc) => ({
    ...doc.data(),
    updatedAt: doc.data().updatedAt?.toDate(),
  })) as DocumentHistory[];
}

function getDocumentTitle(docType: DocumentType): string {
  const titles: Record<DocumentType, string> = {
    privacy_policy: 'Privacy Policy',
    terms_of_service: 'Terms & Conditions',
    contact_support: 'Contact / Support',
  };
  return titles[docType];
}

async function logAuditEvent(event: {
  action: string;
  documentType?: DocumentType;
  version?: number;
  performedBy: string;
}): Promise<void> {
  try {
    await setDoc(doc(firestore, 'audit_logs', `${Date.now()}_${event.performedBy}`), {
      ...event,
      timestamp: serverTimestamp(),
    });
  } catch (error) {
    console.error('Failed to log audit event:', error);
  }
}
