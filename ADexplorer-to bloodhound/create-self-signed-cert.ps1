# Create a self-signed certificate for script signing
# This allows you to sign your own scripts

Write-Host "Creating self-signed certificate for script signing..." -ForegroundColor Yellow

try {
    # Create a self-signed certificate
    $cert = New-SelfSignedCertificate -Type CodeSigningCert -Subject "CN=ADExplorerConverter" -KeyUsage DigitalSignature -FriendlyName "ADExplorer Converter" -CertStoreLocation "Cert:\CurrentUser\My" -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.3")
    
    Write-Host "✓ Certificate created successfully" -ForegroundColor Green
    Write-Host "  Subject: $($cert.Subject)" -ForegroundColor Gray
    Write-Host "  Thumbprint: $($cert.Thumbprint)" -ForegroundColor Gray
    
    # Export the certificate to a file
    $certPath = ".\ADExplorerConverter.cer"
    Export-Certificate -Cert $cert -FilePath $certPath
    Write-Host "✓ Certificate exported to: $certPath" -ForegroundColor Green
    
    # Sign the main conversion script
    $scriptPath = ".\Convert-ADExplorer.ps1"
    if (Test-Path $scriptPath) {
        Set-AuthenticodeSignature -FilePath $scriptPath -Certificate $cert
        Write-Host "✓ Script signed successfully" -ForegroundColor Green
    }
    
    Write-Host "`nTo trust this certificate on other machines:" -ForegroundColor Cyan
    Write-Host "1. Copy $certPath to the target machine" -ForegroundColor Gray
    Write-Host "2. Run: Import-Certificate -FilePath '$certPath' -CertStoreLocation 'Cert:\LocalMachine\TrustedPublisher'" -ForegroundColor Gray
    
}
catch {
    Write-Host "✗ Failed to create certificate: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "You may need to run PowerShell as Administrator" -ForegroundColor Yellow
}
