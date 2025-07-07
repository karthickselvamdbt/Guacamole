// TutorPro360 Home Page Branding Fix
// This script specifically targets the home page and replaces all content with TutorPro360 branding

(function() {
    'use strict';
    
    console.log('🎓 Applying TutorPro360 home page branding...');
    
    // Function to completely rebrand the home page
    function rebrandHomePage() {
        // Change page title immediately
        document.title = 'TutorPro360 - Educational Remote Access Platform';
        
        // Remove any existing TutorPro360 elements to avoid duplicates
        const existingElements = document.querySelectorAll('[id^="tutorpro360"]');
        existingElements.forEach(el => el.remove());
        
        // Create TutorPro360 header
        const header = document.createElement('div');
        header.id = 'tutorpro360-main-header';
        header.innerHTML = `
            <div style="
                position: fixed;
                top: 0;
                left: 0;
                right: 0;
                height: 80px;
                background: linear-gradient(135deg, #2143AF 0%, #00BCD4 100%);
                z-index: 9999;
                display: flex;
                align-items: center;
                padding: 0 30px;
                box-shadow: 0 4px 20px rgba(0,0,0,0.15);
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            ">
                <div style="display: flex; align-items: center; gap: 20px;">
                    <div style="
                        width: 60px;
                        height: 60px;
                        background: #00BCD4;
                        border-radius: 50%;
                        display: flex;
                        align-items: center;
                        justify-content: center;
                        font-weight: bold;
                        color: white;
                        font-size: 18px;
                        box-shadow: 0 4px 15px rgba(0,0,0,0.2);
                    ">360</div>
                    <div>
                        <h1 style="
                            margin: 0;
                            color: white;
                            font-size: 32px;
                            font-weight: bold;
                            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
                        ">TutorPro360</h1>
                        <p style="
                            margin: 0;
                            color: rgba(255,255,255,0.9);
                            font-size: 16px;
                            font-weight: 300;
                        ">Educational Remote Access Platform</p>
                    </div>
                </div>
                <div style="margin-left: auto; color: white; font-size: 14px;">
                    🎓 Secure • Reliable • Educational
                </div>
            </div>
        `;
        
        // Insert header at the beginning of body
        document.body.insertBefore(header, document.body.firstChild);
        
        // Adjust body padding for fixed header
        document.body.style.paddingTop = '100px';
        document.body.style.background = 'linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%)';
        document.body.style.minHeight = '100vh';
        document.body.style.fontFamily = "'Segoe UI', Tahoma, Geneva, Verdana, sans-serif";
        
        // Find and replace the main content area
        const mainContent = document.querySelector('.home-contents, .main-content, .content, main, #content') || 
                           document.querySelector('div[class*="home"]') ||
                           document.body;
        
        // Create TutorPro360 home page content
        const homePageContent = document.createElement('div');
        homePageContent.id = 'tutorpro360-home-content';
        homePageContent.innerHTML = `
            <div style="
                max-width: 1200px;
                margin: 0 auto;
                padding: 40px 20px;
            ">
                <!-- Welcome Section -->
                <div style="
                    background: white;
                    border-radius: 20px;
                    padding: 50px;
                    margin-bottom: 40px;
                    box-shadow: 0 10px 30px rgba(0,0,0,0.1);
                    text-align: center;
                    border-top: 5px solid #2143AF;
                ">
                    <h2 style="
                        color: #2143AF;
                        font-size: 36px;
                        margin-bottom: 20px;
                        font-weight: 700;
                    ">Welcome to TutorPro360</h2>
                    <p style="
                        color: #666;
                        font-size: 20px;
                        line-height: 1.6;
                        margin-bottom: 30px;
                        max-width: 800px;
                        margin-left: auto;
                        margin-right: auto;
                    ">Your comprehensive educational remote access platform. Connect securely to virtual labs, educational software, and remote desktops from anywhere in the world.</p>
                    
                    <div style="
                        display: grid;
                        grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
                        gap: 30px;
                        margin-top: 40px;
                    ">
                        <div style="
                            background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
                            padding: 30px;
                            border-radius: 15px;
                            border-left: 5px solid #2143AF;
                            text-align: center;
                        ">
                            <div style="font-size: 48px; margin-bottom: 15px;">🎓</div>
                            <h3 style="color: #2143AF; margin-bottom: 10px;">For Students</h3>
                            <p style="color: #666; font-size: 14px;">Access virtual labs, educational software, and learning environments securely from any device.</p>
                        </div>
                        
                        <div style="
                            background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
                            padding: 30px;
                            border-radius: 15px;
                            border-left: 5px solid #00BCD4;
                            text-align: center;
                        ">
                            <div style="font-size: 48px; margin-bottom: 15px;">👨‍🏫</div>
                            <h3 style="color: #00BCD4; margin-bottom: 10px;">For Educators</h3>
                            <p style="color: #666; font-size: 14px;">Manage student access, monitor usage, and provide seamless educational technology experiences.</p>
                        </div>
                        
                        <div style="
                            background: linear-gradient(135deg, #f8f9fa 0%, #e9ecef 100%);
                            padding: 30px;
                            border-radius: 15px;
                            border-left: 5px solid #FF6B35;
                            text-align: center;
                        ">
                            <div style="font-size: 48px; margin-bottom: 15px;">🔒</div>
                            <h3 style="color: #FF6B35; margin-bottom: 10px;">Secure & Reliable</h3>
                            <p style="color: #666; font-size: 14px;">Enterprise-grade security with encrypted connections and comprehensive access controls.</p>
                        </div>
                    </div>
                </div>
                
                <!-- Quick Access Section -->
                <div style="
                    background: white;
                    border-radius: 20px;
                    padding: 40px;
                    margin-bottom: 40px;
                    box-shadow: 0 10px 30px rgba(0,0,0,0.1);
                    border-top: 5px solid #00BCD4;
                ">
                    <h3 style="
                        color: #2143AF;
                        font-size: 28px;
                        margin-bottom: 30px;
                        text-align: center;
                    ">Quick Access</h3>
                    
                    <div style="
                        display: grid;
                        grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
                        gap: 20px;
                    ">
                        <button onclick="window.location.href='#/connections'" style="
                            background: linear-gradient(135deg, #2143AF 0%, #00BCD4 100%);
                            color: white;
                            border: none;
                            padding: 20px;
                            border-radius: 10px;
                            font-size: 16px;
                            font-weight: 600;
                            cursor: pointer;
                            transition: all 0.3s ease;
                            box-shadow: 0 4px 15px rgba(33, 67, 175, 0.3);
                        " onmouseover="this.style.transform='translateY(-2px)'; this.style.boxShadow='0 8px 25px rgba(33, 67, 175, 0.4)'" onmouseout="this.style.transform='translateY(0)'; this.style.boxShadow='0 4px 15px rgba(33, 67, 175, 0.3)'">
                            🖥️ My Connections
                        </button>
                        
                        <button onclick="window.location.href='#/settings'" style="
                            background: linear-gradient(135deg, #00BCD4 0%, #2143AF 100%);
                            color: white;
                            border: none;
                            padding: 20px;
                            border-radius: 10px;
                            font-size: 16px;
                            font-weight: 600;
                            cursor: pointer;
                            transition: all 0.3s ease;
                            box-shadow: 0 4px 15px rgba(0, 188, 212, 0.3);
                        " onmouseover="this.style.transform='translateY(-2px)'; this.style.boxShadow='0 8px 25px rgba(0, 188, 212, 0.4)'" onmouseout="this.style.transform='translateY(0)'; this.style.boxShadow='0 4px 15px rgba(0, 188, 212, 0.3)'">
                            ⚙️ Settings
                        </button>
                        
                        <button onclick="window.location.href='#/users'" style="
                            background: linear-gradient(135deg, #FF6B35 0%, #F7931E 100%);
                            color: white;
                            border: none;
                            padding: 20px;
                            border-radius: 10px;
                            font-size: 16px;
                            font-weight: 600;
                            cursor: pointer;
                            transition: all 0.3s ease;
                            box-shadow: 0 4px 15px rgba(255, 107, 53, 0.3);
                        " onmouseover="this.style.transform='translateY(-2px)'; this.style.boxShadow='0 8px 25px rgba(255, 107, 53, 0.4)'" onmouseout="this.style.transform='translateY(0)'; this.style.boxShadow='0 4px 15px rgba(255, 107, 53, 0.3)'">
                            👥 User Management
                        </button>
                    </div>
                </div>
                
                <!-- Footer -->
                <div style="
                    text-align: center;
                    padding: 30px;
                    color: #666;
                    font-size: 14px;
                ">
                    <p style="margin: 0;">© 2025 TutorPro360 Educational Platform. All rights reserved.</p>
                    <p style="margin: 10px 0 0 0;">Secure • Reliable • Educational • Professional</p>
                </div>
            </div>
        `;
        
        // Replace the main content
        if (mainContent && mainContent !== document.body) {
            mainContent.innerHTML = '';
            mainContent.appendChild(homePageContent);
        } else {
            // If we can't find a specific content area, append to body
            document.body.appendChild(homePageContent);
        }
        
        // Hide any elements that might contain the old ID
        const elementsToHide = document.querySelectorAll('*');
        elementsToHide.forEach(el => {
            if (el.textContent && el.textContent.includes('12783445-18a7-4ad0-b58d-ee0172d01619')) {
                el.style.display = 'none';
            }
        });
    }
    
    // Function to replace any remaining text
    function replaceAllText() {
        const walker = document.createTreeWalker(
            document.body,
            NodeFilter.SHOW_TEXT,
            null,
            false
        );
        
        let node;
        while (node = walker.nextNode()) {
            let text = node.textContent;
            
            // Replace the specific ID
            if (text.includes('12783445-18a7-4ad0-b58d-ee0172d01619')) {
                text = text.replace(/12783445-18a7-4ad0-b58d-ee0172d01619/g, 'TutorPro360');
            }
            
            // Replace Guacamole references
            if (text.includes('Guacamole')) {
                text = text.replace(/Apache Guacamole/gi, 'TutorPro360');
                text = text.replace(/Guacamole/gi, 'TutorPro360');
            }
            
            // Replace other generic terms
            text = text.replace(/Remote Desktop Gateway/gi, 'Educational Remote Access');
            text = text.replace(/clientless remote desktop/gi, 'educational remote access');
            
            if (text !== node.textContent) {
                node.textContent = text;
            }
        }
    }
    
    // Apply branding immediately
    function applyBranding() {
        rebrandHomePage();
        replaceAllText();
        console.log('✅ TutorPro360 home page branding applied successfully!');
    }
    
    // Run immediately if DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', applyBranding);
    } else {
        applyBranding();
    }
    
    // Monitor for changes and reapply branding
    const observer = new MutationObserver(function(mutations) {
        let shouldUpdate = false;
        
        mutations.forEach(function(mutation) {
            mutation.addedNodes.forEach(function(node) {
                if (node.nodeType === Node.ELEMENT_NODE) {
                    // Check if the problematic ID appears
                    if (node.textContent && node.textContent.includes('12783445-18a7-4ad0-b58d-ee0172d01619')) {
                        shouldUpdate = true;
                    }
                    // Check if Guacamole text appears
                    if (node.textContent && node.textContent.includes('Guacamole')) {
                        shouldUpdate = true;
                    }
                }
            });
        });
        
        if (shouldUpdate) {
            setTimeout(() => {
                replaceAllText();
                // Ensure header is still present
                if (!document.getElementById('tutorpro360-main-header')) {
                    rebrandHomePage();
                }
            }, 100);
        }
    });
    
    observer.observe(document.body, {
        childList: true,
        subtree: true,
        characterData: true
    });
    
    // Reapply branding every 3 seconds to catch any dynamic content
    setInterval(function() {
        replaceAllText();
        if (!document.getElementById('tutorpro360-main-header')) {
            rebrandHomePage();
        }
    }, 3000);
    
})();
