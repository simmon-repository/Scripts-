

Login-AzureRmAccount –SubscriptionId 9b07432f-cf4c-4b84-878c-6e75b843255c -TenantId 23dc43b7-970b-42e0-a2c9-2e5b63029a09


$result = Add-AzureRmAccount –SubscriptionId 9b07432f-cf4c-4b84-878c-6e75b843255c -TenantId 23dc43b7-970b-42e0-a2c9-2e5b63029a09



Get-AzureRmSubscription -SubscriptionName  'Microsoft Azure' | Set-AzureRmContext 


$gitrepo="https://github.com/simmon-repository/B2C.git"

$webappname="mywebapp$(Get-Random)"

$location="West US"

$ResourceGroupName ="AppB2Cdev"

$webappnamePlan ="ASP"


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
  
 New-AzureRMAppServicePlan -Name $webappnamePlan -Location $location -ResourceGroupName $ResourceGroupName -Tier Free

# Create a web app.
New-AzureRMWebApp -Name $webappname -Location $location -AppServicePlan $webappnamePlan -ResourceGroupName $ResourceGroupName


New-AzureRmWebApp -ResourceGroupName $ResourceGroupName -Name $webappname -Location "West US" -AppServicePlan $webappnamePlan


# Upgrade App Service plan to Standard tier ( required by deployment slots)

Set-AzureRMAppServicePlan -Name $webappnamePlan -ResourceGroupName $ResourceGroupName -Tier Standard

#Create a deployment slot with the name "staging".

New-AzureRMWebAppSlot -Name $webappname -ResourceGroupName $ResourceGroupName -Slot staging

# Configure GitHub deployment to the staging slot from your GitHub repo and deploy once.

$PropertiesObject = @{
    repoUrl = "$gitrepo";
    branch = "master";
}

Set-AzureRMResource -PropertyObject $PropertiesObject -ResourceGroupName $ResourceGroupName -ResourceType Microsoft.Web/sites/slots/sourcecontrols -ResourceName $webappname/staging/web -ApiVersion 2015-08-01 -Force

# Swap the verified/warmed up staging slot into production.
Switch-AzureRMWebAppSlot -Name $webappname -ResourceGroupName $ResourceGroupName -SourceSlotName staging -DestinationSlotName production



  } else {
  

Write-Verbose "the  AppServicePlan   already  exist "
  
  }
  