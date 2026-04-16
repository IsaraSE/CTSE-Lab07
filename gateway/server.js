const express = require('express');
const cors = require('cors');
const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
    res.status(200).json({ status: 'ok', service: 'gateway', timestamp: new Date().toISOString() });
});

// Demo API endpoint
app.get('/api/message', (req, res) => {
    res.json({ message: 'Hello from the Azure Microservices Gateway!', status: 'Running on Azure Container Apps' });
});

// Root endpoint
app.get('/', (req, res) => {
    res.send('<h1>Azure Microservices Gateway</h1><p>The gateway is operational. Use /health or /api/message for API responses.</p>');
});

app.listen(PORT, () => {
    console.log(`Gateway service listening on port ${PORT}`);
});
