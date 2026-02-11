<#
.SYNOPSIS
    Simple Load Generator for AWS ALB to trigger ASG Scaling
.DESCRIPTION
    This script retrieves the ALB DNS name from Terraform outputs and sends
    concurrent HTTP requests to generate load on the target group.
#>

$ErrorActionPreference = "Stop"

Write-Host "Fetching ALB DNS name from Terraform..." -ForegroundColor Cyan
try {
    $albUrl = terraform output -raw alb_dns_name
    if (-not $albUrl) {
        Write-Error "Could not retrieve ALB DNS name. Ensure 'terraform apply' has finished successfully."
    }
}
catch {
    Write-Error "Error running terraform output. Ensure you are in the root directory."
}

$url = "http://$albUrl"
Write-Host "Target URL: $url" -ForegroundColor Green
Write-Host "Starting load test... Press Ctrl+C to stop." -ForegroundColor Yellow

$i = 0
while ($true) {
    try {
        # Send request safely ignoring response content to save memory
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -Method Head
        $i++
        if ($i % 10 -eq 0) {
            Write-Host "Sent $i requests..." -NoNewline -ForegroundColor Gray
            Write-Host "`r" -NoNewline
        }
    }
    catch {
        Write-Host "Request failed: $_" -ForegroundColor Red
    }
    # Small delay to prevent local port exhaustion but keep rate high
    Start-Sleep -Milliseconds 100
}
