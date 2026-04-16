#!/bin/bash

# Azure Microservices Lab - Cleanup Script
# This script deletes the resource group to avoid ongoing Azure costs.

RG_NAME="microservices-rg"

# Colors for output
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Warning: This will permanently delete all resources in '$RG_NAME'.${NC}"
echo -ne "Are you sure you want to proceed? (y/n): "
read confirmation

if [[ "$confirmation" == "y" || "$confirmation" == "Y" ]]; then
    echo "Deleting resource group '$RG_NAME'..."
    az group delete --name $RG_NAME --yes --no-wait
    echo -e "${YELLOW}Delete operation initiated. This may take a few minutes to complete in the background.${NC}"
else
    echo "Cleanup cancelled."
fi
