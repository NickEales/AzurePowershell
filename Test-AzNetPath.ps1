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
    param([string]$APIPath,[string]$APIParameters,[object]$Header,[string]$Method='GET')
    $RestApiURL = "https://management.azure.com/$($apipath.trimstart('/'))?$($APIParameters)"
    write-verbose "$Method $RestApiURL" -verbose #remove the -Verbose for this to stop showing the yellow Verbose output
    $ApiResponse = Invoke-RestMethod -Method $Method -Uri $RestApiURL -Headers $Headers
    $ApiResponse
}

$PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
$ResourceList = @()

#Prepare Authorization Header
. "$PSScriptRoot\Get-AzCurrentUserToken.ps1"
$AuthorizationToken = Get-AzCurrentUserToken
$Headers = @{}
$Headers.Add("Authorization","$($AuthorizationToken.token_type) "+ " " + "$($AuthorizationToken.access_token)")

$SubscriptionID = (call-AzureRestAPI -Header $header -APIPath 'subscriptions' -APIParameters 'api-version=2016-06-01').value.id
if(!$SubscriptionID){throw "unable to get subscriptions - is the user token still valid?"}

write-host $SubscriptionIDs

Write-Verbose -Message 'Checking presence of resource provided. 404 error states that it could not be found' -Verbose
$Resource = call-AzureRestAPI -Header $header -APIPath $SourceResourceId -APIParameters 'api-version=2019-07-01' # -Method 'HEAD'
#if(!$SubscriptionIDs){throw "unable to get subscriptions - is the user token still valid?"}
write-host $resource.Type
switch ($Resource.Type){
    'Microsoft.Compute/virtualMachines' {$VirtualMachine=$Resource}
    'Microsoft.Network/networkInterfaces' {$NIC=$Resource}
}

if($VirtualMachine -and !$NIC){
    $NIC = call-AzureRestAPI -Header $header -APIPath $VirtualMachine.properties.networkProfile.networkInterfaces[0].id -APIParameters 'api-version=2019-07-01' # -Method 'HEAD'
}

if(!$nic){write-host "NIC not found"}

$SubnetID = if($SourceIP){
        $NIC.properties.ipConfigurations `
            | where {$_.privateIPAddress -eq $SourceIP} `
            | %{$_.properties.subnet.id}
        } else {
            $NIC.properties.ipConfigurations `
            | select -first 1 `
            | %{$_.properties.subnet.id}
        }   

#$nic | convertto-json -Depth 5 | write-host

if(!$SubnetID){write-host "Subnet not found"}

$NSGList=call-AzureRestAPI -Header $header -APIPath "$SubscriptionID/resources" -APIParameters "`$filter=resourceType eq 'Microsoft.Network/networkSecurityGroups'&api-version=2019-05-10"


$NSGList | convertto-json -Depth 5 | write-host

