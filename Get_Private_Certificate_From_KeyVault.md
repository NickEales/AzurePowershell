Getting a certificate from key vault using PowerShell – while it isn’t obvious also isn’t hard. I’m putting this sample code here for me to use as a reference – but feel free to use & adjust it as you want.

A few key points first about certificates in Key Vault.
- BYO certificates when loaded into key vault are added using the *AzureKeyVaultCertificate* powershell cmdlets.
Key Vault can generate self-signed certificates using the New-AzureKeyVaultCertificatePolicy cmdlet with ‘-IssuerName Self’ and the Add-AzureKeyVaultCertificate cmdlet
- Private Certificates can then be accessed using the Get-AzureKeyVaultSecret cmdlet
- Public Certificates  can then be accessed using the Get-AzureKeyVaultKey cmdlet.
- Access to run each cmdlet is governed through a range of access policies. E.g. ‘Get’ rights on ‘secret’ objects lets you get a secret (e.g. by running Get-AzureKeyVaultSecret with ’-name’), and ‘List’ rights on ‘key’ objects lets you list the keys (e.g. by running Get-AzureKeyVaultKey without ’-name’).
- the below script assumes that you have authenticated to Key Vault and have permissions for the get operation.

anyway.. some code to get private certificates and make them available for a few difference purposes (the main point of this post):

        #get Secret object (Containing private key) from Key Vault
        $AzureKeyVaultSecret=Get-AzureKeyVaultSecret -VaultName $VaultName -Name $CertificateName -ErrorAction SilentlyContinue

        #Convert private cert to bytes
        $PrivateCertKVBytes = [System.Convert]::FromBase64String($AzureKeyVaultSecret.SecretValueText)

        #Convert Bytes to Certificate (flagged as exportable & retaining private key)
        #possible flags: https://msdn.microsoft.com/en-us/library/system.security.cryptography.x509certificates.x509keystorageflags(v=vs.110).aspx
        $certObject = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 -argumentlist $PrivateCertKVBytes,$null, "Exportable, PersistKeySet"


        #Optional: import certificate to current user Certificate store
        $Certificatestore = New-Object System.Security.Cryptography.X509Certificates.X509Store -argumentlist "My","Currentuser"
        $Certificatestore.open("readWrite")
        $Certificatestore.Add($certObject)
        $Certificatestore.Close()

        #if private certificate needs to be exported, then it needs a password - create Temporary Random Password for certificate
        $PasswordLength=20
        $ascii = 33..126 | %{[char][byte]$_}
        $CertificatePfxPassword = $(0..$passwordLength | %{$ascii | get-random}) -join ""
        # Alternative Method:
        $CertificatePfxPassword = [system.guid]::Newguid().ToString().Replace('-','').Trim(20)

        #Encrypt private Certificate using password (required if exporting to file or memory for use in ARM template)
        $protectedCertificateBytes = $certObject.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Pkcs12,
        $CertificatePfxPassword)
        Write-output "Private Certificate Password: '$CertificatePfxPassword'"

        #Optional: Export encrypted certificate to Base 64 String in memory (for use in ARM templates / other):
        $InternetPfxCertdata = [System.Convert]::ToBase64String($protectedCertificateBytes)

        #Optional: Export encrypted certificate to file on desktop:
        $pfxPath = '{0}\{1}.pfx' -f [Environment]::GetFolderPath("Desktop") ,$CertificateName
        [System.IO.File]::WriteAllBytes($pfxPath, $protectedCertificateBytes)

While the above example is for getting a private certificate, getting a public certificate is similar & simpler. (use Get-AzureKeyVaultKey instead / a slight change to the flags if importing it locally / no need to encrypt if exporting to a .CER file).
