# AI Image Reminders Deployment Script

This PowerShell script automates the deployment of the AI Image Reminders package to your Home Assistant environment.

## Setup

1. Set environment variables for API access:
   ```powershell
   $env:HA_BASE_URL = "http://10.0.0.55:8123"
   $env:HA_TOKEN = "your_long_lived_access_token"
   ```

2. Optionally set verification entity (defaults to `sensor.kitchen_analysis`):
   ```powershell
   $env:HA_VERIFY_ENTITY = "sensor.kitchen_analysis"
   ```

## Usage

### Basic deployment:
```powershell
.\deploy.ps1
```

### Force copy all files (ignore timestamps):
```powershell
.\deploy.ps1 -ForceCopy
```

### Always restart HA even if no changes detected:
```powershell
.\deploy.ps1 -AlwaysRestart
```

### Dump error logs after deployment:
```powershell
.\deploy.ps1 -DumpErrorLog
```

### Custom packages destination:
```powershell
.\deploy.ps1 -PackagesDest "\\my-ha-server\config\packages"
```

## Parameters

- **PackagesDest**: Destination path for packages (default: `\\10.0.0.55\config\packages`)
- **VerifyEntity**: Entity to verify after restart (default: `sensor.kitchen_analysis`)
- **ForceCopy**: Force copy all files regardless of timestamps
- **AlwaysRestart**: Restart HA even if no changes detected
- **DumpErrorLog**: Always dump error log after restart
- **DumpErrorLogOnFail**: Dump error log only on failures
- **FailOnNoRestart**: Fail if restart was requested but no downtime observed

## Environment Variables

- **HA_BASE_URL**: Home Assistant base URL
- **HA_TOKEN**: Long-lived access token
- **HA_VERIFY_ENTITY**: Entity to verify (overrides -VerifyEntity)
- **HA_RESTART_MAX_WAIT_SEC**: Max seconds to wait for restart (default: 60)
- **HA_RESTART_POLL_INTERVAL_SEC**: Polling interval during restart (default: 2)
- **HA_VERIFY_MAX_WAIT_SEC**: Max seconds to wait for entity verification (default: 45)
- **HA_VERIFY_POLL_INTERVAL_SEC**: Polling interval for verification (default: 2)
- **AIR_SAVE_ERROR_LOG_TO_TEMP**: Save error logs to temp folder (1/true/yes)

## What it does

1. **File Copy**: Copies package files to `\\server\config\packages\ai_image_reminders\`
2. **Config Check**: Validates Home Assistant configuration before restart
3. **Restart**: Restarts Home Assistant core if changes detected
4. **Verification**: Waits for HA to come back online and verifies key entities
5. **Error Logging**: Captures and displays relevant error log entries

## Verification

The script verifies these key entities after deployment:
- `sensor.kitchen_analysis` (or custom entity)
- `input_boolean.kitchen_monitoring_enabled`
- `input_boolean.family_room_monitoring_enabled`
- `input_boolean.dog_walk_monitoring_enabled`
- `sensor.kitchen_status`
- `sensor.family_room_status`
- `sensor.dog_walk_status`

## Exit Codes

- **0**: Success
- **2**: Verification failure (regression detected)
