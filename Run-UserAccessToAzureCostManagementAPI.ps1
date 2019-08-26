$PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent

& "$PSScriptRoot\Run-GetUserTokenAndRunScript.ps1" `
    -ScriptToCall "$PSScriptRoot\AzureCostManagementRestApiExample.ps1" `
    -username 'someone@somewhere.com' `
    -password 'Password1' `
    -TenantId '61b9f171-AAAA-CCCC-94c0-25df1220b4f4'

