# File Encryption/Decryption Script

function Encrypt-Files {
    param (
        [string]$certificatePath,
        [string]$itemsToEncrypt
    )

    # Import the certificate
    $password = Read-Host "Enter the certificate password" -AsSecureString
    $cert = Import-PfxCertificate -FilePath $certificatePath -CertStoreLocation Cert:\CurrentUser\My -Password $password

    # Process each item (file or folder)
    $items = $itemsToEncrypt -split ','
    foreach ($item in $items) {
        $item = $item.Trim()
        if (Test-Path $item -PathType Container) {
            # It's a folder, encrypt all files in it
            Get-ChildItem $item -File -Recurse | ForEach-Object {
                Protect-CmsMessage -Path $_.FullName -To $cert.Thumbprint -OutFile "$($_.FullName).tmp"
                Remove-Item $_.FullName
                Rename-Item "$($_.FullName).tmp" "$($_.FullName).encrypted"
                Write-Host "Encrypted and replaced: $($_.FullName)"
            }
        } elseif (Test-Path $item -PathType Leaf) {
            # It's a file, encrypt it
            Protect-CmsMessage -Path $item -To $cert.Thumbprint -OutFile "$item.tmp"
            Remove-Item $item
            Rename-Item "$item.tmp" "$item.encrypted"
            Write-Host "Encrypted and replaced: $item"
        } else {
            Write-Host "Invalid path: $item"
        }
    }
}

function Decrypt-Files {
    param (
        [string]$certificatePath,
        [string]$itemsToDecrypt
    )

    # Import the certificate
    $password = Read-Host "Enter the certificate password" -AsSecureString
    Import-PfxCertificate -FilePath $certificatePath -CertStoreLocation Cert:\CurrentUser\My -Password $password

    # Process each item (file or folder)
    $items = $itemsToDecrypt -split ','
    foreach ($item in $items) {
        $item = $item.Trim()
        if (Test-Path $item -PathType Container) {
            # It's a folder, decrypt all .encrypted files in it
            Get-ChildItem $item -File -Filter *.encrypted -Recurse | ForEach-Object {
                $decryptedPath = $_.FullName -replace '\.encrypted$',''
                # Capture the decrypted message into a variable
                $decryptedMessage = Unprotect-CmsMessage -Path $_.FullName
                # Write the decrypted message to the original path
                Set-Content -Path "$decryptedPath.tmp" -Value $decryptedMessage
                Remove-Item $_.FullName
                Rename-Item "$decryptedPath.tmp" $decryptedPath
                Write-Host "Decrypted and replaced: $($_.FullName)"
            }
        } elseif (Test-Path $item -PathType Leaf -and $item -like '*.encrypted') {
            # It's a file, decrypt it
            $decryptedPath = $item -replace '\.encrypted$',''
            # Capture the decrypted message into a variable
            $decryptedMessage = Unprotect-CmsMessage -Path $item
            # Write the decrypted message to the original path
            Set-Content -Path "$decryptedPath.tmp" -Value $decryptedMessage
            Remove-Item $item
            Rename-Item "$decryptedPath.tmp" $decryptedPath
            Write-Host "Decrypted and replaced: $item"
        } else {
            Write-Host "Invalid path or file is not encrypted: $item"
        }
    }
}

# Main script logic
$action = Read-Host "Enter 'encrypt' to encrypt files or 'decrypt' to decrypt files"
$certificatePath = Read-Host "Enter the full path to your certificate file"

if ($action -eq 'encrypt') {
    $itemsToProcess = Read-Host "Enter the paths of files or folders to encrypt, separated by commas"
    Encrypt-Files -certificatePath $certificatePath -itemsToEncrypt $itemsToProcess
} elseif ($action -eq 'decrypt') {
    $itemsToProcess = Read-Host "Enter the paths of files or folders to decrypt, separated by commas"
    Decrypt-Files -certificatePath $certificatePath -itemsToDecrypt $itemsToProcess
} else {
    Write-Host "Invalid action. Please run the script again and enter 'encrypt' or 'decrypt'."
}
