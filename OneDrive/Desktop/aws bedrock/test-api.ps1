###############################################################################
# AI Assistant - API Testing Script (PowerShell)
# Comprehensive tests for all response types
###############################################################################

# Get API endpoint from deployment info
if (Test-Path "deployment-info.txt") {
    $content = Get-Content "deployment-info.txt" -Raw
    $apiEndpoint = ($content -split "`n" | Where-Object { $_ -match "API Endpoint:" }) -replace "API Endpoint: ", ""
    $apiEndpoint = $apiEndpoint.Trim()
}
else {
    Write-Error "deployment-info.txt not found. Please deploy first."
    exit 1
}

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "  AI Assistant API Test Suite" -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "API Endpoint: $apiEndpoint" -ForegroundColor Yellow
Write-Host ""

# Test 1: General Question
Write-Host "Test 1: General Question" -ForegroundColor Green
Write-Host "------------------------"
$body1 = @{
    user_input = "What is Python programming?"
    response_type = "general"
} | ConvertTo-Json

Invoke-RestMethod -Uri $apiEndpoint -Method Post -Body $body1 -ContentType "application/json" | ConvertTo-Json -Depth 5
Write-Host ""
Start-Sleep -Seconds 2

# Test 2: Code Help
Write-Host "Test 2: Code Help" -ForegroundColor Green
Write-Host "------------------------"
$body2 = @{
    user_input = "How to reverse a string in Python?"
    response_type = "code"
} | ConvertTo-Json

Invoke-RestMethod -Uri $apiEndpoint -Method Post -Body $body2 -ContentType "application/json" | ConvertTo-Json -Depth 5
Write-Host ""
Start-Sleep -Seconds 2

# Test 3: Explanation
Write-Host "Test 3: Detailed Explanation" -ForegroundColor Green
Write-Host "------------------------"
$body3 = @{
    user_input = "Machine Learning"
    response_type = "explain"
} | ConvertTo-Json

Invoke-RestMethod -Uri $apiEndpoint -Method Post -Body $body3 -ContentType "application/json" | ConvertTo-Json -Depth 5
Write-Host ""
Start-Sleep -Seconds 2

# Test 4: Summary
Write-Host "Test 4: Summary" -ForegroundColor Green
Write-Host "------------------------"
$body4 = @{
    user_input = "Benefits of cloud computing"
    response_type = "summarize"
} | ConvertTo-Json

Invoke-RestMethod -Uri $apiEndpoint -Method Post -Body $body4 -ContentType "application/json" | ConvertTo-Json -Depth 5
Write-Host ""
Start-Sleep -Seconds 2

# Test 5: Blog Post (Backward Compatible)
Write-Host "Test 5: Blog Post (Backward Compatible)" -ForegroundColor Green
Write-Host "------------------------"
$body5 = @{
    blog_topic = "Artificial Intelligence"
    word_count = 200
    output_format = "text"
} | ConvertTo-Json

Invoke-RestMethod -Uri $apiEndpoint -Method Post -Body $body5 -ContentType "application/json" | ConvertTo-Json -Depth 5
Write-Host ""
Start-Sleep -Seconds 2

# Test 6: HTML Output
Write-Host "Test 6: HTML Output Format" -ForegroundColor Green
Write-Host "------------------------"
$body6 = @{
    user_input = "Web Development"
    response_type = "explain"
    output_format = "html"
} | ConvertTo-Json

Invoke-RestMethod -Uri $apiEndpoint -Method Post -Body $body6 -ContentType "application/json" | ConvertTo-Json -Depth 5
Write-Host ""
Start-Sleep -Seconds 2

# Test 7: Markdown Output
Write-Host "Test 7: Markdown Output Format" -ForegroundColor Green
Write-Host "------------------------"
$body7 = @{
    user_input = "Data Structures"
    response_type = "explain"
    output_format = "markdown"
} | ConvertTo-Json

Invoke-RestMethod -Uri $apiEndpoint -Method Post -Body $body7 -ContentType "application/json" | ConvertTo-Json -Depth 5
Write-Host ""
Start-Sleep -Seconds 2

# Test 8: Error Handling - Empty Input
Write-Host "Test 8: Error Handling - Empty Input" -ForegroundColor Green
Write-Host "------------------------"
$body8 = @{
    user_input = ""
    response_type = "general"
} | ConvertTo-Json

try {
    Invoke-RestMethod -Uri $apiEndpoint -Method Post -Body $body8 -ContentType "application/json" | ConvertTo-Json -Depth 5
}
catch {
    Write-Host "Expected error: $_" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "  Test Suite Complete" -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
