param(
    [string]$PackagesDest = "\\10.0.0.55\config\packages",
    [string]$VerifyEntity,
    [switch]$ForceCopy,
    [switch]$AlwaysRestart,
    [switch]$ForceFullRestart,
    [switch]$DumpErrorLog
)

# Enhanced deployment script for AI Image Reminders package
# Author: Copilot for marka 
# Version: 2024-01-07 with comprehensive error log analysis

$ErrorActionPreference = 'Stop'
$script:airFail = $false

$packageName = "ai_image_reminders"
$repoRoot = $PSScriptRoot
$packageDest = Join-Path $PackagesDest $packageName
$baseUrl = $env:HA_BASE_URL
$token = $env:HA_TOKEN

Write-Host ""
Write-Host "=== AI Image Reminders Deployment ===" -ForegroundColor Cyan
Write-Host "Deploying AI Image Reminders package from: $repoRoot" -ForegroundColor Cyan
Write-Host "To: $packageDest" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $repoRoot)) {
    Write-Warning "Source path not found: $repoRoot"
    exit 1
}
if (-not (Test-Path $PackagesDest)) {
    Write-Host "Packages destination missing; creating: $PackagesDest" -ForegroundColor DarkGray
    New-Item -ItemType Directory -Force -Path $PackagesDest | Out-Null
}
if (-not (Test-Path $packageDest)) {
    Write-Host "Package destination missing; creating: $packageDest" -ForegroundColor DarkGray
    New-Item -ItemType Directory -Force -Path $packageDest | Out-Null
}

# Exclude specific files and directories during copy
$excludeDirs = @('.git', 'node_modules', '.vscode', '__pycache__')
$excludeFiles = @('deploy.ps1', 'deploy_fixed.ps1', 'deploy_clean.ps1', '*.log', 'README.md', 'INSTALL.md', 'FEATURES.md', 'TEST_PLAN.md', 'ARCHITECTURE.md', 'DEPLOY.md', '.gitignore', '.copilot-instructions.md')

$packagesCopied = $false

if ($ForceCopy) {
    Write-Host "Force copy enabled; skipping change detection." -ForegroundColor Yellow
    $packagesCopied = $true
}

# Use robocopy to copy files efficiently
$robocopyArgs = @($repoRoot, $packageDest, '/MIR', '/XD') + $excludeDirs + @('/XF') + $excludeFiles + @('/NJH', '/NJS', '/NP', '/LOG+:robocopy.log')
$robocopyExitCode = & robocopy @robocopyArgs
if ($robocopyExitCode -lt 0) { $robocopyExitCode = 16 }
if ($robocopyExitCode -le 7) {
    Write-Host "Robocopy OK (code $robocopyExitCode)" -ForegroundColor DarkGray
}

# Check if files were copied (codes with bit 1 set indicate files copied)
if ( ($robocopyExitCode -band 1) -ne 0 ) { $packagesCopied = $true }

if ($robocopyExitCode -gt 7) {
    Write-Warning "Robocopy reported error (code $robocopyExitCode); attempting fallback copy..."
    
    try {
        $files = Get-ChildItem -Path $repoRoot -Recurse -File | 
            Where-Object { 
                $_.Name -notmatch '\.git|node_modules|\.vscode|__pycache__|deploy\.ps1|deploy_fixed\.ps1|deploy_clean\.ps1|\.log$|README\.md|INSTALL\.md|FEATURES\.md|TEST_PLAN\.md|ARCHITECTURE\.md|DEPLOY\.md|\.gitignore|\.copilot-instructions\.md' 
            }
        foreach ($f in $files) {
            $rel = $f.FullName.Substring($repoRoot.Length).TrimStart([char[]]"/\")
            $destPath = Join-Path $packageDest $rel
            $destDir = [System.IO.Path]::GetDirectoryName($destPath)
            if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Force -Path $destDir | Out-Null }
            Copy-Item -Path $f.FullName -Destination $destPath -Force
        }
        Write-Host "Fallback copy completed" -ForegroundColor Yellow
        $packagesCopied = $true
    } catch {
        Write-Warning "Fallback copy failed: $($_.Exception.Message)"
        exit 1
    }
}

if (-not $packagesCopied) {
    if ($AlwaysRestart) {
        Write-Host "No changes detected, but -AlwaysRestart was specified. Proceeding to restart HA." -ForegroundColor Yellow
    } else {
        Write-Host "No changes detected in AI Image Reminders package. Skipping HA restart." -ForegroundColor DarkGray
        exit 0
    }
}

# HA API integration
if ([string]::IsNullOrWhiteSpace($baseUrl)) {
    if ($PackagesDest -match '^\\\\([^\\]+)\\') {
        $haHost = $Matches[1]
        $baseUrl = "http://$haHost:8123"
        Write-Host "HA_BASE_URL not set; inferring $baseUrl from share host" -ForegroundColor DarkGray
    }
}

if (-not [string]::IsNullOrWhiteSpace($baseUrl) -and -not [string]::IsNullOrWhiteSpace($token)) {
    $headers = @{ Authorization = "Bearer $token"; 'Content-Type' = 'application/json' }
    $basicHeaders = @{ Authorization = "Bearer $token" }
    
    function Get-HAErrorLogTail {
        param([string]$why)
        try {
            $logUri = "$baseUrl/api/error_log"
            $logHeaders = @{ Authorization = "Bearer $token"; 'Accept' = 'text/plain' }
            Write-Host "Fetching HA error log ($why): $logUri" -ForegroundColor DarkGray
            $logTxt = Invoke-RestMethod -Method Get -Uri $logUri -Headers $logHeaders -TimeoutSec 20 -ErrorAction Stop
            if ([string]::IsNullOrWhiteSpace($logTxt)) { 
                Write-Host "HA error log returned empty content." -ForegroundColor DarkGray
                return $true
            }
            
            $lines = $logTxt -split "`n"
            
            # Look for recent AI Image Reminders related errors
            $recentErrors = @()
            $criticalErrors = @()
            
            foreach ($line in $lines) {
                # Check if line contains AI Image Reminders related content
                if ($line -match 'ai_image_reminders|packages/ai_image_reminders|template.*kitchen|template.*family_room|template.*dog_walk|automation.*kitchen|automation.*family_room|automation.*dog_walk|input_boolean.*kitchen|input_boolean.*family_room|input_boolean.*dog') {
                    $recentErrors += $line
                    
                    # Flag critical errors
                    if ($line -match 'ERROR|CRITICAL|exception|failed|invalid|not found|TemplateError|ValueError') {
                        $criticalErrors += $line
                    }
                }
            }
            
            # Show summary first
            Write-Host "`n🔍 AI Image Reminders Error Analysis:" -ForegroundColor Cyan
            Write-Host "   Recent related log lines: $($recentErrors.Count)" -ForegroundColor $(if ($recentErrors.Count -eq 0) { 'Green' } else { 'Yellow' })
            Write-Host "   Critical errors found: $($criticalErrors.Count)" -ForegroundColor $(if ($criticalErrors.Count -eq 0) { 'Green' } else { 'Red' })
            
            if ($criticalErrors.Count -gt 0) {
                Write-Host "`n🚨 CRITICAL ERRORS FOUND:" -ForegroundColor Red
                foreach ($err in ($criticalErrors | Select-Object -Last 10)) {
                    Write-Host "   $err" -ForegroundColor Red
                }
                Write-Host ""
            }
            
            if ($recentErrors.Count -gt 0) {
                $recentTail = ($recentErrors | Select-Object -Last 50) -join "`n"
                Write-Host "--- AI Image Reminders related log lines (last 50) ---" -ForegroundColor Yellow
                Write-Host $recentTail -ForegroundColor Yellow
                Write-Host "--- end ---" -ForegroundColor Yellow
            } else {
                Write-Host "✅ No AI Image Reminders specific errors found in recent logs." -ForegroundColor Green
            }
            
            # Save detailed log if requested
            if ($env:AIR_SAVE_ERROR_LOG_TO_TEMP -match '^(1|true|yes)$') {
                $ts = Get-Date -Format 'yyyyMMdd-HHmmss'
                $tmpFile = Join-Path $env:TEMP "ha-error-log-air-$ts.log"
                $logTxt | Out-File -FilePath $tmpFile -Encoding UTF8
                Write-Host "Saved full HA error log to $tmpFile" -ForegroundColor DarkGray
            }
            
            return $criticalErrors.Count -eq 0
        } catch {
            Write-Warning "Failed to fetch HA error log: $($_.Exception.Message)"
            return $false
        }
    }
    
    # Determine which entity to verify after restart
    if ([string]::IsNullOrWhiteSpace($VerifyEntity)) {
        if (-not [string]::IsNullOrWhiteSpace($env:HA_VERIFY_ENTITY)) {
            $VerifyEntity = $env:HA_VERIFY_ENTITY
        } else {
            # Default to kitchen analysis sensor as primary verification
            $VerifyEntity = 'sensor.kitchen_analysis'
        }
    }
    
    try {
        # Quick auth check
        $cfgUri = "$baseUrl/api/config"
        Write-Host "Checking HA API: $cfgUri" -ForegroundColor DarkGray
        $cfgResp = Invoke-RestMethod -Method Get -Uri $cfgUri -Headers $headers -TimeoutSec 10 -ErrorAction Stop
        Write-Host "HA API reachable (HTTP $($cfgResp.StatusCode))." -ForegroundColor DarkGray
    } catch {
        Write-Warning "HA API check failed: $($_.Exception.Message)"
    }
    
    # Config validation
    try {
        $checkUri = "$baseUrl/api/config/core/check_config"
        Write-Host "Running HA config check: $checkUri" -ForegroundColor DarkGray
        $checkResp = Invoke-RestMethod -Method Post -Uri $checkUri -Headers $headers -TimeoutSec 30 -ErrorAction Stop
        
        $result = $checkResp.result
        if ($result -eq $false -or $result -eq "invalid") {
            Write-Warning "Config check reported INVALID configuration. Details:" 
            if ($checkResp.errors -and $checkResp.errors.Count -gt 0) {
                $checkResp.errors | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
            } else {
                Write-Host ("(No 'errors' field in response) Raw: " + ($checkResp | ConvertTo-Json -Depth 6)) -ForegroundColor Yellow
            }
            $script:airFail = $true
        } else {
            Write-Host "Config check PASSED." -ForegroundColor DarkGray
        }
    } catch {
        $msg = $_.Exception.Message
        $status = if ($_.Exception.Response) { $_.Exception.Response.StatusCode } else { "unknown" }
        if ($status -eq 404) {
            Write-Host "Config core/check_config not available (404). Falling back to service: homeassistant.check_config" -ForegroundColor DarkGray
            try {
                $svcUri = "$baseUrl/api/services/homeassistant/check_config"
                Invoke-RestMethod -Method Post -Uri $svcUri -Headers $headers -Body '{}' -TimeoutSec 30 -ErrorAction Stop | Out-Null
                Start-Sleep -Seconds 3
                
                $pnUri = "$baseUrl/api/states/persistent_notification.invalid_config"
                $pnResp = Invoke-RestMethod -Method Get -Uri $pnUri -Headers $headers -TimeoutSec 10 -ErrorAction SilentlyContinue
                if ($pnResp -and $pnResp.state -ne 'unknown') {
                    Write-Warning "Invalid configuration detected via persistent notification:"
                    $attrs = $pnResp.attributes
                    if ($attrs.message) { Write-Host "  Message: $($attrs.message)" -ForegroundColor Red }
                    $script:airFail = $true
                } else {
                    Write-Host "No invalid_config notification found; assuming config OK." -ForegroundColor DarkGray
                }
            } catch {
                Write-Warning "Fallback service check_config failed: $($_.Exception.Message)"
            }
        } else {
            Write-Warning "Config check call failed: $msg (HTTP $status). Proceeding to restart."
        }
    }
    
    # Skip restart if config is invalid
    if ($script:airFail) {
        Write-Host "Skipping restart due to invalid configuration." -ForegroundColor Yellow
        exit 2
    }
    
    # Try YAML reload first (faster than full restart)
    if (-not $ForceFullRestart) {
        Write-Host "Attempting YAML reload instead of full restart..." -ForegroundColor Cyan
        
        $reloadServices = @('automation', 'template', 'input_boolean', 'input_datetime', 'input_number', 'input_text', 'script')
        $reloadSuccess = $true
        
        foreach ($serviceName in $reloadServices) {
            try {
                $serviceUri = "$baseUrl/api/services/$serviceName/reload"
                Invoke-RestMethod -Method Post -Uri $serviceUri -Headers $headers -Body '{}' -TimeoutSec 30 -ErrorAction Stop | Out-Null
                Write-Host "✅ Reloaded $serviceName" -ForegroundColor Green
            } catch {
                $reloadSuccess = $false
                Write-Warning "❌ Failed to reload $serviceName : $($_.Exception.Message)"
            }
        }
        
        if ($reloadSuccess) {
            # Wait a moment for reload to complete
            Start-Sleep -Seconds 2
            
            # Check error logs after reload for any issues
            Write-Host "Checking error logs after YAML reload..." -ForegroundColor DarkGray
            $logAnalysisOk = Get-HAErrorLogTail -why 'post-yaml-reload'
            
            if ($logAnalysisOk) {
                Write-Host "YAML reload completed successfully with no critical errors! ✨" -ForegroundColor Green
                
                # Optional entity verification
                if (-not [string]::IsNullOrWhiteSpace($VerifyEntity)) {
                    Write-Host "Verifying entity availability: $VerifyEntity (timeout 30s)" -ForegroundColor DarkGray
                    
                    $timeout = 30
                    $verified = $false
                    for ($i = 0; $i -lt $timeout; $i++) {
                        try {
                            $stateUri = "$baseUrl/api/states/$VerifyEntity"
                            $state = Invoke-RestMethod -Method Get -Uri $stateUri -Headers $headers -TimeoutSec 10 -ErrorAction Stop
                            if ($state -and $state.state -ne 'unavailable' -and $state.state -ne 'unknown') {
                                Write-Host "✅ Entity $VerifyEntity is available with state: $($state.state)" -ForegroundColor Green
                                $verified = $true
                                break
                            }
                        } catch {
                            # Entity not found or unavailable, continue waiting
                        }
                        Start-Sleep -Seconds 1
                    }
                    
                    if (-not $verified) {
                        Write-Warning "Entity $VerifyEntity was not available within ${timeout}s after YAML reload."
                    }
                }
                
                Write-Host "AI Image Reminders deployment completed via YAML reload! 🎉" -ForegroundColor Green
                exit 0
            } else {
                Write-Warning "YAML reload succeeded but critical errors found in logs. Consider reviewing configuration."
                Write-Host "Continuing with deployment but monitoring recommended." -ForegroundColor Yellow
                exit 0
            }
        } else {
            Write-Warning "YAML reload partially failed. Falling back to full restart..."
        }
    } else {
        Write-Host "ForceFullRestart specified, skipping YAML reload and proceeding with full restart." -ForegroundColor Yellow
    }
    
    # Full HA restart
    $uri = "$baseUrl/api/services/homeassistant/restart"
    try {
        Write-Host "Requesting HA Core restart via REST: $uri" -ForegroundColor Cyan
        $resp = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body '{}' -TimeoutSec 30 -ErrorAction Stop
        Write-Host "HA restart requested (HTTP $($resp.StatusCode))." -ForegroundColor Green
    } catch {
        $msg = $_.Exception.Message
        $status = if ($_.Exception.Response) { $_.Exception.Response.StatusCode } else { "unknown" }
        
        if ($status -eq 503 -or $msg -match "Service Unavailable|restart") {
            Write-Warning "HA restart REST call failed: $msg (HTTP $status)"
            if ($status -eq 503) {
                Write-Host "Restart likely in progress; HA may be temporarily unavailable." -ForegroundColor Yellow
            }
            
            # Retry once after a brief delay
            try {
                Start-Sleep -Seconds 5
                $resp2 = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body '{}' -TimeoutSec 15 -ErrorAction Stop
                Write-Host "HA restart requested on retry (HTTP $($resp2.StatusCode))." -ForegroundColor Green
            } catch {
                Write-Warning "HA restart retry failed: $($_.Exception.Message)"
            }
        }
    }
    
    # Wait for HA to restart
    $maxWait = 120
    $elapsed = 0
    $pingStart = Get-Date
    $wasDown = $false
    
    Write-Host "Waiting up to $maxWait s for HA to come back online..." -ForegroundColor DarkGray
    while ($elapsed -lt $maxWait) {
        try {
            $ping = Invoke-WebRequest -Method Get -Uri "$baseUrl/api/config" -Headers $headers -TimeoutSec 10 -ErrorAction Stop
            if ($ping.StatusCode -eq 200) {
                Write-Host "HA back online after ${elapsed}s (HTTP 200)." -ForegroundColor Green
                break
            }
        } catch {
            $wasDown = $true
        }
        
        Start-Sleep -Seconds 2
        $elapsed = [int]((Get-Date) - $pingStart).TotalSeconds
    }
    
    if ($elapsed -ge $maxWait) {
        Write-Warning "HA did not respond with HTTP 200 within $maxWait s; it may still be restarting."
    }
    
    # Sanity check: if HA never appeared down, the restart might not have worked
    if (-not $wasDown -and $elapsed -lt 10) {
        Write-Warning "No downtime observed after restart request; restart likely did not occur."
    }
    
    # Wait additional time for full initialization
    if ($elapsed -lt $maxWait) {
        Write-Host "Waiting additional 10s for HA to fully initialize..." -ForegroundColor DarkGray
        Start-Sleep -Seconds 10
    }
    
    # Verify specific entity is available after restart
    if (-not [string]::IsNullOrWhiteSpace($VerifyEntity)) {
        $verifyMaxWait = 60
        Write-Host "Verifying entity availability: $VerifyEntity (timeout ${verifyMaxWait}s)" -ForegroundColor DarkGray
        
        $verifyStart = Get-Date
        $entityVerified = $false
        while (((Get-Date) - $verifyStart).TotalSeconds -lt $verifyMaxWait) {
            try {
                $stateResp = Invoke-WebRequest -Method Get -Uri "$baseUrl/api/states/$VerifyEntity" -Headers $headers -TimeoutSec 10 -ErrorAction Stop
                if ($stateResp.StatusCode -eq 200) {
                    $stateData = $stateResp.Content | ConvertFrom-Json
                    if ($stateData -and $stateData.state -and $stateData.state -ne 'unavailable' -and $stateData.state -ne 'unknown') {
                        $st = $stateData.state
                        Write-Host "Entity $VerifyEntity is available with state: $st" -ForegroundColor Green
                        $entityVerified = $true
                        break
                    }
                }
            } catch {
                # Continue waiting
            }
            Start-Sleep -Seconds 2
        }
        
        if (-not $entityVerified) {
            Write-Warning "Entity $VerifyEntity was not available within ${verifyMaxWait}s. Possible regression introduced."
            $script:airFail = $true
        }
    }
    
    # Optional: verify a few key entities exist
    $keyEntities = @('sensor.kitchen_analysis', 'input_boolean.kitchen_monitoring_enabled', 'automation.kitchen_monitoring')
    foreach ($entity in $keyEntities) {
        if (-not [string]::IsNullOrWhiteSpace($entity)) {
            try {
                $entityResp = Invoke-WebRequest -Method Get -Uri "$baseUrl/api/states/$entity" -Headers $headers -TimeoutSec 10 -ErrorAction SilentlyContinue
                if ($entityResp.StatusCode -eq 200) {
                    $entityData = $entityResp.Content | ConvertFrom-Json
                    $entityState = if ($entityData.state) { $entityData.state } else { "(no state)" }
                    Write-Host "Verified $entity = $entityState" -ForegroundColor DarkGray
                } else {
                    Write-Warning "Key entity $entity not found or unavailable"
                    $script:airFail = $true
                }
            } catch {
                Write-Warning "Failed to verify entity $entity : $($_.Exception.Message)"
                $script:airFail = $true
            }
        }
    }
    
    # Optional: always dump error log after restart (useful when diagnosing load issues)
    if ($DumpErrorLog) { 
        Get-HAErrorLogTail -why 'post-restart (requested)' | Out-Null
    }
} else {
    Write-Host "Skipping HA restart (set HA_BASE_URL and HA_TOKEN to enable)." -ForegroundColor DarkGray
}

if ($script:airFail) {
    # Non-zero exit to indicate verification failure
    exit 2
}

Write-Host "AI Image Reminders package deployment completed successfully!" -ForegroundColor Green
exit 0
