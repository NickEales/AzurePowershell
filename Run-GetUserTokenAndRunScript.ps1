param(
    [string]$TenantId,          #AAD Tenant ID
    [string]$username,
    [string]$password,  #NB - CLEARTEXT!!!
    [string]$ScriptToCall,
    [object]$ScriptParam=@{}
)


write-verbose $RequestAccessTokenUri -verbose #remove the -Verbose for this to stop showing the yellow Verbose output



#Get Authorization token
$RequestAccessTokenUri = "https://login.microsoftonline.com/$TenantId/oauth2/token"
$Resource = "https://management.azure.com/"
$ClientID = '1950a258-227b-4e31-a9cf-717495945fc2' # PowerShell ClientID
$body = "grant_type=password&username=$username&password=$Password&resource=$Resource&client_id=$ClientID&scope=openid"
$Token = Invoke-RestMethod -Method Post -Uri $RequestAccessTokenUri -Body $body -ContentType 'application/x-www-form-urlencoded'

if($null -eq $Token){throw "token not obtained - exiting"}

& $scriptToCall -AuthorizationToken $token @ScriptParam
