param( 
[string] $strTenant, 
[string] $strFilePolicy, 
[string] $strUserID, 
[SecureString] $strPw 
)

$cred = New-Object System.Management.Automation.PSCredential ($strUserID, $strPw) 
Login-AzureRmAccount -Credential $cred

$context = Set-AzureRmContext -TenantId $strTenant -Name B2C -Force 

$context | Select-AzureRmContext | Out-Null
$TenantId = $context.Tenant.TenantId 

$token = $context.TokenCache.ReadItems() | Where-Object { $_.Resource -ilike "*/management.core.windows.net/*" -and $_.AccessToken -ne $null -and $TenantId -ieq $_.Authority.Split('/')[3] } | sort -Property ExpiresOn -Descending | select -First 1 
$strAccessToken = $token.AccessToken

if (Test-Path $strFilePolicy) { 


Write-Output "Uploading policy: $($strFilePolicy.Split('`\')[-1])"
$strPolicy = (Get-Content -Path $strFilePolicy) -join "`n" 
Add-Type -AssemblyName System.Web 
$strBody = "<string xmlns=`"http://schemas.microsoft.com/2003/10/Serialization/`">$([System.Web.HttpUtility]::HtmlEncode($strPolicy))</string>"
$htHeaders = @{ "Authorization" = "Bearer $strAccessToken" }
$response = $null 
$response = Invoke-WebRequest -Uri "https://main.b2cadmin.ext.azure.com/api/trustframework?tenantId=$strTenant&overwriteIfExists=true&quot; -Method POST -Body $strBody -ContentType "application/xml" -Headers $htHeaders -UseBasicParsing
if ($response.StatusCode -ge 200 -and $response.StatusCode -le 299) 
{ 
Write-Output "Policy successfully uploaded" 
} 
else 
{ 
Write-Output "Failed to upload policy" 
}
} 
else 
{ 
Write-Error "Cannot find file: $strFilePolicy" 
} 
