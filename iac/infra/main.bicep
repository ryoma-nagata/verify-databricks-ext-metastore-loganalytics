targetScope = 'subscription'

param project string ='databricks'
@allowed([
  'demo'
  'verify'
])
param env string = 'verify'
param deployment_id string = '001'
param location string = 'japaneast'

param sqlLogin string = 'sqladmin'
param sqlPassword string = 'P@ssword1234'
param signed_in_user_object_id string 

var uniqueName = '${project}-${deployment_id}-${env}'
var resouceGroupName = 'rg-${uniqueName}'
var databricks001Name = 'adb001-${uniqueName}'
var databricks002Name = 'adb002-${uniqueName}'
var metakeyVaultName = replace(replace(toLower('m-kv-${uniqueName}'), '-', ''), '_', '')
var sqlServerName = 'sql-${uniqueName}'
var sqlDatabaseName = 'metastore'
var logkeyVaultName = replace(replace(toLower('l-kv-${uniqueName}'), '-', ''), '_', '')
var logAnalyticsWorkspaceName = 'log-${uniqueName}'


var SqlServerUsernameSecretName = 'hiveMetastoreConnectionUserName'
var SqlServerPasswordSecretName = 'hiveMetastoreConnectionPassword'
var sqlConnectionStringSecretName = 'hiveMetastoreConnectionURL'

var tags = {
  Environment : env
  Project : project
}

resource verifyDatabricksRG 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name:resouceGroupName
  location:location
  tags:tags
}

module databricks001 'modules/services/databricks.bicep' ={
  name:'databricks001'
  scope:verifyDatabricksRG
  params:{
    databricksName:databricks001Name
    location:verifyDatabricksRG.location
    tags:tags
  }
}


module databricks002 'modules/services/databricks.bicep' ={
  name:'databricks002'
  scope:verifyDatabricksRG
  params:{
    databricksName:databricks002Name
    location:verifyDatabricksRG.location
    tags:tags
  }
}

module metakeyVault 'modules/services/keyvault.bicep' = {
  name: 'metakeyVault'
  scope:verifyDatabricksRG
  params:{
    location: verifyDatabricksRG.location
    tags: tags
    keyVaultName: metakeyVaultName
  }
}

module logkeyVault 'modules/services/keyvault.bicep' = {
  name: 'logkeyVault'
  scope:verifyDatabricksRG
  params:{
    location: verifyDatabricksRG.location
    tags: tags
    keyVaultName: logkeyVaultName
  }
}

module sql 'modules/services/sql.bicep' = {
  name:'sql'
  scope:verifyDatabricksRG
  params:{
    sqlPassword: sqlPassword
    sqlserverName: sqlServerName
    sqldbName: sqlDatabaseName
    sqlLogin: sqlLogin
  }
}

module AssignmentKeyAdmin 'modules/auxiliary/userRoleAssignmentResourceGroup.bicep' ={
  name: 'AssignmentKeyAdmin'
  scope:verifyDatabricksRG
  params:{
    userId: signed_in_user_object_id
  }
}

module AssignmentmetaDatabricks 'modules/auxiliary/databricksRoleAssignmentKeyVault.bicep' ={
  name: 'AssignmentmetaDatabricks'
  scope:verifyDatabricksRG
  params:{
    keyVaultId:metakeyVault.outputs.keyvaultId
  }
}
module AssignmentlogDatabricks 'modules/auxiliary/databricksRoleAssignmentKeyVault.bicep' ={
  name: 'AssignmentlogDatabricks'
  scope:verifyDatabricksRG
  params:{
    keyVaultId:logkeyVault.outputs.keyvaultId
  }
}


module sqlserver001UsernameSecretDeployment 'modules/services/keyvaultSecret.bicep' ={
  name:'sqlserver001UsernameSecretDeployment'
  scope: verifyDatabricksRG 
  params:{
    secretValue: '${sqlLogin}@${sqlServerName}'
    keyVaultId: metakeyVault.outputs.keyvaultId
    secretName: SqlServerUsernameSecretName
  }
}

module sqlserverPasswordSecretDeployment 'modules/services/keyvaultSecret.bicep' ={
  name:'sqlserverPasswordSecretDeployment'
  scope: verifyDatabricksRG 
  params:{
    secretValue: sqlPassword
    keyVaultId: metakeyVault.outputs.keyvaultId
    secretName: SqlServerPasswordSecretName
  }
}

module sqlserverConnectionStringSecretDeployment 'modules/services/keyvaultSecret.bicep' ={
  name:'sqlserverConnectionStringSecretDeployment'
  scope: verifyDatabricksRG 
  params:{
    secretValue: 'jdbc:sqlserver://${sql.outputs.sqlserverName}.database.windows.net:1433;database=${sql.outputs.sqlDatabaseName};encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30;'
    keyVaultId: metakeyVault.outputs.keyvaultId
    secretName: sqlConnectionStringSecretName
  }
}

module loganalytics 'modules/services/loganalytics.bicep' ={
  name:'loganalytics'
  scope: verifyDatabricksRG
  params:{
    location:verifyDatabricksRG.location
    logAnanalyticsName:logAnalyticsWorkspaceName
    tags:tags
  }
}


module logAnalyticsSecretDeployment 'modules/auxiliary/logAnalyticsSecretDeployment.bicep' = {
  name:'logAnalyticsSecretDeployment'
  scope:verifyDatabricksRG
  params:{
    keyVaultId: logkeyVault.outputs.keyvaultId
    logAnalyticsId: loganalytics.outputs.logAnalyticsWorkspaceId
  }
}

output databricks001HostUrl string = 'https://${databricks001.outputs.databricksWorkspaceUrl}'
output databricks002HostUrl string = 'https://${databricks002.outputs.databricksWorkspaceUrl}'
output hiveKeyVaultResourceId string = metakeyVault.outputs.keyvaultId
output hiveKeyVaultDnsName string = 'https://${metakeyVaultName}${environment().suffixes.keyvaultDns}/'
output logKeyVaultResourceId string = logkeyVault.outputs.keyvaultId
output logKeyVaultDnsName string = 'https://${logkeyVaultName}${environment().suffixes.keyvaultDns}/'
output databricksWorkspaceSubscriptionId string = subscription().subscriptionId
output databricksWorkspaceResourceGroupName string = resouceGroupName
output databricksWorkspace001Name string = databricks001Name
output databricksWorkspace002Name string = databricks002Name
