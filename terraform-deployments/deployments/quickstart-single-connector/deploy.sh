#!/bin/bash

export ARM_SUBSCRIPTION_ID=$(az account show --query id --output tsv)
export ARM_TENANT_ID=$(az account show --query homeTenantId --output tsv)

# print output
printf "Setting user subscription and tenant IDs...\n\n"

echo $ARM_SUBSCRIPTION_ID
echo $ARM_TENANT_ID
