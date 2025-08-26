# 🏠 AI Image Reminders - ADHD-Friendly Home Assistant Package

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/markaggar/ai-image-reminders)
[![Home Assistant](https://img.shields.io/badge/Home%20Assistant-2025.8%2B-green.svg)](https://www.home-assistant.io/)
[![License](https://img.shields.io/badge/license-MIT-brightgreen.svg)](LICENSE)

A comprehensive Home Assistant package that uses AI-powered image and video analysis to provide gentle, ADHD-friendly reminders for household tasks and dog walking. Features smart notifications via speakers, displays, and mobile devices with positive reinforcement and clear guidance.

## ✨ Features

### 🎯 **ADHD-Focused Design**
- **Gentle Reminders**: Encouraging language instead of nagging
- **Specific Tasks**: AI provides actionable, detailed instructions
- **Positive Reinforcement**: Celebrates completed tasks with enthusiasm
- **Multi-Modal Notifications**: Audio (speakers) + Visual (displays) + Mobile
- **Smart Timing**: Context-aware reminders that adapt to activity patterns

### 🤖 **AI-Powered Analysis**
- **Kitchen Monitoring**: Detects when kitchen needs cleaning with specific tasks
- **Family Room Tracking**: Identifies tidying needs with detailed task lists  
- **Dog Walk Detection**: Video analysis for walk start/completion detection
- **Enhanced Walk Returns**: Specialized detection for low-light/obscured scenarios
- **Multi-Camera Support**: Primary + secondary camera angles for better coverage

### 🔔 **Smart Notification System**
- **Targeted Messaging**: Different notifications for family members vs. parents
- **UNotify Integration**: Rich notifications with audio, display, and mobile delivery
- **Walk-in-Progress Awareness**: Suppresses duplicate reminders during active walks
- **Notification Cooldowns**: Prevents ADHD-triggering notification spam
- **Interactive Confirmations**: Action buttons for unclear situations

### 📱 **Advanced Walk Tracking**
- **Dual-Sensor Logic**: Requires both person and pet detection for reliability
- **Video-Based Analysis**: 30-second recordings with 15-second lookback
- **Direction Detection**: Distinguishes between starting and ending walks
- **Walk-in-Progress Monitoring**: Enhanced return detection during active walks
- **Manual Override**: User confirmation for ambiguous situations

## 🏗️ **Architecture**

### **Modular Design**
The package uses a modular architecture with automated build system:

```
src/
├── automations/          # 15 automation components
├── sensors/             # Template sensors for status tracking
├── helpers/             # Input helpers for configuration
└── header.yaml          # Package metadata

build-deploy.ps1         # Automated build and deployment
```

### **Key Components**
- **15 Automation Files**: Each handling specific functionality
- **Template Sensors**: AI analysis status and system monitoring
- **Input Helpers**: Configurable settings and thresholds  
- **Variable Sensors**: Unlimited storage for AI analysis results
- **Build System**: Automated concatenation and deployment

## 🚀 **Quick Start**

### **Prerequisites**
- Home Assistant 2025.8+
- AI Tasks integration (Google AI or compatible)
- Camera entities for monitoring areas
- Motion sensors for person/pet detection
- UNotify integration for enhanced notifications

### **Installation**

1. **Clone the repository:**
   ```powershell
   git clone https://github.com/markaggar/ai-image-reminders.git
   cd ai-image-reminders
   ```

2. **Configure entity names in Home Assistant:**
   - Update `input_text` helpers with your actual entity names:
     - Camera entities (`camera.kitchen`, `camera.family_room`, `camera.driveway`)
     - Motion sensors (`binary_sensor.kitchen_person_motion`, etc.)
     - AI Tasks entity (`ai_task.google_ai_task`)

3. **Deploy the package:**
   ```powershell
   .\build-deploy.ps1
   ```

4. **Enable monitoring:**
   - Turn on `input_boolean.ai_detection_enabled`
   - Enable specific monitoring: `kitchen_monitoring_enabled`, `family_room_monitoring_enabled`, `dog_walk_monitoring_enabled`
   - Configure notification settings

## ⚙️ **Configuration**

### **Essential Settings**
- **Camera Entities**: Configure your actual camera entity names
- **Motion Sensors**: Set up person and pet detection sensors
- **AI Tasks**: Ensure AI integration is configured and working
- **UNotify**: Set up for multi-modal notification delivery

### **Customizable Parameters**
- **Notification Cooldown**: 10-240 minutes (default: 30)
- **Walk Completion Window**: Auto-detect timeouts and thresholds
- **Analysis Triggers**: Motion-based timing for room analysis
- **Message Targeting**: Configure `liam` vs `parents` notifications

## 📊 **Notification System**

### **For ADHD Family Member (Liam)**
- 🎵 **Audio**: Encouraging reminders via speakers
- 📺 **Display**: Visual notifications on TV/displays  
- 📱 **Mobile**: Full notification experience
- 🎯 **Content**: Task reminders, walk prompts, positive reinforcement

### **For Parents (Remote Monitoring)**
- 📱 **Mobile Only**: Silent text notifications
- 📊 **Status Updates**: Completion confirmations and system status
- ❓ **Decision Points**: Unclear situations requiring input
- 🔕 **No Audio/Display**: Appropriate for remote/work situations

## 🎮 **Manual Controls**

### **Force Analysis**
- `input_boolean.force_kitchen_check`
- `input_boolean.force_family_room_check`

### **Walk Management**
- `input_boolean.walk_in_progress`
- `input_datetime.morning_walk_done`
- `input_datetime.evening_walk_done`

### **System Toggles**
- `input_boolean.ai_detection_enabled` - Master system toggle
- `input_boolean.notifications_enabled` - All notifications
- Individual monitoring enables for each area

## 🛠️ **Development**

### **Build System**
The modular build system automatically:
1. Combines all source components
2. Validates YAML syntax
3. Deploys to Home Assistant
4. Reloads configurations
5. Archives previous versions

```powershell
.\build-deploy.ps1  # Full build and deploy
```

### **Component Structure**
- Each automation is a separate file for easy development
- Template sensors provide system status and AI analysis
- Input helpers offer user-configurable settings
- Automated dependency management and validation

## 📈 **System Status**

### **Monitoring Dashboard**
- **AI Detection Status**: Active, monitoring, checking, disabled
- **Last Analysis Times**: Kitchen, family room, driveway
- **Walk Status**: In progress, completion times, duration tracking  
- **Notification Cooldowns**: Current status and remaining time

### **Troubleshooting**
- Check entity availability in Developer Tools > States
- Verify AI Tasks integration is responding
- Confirm camera entities are accessible
- Test motion sensor triggering

## 🤝 **Contributing**

This project is designed for ADHD-friendly home automation. Contributions should maintain:
- Gentle, encouraging language in all notifications
- Clear, specific task instructions
- Positive reinforcement patterns
- Accessible configuration options

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 **Acknowledgments**

- Home Assistant community for the foundation
- AI Tasks integration developers
- UNotify integration for enhanced notifications
- ADHD community for guidance on supportive technology design

---

**Version 1.0.0** - Complete ADHD-friendly home automation with AI-powered analysis, smart notifications, and comprehensive walk tracking. Ready for production use! 🎉
