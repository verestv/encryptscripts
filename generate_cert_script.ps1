# Certificate Generation Script
function Generate-Certificate {
    param (
        [string]$subject,
        [string]$exportPath,
        [SecureString]$password
    )

    # Generate the certificate
    $cert = New-SelfSignedCertificate -Subject "CN=$subject" -CertStoreLocation "Cert:\CurrentUser\My" -KeyUsage KeyEncipherment,DataEncipherment -Type DocumentEncryptionCert

    # Export the certificate
    Export-PfxCertificate -Cert $cert -FilePath $exportPath -Password $password

    return $cert
}

# Main script
$subject = Read-Host "Enter a name for your certificate (e.g., YourName)"
$exportPath = Read-Host "Enter the full path where you want to save the certificate (e.g., C:\Certificates\MyCert.pfx)"
$passwordString = Read-Host "Enter a strong password to protect your certificate" -AsSecureString

# Generate and export the certificate
$cert = Generate-Certificate -subject $subject -exportPath $exportPath -password $passwordString

# Display certificate information
Write-Host "Certificate generated successfully!"
Write-Host "Subject: $($cert.Subject)"
Write-Host "Thumbprint: $($cert.Thumbprint)"
Write-Host "Exported to: $exportPath"
Write-Host "Please remember your password and keep it secure."
