
$ScriptDir  = Set-Location -Path  "C:\Users\bcumant\Documents\Scripts"   -PassThru

$file ="\WebJobCreate.json"

$JsonObject   = Get-Content -Path .\$file |ConvertFrom-Json

$JsonObject.deployment[0]
 

Write-Host "Attributes individually printed"

$resourceGroupName  = $JsonObject.deployment[0].resourceGroupName 
$webAppName = $JsonObject.deployment[0].webAppName
$Location =  $JsonObject.deployment[0].Location 
$Apiversion = $JsonObject.deployment[0].Apiversion
$fileToUpload=$JsonObject.deployment[0].fileToUpload
$WebjobName=$JsonObject.deployment[0].'$WebjobName'
$WebjobType=$JsonObject.deployment[0].'$WebjobType'
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


# $creds = Get-PublishingProfileCredentials -resourceGroupName $resourceGroupName -webAppName $webAppName

#Pulling authorization access token :

function Get-KuduApiAuthorisationHeaderValue($resourceGroupName, $webAppName){



$publishingCredentials = Get-PublishingProfileCredentials $resourceGroupName $webAppName


return ("Basic {0}" -f [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $publishingCredentials.Properties.PublishingUserName, $publishingCredentials.Properties.PublishingPassword))))
}



$accessToken = Get-KuduApiAuthorisationHeaderValue $resourceGroupName $webAppname


# to get site connection string and profiles 
$PublishingProfile=Get-AzureRmWebAppSlotPublishingProfile -ResourceGroupName $resourceGroupName -Name $webAppname -Slot "staging" -Format WebDeploy  -OutputFile $ScriptDir\publishProfile.txt


$Header = @{'Content-Disposition'='attachment; attachment; filename =$ScriptDir\$fileToUpload'

'Authorization'=$accessToken
        }


$apiUrl2="https://$webAppName.scm.azurewebsites.net"
$userAgent = "powershell/1.0"


try {


$response  = Invoke-RestMethod -Uri $apiUrl2 -Headers $Header -UserAgent $userAgent -Method POST -InFile $ScriptDir\$fileToUpload -ContentType "multipart/form-data"


Write-Host `n`n$response`n`n

    
} catch {
    # Dig into the exception to get the Response details.
    # Note that value__ is not a typo.

    Write-Host "StatusCode:" $_.Exception.Response.StatusCode.value__ 
    Write-Host "StatusDescription:" $_.Exception.Response.StatusDescription

    
}


# Start kudu  to verified deployment 
Start-Process https://b2cdemowebapp-staging.scm.azurewebsites.net:443

# for put method  if needed 
# https://$webAppName-stage.scm.azurewebsites.net/api/$WebjobType/$WebjobName/run


#Get list of all Webjobs
Get-AzureRmResource -ResourceGroupName $ResourceGroupName -ResourceName $webAppName -ResourceType microsoft.web/sites/ -ApiVersion $Apiversion 

#Start/Stop the Webjobs 
# Invoke-AzureRmResourceAction -ApiVersion $Apiversion  -ResourceGroupName $ResourceGroupName  -ResourceType microsoft.web/sites/ -Action start  -Force 
