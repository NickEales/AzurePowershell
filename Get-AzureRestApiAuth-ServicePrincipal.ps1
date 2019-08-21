param(
    [striong]$TenantId,
    [string]$clientId,
    [string]$ClientSecret
)


$RequestAccessTokenUri = "https://login.microsoftonline.com/$TenantId/oauth2/token"
$Resource = "https://management.core.windows.net/"
$body = "grant_type=client_credentials&client_id=$ClientId&client_secret=$ClientSecret&resource=$Resource"
$Token = Invoke-RestMethod -Method Post -Uri $RequestAccessTokenUri -Body $body -ContentType 'application/x-www-form-urlencoded'
if($null -eq $Token){throw "token not obtained - exiting"}
return $Token