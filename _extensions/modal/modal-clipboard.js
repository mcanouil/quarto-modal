/**
# MIT License
#
# Copyright (c) 2026 Mickaël Canouil
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
*/

// npx uglify-js _extensions/modal/modal-clipboard.js -o _extensions/modal/modal-clipboard.min.js --compress --mangle

// General clipboard.js setup for modals
window.document.addEventListener('DOMContentLoaded', (event) => {
  /**
  * Initialise clipboard functionality for any modal
  */
  const initialiseModalClipboard = () => {
    // Find all modals in the document
    const modals = document.querySelectorAll('.modal');
    
    modals.forEach((modal) => {
      const modalId = modal.getAttribute('id');
      if (!modalId) return;
      
      // Find code copy buttons within this modal
      const copyButtons = modal.querySelectorAll('.code-copy-button');
      if (copyButtons.length === 0) return;
      
      // Add data-in-quarto-modal attribute to buttons in this modal
      copyButtons.forEach((button) => {
        button.setAttribute('data-in-quarto-modal', modalId);
      });
      
      console.log(`Initialising clipboard for modal: ${modalId}`);
      
      // Create clipboard instance for this modal
      const clipboardModal = new window.ClipboardJS(
        `.code-copy-button[data-in-quarto-modal="${modalId}"]`, 
        {
          text: (trigger) => {
            // Get text from the code element, excluding annotations
            const codeEl = trigger.previousElementSibling.cloneNode(true);
            const annotations = codeEl.querySelectorAll('[class*="code-annotation-"]');
            annotations.forEach((annotation) => annotation.remove());
            return codeEl.innerText;
          },
          container: modal // Set the modal as container for clipboard operations
        }
      );
      
      // Success handler with visual feedback
      clipboardModal.on('success', (e) => {
        const button = e.trigger;
        button.blur();
        
        // Visual feedback
        button.classList.add('code-copy-button-checked');
        const currentTitle = button.getAttribute('title');
        button.setAttribute('title', 'Copied!');
        
        // Bootstrap tooltip feedback
        let tooltip;
        if (window.bootstrap) {
          button.setAttribute('data-bs-toggle', 'tooltip');
          button.setAttribute('data-bs-placement', 'left');
          button.setAttribute('data-bs-title', 'Copied!');
          tooltip = new bootstrap.Tooltip(button, { 
            trigger: 'manual', 
            customClass: 'code-copy-button-tooltip',
            offset: [0, -8]
          });
          tooltip.show();    
        }
        
        // Reset after 1 second
        setTimeout(() => {
          if (tooltip) {
            tooltip.hide();
            button.removeAttribute('data-bs-title');
            button.removeAttribute('data-bs-toggle');
            button.removeAttribute('data-bs-placement');
          }
          button.setAttribute('title', currentTitle);
          button.classList.remove('code-copy-button-checked');
        }, 1000);
        
        e.clearSelection();
        console.log(`Copied from modal ${modalId}:`, e.text);
      });
      
      // Error handler
      clipboardModal.on('error', (e) => {
        console.error(`Clipboard error in modal ${modalId}:`, e);
        const button = e.trigger;
        button.setAttribute('title', 'Press Ctrl+C to copy');
        
        // Visual feedback for error
        button.style.backgroundColor = '#f8d7da';
        setTimeout(() => {
          button.style.backgroundColor = '';
          button.setAttribute('title', 'Copy to Clipboard');
        }, 2000);
      });
    });
  };
  
  // Initialise clipboard for modals
  initialiseModalClipboard();
  
  // Also initialise when modals are shown (in case of dynamic content)
  document.addEventListener('shown.bs.modal', () => {
    initialiseModalClipboard();
  });
});
