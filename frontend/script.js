document.addEventListener('DOMContentLoaded', () => {
    const fetchBtn = document.getElementById('fetch-btn');
    const responseBox = document.getElementById('response-box');
    const connectionIndicator = document.getElementById('connection-indicator');
    const statusText = document.getElementById('status-text');
    const timestampSpan = document.getElementById('timestamp');

    // Display current time
    timestampSpan.textContent = new Date().toLocaleDateString(undefined, {
        year: 'numeric', month: 'long', day: 'numeric'
    });

    // Determine API Base URL
    // In local development, it's likely localhost:3000
    // In production (Azure), it will be the Container App URL
    const API_BASE_URL = window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1'
        ? 'http://localhost:3000'
        : ''; // Will be set via REACT_APP_API_URL or relative path if configured

    async function checkHealth() {
        try {
            const controller = new AbortController();
            const timeoutId = setTimeout(() => controller.abort(), 3000);
            
            const response = await fetch(`${API_BASE_URL}/health`, { signal: controller.signal });
            const data = await response.json();
            
            if (data.status === 'ok') {
                connectionIndicator.className = 'indicator online';
                statusText.textContent = 'Gateway Online';
            }
        } catch (error) {
            connectionIndicator.className = 'indicator offline';
            statusText.textContent = 'Gateway Offline';
            console.error('Health check failed:', error);
        }
    }

    async function fetchMessage() {
        responseBox.innerHTML = '<p class="placeholder">Fetching message...</p>';
        try {
            const response = await fetch(`${API_BASE_URL}/api/message`);
            const data = await response.json();
            
            responseBox.innerHTML = `
                <div class="json-response">
                    <pre>${JSON.stringify(data, null, 2)}</pre>
                </div>
            `;
        } catch (error) {
            responseBox.innerHTML = `
                <p class="error-msg" style="color: #ff4d4d">Error: Could not connect to gateway.</p>
                <p style="font-size: 0.7rem; margin-top: 5px">${error.message}</p>
            `;
        }
    }

    fetchBtn.addEventListener('click', fetchMessage);

    // Initial check
    checkHealth();
    // Re-check every 10 seconds
    setInterval(checkHealth, 10000);
});
