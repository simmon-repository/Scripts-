[CmdletBinding()]
Param (
    [string]
    [Parameter(Mandatory = $true)]
    $WebSiteName,
    [string]
    [Parameter(Mandatory = $true)]
    $ResourceGroupName,

    [hashtable]
    [Parameter(Mandatory = $false)]
    $AppSettings
)

Begin
{
    Write-Verbose "Parameter Values:"

    foreach($key in $PSBoundParameters.Keys)
    {
        Write-Verbose ("    $key = $($PSBoundParameters[$key])")
    }

    if([string]::IsNullOrWhiteSpace($WebSiteName))
    {
        Write-Error "WorkspaceCollectionName can not be empty!"
        Write-Output "##vso[task.complete result=Failed;]WorkspaceCollectionName can not be empty!"
        exit 1
    }

    if([string]::IsNullOrWhiteSpace($ResourceGroupName))
    {
        Write-Error "ResourceGroupName can not be empty!"
        Write-Output "##vso[task.complete result=Failed;]ResourceGroupName can not be empty!"
        exit 1
    }
}

Process
{
    Write-Output "Updating application settings"
    Write-Verbose "Getting WebApp..."
    $webApp = Get-AzureRmWebApp -ResourceGroupName $ResourceGroupName -Name $WebSiteName
    Write-Verbose "    Done."

    Write-Verbose "Reading AppSettings for '$($webApp.Name)'..."
    $appSettingList = $webApp.SiteConfig.AppSettings
    Write-Verbose "    Done."

    $newAppSettingList = @{}

    Write-Verbose "Read all existing settings..."
    ForEach ($kvp in $appSettingList) {
        $newAppSettingList[$kvp.Name] = $kvp.Value
    }
    Write-Verbose "    Done."

    Write-Verbose "Add or override new settings..."
    ForEach ($key in $AppSettings.Keys) {
        $newAppSettingList[$key] = $AppSettings[$key]
    }
    Write-Verbose "    Done."

    Write-Verbose "Updating WebApp '$($webApp.Name)'..."
    $updatedWebApp = Set-AzureRMWebApp -ResourceGroupName $ResourceGroupName -Name $WebSiteName -AppSettings $newAppSettingList
    Write-Verbose "    Done."
    
    Write-Output "Finished updating application settings"
}
