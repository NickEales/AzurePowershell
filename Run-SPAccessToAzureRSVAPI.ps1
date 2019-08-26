$PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent

if([string]::isnullorempty($ClientSecret)){. "$PSScriptRoot\Creds.ps1"}

& "$PSScriptRoot\Run-GetSPTokenAndRunScript.ps1" `
    -scriptToCall "$PSScriptRoot\AzureRSVRestApiExample.ps1" `
    -TenantId $tenantId `
    -clientId $ClientId `
    -ClientSecret $ClientSecret `
    -ScriptParam @{TenantId = $tenantId}
