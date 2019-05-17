
$ScriptDir  = Set-Location "C:\Users\bcumant\Documents\Scripts"

$file ="WebJobCreate.json"

$JsonObject   = Get-Content -Path .\$ScriptDir\$file |ConvertFrom-Json

$JsonObject.deployment[0]
 

Write-Host "Attributes individually printed"

$resourceGroupName  = $JsonObject.deployment[0].resourceGroupName 
$webAppName = $JsonObject.deployment[0].webAppName
$Location =  $JsonObject.deployment[0].Location 
$Apiversion = $JsonObject.deployment[0].Apiversion
$fileToUpload=$JsonObject.deployment[0].fileToUpload
$WebjobName=$JsonObject.deployment[0].WebjobName
$WebjobType=$JsonObject.deployment[0].WebjobType



$SubscriptionId =$JsonObject.deployment[1].SubscriptionId
$TenantId = $JsonObject.deployment[2].TenantId



Login-AzureRmAccount –SubscriptionId $SubscriptionId -TenantId $TenantId

 
$context = Set-AzureRmContext -TenantId $TenantId -Name B2C -Force




#Resource details :


# $resourceGroupName = "az-prd-westus2-b2c-devauth";
# $webAppName = "B2CdemoWebApp";
# $Apiversion = 2015-08-01
# $fileToUpload = "WebJob.zip"
# $WebjobName="webjobtest"
# $WebjobType="Continuous"


#Function to get Publishing credentials for the WebApp :


function Get-PublishingProfileCredentials($resourceGroupName, $webAppName){

$resourceType = "Microsoft.Web/sites/config"

$resourceName = "$webAppName/publishingcredentials"

$publishingCredentials = Invoke-AzureRmResourceAction -ResourceGroupName $resourceGroupName -ResourceType $resourceType -ResourceName $resourceName -Action list -ApiVersion $Apiversion -Force
  
   return $publishingCredentials
}

#Pulling authorization access token :
function Get-KuduApiAuthorisationHeaderValue($resourceGroupName, $webAppName){

$publishingCredentials = Get-PublishingProfileCredentials $resourceGroupName $webAppName

return ("Basic {0}" -f [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f 

$publishingCredentials.Properties.PublishingUserName, $publishingCredentials.Properties.PublishingPassword))))
}

$accessToken = Get-KuduApiAuthorisationHeaderValue $resourceGroupName $webAppname

#Generating header to create and publish the Webjob :
$Header = @{
'Content-Disposition'='attachment; attachment; filename=$fileToUpload'
'Authorization'=$accessToken
        }
$apiUrl = "https://$webAppName.scm.azurewebsites.net/api/$WebjobType/$WebjobName"

$result = Invoke-RestMethod -Uri $apiUrl -Headers $Header -Method put -InFile ".\$ScriptDir\$fileToUpload\" -ContentType 'application/zip' 





#Get list of all Webjobs

Get-AzureRmResource -ResourceGroupName $ResourceGroupName -ResourceName $AppService -ResourceType microsoft.web/sites/$WebjobType -ApiVersion $Apiversion 

#Start/Stop the Webjobs

Invoke-AzureRmResourceAction -ApiVersion $Apiversion  -ResourceGroupName $ResourceGroupName -ResourceName $ResourceName -ResourceType microsoft.web/sites/$WebjobType -Action start/stop  -Force

#Delete a Webjob
Remove-AzureRmResource -ApiVersion $Apiversion  -ResourceGroupName $ResourceGroupName -ResourceName $ResourceName -ResourceType
