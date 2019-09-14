Function Get-AzCurrentUserToken{
Param(
    [string]$TenantID,
    [string]$endpoint = 'https://login.microsoftonline.com/'
)

$Context = Get-AzContext
    if(!$Context){throw "Not logged into Azure"}

    if(!$tenantid){$TEnantID=$Context.Tenant.Id}

    $cachedTokens = $Context.tokenCache.ReadItems() `
            | where { $_.TenantId -eq $tenantId } `
            | Sort-Object -Property ExpiresOn -Descending

    $Token = @{token_type='Bearer';access_token=$cachedTokens[0].AccessToken}

    return $Token
}