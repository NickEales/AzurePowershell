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
    [object]$AuthorizationToken
)

function call-AzureRestAPI
{
    param([string]$APIPath,[string]$APIParameters,[object]$Header,[string]$method='GET',[string]$Requestbody='')
    $RestApiURL = "https://management.azure.com$($apipath)?$($APIParameters)"
    if($method -eq 'GET'){
        write-verbose "$method - $RestApiURL" -verbose #remove the -Verbose for this to stop showing the yellow Verbose output
        $ApiResponse = Invoke-RestMethod -Method $Method -Uri $RestApiURL -Headers $Headers 
    }else{
        write-verbose "$method - $RestApiURL" -verbose #remove the -Verbose for this to stop showing the yellow Verbose output
        #Write-Verbose $Requestbody -Verbose
        #$Headers | convertto-json -depth 5 | write-verbose -Verbose
        $ApiResponse = Invoke-RestMethod -Method $Method -Uri $RestApiURL -Headers $Headers -Body $Requestbody -ContentType "application/json"
    }
    $ApiResponse#.value
}

$Headers = @{}
$Headers.Add("Authorization","$($AuthorizationToken.token_type) "+ " " + "$($AuthorizationToken.access_token)")

write-host "Query Cost API:"
$BodyObject=@{
    
    type='Usage'
    timeframe='TheLastMonth'
    dataset=@{
        granularity = 'Daily'
        aggregation=@{
            totalCost=@{
                name='PreTaxCost'
                function='Sum'
            }
        }
    }
}       
$Requestbody = $BodyObject | convertto-json -Depth 10

<#
write-host -ForegroundColor Cyan 'Testing API ManagementGroups cost management'
$ManagementGroupId='RestTest'
$scope = "/providers/Microsoft.Management/managementGroups/$($ManagementGroupId)"
$ApiParameters = "api-version=2019-01-01"
$result = (call-AzureRestAPI -Header $header -APIPath "$($scope)/providers/Microsoft.CostManagement/query" -APIParameters $ApiParameters -method 'POST' -requestBody $Requestbody  -Verbose)
$result | ConvertTo-Json -Depth 5 | write-host
#>

<#
write-host -ForegroundColor Cyan 'Testing API for Resource Groups cost management'
$scope = "/subscriptions/92feddf2-3895-421d-a564-98a43783608e/resourceGroups/testRsvApi"
$ApiParameters = "api-version=2019-01-01"
$result = (call-AzureRestAPI -Header $header -APIPath "$($scope)/providers/Microsoft.CostManagement/query" -APIParameters $ApiParameters -method 'POST' -requestBody $Requestbody  -Verbose)

$result | ConvertTo-Json -Depth 5 | write-host
#>

Write-verbose -verbose 'Get list of management groups'
$ManagementGroupId='RestTest'
$APIPath = "/providers/Microsoft.Management/managementGroups"
$ApiParameters = "api-version=2018-03-01-preview"
$result = (call-AzureRestAPI -Header $header -APIPath $APIPath -APIParameters $ApiParameters -method 'GET' -Verbose)
#$result | ConvertTo-Json -Depth 5 | write-host

$ManagementGroupIDs = $result.value |%{$_.id}

Foreach($ManagementGroupID in $ManagementGroupIDs){
    Write-verbose -verbose "Get subscriptions in management group $ManagementGroupID"
    $APIPath = "$ManagementGroupID/descendants"
    $ApiParameters = "api-version=2018-03-01-preview"
    $result = (call-AzureRestAPI -Header $header -APIPath $APIPath -APIParameters $ApiParameters -method 'GET'  -Verbose)
#    $result | ConvertTo-Json -Depth 5 | write-host
    
    $SubUrlIDs = $result.value | %{$_.id}

    foreach($SubUrlID in $SubUrlIDs){
        Write-verbose -verbose "Get cost details for subscription $SubUrlID"
        $ApiParameters = "api-version=2019-01-01"
        $APIPath = "$SubUrlID/providers/Microsoft.CostManagement/query"
        $result = (call-AzureRestAPI -Header $header -APIPath $APIPath -APIParameters $ApiParameters -method 'POST' -requestBody $Requestbody  -Verbose)
        $result | ConvertTo-Json -Depth 5 | write-host
    }
    
}
<#
Write-verbose -verbose "Get subscriptions in management group "
$Part1 = $result.value[0].id 
$part2 = '/descendants'
$APIPath = "$Part1$Part2"
$ApiParameters = "api-version=2018-03-01-preview"
$result = (call-AzureRestAPI -Header $header -APIPath $APIPath -APIParameters $ApiParameters -method 'GET'  -Verbose)

$result | ConvertTo-Json -Depth 5 | write-host

$SubUrlIDs = $result.value | %{$_.id}

foreach($scope in $SubUrlIDs){
    $ApiParameters = "api-version=2019-01-01"
    $result = (call-AzureRestAPI -Header $header -APIPath "$($scope)/providers/Microsoft.CostManagement/query" -APIParameters $ApiParameters -method 'POST' -requestBody $Requestbody  -Verbose)
    
    $result | ConvertTo-Json -Depth 5 | write-host
}
#>
<#
$ManagementGroupId='RestTest'
$scope = "providers/Microsoft.Management/managementGroups/$($ManagementGroupId)"
#$scope = "subscriptions/92feddf2-3895-421d-a564-98a43783608e/resourceGroups/testRsvApi"
$ApiParameters = "api-version=2019-01-01"
$result = (call-AzureRestAPI -Header $header -APIPath "$($scope)/providers/Microsoft.CostManagement/query" -APIParameters $ApiParameters -method 'POST' -requestBody $Requestbody  -Verbose)

$result | ConvertTo-Json -Depth 5 | write-host

#>