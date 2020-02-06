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

#Find all VMs across all subscriptions (that I have access to), and report on whether or not they use managed disks:

#assumes you are already logged into Azure in powershell, and are using the 'Az" modules.

foreach($SubID in (Get-AzSubscription).SubscriptionId){
    set-azcontext -subscriptionid $SubID
    $output = Foreach($VM in Get-AzVM){
        new-object -type psobject -property @{
            id=$VM.id; 
            osDiskManaged=$null -eq $VM.StorageProfile.OSDisk.Vhd -and $null -ne $VM.StorageProfile.OSDisk.ManagedDisk;
            dataDiskUnmanagedCount=$(($VM.StorageProfile.datadisks.vhd |measure).count);
            dataDiskManagedCount=$(($_.StorageProfile.datadisks.ManagedDisk |measure).count)}
    } 
    $output|ft
}