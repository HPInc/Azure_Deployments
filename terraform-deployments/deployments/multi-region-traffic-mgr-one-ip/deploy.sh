#!/bin/bash

# set env vars
export ARM_SUBSCRIPTION_ID=$(az account show --query id --output tsv)
export ARM_TENANT_ID=$(az account show --query homeTenantId --output tsv)

# print output
printf "Setting user subscription and tenant IDs...\n\n"

# echo check
echo "Subscription ID:" $ARM_SUBSCRIPTION_ID
echo "Tenant ID:" $ARM_TENANT_ID
printf "\n"

# create service principal and assign roles
printf "Creating Service Principal and assigning roles...\n"

SPName="multi-region-traffic-mgr-one-ip"

SubscriptionID=$(az account show --query id --output tsv)

(az ad sp create-for-rbac --name $SPName --role "9980e02c-c2be-4d73-94e8-173b1dc7cf3c" --scopes /subscriptions/$SubscriptionID)

# storing application ID and tenant ID
appID=$(az ad sp list --display-name $SPName --query [0].appId -o tsv)
tenantID=$(az ad sp list --display-name $SPName --query [0].tenant -o tsv)

# assign reader and contributor roles
az role assignment create --assignee $appID \
--role "Reader" \
--subscription $SubscriptionID

az role assignment create --assignee $appID \
--role "Contributor" \
--subscription $SubscriptionID

# run bash script via following command
# . deploy.sh
echo $SPName "setup complete:"
echo "  store output into terraform.tfvars file by copying values over"
echo "  application_id value = appId"
echo "  aad_client_secret value = password"
echo "  complete remaining tfvars configurations and run terraform init followed by terraform apply -auto-approve" 