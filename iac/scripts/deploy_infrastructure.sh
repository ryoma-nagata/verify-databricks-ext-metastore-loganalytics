#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
# set -o xtrace # For debugging

###################
# REQUIRED ENV VARIABLES:
#
# PROJECT
# DEPLOYMENT_ID
# ENV_NAME
# AZURE_LOCATION
# AZURE_SUBSCRIPTION_ID

#####################

#####################
# DEPLOY ARM TEMPLATE
sqlpwd=$(echo /dev/urandom | base64 | fold -w 10 | head -n 1)

# Set account to where ARM template will be deployed to
echo "Deploying to Subscription: $AZURE_SUBSCRIPTION_ID"
az account set --subscription "$AZURE_SUBSCRIPTION_ID"

# # Retrieve User Id
signed_in_user_object_id=$(az ad signed-in-user show --output json | jq -r '.objectId')


# Validate arm template
# Management Resources
echo "Validating deployment "
arm_output=$(az deployment sub validate \
    --name $PROJECT \
    --location $AZURE_LOCATION \
    --template-file ./iac/infra/main.bicep \
    --parameters location=$AZURE_LOCATION project=$PROJECT env=$ENV_NAME deployment_id=$DEPLOYMENT_ID signed_in_user_object_id=$signed_in_user_object_id\
    --output json)

# # Deploy arm template
echo "Start deployment"
arm_output=$(az deployment sub create \
    --name $PROJECT \
    --location $AZURE_LOCATION \
    --template-file ./iac/infra/main.bicep \
    --parameters location=$AZURE_LOCATION project=$PROJECT env=$ENV_NAME deployment_id=$DEPLOYMENT_ID signed_in_user_object_id=$signed_in_user_object_id\
    --output json)

echo "Finish deploying resources "


databricks001HostUrl=$(echo "$arm_output" | jq -r '.properties.outputs.databricks001HostUrl.value')
databricks002HostUrl=$(echo "$arm_output" | jq -r '.properties.outputs.databricks002HostUrl.value')
databricksWorkspace001Name=$(echo "$arm_output" | jq -r '.properties.outputs.databricksWorkspace001Name.value')
databricksWorkspace002Name=$(echo "$arm_output" | jq -r '.properties.outputs.databricksWorkspace002Name.value')

databricksWorkspaceSubscriptionId=$(echo "$arm_output" | jq -r '.properties.outputs.databricksWorkspaceSubscriptionId.value')
databricksWorkspaceResourceGroupName=$(echo "$arm_output" | jq -r '.properties.outputs.databricksWorkspaceResourceGroupName.value')

hiveKeyVaultResourceId=$(echo "$arm_output" | jq -r '.properties.outputs.hiveKeyVaultResourceId.value')
hiveKeyVaultDnsName=$(echo "$arm_output" | jq -r '.properties.outputs.hiveKeyVaultDnsName.value')
logKeyVaultResourceId=$(echo "$arm_output" | jq -r '.properties.outputs.logKeyVaultResourceId.value')
logKeyVaultDnsName=$(echo "$arm_output" | jq -r '.properties.outputs.logKeyVaultDnsName.value')


HIVEKEYVAULTRESOURCEID=$hiveKeyVaultResourceId \
HIVEKEYVAULTDNSNAME=$hiveKeyVaultDnsName \
DATABRICKSHOSTURL=$databricks001HostUrl \
DATABRICKSWORKSPACESUBSCRIPTIONID=$databricksWorkspaceSubscriptionId \
DATABRICKSWORKSPACERESOURCEGROUPNAME=$databricksWorkspaceResourceGroupName \
DATABRICKSWORKSPACENAME=$databricksWorkspace001Name \
LOGKEYVAULTRESOURCEID=$logKeyVaultResourceId \
LOGKEYVAULTDNSNAME=$logKeyVaultDnsName \
    bash -c "./iac/scripts/deploy_databricks.sh"


HIVEKEYVAULTRESOURCEID=$hiveKeyVaultResourceId \
HIVEKEYVAULTDNSNAME=$hiveKeyVaultDnsName \
DATABRICKSHOSTURL=$databricks002HostUrl \
DATABRICKSWORKSPACESUBSCRIPTIONID=$databricksWorkspaceSubscriptionId \
DATABRICKSWORKSPACERESOURCEGROUPNAME=$databricksWorkspaceResourceGroupName \
DATABRICKSWORKSPACENAME=$databricksWorkspace002Name \
LOGKEYVAULTRESOURCEID=$logKeyVaultResourceId \
LOGKEYVAULTDNSNAME=$logKeyVaultDnsName \
    bash -c "./iac/scripts/deploy_databricks.sh"

# finish
echo "Completed deploying Azure resources" 