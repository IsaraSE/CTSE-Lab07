#!/bin/bash

# Azure Microservices Deployment Lab - Automation Script (v5 - Provider Registration)
# SLIIT - Current Trends in Software Engineering

# Exit immediately if a command exits with a non-zero status
set -e

# Configuration
RG_NAME="microservices-rg"
LOCATION="centralindia" 
ACR_NAME="sliitmicroregistry$(date +%s | cut -c 6-10)" 
IMAGE_NAME="gateway:v1"
APP_NAME="gateway"
ENV_NAME="micro-env"
FRONTEND_NAME="sliit-frontend-app"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== Azure Microservices Deployment Automation (v5) ===${NC}"

# Check for Azure CLI
if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI not found.${NC}"
    exit 1
fi

# 1. Login & Subscription Verification
echo -e "${YELLOW}Step 1: Checking Authentication and Subscriptions...${NC}"
az account show --output none 2>/dev/null || (echo -e "${RED}Not logged in. Running 'az login'...${NC}" && az login)

SUBSCRIPTION_COUNT=$(az account list --query "length([])" -o tsv)
if [ "$SUBSCRIPTION_COUNT" -eq 0 ] || [ -z "$SUBSCRIPTION_COUNT" ]; then
    echo -e "${RED}Error: No active subscriptions found.${NC}"
    exit 1
fi
echo -e "${GREEN}Authenticated with active subscription.${NC}"

# 2. Provider Registration (CRITICAL FIX)
echo -e "${YELLOW}Step 2: Registering Required Azure Providers...${NC}"
echo "Registering Container Registry provider..."
az provider register --namespace Microsoft.ContainerRegistry --wait

echo "Registering Container Apps and Logs providers..."
az provider register --namespace Microsoft.App --wait
az provider register --namespace Microsoft.OperationalInsights --wait || true

# 3. Infrastructure Provisioning
echo -e "${YELLOW}Step 3: Creating Resource Group and ACR in $LOCATION...${NC}"
az group create --name $RG_NAME --location $LOCATION --output table

echo "Creating ACR: $ACR_NAME (Basic SKU)..."
az acr create --resource-group $RG_NAME --name $ACR_NAME --sku Basic --output table

echo "Logging into ACR..."
az acr login --name $ACR_NAME

ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --query loginServer --output tsv)
FULL_IMAGE_NAME="$ACR_LOGIN_SERVER/$IMAGE_NAME"

# 4. Build and Push
echo -e "${YELLOW}Step 4: Building and Pushing Docker Image...${NC}"
echo "Building image: $FULL_IMAGE_NAME"
# Using --platform linux/amd64 for cross-platform compatibility
docker build --platform linux/amd64 -t $FULL_IMAGE_NAME ./gateway/

echo "Pushing image to ACR..."
docker push $FULL_IMAGE_NAME

# 5. Container App Deployment
echo -e "${YELLOW}Step 5: Deploying Container App environment...${NC}"
echo "Creating Environment: $ENV_NAME..."
az containerapp env create \
    --name $ENV_NAME \
    --resource-group $RG_NAME \
    --location $LOCATION --output table

echo "Enabling ACR Admin Credentials..."
az acr update -n $ACR_NAME --admin-enabled true
ACR_PASS=$(az acr credential show --name $ACR_NAME --query "passwords[0].value" -o tsv)

echo "Deploying Gateway Container App..."
az containerapp create \
    --name $APP_NAME \
    --resource-group $RG_NAME \
    --environment $ENV_NAME \
    --image $FULL_IMAGE_NAME \
    --target-port 3000 \
    --ingress external \
    --registry-server $ACR_LOGIN_SERVER \
    --registry-username $ACR_NAME \
    --registry-password $ACR_PASS \
    --output table

GATEWAY_URL=$(az containerapp show --name $APP_NAME --resource-group $RG_NAME --query properties.configuration.ingress.fqdn --output tsv)
echo -e "${GREEN}Gateway successfully deployed at: https://$GATEWAY_URL${NC}"

# 6. Summary Info
echo -e "${BLUE}=== Deployment Summary ===${NC}"
echo -e "Resource Group:  $RG_NAME"
echo -e "Region:          $LOCATION"
echo -e "Gateway URL:     https://$GATEWAY_URL"
echo -e ""
echo -e "${YELLOW}Next Step: Run the Static Web App command with GitHub Login.${NC}"
