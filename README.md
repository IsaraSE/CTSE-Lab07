# Azure Microservices Deployment Lab

This project demonstrates a containerized microservices architecture deployed on Microsoft Azure. It was built as part of the SLIIT **Current Trends in Software Engineering (SE4010)** module.

## Architecture

- **Gateway Service:** A Node.js Express server acting as the API gateway, containerized and deployed on **Azure Container Apps**.
- **Frontend App:** A premium, responsive web interface hosted on **Azure Static Web Apps**.
- **Container Registry:** Private Docker images managed via **Azure Container Registry (ACR)**.

## Project Structure

```text
├── gateway/          # API Gateway microservice (Node.js)
│   ├── Dockerfile    # Container definition
│   └── server.js     # Express server logic
├── frontend/         # Static frontend assets
│   ├── index.html    # Core UI
│   ├── styles.css    # Premium Glassmorphism styling
│   └── script.js     # Frontend logic & API interaction
├── deploy.sh         # Integrated Azure deployment script
└── README.md         # Project documentation
```

## Getting Started

### Local Development

1. **Gateway:**
   ```bash
   cd gateway
   npm install
   npm start
   ```

2. **Frontend:**
   Simply open `frontend/index.html` in your browser.

### Azure Deployment

1. Ensure you have the **Azure CLI** and **Docker Desktop** installed.
2. Run the deployment script:
   ```bash
   ./deploy.sh
   ```

## Author
SLIIT Student - it22154880
