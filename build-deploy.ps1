# AI Image Reminders - Modular Build and Deploy Script
# Builds package from modular source files and deploys to Home Assistant

param(
    [switch]$BuildOnly,
    [switch]$Verbose
)

# Build configuration
$SourceDir = "src"
$OutputFile = "ai_image_reminders.yaml"
$BackupFile = "ai_image_reminders.backup.yaml"

# Home Assistant configuration
$HAConfigPath = "\\10.0.0.55\config\packages\ai_image_reminders"
$HABaseURL = $env:HA_BASE_URL ?? "http://10.0.0.55:8123"
$HAToken = $env:HA_TOKEN

Write-Host "=== AI Image Reminders - Modular Build & Deploy ===" -ForegroundColor Green
Write-Host "Building package from modular components..." -ForegroundColor Yellow

# Check if source directory exists
if (-not (Test-Path $SourceDir)) {
    Write-Error "Source directory '$SourceDir' not found!"
    exit 1
}

# Backup existing package if it exists
if (Test-Path $OutputFile) {
    Copy-Item $OutputFile $BackupFile -Force
    Write-Host "✓ Backed up existing package to $BackupFile" -ForegroundColor Green
}

# Build the package
$packageContent = @()

# Add header from header.yaml file if it exists
$headerFile = Join-Path $SourceDir "header.yaml"
if (Test-Path $headerFile) {
    Write-Host "Adding package header..." -ForegroundColor Cyan
    $headerContent = Get-Content $headerFile -Raw
    if ($headerContent) {
        # Replace timestamp placeholder with actual timestamp
        $headerContent = $headerContent -replace '\[BUILD_TIMESTAMP\]', (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        $headerLines = ($headerContent -split "`r?`n")
        $packageContent += $headerLines
        $packageContent += ""
    }
} else {
    # Fallback to simple header if header.yaml doesn't exist
    $packageContent += "# AI Image Reminders - Complete Package"
    $packageContent += "# Generated from modular components: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $packageContent += "# Source: Modular components in $SourceDir/"
    $packageContent += ""
}

# Component build order and sections
$buildSections = [ordered]@{
    "template:" = @{
        Path = "sensors/*.yaml"
        Description = "Template Sensors"
    }
    "automation:" = @{
        Path = "automations/*.yaml" 
        Description = "Automations"
    }
    "script:" = @{
        Path = "scripts/*.yaml"
        Description = "Scripts"
    }
    "input_boolean:" = @{
        Path = "helpers/input_boolean.yaml"
        Description = "Input Boolean Helpers"
    }
    "input_datetime:" = @{
        Path = "helpers/input_datetime.yaml"
        Description = "Input DateTime Helpers"
    }
    "input_number:" = @{
        Path = "helpers/input_number.yaml"
        Description = "Input Number Helpers"
    }
    "input_text:" = @{
        Path = "helpers/input_text.yaml"
        Description = "Input Text Helpers"
    }
}

# Build each section
foreach ($section in $buildSections.GetEnumerator()) {
    $sectionName = $section.Key
    $config = $section.Value
    $searchPath = Join-Path $SourceDir $config.Path
    
    Write-Host "Building: $($config.Description)" -ForegroundColor Cyan
    
    $files = Get-ChildItem $searchPath -ErrorAction SilentlyContinue
    
    if ($files) {
        $packageContent += "# $($config.Description)"
        $packageContent += $sectionName
        
        $fileCount = 0
        foreach ($file in $files | Sort-Object Name) {
            if ($Verbose) {
                Write-Host "  + $($file.Name)" -ForegroundColor Gray
            }
            
            $content = Get-Content $file.FullName -Raw
            if ($content) {
                # Remove any leading/trailing whitespace and split into lines
                $lines = ($content -split "`r?`n") | Where-Object { $_ -notmatch "^#\s*$|^\s*$" -or $_ -match "\S" }
                
                # Check if this is a list-based section (automation, template)
                $isListSection = $sectionName -in @("automation:", "template:")
                
                if ($isListSection -and $sectionName -eq "automation:") {
                    # For automation sections, add list marker and proper indentation
                    $indentedLines = @()
                    $first = $true
                    foreach ($line in $lines) {
                        if ($line -match "^\s*#") {
                            # Keep comments as-is
                            $indentedLines += $line
                        } elseif ($line -match "^id:\s" -and $first) {
                            # First content line gets list marker
                            $indentedLines += "  - $line"
                            $first = $false
                        } else {
                            # All other lines get standard indentation
                            $indentedLines += "    $line"
                        }
                    }
                    $packageContent += $indentedLines
                } elseif ($isListSection -and $sectionName -eq "template:") {
                    # For template sections, content already has proper list structure
                    $indentedLines = @()
                    foreach ($line in $lines) {
                        if ($line -match "^\s*#") {
                            # Keep comments as-is
                            $indentedLines += $line
                        } else {
                            # Add standard template indentation
                            $indentedLines += "  $line"
                        }
                    }
                    $packageContent += $indentedLines
                } else {
                    # For non-list sections, just add the content as-is
                    $packageContent += $lines
                }
                $fileCount++
            }
        }
        
        Write-Host "  ✓ Added $fileCount files" -ForegroundColor Green
        $packageContent += ""
    } else {
        Write-Host "  - No files found for $($config.Description)" -ForegroundColor Yellow
    }
}

# Write the built package
try {
    $packageContent | Out-File $OutputFile -Encoding UTF8 -Force
    Write-Host "✅ Package built successfully: $OutputFile" -ForegroundColor Green
    
    $lineCount = (Get-Content $OutputFile).Count
    Write-Host "   📊 Package contains $lineCount lines" -ForegroundColor Gray
    
} catch {
    Write-Error "Failed to write package file: $($_.Exception.Message)"
    exit 1
}

# If build-only mode, stop here
if ($BuildOnly) {
    Write-Host "🏗️  Build complete (build-only mode)" -ForegroundColor Green
    exit 0
}

# Continue with deployment...
Write-Host "🚀 Starting deployment..." -ForegroundColor Yellow

# Rest of deployment logic (same as original deploy.ps1)
Write-Host "Deploying AI Image Reminders package from: $(Get-Location)"
Write-Host "To: $HAConfigPath"

# Copy file with robocopy first, then fallback
$robocopyResult = robocopy . $HAConfigPath $OutputFile /R:3 /W:1 2>&1
if ($LASTEXITCODE -gt 7) {
    Write-Warning "Robocopy reported error (code $LASTEXITCODE); attempting fallback copy..."
    try {
        Copy-Item $OutputFile $HAConfigPath -Force
        Write-Host "Fallback copy completed" -ForegroundColor Green
    } catch {
        Write-Error "Both robocopy and fallback copy failed: $($_.Exception.Message)"
        exit 1
    }
} else {
    Write-Host "✅ File copied successfully" -ForegroundColor Green
}

# HA API calls and error checking (same as original)...
Write-Host "Checking HA API: $HABaseURL/api/config"
try {
    $apiTest = Invoke-RestMethod -Uri "$HABaseURL/api/config" -Headers @{Authorization="Bearer $HAToken"} -TimeoutSec 10
    Write-Host "HA API reachable (HTTP $($apiTest.version))." -ForegroundColor Green
} catch {
    Write-Warning "HA API check failed, but continuing deployment..."
}

# Config validation
Write-Host "Running HA config check: $HABaseURL/api/config/core/check_config"
try {
    $configCheck = Invoke-RestMethod -Uri "$HABaseURL/api/config/core/check_config" -Headers @{Authorization="Bearer $HAToken"} -Method Post -TimeoutSec 30
    if ($configCheck.result -eq "valid") {
        Write-Host "Config check PASSED." -ForegroundColor Green
    } else {
        Write-Warning "Config check result: $($configCheck.result)"
        Write-Warning "Errors: $($configCheck.errors -join ', ')"
    }
} catch {
    Write-Warning "Config check failed: $($_.Exception.Message)"
}

# YAML reload
Write-Host "Attempting YAML reload instead of full restart..."
$reloadServices = @("automation", "template", "input_boolean", "input_datetime", "input_number", "input_text", "script")

foreach ($service in $reloadServices) {
    try {
        $reloadResult = Invoke-RestMethod -Uri "$HABaseURL/api/services/homeassistant/reload_config_entry" -Headers @{Authorization="Bearer $HAToken"} -Method Post -Body (@{domain=$service} | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 15
        Write-Host "✅ Reloaded $service" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to reload $service`: $($_.Exception.Message)"
    }
}

Write-Host "🎉 Modular build and deployment complete!" -ForegroundColor Green
Write-Host "📁 Built from $(($buildSections.Count)) component sections" -ForegroundColor Gray
