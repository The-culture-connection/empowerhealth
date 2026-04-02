/**
 * Simple Markdown Renderer
 * Converts markdown text to formatted HTML
 */

interface MarkdownRendererProps {
  content: string;
}

export function MarkdownRenderer({ content }: MarkdownRendererProps) {
  // Simple markdown to HTML converter
  function markdownToHtml(markdown: string): string {
    if (!markdown || !markdown.trim()) {
      return '<p></p>';
    }

    let html = markdown;

    // Escape HTML to prevent XSS
    const escapeHtml = (text: string) => {
      const div = document.createElement('div');
      div.textContent = text;
      return div.innerHTML;
    };

    // Process line by line for better control
    const lines = html.split('\n');
    const processedLines: string[] = [];
    let inList = false;
    let listType: 'ul' | 'ol' | null = null;

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim();
      
      // Headers
      if (line.startsWith('### ')) {
        if (inList) {
          processedLines.push(`</${listType}>`);
          inList = false;
          listType = null;
        }
        processedLines.push(`<h3>${escapeHtml(line.substring(4))}</h3>`);
        continue;
      }
      if (line.startsWith('## ')) {
        if (inList) {
          processedLines.push(`</${listType}>`);
          inList = false;
          listType = null;
        }
        processedLines.push(`<h2>${escapeHtml(line.substring(3))}</h2>`);
        continue;
      }
      if (line.startsWith('# ')) {
        if (inList) {
          processedLines.push(`</${listType}>`);
          inList = false;
          listType = null;
        }
        processedLines.push(`<h1>${escapeHtml(line.substring(2))}</h1>`);
        continue;
      }

      // Unordered list
      if (line.match(/^[-*] /)) {
        if (!inList || listType !== 'ul') {
          if (inList) {
            processedLines.push(`</${listType}>`);
          }
          processedLines.push('<ul>');
          inList = true;
          listType = 'ul';
        }
        const listContent = escapeHtml(line.substring(2));
        processedLines.push(`<li>${processInlineMarkdown(listContent)}</li>`);
        continue;
      }

      // Ordered list
      const orderedMatch = line.match(/^(\d+)\. /);
      if (orderedMatch) {
        if (!inList || listType !== 'ol') {
          if (inList) {
            processedLines.push(`</${listType}>`);
          }
          processedLines.push('<ol>');
          inList = true;
          listType = 'ol';
        }
        const listContent = escapeHtml(line.substring(orderedMatch[0].length));
        processedLines.push(`<li>${processInlineMarkdown(listContent)}</li>`);
        continue;
      }

      // Empty line - close list if open
      if (line === '') {
        if (inList) {
          processedLines.push(`</${listType}>`);
          inList = false;
          listType = null;
        }
        processedLines.push('<br>');
        continue;
      }

      // Regular paragraph
      if (inList) {
        processedLines.push(`</${listType}>`);
        inList = false;
        listType = null;
      }
      processedLines.push(`<p>${processInlineMarkdown(escapeHtml(line))}</p>`);
    }

    // Close any open list
    if (inList) {
      processedLines.push(`</${listType}>`);
    }

    return processedLines.join('\n');
  }

  // Process inline markdown (bold, italic, links)
  function processInlineMarkdown(text: string): string {
    // Links (must come before bold/italic to avoid conflicts)
    text = text.replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2" target="_blank" rel="noopener noreferrer" style="color: var(--lavender-600); text-decoration: underline;">$1</a>');
    
    // Bold
    text = text.replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>');
    text = text.replace(/__([^_]+)__/g, '<strong>$1</strong>');
    
    // Italic
    text = text.replace(/\*([^*]+)\*/g, '<em>$1</em>');
    text = text.replace(/_([^_]+)_/g, '<em>$1</em>');
    
    return text;
  }

  const htmlContent = markdownToHtml(content);

  return (
    <div
      className="prose max-w-none"
      style={{
        color: 'var(--warm-600)',
        lineHeight: '1.8',
      }}
    >
      <style>{`
        .prose h1 {
          font-size: 2em;
          font-weight: bold;
          margin-top: 1em;
          margin-bottom: 0.5em;
          color: var(--warm-700);
        }
        .prose h2 {
          font-size: 1.5em;
          font-weight: bold;
          margin-top: 0.8em;
          margin-bottom: 0.4em;
          color: var(--warm-700);
        }
        .prose h3 {
          font-size: 1.25em;
          font-weight: bold;
          margin-top: 0.6em;
          margin-bottom: 0.3em;
          color: var(--warm-700);
        }
        .prose p {
          margin-bottom: 1em;
        }
        .prose ul, .prose ol {
          margin-left: 1.5em;
          margin-bottom: 1em;
        }
        .prose li {
          margin-bottom: 0.5em;
        }
        .prose a {
          color: var(--lavender-600);
          text-decoration: underline;
        }
        .prose a:hover {
          color: var(--lavender-700);
        }
        .prose strong {
          font-weight: 600;
        }
        .prose em {
          font-style: italic;
        }
      `}</style>
      <div dangerouslySetInnerHTML={{ __html: htmlContent }} />
    </div>
  );
}
