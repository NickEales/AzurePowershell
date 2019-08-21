<#
Disclaimer: The sample scripts are not supported under any Microsoft standard support program or service. 
The sample scripts are provided AS IS without warranty of any kind. Microsoft further disclaims all implied 
warranties including, without limitation, any implied warranties of merchantability or of fitness for a 
particular purpose. The entire risk arising out of the use or performance of the sample scripts and 
documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in the 
creation, production, or delivery of the scripts be liable for any damages whatsoever (including, without 
limitation, damages for loss of business profits, business interruption, loss of business information, or 
other pecuniary loss) arising out of the use of or inability to use the sample scripts or documentation, 
even if Microsoft has been advised of the possibility of such damages. 
#>

param(
    [string]$TenantID,    #TenantID to scan for recovery services vaults
    [object]$AuthorizationToken,
    [int]$HoursAgo=48
)

write-host "showing result of all backup jobs in the last $HoursAgo hours for all subscriptions in the tenant $TenantID"

function call-AzureRestAPI
{
    param([string]$APIPath,[string]$APIParameters,[object]$Header)
    $RestApiURL = "https://management.azure.com/$($apipath)?$($APIParameters)"
    write-verbose $RestApiURL -verbose #remove the -Verbose for this to stop showing the yellow Verbose output
    $ApiResponse = Invoke-RestMethod -Method GET -Uri $RestApiURL -Headers $Headers
    $ApiResponse.value
}

$Headers = @{}
$Headers.Add("Authorization","$($AuthorizationToken.token_type) "+ " " + "$($AuthorizationToken.access_token)")

$SubscriptionIDs = (call-AzureRestAPI -Header $header -APIPath '/subscriptions' -APIParameters 'api-version=2016-06-01').id

write-host "get backup jobs over last $HoursAgo hours:"
$startTime=get-date $(get-date).touniversaltime().addHours(0-$HoursAgo) -uFormat "%Y-%m-%d %r" 
$endTime=get-date $(get-date).touniversaltime() -uFormat "%Y-%m-%d %r" 

$Result = foreach($SubscriptionID in $SubscriptionIDs)
{
    $oDatafilter = "resourceType eq 'Microsoft.RecoveryServices/vaults'"  
    $UrlEncodedoDataFilter = [System.Web.HttpUtility]::UrlEncode($oDatafilter) 

    $ApiParameters = "api-version=2019-05-10&`$filter=$UrlEncodedoDataFilter"
    $ResourceIDs = (call-AzureRestAPI -Header $header -APIPath "$subscriptionid/resources" -APIParameters $ApiParameters).id

    foreach($ResourceID in $ResourceIDs)
    {
        $oDatafilter = "operation eq 'Backup' and startTime eq '$startTime' and endTime eq '$endTime'"  
        $UrlEncodedoDataFilter = [System.Web.HttpUtility]::UrlEncode($oDatafilter) 
        $ApiParameters = "api-version=2017-07-01&`$filter=$UrlEncodedoDataFilter"

        $BackupJobs = (call-AzureRestAPI -Header $header -APIPath "$ResourceID/backupJobs" -APIParameters $ApiParameters)
        $BackupJobs
    }
}

$result.properties | ft backupManagementType,entityFriendlyName,operation,status,startTime,endTime
#uncomment for more details - including vault resource ID
#$result | convertto-json -Depth 3
