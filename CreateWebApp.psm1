
# param( 
# [string] $ResourceGroupName, 
# [string] $webappname, 
# [string] $webappnamePlan,
# [string] $AppTypeTier
#)


#Param(
#  [parameter(mandatory=$true)][string]$file
# )


Param(
  [string]$file
)


#$ScriptDir = Split-Path $script:MyInvocation.MyCommand.Path

 $ScriptDir = Get-Location  



#Getting information from the json file
#The we pass the output from Get-Content to ConvertFrom-Json Cmdlet

$JsonObject = Get-Content -Path "$ScriptDir\deployIam.json" |ConvertFrom-Json

 
#  indexing array 


$JsonObject.deployment[0]
 
#call the attributes of the elements

Write-Host "Attributes individually printed"


$ResourceGroupName = $JsonObject.deployment[0].ResourceGroupName   
$gitrepo = $JsonObject.deployment[0].repo  
$webappnamePlan = $JsonObject.deployment[0].webappnamePlan 
$webappname  = $JsonObject.deployment[0].webappname
$AppTypeTier = $JsonObject.Deployment[0].'AppTypeTier '
$location =  $JsonObject.Deployment[0].location

Write-Host "Attributes individually printed"

$SubscriptionId =$JsonObject.deployment[1].SubscriptionId
 
$TenantId = $JsonObject.deployment[2].TenantId

$SubscriptionName = $JsonObject.deployment[3].SubscriptionName



Login-AzureRmAccount –SubscriptionId $SubscriptionId -TenantId $TenantId


# $result = Add-AzureRmAccount –SubscriptionId 9b07432f-cf4c-4b84-878c-6e75b843255c -TenantId 23dc43b7-970b-42e0-a2c9-2e5b63029a09



#Get-AzureRmSubscription -SubscriptionName  $SubscriptionName  | Set-AzureRmContext 

Get-AzureRmSubscription –SubscriptionId $SubscriptionId  | Set-AzureRmContext 

# $location="West US"




# Check to see if the resource group already exists

  Write-Verbose "Checking for Resource Group $ResourceGroupName"

  $rgExists = Get-AzureRmResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
  
  # If not, create it.

  
  if ( $rgExists -eq $null )

  {
  

    Write-Verbose "Creating Resource Group $ResourceGroupName"


    New-AzureRmResourceGroup -Name $ResourceGroupName -Location $Location

    

  } else {
  Write-Verbose "the  Resource Group   $ResourceGroupName already  exist "
  
  }

  
 #check if App service plan exist 

 # Get-AzureRmAppServicePlan -ResourceGroupName $ResourceGroupName 


  $AppServicePlanExists = Get-AzureRMAppServicePlan -ResourceGroupName $ResourceGroupName  -ErrorAction SilentlyContinue


if ( $AppServicePlanExists -eq $null )

  {
  

    Write-Verbose "Creating AppService Plan"
    
      
  # Create an App Service plan in Free tier.
  
 New-AzureRMAppServicePlan -Name $webappnamePlan -Location $location -ResourceGroupName $ResourceGroupName -Tier $AppTypeTier 

# Create a web app first time with Nane in the parametre file 


New-AzureRMWebApp -Name $webappname -Location $location -AppServicePlan $webappnamePlan -ResourceGroupName $ResourceGroupName




  } else {
  

Write-Verbose "the  AppServicePlan   exist   "


}

$WebAppExist = get-AzureRmWebApp -ResourceGroupName $ResourceGroupName  -ErrorAction SilentlyContinue

  while ( $WebAppExist -eq $null )

  {
  

    Write-Verbose "App wasn't created  because Name already  taken "




    $webappname = Read-Host ="re-enter AppName to test if not exist  " 

    
    New-AzureRMWebApp -Name $webappname -Location $location -AppServicePlan $webappnamePlan -ResourceGroupName $ResourceGroupName

        
  }
  
  
  
# Upgrade App Service plan to Standard tier ( required by deployment slots)

Set-AzureRMAppServicePlan -Name $webappnamePlan -ResourceGroupName $ResourceGroupName -Tier Standard

#Create a deployment slot with the name "staging".

New-AzureRMWebAppSlot -Name $webappname -ResourceGroupName $ResourceGroupName -Slot staging

# Configure GitHub deployment to the staging slot from your GitHub repo and deploy once.


$PropertiesObject = @{
 
    token= "467146d20939af4f7d4af0acf0cec6a5cdaa169e";
    repoUrl = $gitrepo;
    branch = "master";
    IsManualIntegration = true 
}

Set-AzureRMResource -PropertyObject $PropertiesObject -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/sites/slots/sourcecontrols -ResourceName $webappname/staging/web -ApiVersion 2015-08-01 -Force

# Swap the verified/warmed up staging slot into production.
Switch-AzureRMWebAppSlot -Name $webappname -ResourceGroupName $ResourceGroupName -SourceSlotName staging -DestinationSlotName production
