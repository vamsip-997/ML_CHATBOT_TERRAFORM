###############################################################################
# Quick Deployment Status Checker
###############################################################################

$StackName = "ai-assistant-stack"
$Region = "us-east-1"

Write-Host "=========================================================================" -ForegroundColor Cyan
Write-Host "  AI Assistant - Deployment Status Checker" -ForegroundColor Cyan
Write-Host "=========================================================================" -ForegroundColor Cyan
Write-Host ""

# Get stack status
try {
    $outputs = aws cloudformation describe-stacks --stack-name $StackName --region $Region --output json | ConvertFrom-Json
    $stack = $outputs.Stacks[0]
    $status = $stack.StackStatus
    
    Write-Host "Stack Name: $StackName" -ForegroundColor White
    Write-Host "Status: $status" -ForegroundColor $(if ($status -eq "CREATE_COMPLETE") { "Green" } elseif ($status -like "*PROGRESS*") { "Yellow" } else { "Red" })
    Write-Host "Created: $($stack.CreationTime)" -ForegroundColor White
    Write-Host ""
    
    if ($status -eq "CREATE_COMPLETE") {
        Write-Host "✅ DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Deployment Information:" -ForegroundColor Cyan
        Write-Host "------------------------" -ForegroundColor Cyan
        
        foreach ($output in $stack.Outputs) {
            Write-Host "$($output.OutputKey):" -ForegroundColor Yellow
            Write-Host "  $($output.OutputValue)" -ForegroundColor White
        }
        
        Write-Host ""
        Write-Host "Next Steps:" -ForegroundColor Cyan
        Write-Host "1. Update Lambda function code with: aws lambda update-function-code ..." -ForegroundColor White
        Write-Host "2. Test the API endpoint" -ForegroundColor White
        Write-Host "3. Run: .\test-api.ps1" -ForegroundColor White
        
    } elseif ($status -like "*PROGRESS*") {
        Write-Host "⏳ Stack is still being created..." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Recent events:" -ForegroundColor Cyan
        aws cloudformation describe-stack-events --stack-name $StackName --region $Region --max-items 5 --query 'StackEvents[].[Timestamp,ResourceType,ResourceStatus]' --output table
        
    } elseif ($status -like "*FAILED*" -or $status -like "*ROLLBACK*") {
        Write-Host "❌ Stack creation failed!" -ForegroundColor Red
        Write-Host ""
        Write-Host "Failed resources:" -ForegroundColor Red
        aws cloudformation describe-stack-events --stack-name $StackName --region $Region --query 'StackEvents[?ResourceStatus==`CREATE_FAILED`].[ResourceType,ResourceStatusReason]' --output table
    }
    
    Write-Host ""
    Write-Host "AWS Console: https://console.aws.amazon.com/cloudformation/home?region=$Region#/stacks" -ForegroundColor Blue
    
} catch {
    Write-Host "❌ Error checking stack status: $_" -ForegroundColor Red
    Write-Host "Stack may not exist yet." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=========================================================================" -ForegroundColor Cyan
