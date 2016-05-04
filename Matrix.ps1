

clear
$resourceGroupName ="DEV-MATRIX02"
$Location ="North Europe"
$dnsName ="danmatrixdev02"
$templateFile="azuredeploy.json"
$parametersFile ="azuredeploy.parameters.json"
$deploymentName = "dev02-matrix"

if($adminUserName -eq $null) {
    $adminUserName = Read-Host -Prompt "Enter Admin User Name" 
}

if($adminUserPassword -eq $null) {
    $adminUserPassword = Read-Host -Prompt "Enter Admin User Password" 
}

if($adminsshKey -eq $null) {
    $adminsshKey = Read-Host -Prompt "Enter Admin ssh Key" 
}

function GetOrCreateResourceGroup
{
    
        if (-not (Get-AzureRmResourceGroup | ? ResourceGroupName -eq $resourceGroupName))
        {
            $newResourceGroup = New-AzureRmResourceGroup  -Name $ResourceGroupName -Location $Location -Verbose 
        }
}

GetOrCreateResourceGroup

function SetClusterTemplateParameters()
{
    Param(
          [string] $adminUserName,  
          [string] $adminUserPassword,
          [string] $adminsshKey,
          [string] $location,
          [string] $dnsName
          
         )
    
    # Read the Json Parameters file and Convert to HashTable
    $parameters = New-Object -TypeName hashtable 
    $jsonContent = Get-Content "azuredeploy.parameters.json"  -Raw | ConvertFrom-Json 
    $jsonContent.parameters.psobject.Properties.Name `
            |ForEach-Object {$parameters.Add($_ ,$jsonContent.parameters.$_.Value)}
    
    # Add Sensitive Parameters 
    $parameters["adminUserName"] = $adminUserName  
    $parameters["adminPassword"] = $adminUserPassword  
    $parameters["sshKeyData"] = $adminsshKey 
    $parameters["dnsName"] = $dnsName
    $parameters["location"] = $location
    

    
    $parameters
}
####### STEP 4 : Retrieve and Print Cluster Parameters #####################
$clusterParameters = SetClusterTemplateParameters -adminUserPassword $adminUserPassword -adminUserName $adminUserName -adminsshKey $adminsshKey `
                                                  -location $Location -dnsName $dnsName
Write-Host $clusterParameters

####### STEP 5 : TEST RESOURCE GROUP #####################
$validation = Test-AzureRmResourceGroupDeployment -ResourceGroupName $resourceGroupName `
                                                  -TemplateFile $templateFile -TemplateParameterObject $clusterParameters
    
if($validation.Count -eq 0)
{
        New-AzureRmResourceGroupDeployment  -Name $deploymentName -ResourceGroupName $resourceGroupName `
                                            -TemplateFile $templateFile -TemplateParameterObject $clusterParameters -DeploymentDebugLogLevel All

}else
{
    $validation
}