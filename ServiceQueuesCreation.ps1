



$ScriptDir  = Set-Location "C:\Users\bcumant\Documents\Scripts"

$file ="ServiceBusCreation.json"

$JsonObject   = Get-Content -Path .\$ScriptDir\$file |ConvertFrom-Json

$JsonObject.deployment[0]
 

Write-Host "Attributes individually printed"


$ResGrpName  = $JsonObject.deployment[0].ResGrpName 
$Namespace = $JsonObject.deployment[0].Namespace
$Location =  $JsonObject.deployment[0].Location 
$AuthRule = $JsonObject.deployment[0].AuthRule
$QueueName=$JsonObject.deployment[0].QueueName



$SubscriptionId =$JsonObject.deployment[1].SubscriptionId
$TenantId = $JsonObject.deployment[2].TenantId




 Login-AzureRmAccount –SubscriptionId $SubscriptionId -TenantId $TenantId

 


$context = Set-AzureRmContext -TenantId $TenantId -Name B2C -Force





 # Query to see if the namespace currently exists
$CurrentNamespace = Get-AzureRMServiceBusNamespace -ResourceGroup $ResGrpName -NamespaceName $Namespace -ErrorAction SilentlyContinue

# Check if the namespace already exists or needs to be created
if ($CurrentNamespace -ne $null) 
{
    Write-Host "The namespace $Namespace already exists in the $Location region:"
 	# Report what was found


 	Get-AzureRMServiceBusNamespace -ResourceGroup $ResGrpName -NamespaceName $Namespace
}
else
{
    Write-Host "The $Namespace namespace does not exist."
    Write-Host "Creating the $Namespace namespace in the $Location region..."

    New-AzureRMServiceBusNamespace -ResourceGroup $ResGrpName -NamespaceName $Namespace -Location $Location
    $CurrentNamespace = Get-AzureRMServiceBusNamespace -ResourceGroup $ResGrpName -NamespaceName $Namespace
    Write-Host "The $Namespace namespace in Resource Group $ResGrpName in the $Location region has been successfully created."

}





# Query to see if rule exists
$CurrentRule = Get-AzureRMServiceBusAuthorizationRule -ResourceGroup $ResGrpName -NamespaceName $Namespace -AuthorizationRuleName $AuthRule -ErrorAction SilentlyContinue

# Check if the rule already exists or needs to be created
if ($CurrentRule  -ne $null )
{
    Write-Host "The $AuthRule rule already exists for the namespace $Namespace."
}
else
{
    Write-Host "The $AuthRule rule does not exist."

    Write-Host "Creating the $AuthRule rule for the $Namespace namespace..."

    New-AzureRMServiceBusAuthorizationRule -ResourceGroup $ResGrpName -NamespaceName $Namespace -AuthorizationRuleName $AuthRule -Rights @("Listen","Send")
    
    
    $CurrentRule = Get-AzureRMServiceBusAuthorizationRule -ResourceGroup $ResGrpName -NamespaceName $Namespace -AuthorizationRuleName $AuthRule -ErrorAction SilentlyContinue
   
    Write-Host "The $AuthRule rule for the $Namespace namespace has been successfully created."

    Write-Host "Setting rights on the namespace"
    $authRuleObj = Get-AzureRMServiceBusAuthorizationRule -ResourceGroup $ResGrpName -NamespaceName $Namespace -AuthorizationRuleName $AuthRule

    Write-Host "Remove Send rights"

    $authRuleObj.Rights.Remove("Send")

    Set-AzureRMServiceBusAuthorizationRule -ResourceGroup $ResGrpName -NamespaceName $Namespace -AuthRuleObj $authRuleObj

    Write-Host "Add Send and Manage rights to the namespace"
    $authRuleObj.Rights.Add("Send")

    Set-AzureRMServiceBusAuthorizationRule -ResourceGroup $ResGrpName -NamespaceName $Namespace -AuthRuleObj $authRuleObj

    $authRuleObj.Rights.Add("Manage")
    Set-AzureRMServiceBusAuthorizationRule -ResourceGroup $ResGrpName -NamespaceName $Namespace -AuthRuleObj $authRuleObj

    Write-Host "Show value of primary key"
    $CurrentKey = Get-AzureRMServiceBusKey -ResourceGroup $ResGrpName -NamespaceName $Namespace -Name $AuthRule
        
    Write-Host "Remove this authorization rule"
    Remove-AzureRMServiceBusAuthorizationRule -ResourceGroup $ResGrpName -NamespaceName $Namespace -Name $AuthRule


    
}




$CurrentQ = Get-AzureRMServiceBusQueue -ResourceGroup $ResGrpName -NamespaceName $Namespace -QueueName $QueueName -ErrorAction SilentlyContinue

if($CurrentQ)
{
    Write-Host "The queue $QueueName already exists in the $Location region:"
}
else
{
    Write-Host "The $QueueName queue does not exist."
    Write-Host "Creating the $QueueName queue in the $Location region..."


    New-AzureRMServiceBusQueue -ResourceGroup $ResGrpName -NamespaceName $Namespace -QueueName $QueueName -EnablePartitioning $True

    $CurrentQ = Get-AzureRMServiceBusQueue -ResourceGroup $ResGrpName -NamespaceName $Namespace -QueueName $QueueName
    Write-Host "The $QueueName queue in Resource Group $ResGrpName in the $Location region has been successfully created."
}



#  setting properties 


$CurrentQ.DeadLetteringOnMessageExpiration = $True
$CurrentQ.MaxDeliveryCount = 7
$CurrentQ.MaxSizeInMegabytes = 2048
$CurrentQ.EnableExpress = $True

Set-AzureRMServiceBusQueue -ResourceGroup $ResGrpName -NamespaceName $Namespace -QueueName $QueueName -QueueObj $CurrentQ
