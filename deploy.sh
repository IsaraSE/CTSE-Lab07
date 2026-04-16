#!/bin/bash

# Azure Microservices Deployment Lab - Automation Script
# SLIIT - Current Trends in Software Engineering

# Configuration - EDIT THESE IF NEEDED
RG_NAME="microservices-rg"
LOCATION="eastus"
ACR_NAME="sliitmicroregistry$(date +%s | cut -c 6-10)" # Appending random suffix for uniqueness
IMAGE_NAME="gateway:v1"
APP_NAME="gateway"
ENV_NAME="micro-env"
FRONTEND_NAME="sliit-frontend-app"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Azure Microservices Deployment Automation ===${NC}"

# Check for Azure CLI
if ! command -v az &> /dev/null; then
    echo -e "${RED}Error: Azure CLI (az) not found.${NC}"
    echo "Please install it using: brew install azure-cli"
    exit 1
fi

# 1. Login & Subscription Verification
echo -e "${YELLOW}Step 1: Checking Authentication and Subscriptions...${NC}"
az account show --output none 2>/dev/null
if [ $? -ne 0 ]; then
    echo -e "${RED}Not logged in. Running 'az login'...${NC}"
    az login
fi

# Check for active subscriptions
SUBSCRIPTION_COUNT=$(az account list --query "length([])" -o tsv)
if [ "$SUBSCRIPTION_COUNT" -eq 0 ] || [ -z "$SUBSCRIPTION_COUNT" ]; then
    echo -e "${RED}Error: No active Azure subscriptions found for this account.${NC}"
    echo -e "Please ensure you have activated 'Azure for Students' or have a valid billing account."
    echo -e "Visit: https://azure.microsoft.com/free/students/ to activate."
    exit 1
fi
echo -e "${GREEN}Authenticated with active subscription.${NC}"

# 2. Infrastructure Provisioning
echo -e "${YELLOW}Step 2: Creating Resource Group and ACR...${NC}"
az group create --name $RG_NAME --location $LOCATION --output table

echo "Creating ACR: $ACR_NAME (Basic SKU)..."
az acr create --resource-group $RG_NAME --name $ACR_NAME --sku Basic --output table

echo "Logging into ACR..."
az acr login --name $ACR_NAME

ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --query loginServer --output tsv)
FULL_IMAGE_NAME="$ACR_LOGIN_SERVER/$IMAGE_NAME"

# 3. Build and Push
echo -e "${YELLOW}Step 3: Building and Pushing Docker Image...${NC}"
echo "Building image: $FULL_IMAGE_NAME"
docker build -t $FULL_IMAGE_NAME ./gateway

echo "Pushing image to ACR..."
docker push $FULL_IMAGE_NAME

# 4. Container App Deployment
echo -e "${YELLOW}Step 4: Deploying Container App...${NC}"
echo "Registering Providers (this may take a minute)..."
az provider register --namespace Microsoft.App --wait
az provider register --namespace Microsoft.OperationalInsights --wait

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
echo -e "${GREEN}Gateway deployed at: https://$GATEWAY_URL${NC}"

# 5. Summary Info
echo -e "${BLUE}=== Deployment Summary ===${NC}"
echo -e "Resource Group:  $RG_NAME"
echo -e "ACR Name:        $ACR_NAME"
echo -e "Image Path:      $FULL_IMAGE_NAME"
echo -e "Gateway URL:     https://$GATEWAY_URL"
echo -e ""
echo -e "${YELLOW}Next Steps:${NC}"
echo -e "1. Create a GitHub repo for the /frontend folder."
echo -e "2. Push the code to GitHub."
echo -e "3. Run Task 5.2 in the lab to create the Static Web App."
echo -e "4. Use 'az group delete --name $RG_NAME' when finished to avoid costs."
