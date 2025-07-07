// TutorPro360 Browser Branding Script
// Copy and paste this script into your browser's developer console (F12)
// Or save as a bookmark with javascript: prefix

(function() {
    'use strict';
    
    console.log('🎓 Applying TutorPro360 branding...');
    
    // Change page title
    document.title = 'TutorPro360 - Educational Remote Access Platform';
    
    // Add TutorPro360 CSS
    const tutorProCSS = `
        /* TutorPro360 Branding Styles */
        
        /* Hide original Guacamole branding */
        .home-logo, .login-logo, .header-logo, .brand, .logo {
            display: none !important;
        }
        
        /* Create TutorPro360 Header */
        #tutorpro360-header {
            position: fixed !important;
            top: 0 !important;
            left: 0 !important;
            right: 0 !important;
            height: 80px !important;
            background: linear-gradient(135deg, #2143AF 0%, #00BCD4 100%) !important;
            z-index: 9999 !important;
            display: flex !important;
            align-items: center !important;
            padding: 0 20px !important;
            box-shadow: 0 2px 10px rgba(0,0,0,0.2) !important;
            font-family: Arial, sans-serif !important;
        }
        
        #tutorpro360-logo {
            display: flex !important;
            align-items: center !important;
            gap: 15px !important;
        }
        
        #tutorpro360-icon {
            width: 50px !important;
            height: 50px !important;
            background: #00BCD4 !important;
            border-radius: 50% !important;
            display: flex !important;
            align-items: center !important;
            justify-content: center !important;
            font-weight: bold !important;
            color: white !important;
            font-size: 14px !important;
        }
        
        #tutorpro360-title {
            margin: 0 !important;
            color: white !important;
            font-size: 28px !important;
            font-weight: bold !important;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3) !important;
        }
        
        #tutorpro360-subtitle {
            margin: 0 !important;
            color: rgba(255,255,255,0.9) !important;
            font-size: 14px !important;
        }
        
        /* Adjust body for header */
        body {
            padding-top: 100px !important;
            background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%) !important;
        }
        
        /* Style login form */
        .login-ui {
            background: transparent !important;
        }
        
        .login-dialog {
            border: 2px solid #2143AF !important;
            border-radius: 10px !important;
            box-shadow: 0 10px 30px rgba(33, 67, 175, 0.3) !important;
            background: white !important;
        }
        
        /* Style buttons */
        .button, .btn, input[type="submit"] {
            background-color: #2143AF !important;
            border-color: #2143AF !important;
            color: white !important;
        }
        
        .button:hover, .btn:hover, input[type="submit"]:hover {
            background-color: #00BCD4 !important;
            border-color: #00BCD4 !important;
        }
        
        /* Style links */
        a {
            color: #2143AF !important;
        }
        
        a:hover {
            color: #00BCD4 !important;
        }
        
        /* Welcome message */
        #tutorpro360-welcome {
            background: white !important;
            margin: 20px auto !important;
            padding: 30px !important;
            border-radius: 10px !important;
            box-shadow: 0 4px 15px rgba(0,0,0,0.1) !important;
            max-width: 800px !important;
            text-align: center !important;
            border-top: 4px solid #2143AF !important;
        }
        
        .tutorpro360-feature {
            background: #f8f9fa !important;
            padding: 15px !important;
            border-radius: 8px !important;
            border-left: 4px solid #00BCD4 !important;
            margin: 10px !important;
            display: inline-block !important;
            width: 200px !important;
            vertical-align: top !important;
        }
    `;
    
    // Add CSS to page
    const styleSheet = document.createElement('style');
    styleSheet.textContent = tutorProCSS;
    document.head.appendChild(styleSheet);
    
    // Create TutorPro360 header
    function createHeader() {
        // Remove existing header if present
        const existingHeader = document.getElementById('tutorpro360-header');
        if (existingHeader) {
            existingHeader.remove();
        }
        
        const header = document.createElement('div');
        header.id = 'tutorpro360-header';
        header.innerHTML = `
            <div id="tutorpro360-logo">
                <div id="tutorpro360-icon">360</div>
                <div>
                    <h1 id="tutorpro360-title">TutorPro360</h1>
                    <p id="tutorpro360-subtitle">Educational Remote Access Platform</p>
                </div>
            </div>
        `;
        
        document.body.insertBefore(header, document.body.firstChild);
    }
    
    // Replace text content
    function replaceText() {
        function replaceInNode(node) {
            if (node.nodeType === Node.TEXT_NODE) {
                let text = node.textContent;
                text = text.replace(/Apache Guacamole/gi, 'TutorPro360');
                text = text.replace(/Guacamole/gi, 'TutorPro360');
                text = text.replace(/Remote Desktop Gateway/gi, 'Educational Remote Access');
                text = text.replace(/clientless remote desktop/gi, 'educational remote access');
                node.textContent = text;
            } else if (node.nodeType === Node.ELEMENT_NODE) {
                // Replace in attributes
                if (node.title) {
                    node.title = node.title.replace(/Guacamole/gi, 'TutorPro360');
                }
                if (node.alt) {
                    node.alt = node.alt.replace(/Guacamole/gi, 'TutorPro360');
                }
                
                // Skip our custom elements
                if (!node.id || !node.id.startsWith('tutorpro360-')) {
                    for (let i = 0; i < node.childNodes.length; i++) {
                        replaceInNode(node.childNodes[i]);
                    }
                }
            }
        }
        
        replaceInNode(document.body);
    }
    
    // Add welcome message
    function addWelcomeMessage() {
        // Only add if not already present
        if (document.getElementById('tutorpro360-welcome')) {
            return;
        }
        
        const welcomeDiv = document.createElement('div');
        welcomeDiv.id = 'tutorpro360-welcome';
        welcomeDiv.innerHTML = `
            <h2 style="color: #2143AF; margin-bottom: 15px; font-size: 24px;">
                Welcome to TutorPro360
            </h2>
            <p style="color: #666; font-size: 16px; line-height: 1.6; margin-bottom: 20px;">
                Your comprehensive educational remote access platform. Connect securely to educational resources, virtual labs, and remote desktops from anywhere.
            </p>
            <div style="display: flex; justify-content: center; gap: 20px; flex-wrap: wrap;">
                <div class="tutorpro360-feature">
                    <strong style="color: #2143AF;">🎓 For Students</strong><br>
                    <span style="color: #666; font-size: 14px;">Access virtual labs and educational software</span>
                </div>
                <div class="tutorpro360-feature">
                    <strong style="color: #2143AF;">👨‍🏫 For Educators</strong><br>
                    <span style="color: #666; font-size: 14px;">Manage and monitor student access</span>
                </div>
                <div class="tutorpro360-feature">
                    <strong style="color: #2143AF;">🔒 Secure</strong><br>
                    <span style="color: #666; font-size: 14px;">Enterprise-grade security and encryption</span>
                </div>
            </div>
        `;
        
        // Find a good place to insert the welcome message
        const mainContent = document.querySelector('.main-content, .content, main, #content') || document.body;
        const firstChild = mainContent.firstElementChild;
        if (firstChild) {
            mainContent.insertBefore(welcomeDiv, firstChild);
        } else {
            mainContent.appendChild(welcomeDiv);
        }
    }
    
    // Initialize branding
    function initializeBranding() {
        createHeader();
        replaceText();
        addWelcomeMessage();
        console.log('✅ TutorPro360 branding applied successfully!');
    }
    
    // Apply branding immediately
    initializeBranding();
    
    // Monitor for changes and reapply branding
    const observer = new MutationObserver(function(mutations) {
        let shouldUpdate = false;
        
        mutations.forEach(function(mutation) {
            mutation.addedNodes.forEach(function(node) {
                if (node.nodeType === Node.ELEMENT_NODE) {
                    shouldUpdate = true;
                }
            });
        });
        
        if (shouldUpdate) {
            setTimeout(() => {
                if (!document.getElementById('tutorpro360-header')) {
                    createHeader();
                }
                replaceText();
            }, 100);
        }
    });
    
    observer.observe(document.body, {
        childList: true,
        subtree: true
    });
    
    // Reapply branding every 5 seconds to handle dynamic content
    setInterval(function() {
        if (!document.getElementById('tutorpro360-header')) {
            createHeader();
        }
        replaceText();
    }, 5000);
    
    console.log('🎓 TutorPro360 branding script loaded! The interface will be continuously branded.');
    
})();
