# Installation Instructions for AI Image Reminders

## Quick Start

### 1. Copy Package to Home Assistant
Copy the entire `ai_image_reminders` folder to your Home Assistant `packages` directory:
```
/config/packages/ai_image_reminders/
```

### 2. Configure Your Cameras
Edit the following files to match your camera entity names:
- `input_datetime/timing_controls.yaml` - Update camera entity names
- `sensors/kitchen_sensors.yaml` - Update kitchen camera reference
- `sensors/ai_detection_sensors.yaml` - Update all camera references

### 3. Set Up API Keys
Add to your `secrets.yaml`:
```yaml
gemini_api_key: "your_google_gemini_api_key_here"
ha_long_lived_token: "your_home_assistant_long_lived_access_token"
```

### 4. Configure Notifications
Update notification targets in:
- `automations/kitchen_monitoring.yaml` 
- `automations/dog_walking_reminders.yaml`
- `automations/notification_system.yaml`

Change `notify.mobile_app_adhd_monitoring` to your actual notification service.

### 5. Install Python Dependencies
If using the Python scripts, install requirements:
```bash
pip install -r requirements.txt
```

### 6. Restart Home Assistant
Restart Home Assistant to load the new package.

## Configuration Details

### Camera Entities to Update
Replace these default camera names with your actual entities:
- `camera.kitchen_camera` → your kitchen camera
- `camera.family_room_camera` → your family room camera  
- `camera.front_yard_camera` → your front door/yard camera

### Sensor Names to Update
If you have existing motion/door sensors, update references to:
- `binary_sensor.front_door_motion` → your front door sensor
- `binary_sensor.front_yard_activity` → your yard motion sensor

### Notification Services
Update all instances of `notify.mobile_app_adhd_monitoring` to:
- `notify.mobile_app_your_phone_name` (for Home Assistant app)
- `notify.your_notification_service` (for other services)

## Environment Variables for Python Scripts

Set these environment variables for the Python scripts:
```bash
export GEMINI_API_KEY="your_api_key"
export HA_URL="http://your_home_assistant_ip:8123"  
export HA_TOKEN="your_long_lived_access_token"
export KITCHEN_CAMERA_ENTITY="camera.your_kitchen_camera"
```

## Testing the System

### 1. Enable Monitoring
- Go to Home Assistant → Settings → Entities
- Enable `input_boolean.ai_detection_enabled`
- Enable `input_boolean.kitchen_monitoring_enabled`
- Enable `input_boolean.dog_walk_reminders_enabled`

### 2. Test Kitchen Detection
- Run script: `script.manual_kitchen_check`
- Check sensor: `sensor.kitchen_cleanliness_status`

### 3. Test Notifications
- Run script: `script.send_test_notification`

### 4. Test Dog Walking
- Enable `input_boolean.dog_walk_in_progress` manually
- Wait a few minutes, then disable it
- Check that `sensor.last_dog_walk_duration` updates

## Customization

### Adjust Timing
- Modify reminder intervals in `input_datetime/timing_controls.yaml`
- Change check frequencies in automation trigger times

### Customize Messages
- Edit notification templates in `templates/notification_templates.yaml`
- Modify automation messages in the automation files

### Add New Detection Types
- Create new sensors in the sensor files
- Add corresponding automations
- Update the Python scripts for new analysis types

## Troubleshooting

### Common Issues
1. **Camera not found**: Update camera entity names in config files
2. **API errors**: Check Gemini API key and quota
3. **No notifications**: Verify notification service names
4. **Python script errors**: Check environment variables and dependencies

### Logs to Check
- Home Assistant logs: `Settings → System → Logs`
- Automation traces: `Settings → Automations → [automation] → Traces`
- Sensor states: `Developer Tools → States`
