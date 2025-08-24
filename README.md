# AI Image Reminders - Home Assistant Package

A comprehensive Home Assistant package for monitoring and providing reminders for ADHD individuals using AI-powered image detection.

## Features

### 🏠 Kitchen Monitoring
- **Food Detection**: AI detection of food items left out on counters
- **Dirty Dishes Detection**: Monitor sink and counter areas for dirty dishes
- **Cleanup Reminders**: Automated notifications when cleaning is needed
- **Independent Sensors**: Can be used standalone to check kitchen status

### 🐕 Dog Walking Monitoring
- **Walk Detection**: Monitor when the dog is taken outside
- **Duration Tracking**: Track how long walks last
- **Reminder System**: Send notifications if walks are overdue
- **Status Sensors**: Independent sensors to check if dog needs a walk

### 🤖 AI Image Detection
- **Google Gemini Integration**: Leverage existing Gemini AI for image analysis
- **Security Camera Integration**: Use existing Home Assistant connected cameras
- **Pattern Recognition**: Detect patterns in kitchen cleanliness and pet care
- **Flexible Detection**: Configurable detection parameters for different scenarios

### 📱 Smart Notifications
- **Context-Aware Reminders**: Send appropriate reminders based on detected conditions
- **Timing Intelligence**: Avoid sending reminders during inappropriate times
- **Escalation System**: Increase reminder frequency if conditions persist
- **Mobile Integration**: Send notifications to phones/devices

## Package Structure

```
ai_image_reminders/
├── README.md
├── automations/
│   ├── kitchen_monitoring.yaml
│   ├── dog_walking_reminders.yaml
│   └── notification_system.yaml
├── sensors/
│   ├── kitchen_sensors.yaml
│   ├── dog_walk_sensors.yaml
│   └── ai_detection_sensors.yaml
├── scripts/
│   ├── ai_image_analysis.py
│   ├── kitchen_detector.py
│   └── dog_walk_tracker.py
├── input_boolean/
│   └── monitoring_controls.yaml
├── input_datetime/
│   └── timing_controls.yaml
└── templates/
    └── notification_templates.yaml
```

## Prerequisites

- Home Assistant with security cameras configured
- Google Gemini AI integration
- Mobile notifications setup (Home Assistant app or similar)
- Camera entities accessible in Home Assistant

## Installation

1. Copy the `ai_image_reminders` folder to your Home Assistant `packages` directory
2. Add your camera entity names to the configuration files
3. Configure notification targets (mobile devices, etc.)
4. Restart Home Assistant
5. Enable the monitoring systems via the created input_boolean entities

## Configuration

### Camera Setup
Update the camera entity names in the sensor files:
- Kitchen camera: `camera.kitchen_camera`
- Family room camera: `camera.family_room_camera`
- Front door/yard camera: `camera.front_yard_camera`

### Notification Setup
Configure your notification services in the automation files:
- Mobile notifications: `notify.mobile_app_your_phone`
- Other notification methods as needed

### Timing Configuration
Adjust reminder intervals and quiet hours in:
- `input_datetime/timing_controls.yaml`
- Individual automation files

## Usage

### Independent Monitoring
Each sensor can be used independently to check status:
- `sensor.kitchen_cleanliness_status`
- `sensor.dog_walk_needed`
- `sensor.last_dog_walk_duration`

### Automated Reminders
Automations will trigger based on:
- Time since last cleanup
- Food/dishes detected in kitchen
- Time since last dog walk
- Current time of day (respecting quiet hours)

### Manual Controls
Use the input_boolean entities to:
- Enable/disable monitoring systems
- Pause reminders temporarily
- Reset detection counters

## Customization

The package is designed to be modular and customizable:
- Adjust AI detection sensitivity in Python scripts
- Modify reminder frequencies in automations
- Add new detection types by extending the sensor configurations
- Customize notification messages in templates

## Support

This package leverages your existing Google Gemini integration pattern for package delivery detection, adapted for kitchen and pet monitoring scenarios.
