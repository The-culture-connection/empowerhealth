// ============================================================================
// HIPAA COMPLIANCE UTILITIES
// ============================================================================

// PHI Redaction Utility - Remove PII/PHI before sending to AI
function redactPHI(text) {
  if (!text || typeof text !== 'string') return text;
  
  let redacted = text;
  
  // Redact email addresses
  redacted = redacted.replace(/\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b/g, '[EMAIL_REDACTED]');
  
  // Redact phone numbers (various formats)
  redacted = redacted.replace(/\b\d{3}[-.]?\d{3}[-.]?\d{4}\b/g, '[PHONE_REDACTED]');
  redacted = redacted.replace(/\b\(\d{3}\)\s?\d{3}[-.]?\d{4}\b/g, '[PHONE_REDACTED]');
  
  // Redact SSN patterns
  redacted = redacted.replace(/\b\d{3}-\d{2}-\d{4}\b/g, '[SSN_REDACTED]');
  
  // Redact MRN/Medical Record Numbers (common patterns)
  redacted = redacted.replace(/\bMRN[:\s]?\d{6,}\b/gi, '[MRN_REDACTED]');
  redacted = redacted.replace(/\bMedical Record[:\s]?\d{6,}\b/gi, '[MRN_REDACTED]');
  
  // Redact addresses (basic pattern - street numbers and common street terms)
  redacted = redacted.replace(/\b\d+\s+[A-Za-z\s]+(?:Street|St|Avenue|Ave|Road|Rd|Drive|Dr|Lane|Ln|Boulevard|Blvd|Court|Ct|Way|Circle|Cir)\b/gi, '[ADDRESS_REDACTED]');
  
  // Redact ZIP codes (5 or 9 digit)
  redacted = redacted.replace(/\b\d{5}(?:-\d{4})?\b/g, '[ZIP_REDACTED]');
  
  return redacted;
}

// Safe Logger - Strip PHI from logs
function safeLog(level, message, data = {}) {
  // Create a sanitized copy of data
  const sanitized = JSON.parse(JSON.stringify(data));
  
  // Remove common PHI fields
  const phiFields = ['visitText', 'pdfText', 'content', 'notes', 'summary', 'originalText', 'email', 'phone', 'address', 'ssn', 'mrn'];
  phiFields.forEach(field => {
    if (sanitized[field]) {
      sanitized[field] = '[REDACTED]';
    }
  });
  
  // Log with sanitized data
  const logMessage = `[${level.toUpperCase()}] ${message}`;
  if (level === 'error') {
    console.error(logMessage, sanitized);
  } else if (level === 'warn') {
    console.warn(logMessage, sanitized);
  } else {
    console.log(logMessage, sanitized);
  }
}

module.exports = { redactPHI, safeLog };
