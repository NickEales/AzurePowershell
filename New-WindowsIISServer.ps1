# we have a need to setup a Windows VM with IIS for simple network testing.. 

# Variables for common values
$resourceGroup = "testRG"
$location = "australiaeast"
$vmName = "testIISVM"
$subId = 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee'

Set-AzContext -Subscription $subId

# Create user object
$cred = Get-Credential -Message "Enter a username and password for the virtual machine."

# Create a resource group
if(!(get-AzResourceGroup -Name $resourceGroup -ErrorAction SilentlyContinue)){New-AzResourceGroup -Name $resourceGroup -Location $location -Verbose}

# Create a virtual machine
New-AzVM `
  -ResourceGroupName $resourceGroup `
  -Name $vmName `
  -Location $location `
  -ImageName "Win2016Datacenter" `
  -VirtualNetworkName "myVnet" `
  -SubnetName "mySubnet" `
  -SecurityGroupName "myNetworkSecurityGroup" `
  -PublicIpAddressName "myPublicIp" `
  -Credential $cred `
  -OpenPorts 80 `
  -verbose

#get public IP address for display & later testing
$azVM = get-azvm -ResourceGroupName $resourceGroup -Name $vmName
$azNetworkInterface = Get-AzNetworkInterface -ResourceId $azVM.NetworkProfile.NetworkInterfaces.id
$PublicIPAddressResource = Get-AzPublicIpAddress -ResourceGroupName $resourceGroup | where id -eq $azNetworkInterface.IpConfigurations.PublicIpAddress.id 
write-host "Public IP: $($PublicIPAddressResource.IpAddress) (FQDN: '$($PublicIPAddressResource.DnsSettings.Fqdn )')"


# Install IIS
$PublicSettingsJson = @{commandToExecute= "powershell.exe Install-WindowsFeature -name Web-Server -IncludeManagementTools && powershell.exe remove-item 'C:\\inetpub\\wwwroot\\iisstart.htm' && powershell.exe Add-Content -Path 'C:\\inetpub\\wwwroot\\iisstart.htm' -Value `$('Hello World from ' + `$env:computername)"}
$PublicSettings = $PublicSettingsJson | ConvertTo-Json

Set-AzVMExtension -ExtensionName "IIS" -ResourceGroupName $resourceGroup -VMName $vmName `
  -Publisher "Microsoft.Compute" -ExtensionType "CustomScriptExtension" -TypeHandlerVersion 1.4 `
  -SettingString $PublicSettings -Location $location `
  -verbose 

#display output of http request to VM, showing that it is working. 
get-date -format u
(curl "http://$($PublicIPAddressResource.IpAddress)" -usebasicparsing -TimeoutSec 1).content