[cmdletbinding()]
param(
    [string]$SourceResourceId,
    [string]$SourceIP,          #Optional if only one source IP
    [string]$DestIp,      #ClientSecret is the secret from the App registration in Azure AD 
    [int]$SourcePort,
    [int]$DestPort
)

#If no source port or destination port provided, assume we are testing ICMP
$TestICMP = !($SourcePort -or $DestPort)
#if destport is provided but not sourceport, get a random source port
if(!$TestICMP -and !$SourcePort){$SourcePort = get-random -Minimum 5000 -Maximum 65534}
#If Sourceport was provided but no Dest port, default to port 80
if(!$TestICMP -and !$DestPort){$DestPort = 80}
write-verbose "SourceResourceId = $SourceResourceId"
if($SourceIP){write-verbose "SourceIP = $SourceIP"}
write-verbose "DestIp = $DestIp"
write-verbose "TestICMP = $TestICMP"
if($SourcePort){write-verbose "SourcePort = $SourcePort"}
if($SourcePort){write-verbose "DestPort = $DestPort"}

function call-AzureRestAPI
{
    param([string]$APIPath,[string]$APIParameters,[object]$Header)
    $RestApiURL = "https://management.azure.com/$($apipath)?$($APIParameters)"
    write-verbose $RestApiURL -verbose #remove the -Verbose for this to stop showing the yellow Verbose output
    $ApiResponse = Invoke-RestMethod -Method GET -Uri $RestApiURL -Headers $Headers
    $ApiResponse.value
}

$AccessToken= &C:\repo\AzurePowershell\Get-AzCurrentUserToken.ps1
$Headers = @{ "Authorization" = "Bearer " + $accessToken }

$SubscriptionIDs = (call-AzureRestAPI -Header $header -APIPath '/subscriptions' -APIParameters 'api-version=2016-06-01').id
if(!$SubscriptionIDs){throw "unable to get subscriptions - is the user token still valid?"}
