# Unblock all PowerShell scripts in the current directory
# This removes the "Zone.Identifier" alternate data stream that marks files as downloaded

Write-Host "Unblocking PowerShell scripts..." -ForegroundColor Yellow

# Unblock all .ps1 files in current directory
Get-ChildItem -Path "." -Filter "*.ps1" | ForEach-Object {
    try {
        Unblock-File -Path $_.FullName
        Write-Host "✓ Unblocked: $($_.Name)" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Failed to unblock: $($_.Name) - $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Unblock all .psm1 files in current directory
Get-ChildItem -Path "." -Filter "*.psm1" | ForEach-Object {
    try {
        Unblock-File -Path $_.FullName
        Write-Host "✓ Unblocked: $($_.Name)" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Failed to unblock: $($_.Name) - $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nScript unblocking completed!" -ForegroundColor Green
Write-Host "You can now run the scripts normally." -ForegroundColor Cyan
