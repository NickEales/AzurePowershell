Login-AzureRmAccount

$Subscription = (Get-AzureRmSubscription | Out-GridView -Title "Choose a Source & Target Subscription ..." -PassThru)
Select-AzureRmSubscription -Subscription $Subscription
$SubscriptionId = $Subscription.Id
#endregion

##########################################################################################
###############################    AAD SP Functions     ##################################
##########################################################################################

# Using logged in credentials
Function RestAPI-AuthToken ($TenantId, $resourceAppIdURI) {

    # Load ADAL Azure AD Authentication Library Assemblies
    $adal = "${env:ProgramFiles(x86)}\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Services\Microsoft.IdentityModel.Clients.ActiveDirectory.dll"
    $adalforms = "${env:ProgramFiles(x86)}\Microsoft SDKs\Azure\PowerShell\ServiceManagement\Azure\Services\Microsoft.IdentityModel.Clients.ActiveDirectory.WindowsForms.dll"
    $null = [System.Reflection.Assembly]::LoadFrom($adal)
    $null = [System.Reflection.Assembly]::LoadFrom($adalforms)

    $adTenant = $Subscription.TenantId
    # Client ID for Azure PowerShell
    $clientId = "1950a258-227b-4e31-a9cf-717495945fc2"
    # Set redirect URI for Azure PowerShell
    $redirectUri = "urn:ietf:wg:oauth:2.0:oob"

    # Authenticate and Acquire Token

    # Set Authority to Azure AD Tenant
    $authority = "https://login.windows.net/$TenantId"
    # Create Authentication Context tied to Azure AD Tenant
    $authContext = New-Object "Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext" -ArgumentList $authority
    # Acquire token
    $global:Token = $authContext.AcquireToken($resourceAppIdURI, $clientId, $redirectUri, "Auto")
    }

# Using AAD Application Service Principal
Function RestAPI-SPN-AuthToken ($TenantId, $resourceAppIdURI) {

    $Username = $Cred.Username
    $Password = $Cred.Password

    # Set Authority to Azure AD Tenant
    $authority = "https://login.windows.net/$TenantId"

    # Build up the credentials
    $ClientCred = [Microsoft.IdentityModel.Clients.ActiveDirectory.ClientCredential]::new($UserName, $Password)
    # Acquire token
    $authContext = [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext]::new($authority)
    $global:Token = $authContext.AcquireTokenAsync($resourceAppIdURI,$ClientCred)
}

Function SPNRequestHeader {

  # Create Authorization Header
  $authHeader = $global:Token.Result.CreateAuthorizationHeader()
  # Set HTTP request headers to include Authorization header | @marckean
  $requestHeader = @{
    "x-ms-version" = "2014-10-01"; #'2014-10-01'
    "Authorization" = $authHeader
  }
  return $RequestHeader
}

Function RequestHeader {

  # Create Authorization Header
  # Set HTTP request headers to include Authorization header | @marckean
  $requestHeader = @{
    "Content-Type" = "application/json"; #'2014-10-01'
    "Authorization" = "Bearer $($global:Token.AccessToken)"
  }
  return $RequestHeader
}

##########################################################################################
################################     Rest API Token     ##################################
##########################################################################################

switch -Wildcard ($SP_Password)
{
    ?* {
    RestAPI-SPN-AuthToken ($Subscription).TenantId $APIResourceURI # To Logon to Rest and get an an auth key
    $RequestHeader = SPNRequestHeader
    }

    default {
    RestAPI-AuthToken ($Subscription).TenantId $APIResourceURI
    $RequestHeader = RequestHeader
    }
}

$AADToken = $RequestHeader.Authorization

##########################################################################################
###################################    Functions     #####################################
##########################################################################################

#region Function to create and post the request
Function ChangeStorageTier($StorageTier)
{

<#
Authentication for Azure Storage is not simply a matter of providing the access key (that is not very secure).
You need to create a signature string that represents the given request,
sign the string with the HMAC-SHA256 algorithm (using your storage key to sign),
and encode the result in base 64. See https://msdn.microsoft.com/en-us/library/azure/dd179428.aspx for full details,
including how to construct the signature string.
#>

    $RFC1123date= (Get-Date -Format r)

    $method = "PUT"
    $headerDate = '2017-07-29'

    $headers = @{}
    $headers.Add("x-ms-version","$headerDate")
    $headers.Add("x-ms-date",$RFC1123date)
    $headers.Add("x-ms-access-tier",$StorageTier)
    #$headers.Add("x-ms-blob-type",'BlockBlob')

    $storageaccountname = $StgAcct.StorageAccountName
    $ContainerName = $Blob.ICloudBlob.Container.Name
    $BlobName = $Blob.ICloudBlob.Uri.AbsoluteUri -split '/' | select -Last 1
    $BlobName = $Blob.Name
    $uri = "{0}?comp=tier" -f $BlobURI

    $signatureString = "${method}`n`n`n`n`n`n`n`n`n`n`n`n"

    #Add CanonicalizedHeaders
    $signatureString += "x-ms-date:" + $headers["x-ms-date"] + "`n"
    $signatureString += "x-ms-version:" + $headers["x-ms-version"] + "`n"
    #$signatureString += "x-ms-access-tier:" + $headers["x-ms-access-tier"] + "`n"
    #$signatureString += "x-ms-blob-type:" + $headers["x-ms-blob-type"] + "`n"

    #Add CanonicalizedResource
    #$signatureString += "/$($StorageAccountName)/$($ContainerName)/$($BlobName)"
    $signatureString += "/$($StorageAccountName)/$($ContainerName)`ncomp:tier`nrestype:BlockBlob`ntimeout:20"# + "`n"
    #$signatureString += "Content-Length:" + "0"


    # Encode the signaure
    function SignWithAccountKey([string]$stringToSign, [string]$accountKey)
    {

      [Byte[]]$buffer = [Text.Encoding]::UTF8.GetBytes($stringToSign)
      [Byte[]]$key    = [System.Convert]::FromBase64String($accountKey)

      #Hash-based Message Authentication Code (HMAC) 
      $hmacsha = New-Object System.Security.Cryptography.HMACSHA256 -ArgumentList $key
      [Byte[]]$hash = $hmacsha.ComputeHash($buffer)

      $result = [System.Convert]::ToBase64String($hash)
      $result
    }


    $signature = SignWithAccountKey -stringToSign $signatureString -accountKey $StgAcctKey

    $headers.Add("Authorization", "SharedKey " + $StorageAccountName + ":" + $signature);
    $headers.Add('Content-Length', '0')
    write-host -fore green $signatureString


    $response = Invoke-RestMethod -Uri $uri -Method $method -Headers $headers
    return $response.Content | ConvertFrom-Json
}

# Question time
$StorageTiers = @('Hot', 'Cool', 'Archive')
$StorageTier = ($StorageTiers | Out-GridView -Title "Select a storage tier ..." -PassThru)

$StorageAccount        = Get-AzureRmStorageAccount    -ResourceGroupName Testing -Name somenamehere
$StorageAccountKeys    = Get-AzureRmStorageAccountKey -ResourceGroupName Testing -Name somenamehere
$StorageAccountKey     = $StorageAccountKeys[0].Value
$StorageAccountContext = New-AzureStorageContext -StorageAccountName somenamehere -StorageAccountKey $StorageAccountKey
$StorageContainers     = Get-AzureStorageContainer -Context $StorageAccountContext


# Days Retention
write-host -nonewline "Enter the number of days retention you want to set to not NOT archive blobs: " -ForegroundColor Green
[int]$DaysOld = 2 #read-host


# Cycle through all blobs in the storage account
$Blobs = @()
foreach($StorageContainer in $StorageContainers){
  $Blobs += Get-AzureStorageBlob -Context $StorageAccountContext -Container $StorageContainer.Name
}


$RetentionDate = (Get-Date).ToUniversalTime().AddDays(-$DaysOld)
$EarmarkedBlobs = $Blobs | Where-Object {$_.lastmodified.DateTime -le $RetentionDate}

$EarmarkedBlobs = $Blobs | Where-Object {$_.name -match "icecast"}
$EarmarkedBlobs | Out-GridView -Title "Blobs earmarked for Tier change ..."




# Change the Tier on the blobs
Foreach($Blob in $EarmarkedBlobs){

<#
$StartTime = Get-Date
$EndTime = $startTime.AddMinutes(5)
$SAS = New-AzureStorageBlobSASToken -Context $StgAcctContext -Container $Blob.ICloudBlob.Container.Name -Blob $Blob.ICloudBlob.Name -StartTime $StartTime -ExpiryTime $EndTime
#>

$BlobUri = $Blob.ICloudBlob.Uri.AbsoluteUri
ChangeStorageTier

}
