param(
    [string]$TenantId,          #AAD Tenant ID
    [string]$clientId,          #ClientID is the Client ID from the App registration in AzureAD
    [string]$ClientSecret,      #ClientSecret is the secret from the App registration in Azure AD 
    [string]$scriptToCall,
    [object]$ScriptParam=@{}
)

#Get Authorization token
$RequestAccessTokenUri = "https://login.microsoftonline.com/$TenantId/oauth2/token"
$Resource = "https://management.azure.com/"
#$Resource = "https://management.core.windows.net/"
$body = "grant_type=client_credentials&client_id=$ClientId&client_secret=$ClientSecret&resource=$Resource"
write-verbose $RequestAccessTokenUri -verbose #remove the -Verbose for this to stop showing the yellow Verbose output

$Token = Invoke-RestMethod -Method Post -Uri $RequestAccessTokenUri -Body $body -ContentType 'application/x-www-form-urlencoded'

if($null -eq $Token){throw "token not obtained - exiting"}

& $scriptToCall -AuthorizationToken $token @ScriptParam
