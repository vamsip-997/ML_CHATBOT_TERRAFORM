###############################################################################
# Fix Deployment Issues Script
# Resolves dependency conflicts and file lock issues
###############################################################################

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "  Fixing Deployment Issues" -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Kill any processes that might be locking the zip file
Write-Host "[INFO] Checking for file locks on lambda_deployment.zip..." -ForegroundColor Blue
if (Test-Path "lambda_deployment.zip") {
    try {
        # Try to remove it
        Remove-Item -Force lambda_deployment.zip -ErrorAction Stop
        Write-Host "[SUCCESS] Removed old lambda_deployment.zip" -ForegroundColor Green
    }
    catch {
        Write-Host "[WARNING] File is locked. Attempting to unlock..." -ForegroundColor Yellow
        
        # Get processes that might have the file open
        $processes = Get-Process | Where-Object {
            $_.Path -and ($_.Name -match "python|pip|explorer")
        }
        
        if ($processes) {
            Write-Host "[INFO] Found processes that might be locking files:" -ForegroundColor Blue
            $processes | Select-Object Name, Id | Format-Table
            
            $answer = Read-Host "Do you want to close these processes? (y/n)"
            if ($answer -eq 'y' -or $answer -eq 'Y') {
                $processes | ForEach-Object {
                    try {
                        Stop-Process -Id $_.Id -Force
                        Write-Host "[INFO] Stopped process: $($_.Name) (PID: $($_.Id))" -ForegroundColor Blue
                    }
                    catch {
                        Write-Host "[WARNING] Could not stop process: $($_.Name)" -ForegroundColor Yellow
                    }
                }
                Start-Sleep -Seconds 2
            }
        }
        
        # Try again
        try {
            Remove-Item -Force lambda_deployment.zip -ErrorAction Stop
            Write-Host "[SUCCESS] Removed locked file" -ForegroundColor Green
        }
        catch {
            Write-Host "[ERROR] Still cannot remove file. Please close any programs that might be using it." -ForegroundColor Red
            Write-Host "[INFO] Press any key after closing the programs, or Ctrl+C to exit..." -ForegroundColor Blue
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            Remove-Item -Force lambda_deployment.zip -ErrorAction Stop
        }
    }
}

# Step 2: Clean up lambda_package directory completely
Write-Host "[INFO] Cleaning up lambda_package directory..." -ForegroundColor Blue
if (Test-Path "lambda_package") {
    Remove-Item -Recurse -Force lambda_package -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
}
Write-Host "[SUCCESS] Old package directory removed" -ForegroundColor Green

# Step 3: Create fresh package directory
Write-Host "[INFO] Creating fresh package directory..." -ForegroundColor Blue
New-Item -ItemType Directory -Path "lambda_package" -Force | Out-Null

# Step 4: Copy Lambda function
Write-Host "[INFO] Copying Lambda function code..." -ForegroundColor Blue
Copy-Item "lambda_function.py" "lambda_package/"

# Step 5: Install dependencies with upgrade flag to fix conflicts
Write-Host "[INFO] Installing dependencies (this will fix urllib3 conflict)..." -ForegroundColor Blue
Write-Host "[INFO] Using --upgrade flag to resolve dependency conflicts..." -ForegroundColor Blue

# Install with upgrade and ignore conflicts
pip install -r requirements_lambda.txt -t lambda_package/ --upgrade --no-warn-script-location 2>&1 | ForEach-Object {
    if ($_ -match "ERROR|Successfully installed") {
        Write-Host $_ -ForegroundColor $(if ($_ -match "ERROR") { "Red" } else { "Green" })
    }
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "[WARNING] Some pip warnings occurred, but installation may have succeeded" -ForegroundColor Yellow
}

# Step 6: Verify lambda_function.py is present
Write-Host "[INFO] Verifying package contents..." -ForegroundColor Blue
if (Test-Path "lambda_package/lambda_function.py") {
    Write-Host "[SUCCESS] lambda_function.py found in package" -ForegroundColor Green
} else {
    Write-Host "[ERROR] lambda_function.py not found in package!" -ForegroundColor Red
    exit 1
}

# Step 7: Create deployment zip using Python (more reliable than Compress-Archive)
Write-Host "[INFO] Creating deployment package..." -ForegroundColor Blue
python create_deployment_package.py

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "[SUCCESS] Deployment package fixed successfully!" -ForegroundColor Green
    Write-Host ""
    
    if (Test-Path "lambda_deployment.zip") {
        $packageSize = (Get-Item lambda_deployment.zip).Length / 1MB
        Write-Host "[INFO] Package size: $([math]::Round($packageSize, 2)) MB" -ForegroundColor Blue
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Cyan
        Write-Host "1. Run: .\deploy.ps1" -ForegroundColor White
        Write-Host "   OR" -ForegroundColor Yellow
        Write-Host "2. Upload lambda_deployment.zip manually to AWS Lambda" -ForegroundColor White
        Write-Host ""
    } else {
        Write-Host "[ERROR] lambda_deployment.zip was not created" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "[ERROR] Failed to create deployment package" -ForegroundColor Red
    exit 1
}
