﻿param(
    [string]$PackagesDest = "\\10.0.0.55\config\packages",
    [string]$VerifyEntity,
    [switch]$DumpErrorLog,
    [switch]$DumpErrorLogOnFail,
    [switch]$FailOnNoRestart,
    [switch]$ForceCopy,
    [switch]$AlwaysRestart,
    [switch]$ForceFullRestart
)

# Resolve repo root relative to this script
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = $scriptDir  # For this package, the script is in the root
$packageName = "ai_image_reminders"
$packageDest = Join-Path $PackagesDest $packageName

# Track verification failure to signal regressions via exit code
$script:airFail = $false
$packagesCopied = $false
$restartAttempted = $false
$restartAccepted = $false
$sawDowntime = $false

Write-Host "Deploying AI Image Reminders package from: $repoRoot" -ForegroundColor Cyan
Write-Host "To: $packageDest" -ForegroundColor Cyan

if (-not (Test-Path $repoRoot)) {
    Write-Warning "Source path not found: $repoRoot"
    exit 0
}
if (-not (Test-Path $PackagesDest)) {
    Write-Host "Packages destination missing; creating: $PackagesDest" -ForegroundColor DarkGray
    New-Item -ItemType Directory -Force -Path $PackagesDest | Out-Null
}
if (-not (Test-Path $packageDest)) {
    Write-Host "Package destination missing; creating: $packageDest" -ForegroundColor DarkGray
    New-Item -ItemType Directory -Force -Path $packageDest | Out-Null
}

# Copy package files, exclude git/docs/scripts; /FFT for FAT time granularity on Samba; /IS include same (force overwrite)
$robocopyArgs = @(
    $repoRoot,
    $packageDest,
    '*.*','/E','/R:2','/W:2','/FFT',
    '/XF','*.md','*.ps1','deploy.ps1','*.git*',
    '/XD','.git','.github','scripts'
)
if ($ForceCopy) {
    # Include same and tweaked to force copying even if timestamps/sizes look identical on Samba
    $robocopyArgs += @('/IS','/IT')
}

# Run and capture exit code; treat 0..7 as success per Robocopy semantics
& robocopy $robocopyArgs | Out-Null
$code = $LASTEXITCODE
if ($code -lt 0) { $code = 16 }
if ($code -le 7) {
    Write-Host "Robocopy OK (code $code)" -ForegroundColor DarkGray
}

# Mark package changes if any files were copied (bit 0x01)
if ( ($code -band 1) -ne 0 ) { $packagesCopied = $true }

if ($code -gt 7) {
    # Fallback: Copy-Item per file if Robocopy failed
    Write-Warning "Robocopy reported error (code $code); attempting fallback copy..."
    try {
        $files = Get-ChildItem -Path $repoRoot -Recurse -File -Force -ErrorAction Stop |
            Where-Object { 
                $_.Name -notmatch '\\.md$|\\.ps1$|\\.git.*$' -and 
                $_.FullName -notmatch '\\\.git\\|\\\.github\\|\\scripts\\' 
            }
        foreach ($f in $files) {
            $rel = $f.FullName.Substring($repoRoot.Length).TrimStart([char[]]"/\")
            $destFile = Join-Path $packageDest $rel
            $destDir = Split-Path -Parent $destFile
            if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Force -Path $destDir | Out-Null }
            Copy-Item -Path $f.FullName -Destination $destFile -Force
        }
        Write-Host "Fallback copy completed" -ForegroundColor Yellow
        $packagesCopied = $true
    } catch {
        Write-Warning "Fallback copy failed: $($_.Exception.Message)"
    }
}

# If no changes detected, optionally force a restart if -AlwaysRestart was passed
if (-not $packagesCopied) {
    if ($AlwaysRestart) {
        Write-Host "No changes detected, but -AlwaysRestart was specified. Proceeding to restart HA." -ForegroundColor Yellow
    } else {
        Write-Host "No changes detected in AI Image Reminders package. Skipping HA restart." -ForegroundColor DarkGray
        exit 0
    }
}

# Optional: Restart Home Assistant via REST if env vars are present
$baseUrl = $env:HA_BASE_URL
$token = $env:HA_TOKEN
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
            if ([string]::IsNullOrWhiteSpace($logTxt)) { Write-Host "HA error log returned empty content." -ForegroundColor DarkGray; return }
            
            $lines = $logTxt -split "`n"
            
            # Look for recent AI Image Reminders related errors (last 5 minutes)
            $recent = Get-Date
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
            Write-Host "`nðŸ” AI Image Reminders Error Analysis:" -ForegroundColor Cyan
            Write-Host "   Recent related log lines: $($recentErrors.Count)" -ForegroundColor $(if ($recentErrors.Count -eq 0) { 'Green' } else { 'Yellow' })
            Write-Host "   Critical errors found: $($criticalErrors.Count)" -ForegroundColor $(if ($criticalErrors.Count -eq 0) { 'Green' } else { 'Red' })
            
            if ($criticalErrors.Count -gt 0) {
                Write-Host "`nðŸš¨ CRITICAL ERRORS FOUND:" -ForegroundColor Red
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
                Write-Host "âœ… No AI Image Reminders specific errors found in recent logs." -ForegroundColor Green
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
        $cfgResp = Invoke-WebRequest -Method Get -Uri $cfgUri -Headers $headers -TimeoutSec 15 -ErrorAction Stop
        Write-Host "HA API reachable (HTTP $($cfgResp.StatusCode))." -ForegroundColor DarkGray
    } catch {
        Write-Warning "HA API check failed: $($_.Exception.Message)"
    }

    # Preflight config check: try core/check; on 404, fallback to service + persistent notification probe
    $configValid = $true
    try {
        $checkUri = "$baseUrl/api/config/core/check_config"
        Write-Host "Running HA config check: $checkUri" -ForegroundColor DarkGray
        $checkResp = Invoke-RestMethod -Method Post -Uri $checkUri -Headers $headers -TimeoutSec 60 -ErrorAction Stop
        $result = $checkResp.result
        if ($result -and $result.ToString().ToLower() -ne 'valid') {
            $configValid = $false
            $errs = $checkResp.errors
            Write-Warning "Config check reported INVALID configuration. Details:" 
            if ($errs) {
                if ($errs -is [string]) { Write-Host $errs -ForegroundColor Yellow }
                else { $errs | ConvertTo-Json -Depth 6 | Write-Host -ForegroundColor Yellow }
            } else {
                Write-Host ("(No 'errors' field in response) Raw: " + ($checkResp | ConvertTo-Json -Depth 6)) -ForegroundColor Yellow
            }
        } else {
            Write-Host "Config check PASSED." -ForegroundColor DarkGray
        }
    } catch {
        $msg = $_.Exception.Message
        $status = $null
        if ($_.Exception.Response) { try { $status = $_.Exception.Response.StatusCode.value__ } catch {} }
        if ($status -eq 404) {
            Write-Host "Config core/check_config not available (404). Falling back to service: homeassistant.check_config" -ForegroundColor DarkGray
            try {
                $svcUri = "$baseUrl/api/services/homeassistant/check_config"
                $svcResp = Invoke-RestMethod -Method Post -Uri $svcUri -Headers $basicHeaders -TimeoutSec 60 -ErrorAction Stop
                # Give HA a moment to populate notifications
                Start-Sleep -Seconds 2
                # Probe invalid config persistent notification
                $pnUri = "$baseUrl/api/states/persistent_notification.invalid_config"
                $pn = $null
                try { $pn = Invoke-RestMethod -Method Get -Uri $pnUri -Headers $basicHeaders -TimeoutSec 15 -ErrorAction Stop } catch {}
                if ($pn) {
                    $configValid = $false
                    Write-Warning "Invalid configuration detected via persistent notification:"
                    $msgTxt = $pn.attributes.message
                    if ($msgTxt) { Write-Host $msgTxt -ForegroundColor Yellow } else { Write-Host ($pn | ConvertTo-Json -Depth 6) -ForegroundColor Yellow }
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

    if (-not $configValid) {
        if ($DumpErrorLogOnFail) { Get-HAErrorLogTail -why 'config check failed (pre-restart)' }
        $script:airFail = $true
        Write-Host "Skipping restart due to invalid configuration." -ForegroundColor Yellow
        return
    }
    
    # Try YAML reload first to avoid full restart (unless ForceFullRestart is specified)
    if (-not $ForceFullRestart) {
        Write-Host "Attempting YAML reload instead of full restart..." -ForegroundColor Cyan
        $reloadSuccess = $true
    
    function Invoke-HAService($serviceName) {
        try {
            $serviceUri = "$baseUrl/api/services/$serviceName"
            $resp = Invoke-RestMethod -Method Post -Uri $serviceUri -Headers $headers -Body '{}' -TimeoutSec 30 -ErrorAction Stop
            Write-Host "âœ… Reloaded $serviceName" -ForegroundColor Green
            return $true
        } catch {
            Write-Warning "âŒ Failed to reload $serviceName : $($_.Exception.Message)"
            return $false
        }
    }
    
    # Reload core domains for AI Image Reminders package
    if (-not (Invoke-HAService 'template/reload')) { $reloadSuccess = $false }
    if (-not (Invoke-HAService 'automation/reload')) { $reloadSuccess = $false }
    if (-not (Invoke-HAService 'input_boolean/reload')) { $reloadSuccess = $false }
    if (-not (Invoke-HAService 'input_datetime/reload')) { $reloadSuccess = $false }
    if (-not (Invoke-HAService 'input_number/reload')) { $reloadSuccess = $false }
    if (-not (Invoke-HAService 'input_text/reload')) { $reloadSuccess = $false }
    if (-not (Invoke-HAService 'script/reload')) { $reloadSuccess = $false }
    
    # Always check error logs after YAML reload to catch configuration issues
    Write-Host "Checking error logs after YAML reload..." -ForegroundColor DarkGray
    Start-Sleep -Seconds 2  # Give HA a moment to process reloads and log any errors
    $logCheckPassed = Get-HAErrorLogTail -why 'post-YAML reload validation'
    
    if ($reloadSuccess -and $logCheckPassed) {
        Write-Host "YAML reload completed successfully with no critical errors! âœ¨" -ForegroundColor Green
        
        # Still do entity verification to ensure everything loaded properly
        if (-not [string]::IsNullOrWhiteSpace($VerifyEntity)) {
            Write-Host "Verifying entity availability: $VerifyEntity (timeout 30s)" -ForegroundColor DarkGray
            $verified = $false
            $timeout = 30
            $start = Get-Date
            
            while (-not $verified -and ((Get-Date) - $start).TotalSeconds -lt $timeout) {
                try {
                    $stateUri = "$baseUrl/api/states/$VerifyEntity"
                    $state = Invoke-RestMethod -Method Get -Uri $stateUri -Headers $basicHeaders -TimeoutSec 10 -ErrorAction Stop
                    if ($state -and $state.state -and $state.state -ne 'unavailable' -and $state.state -ne 'unknown') {
                        Write-Host "âœ… Entity $VerifyEntity is available with state: $($state.state)" -ForegroundColor Green
                        $verified = $true
                    } else {
                        Start-Sleep -Seconds 2
                    }
                } catch {
                    Start-Sleep -Seconds 2
                }
            }
            
            if (-not $verified) {
                Write-Warning "Entity $VerifyEntity was not available within ${timeout}s after YAML reload."
                $script:airFail = $true
            }
        }
        
        Write-Host "AI Image Reminders deployment completed via YAML reload! ðŸŽ‰" -ForegroundColor Green
        return
    } elseif ($reloadSuccess -and -not $logCheckPassed) {
        Write-Warning "YAML reload succeeded but critical errors found in logs. Consider reviewing configuration."
        Write-Host "Continuing with deployment but monitoring recommended." -ForegroundColor Yellow
        return
    } else {
        Write-Warning "YAML reload partially failed. Falling back to full restart..."
    }
    } else {
        Write-Host "ForceFullRestart specified, skipping YAML reload and proceeding with full restart." -ForegroundColor Yellow
    }
    
    $uri = "$baseUrl/api/services/homeassistant/restart"
    try {
        Write-Host "Requesting HA Core restart via REST: $uri" -ForegroundColor Cyan
        $resp = Invoke-WebRequest -Method Post -Uri $uri -Headers $headers -Body '{}' -TimeoutSec 30 -ErrorAction Stop
        Write-Host "HA restart requested (HTTP $($resp.StatusCode))." -ForegroundColor Green
        $restartAttempted = $true
        if ($resp.StatusCode -in 200,202) { $restartAccepted = $true }
    } catch {
        $msg = $_.Exception.Message
        $status = $null
        if ($_.Exception.Response) { try { $status = $_.Exception.Response.StatusCode.value__ } catch {} }
        Write-Warning "HA restart REST call failed: $msg (HTTP $status)"
        # Treat 502/504 or connection refused as expected during restart
        if ($status -in 502,504 -or $msg -match 'actively refused') {
            Write-Host "Restart likely in progress; HA may be temporarily unavailable." -ForegroundColor Yellow
            $restartAttempted = $true
        } else {
            # Retry once after 2s for transient issues
            Start-Sleep -Seconds 2
            try {
                $resp2 = Invoke-WebRequest -Method Post -Uri $uri -Headers $headers -Body '{}' -TimeoutSec 30 -ErrorAction Stop
                Write-Host "HA restart requested on retry (HTTP $($resp2.StatusCode))." -ForegroundColor Green
                $restartAttempted = $true
                if ($resp2.StatusCode -in 200,202) { $restartAccepted = $true }
            } catch {
                Write-Warning "HA restart retry failed: $($_.Exception.Message)"
                $restartAttempted = $true
            }
        }
    }

    # Poll for HA to come back online
    $maxWait = 60
    if ($env:HA_RESTART_MAX_WAIT_SEC -match '^[0-9]+$') { $maxWait = [int]$env:HA_RESTART_MAX_WAIT_SEC }
    $interval = 2
    if ($env:HA_RESTART_POLL_INTERVAL_SEC -match '^[0-9]+$') { $interval = [int]$env:HA_RESTART_POLL_INTERVAL_SEC }
    $elapsed = 0
    $back = $false
    Write-Host "Waiting up to $maxWait s for HA to come back online..." -ForegroundColor DarkGray
    while ($elapsed -lt $maxWait) {
        try {
            $ping = Invoke-WebRequest -Method Get -Uri "$baseUrl/api/config" -Headers $headers -TimeoutSec 10 -ErrorAction Stop
            if ($ping.StatusCode -eq 200) {
                Write-Host "HA back online after ${elapsed}s (HTTP 200)." -ForegroundColor Green
                $back = $true
                break
            }
        } catch {
            # Any exception here suggests downtime; note it and continue polling
            $sawDowntime = $true
        }
        Start-Sleep -Seconds $interval
        $elapsed += $interval
    }
    if (-not $back) {
        Write-Warning "HA did not respond with HTTP 200 within $maxWait s; it may still be restarting."
        if ($DumpErrorLogOnFail) { Get-HAErrorLogTail -why 'restart did not return 200 in time' }
    }

    # If we requested a restart but never observed downtime, warn (and optionally fail)
    if ($restartAttempted -and -not $sawDowntime) {
        Write-Warning "No downtime observed after restart request; restart likely did not occur."
        if ($DumpErrorLogOnFail) { Get-HAErrorLogTail -why 'restart likely failed (no downtime observed)' }
        if ($FailOnNoRestart) { $script:airFail = $true }
    }

    # Optional: verify a specific entity becomes available
    if ($back -and -not [string]::IsNullOrWhiteSpace($VerifyEntity)) {
        $verifyMaxWait = 45
        if ($env:HA_VERIFY_MAX_WAIT_SEC -match '^[0-9]+$') { $verifyMaxWait = [int]$env:HA_VERIFY_MAX_WAIT_SEC }
        $verifyInterval = 2
        if ($env:HA_VERIFY_POLL_INTERVAL_SEC -match '^[0-9]+$') { $verifyInterval = [int]$env:HA_VERIFY_POLL_INTERVAL_SEC }

        Write-Host "Verifying entity availability: $VerifyEntity (timeout ${verifyMaxWait}s)" -ForegroundColor DarkGray
        $ok = $false
        $elapsed = 0
        while ($elapsed -lt $verifyMaxWait) {
            try {
                $stateResp = Invoke-WebRequest -Method Get -Uri "$baseUrl/api/states/$VerifyEntity" -Headers $headers -TimeoutSec 10 -ErrorAction Stop
                if ($stateResp.StatusCode -eq 200) {
                    $obj = $stateResp.Content | ConvertFrom-Json
                    $st = [string]$obj.state
                    if ($st -and $st -ne 'unknown' -and $st -ne 'unavailable') {
                        Write-Host "Entity $VerifyEntity is available with state: $st" -ForegroundColor Green
                        $ok = $true
                        break
                    }
                }
            } catch {
                # 404 or other while HA is still initializing; keep waiting
            }
            Start-Sleep -Seconds $verifyInterval
            $elapsed += $verifyInterval
        }
        if (-not $ok) {
            Write-Warning "Entity $VerifyEntity was not available within ${verifyMaxWait}s. Possible regression introduced."
            $script:airFail = $true
            # Always fetch error log on verification failure for quick triage
            Get-HAErrorLogTail -why 'entity verification failed (sensor may not have loaded)'
        }
        
        # AI Image Reminders specific verification: check for key input_boolean entities
        if ($ok) {
            $keyEntities = @(
                'input_boolean.kitchen_monitoring_enabled',
                'input_boolean.family_room_monitoring_enabled', 
                'input_boolean.dog_walk_monitoring_enabled',
                'sensor.kitchen_status',
                'sensor.family_room_status',
                'sensor.dog_walk_status'
            )
            
            foreach ($entity in $keyEntities) {
                try {
                    $entityResp = Invoke-WebRequest -Method Get -Uri "$baseUrl/api/states/$entity" -Headers $headers -TimeoutSec 10 -ErrorAction SilentlyContinue
                    if ($entityResp.StatusCode -eq 200) {
                        $entityObj = $entityResp.Content | ConvertFrom-Json
                        $entityState = [string]$entityObj.state
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
    }

    # Optional: always dump error log after restart (useful when diagnosing load issues)
    if ($DumpErrorLog) { Get-HAErrorLogTail -why 'post-restart (requested)' }
} else {
    Write-Host "Skipping HA restart (set HA_BASE_URL and HA_TOKEN to enable)." -ForegroundColor DarkGray
}

if ($script:airFail) {
    # Non-zero exit to indicate verification failure
    exit 2
}

Write-Host "AI Image Reminders package deployment completed successfully!" -ForegroundColor Green
exit 0
