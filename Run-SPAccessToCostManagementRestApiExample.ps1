$PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
& "$PSScriptRoot\Run-GetSPTokenAndRunScript.ps1" `
    -ScriptToCall "$PSScriptRoot\AzureCostManagementRestApiExample.ps1" `
    -TenantId '61b9f171-CCCC-DDDD-94c0-25df1220b4f4' `
    -clientId 'a0f5ec63-AAAA-BBBB-8c35-6d6284cb29b4' `
    -ClientSecret  '=OUUx4P?8.=dvvI2:q_' 
