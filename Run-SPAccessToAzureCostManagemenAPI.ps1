$PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
if([string]::isnullorempty($ClientSecret)){. "$PSScriptRoot\Creds.ps1"}

& "$PSScriptRoot\Run-GetSPTokenAndRunScript.ps1" `
    -ScriptToCall "$PSScriptRoot\AzureCostManagementRestApiExample.ps1" `
    -TenantId $tenantId `
    -clientId $ClientId `
    -ClientSecret $ClientSecret 
