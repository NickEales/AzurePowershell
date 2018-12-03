
I wanted to run sysprep on a Azure VM to create an image, hopefully without needing to login / connect directly to the VM.


1. create a powershell script file, and save it to a new file 'sysprep.ps1':
        param([switch]$runSysprep=$false)
        write-output "Sysprep Script Run, parameter 'runSysprep': $runSysprep"

        if($runSysprep){
        write-output "starting Sysprep"
        Start-Process -FilePath C:\Windows\System32\Sysprep\Sysprep.exe -ArgumentList '/generalize /oobe /shutdown /quiet'
        write-output "started Sysprep"
        }else{
        write-output "skipping Sysprep"
        }


2. upload this to a storage account, set the security on the container to ‘blob’ (there's nothing sensitive in that script), then ran the following:

        $VMName =  'vmName'
        $VMRG = 'vmResourceGroup'
        $VMLocation = 'AustraliaEast'
        $ExtensionName = 'runsysprep'
        $Scripturi = 'https://<storageAccountName>.blob.core.windows.net/templates/scripts/sysprep.ps1'
        Set-AzureRmVMCustomScriptExtension -FileUri $ScriptURI -ResourceGroupName  $VMRG -VMName $VMName -Name $ExtensionName -Location $VMLocation -run './sysprep.ps1' -Argument '-runSysprep'


This gave the output:

        RequestId IsSuccessStatusCode StatusCode ReasonPhrase
        --------- ------------------- ---------- ------------
                                True         OK OK

To see the output messages from the script that was run:

        $status = Get-AzureRmVMDiagnosticsExtension -ResourceGroupName $VMRG -VMName $VMName -Name $ExtensionName -Status
        $status.SubStatuses.message

This displayed the output that was expected:

        Sysprep Script Run, parameter 'runSysprep': True\nstarting Sysprep\nstarted Sysprep

A short time later, the VM is shutdown (but is still allocated & incurring charges), so i then shutdown the VM:

        Stop-AzureRmVM -Name $VMName -ResourceGroupName $VMRG  -force
