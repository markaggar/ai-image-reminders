# AI Image Reminders - ADHD Home Automation Package

## Project Overview
Home Assistant package providing ADHD-friendly automation using AI video/image analysis for room monitoring and dog walk tracking.

## Architecture Guidelines
- Use modular YAML structure in src/ directories
- Follow Home Assistant YAML conventions
- No try/catch blocks (HA doesn't support them)
- Use template conditions and choose/default blocks for error handling
- Integrate with Variables + History for unlimited AI response storage

## Key Components
- AI-powered room analysis (kitchen/family room)
- Dog walk detection with dual-sensor logic
- UNotify notifications with targeted messaging
- Variable sensors for AI response storage
- Comprehensive dashboard for monitoring

## Development Practices
- Test YAML syntax before deployment
- Use continue_on_error for service calls
- Template-driven dynamic entity references
- Proper error handling with conditions
- Maintain backwards compatibility where possible