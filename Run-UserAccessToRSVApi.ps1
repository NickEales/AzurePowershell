$PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent

if([string]::isnullorempty($ClientSecret)){. "$PSScriptRoot\Creds.ps1"}

& "$PSScriptRoot\Run-GetUserTokenAndRunScript.ps1" `
    -scriptToCall "$PSScriptRoot\AzureRSVRestApiExample.ps1" `
    -TenantId $tenantId `
    -UserName $UserName `
    -Password $Password `
    -ScriptParam @{TenantId = $tenantId}
