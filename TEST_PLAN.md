# AI Image Reminders - Comprehensive Test Plan

## Test Plan Overview

This comprehensive test plan covers all components of the AI Image Reminders system, ensuring reliability, accuracy, and user experience quality for ADHD monitoring support.

## Test Environment Setup

### Prerequisites
- Home Assistant 2025.8.0 or later
- Google Generative AI Conversation integration configured
- UNotify service configured
- Test cameras accessible (kitchen, family room, driveway)
- Test motion sensors available

### Initial Configuration Setup

#### Essential Input Boolean Switches (Must be ON for system operation)
1. **`input_boolean.ai_detection_enabled`** - Master switch for AI detection system
2. **`input_boolean.kitchen_monitoring_enabled`** - Enables kitchen cleanliness monitoring
3. **`input_boolean.family_room_monitoring_enabled`** - Enables family room tidiness monitoring
4. **`input_boolean.dog_walk_monitoring_enabled`** - Enables dog walking detection
5. **`input_boolean.notifications_enabled`** - Enables all notifications

#### Reminder Switches (Should be ON for alerts)
6. **`input_boolean.kitchen_reminders_enabled`** - Enables kitchen cleaning reminders
7. **`input_boolean.family_room_reminders_enabled`** - Enables family room tidying reminders
8. **`input_boolean.dog_walk_reminders_enabled`** - Enables dog walking reminders

#### Optional Feature Switches (Configure as needed)
- **`input_boolean.daily_summary_enabled`** - Daily summary reports
- **`input_boolean.weekly_reports_enabled`** - Weekly reports
- **`input_boolean.gemini_api_available`** - API status (system-managed)

#### Switches That Should Stay OFF (Unless specifically needed)
- **`input_boolean.quiet_hours_active`** - Disables notifications during quiet hours
- **`input_boolean.kitchen_manual_override`** - Manual control override
- **`input_boolean.kitchen_reminder_snoozed`** - Temporarily disable kitchen reminders
- **`input_boolean.dog_reminder_snoozed`** - Temporarily disable dog reminders
- **`input_boolean.emergency_override_enabled`** - Emergency override mode
- **Override switches** - Only for manual state forcing

### Quick Setup Checklist
```yaml
Required ON switches for basic operation:
  - input_boolean.ai_detection_enabled: true
  - input_boolean.kitchen_monitoring_enabled: true
  - input_boolean.family_room_monitoring_enabled: true
  - input_boolean.dog_walk_monitoring_enabled: true
  - input_boolean.notifications_enabled: true
  - input_boolean.kitchen_reminders_enabled: true
  - input_boolean.family_room_reminders_enabled: true
  - input_boolean.dog_walk_reminders_enabled: true
```

### Test Data Requirements
- Sample images for each monitoring scenario
- Mock API responses for AI service failures
- Test notification endpoints
- Historical datetime data for time-based tests

## 0. Configuration Validation Tests

### 0.1 Initial System Configuration Test

#### Input Boolean Configuration Validation
```yaml
Test Cases:
- ✅ All required input_boolean entities exist and accessible
- ✅ Master switch (ai_detection_enabled) controls system activation
- ✅ Monitoring switches control respective area monitoring
- ✅ Reminder switches control notification generation
- ✅ Override switches function correctly for manual control
```

**Test Steps:**
1. Verify all input_boolean entities load without errors
2. Test master switch `ai_detection_enabled` ON/OFF behavior:
   - OFF: All monitoring should be disabled
   - ON: Monitoring areas should respect individual switches
3. Test individual monitoring switches:
   - `kitchen_monitoring_enabled` OFF → Kitchen analysis disabled
   - `family_room_monitoring_enabled` OFF → Family room analysis disabled
   - `dog_walk_monitoring_enabled` OFF → Dog detection disabled
4. Test reminder switches:
   - Reminder switches OFF → No notifications sent despite detection
   - Reminder switches ON → Notifications sent when conditions met
5. Test override functionality:
   - Manual overrides force specific states
   - Snooze functions temporarily disable reminders
   - Emergency override bypasses normal logic

#### Entity State Initialization Test
```yaml
Test Cases:
- ✅ All input_datetime entities initialize with reasonable defaults
- ✅ All input_text entities have correct camera entity references
- ✅ Template sensors handle missing dependencies gracefully
- ✅ System operates with recommended switch configuration
```

**Test Steps:**
1. Deploy package with all switches OFF
2. Verify no errors in Home Assistant logs
3. Enable recommended switches per Quick Setup Checklist
4. Verify all template sensors become available
5. Verify automations are ready and waiting for triggers

## 1. Unit Tests - Individual Components

### 1.1 Template Sensor Tests

#### Kitchen Analysis Sensor (`sensor.kitchen_analysis`)
```yaml
Test Cases:
- ✅ AI service available, clean kitchen image → "clean" state
- ✅ AI service available, messy kitchen image → "needs_cleaning" state  
- ✅ AI service unavailable → "unknown" state with graceful degradation
- ✅ Invalid camera entity → error handling without system crash
- ✅ Template renders without errors during bootstrap
```

**Test Steps:**
1. Configure test kitchen camera with known clean image
2. Verify sensor reports "clean" status
3. Replace with messy kitchen image
4. Verify sensor reports "needs_cleaning" status
5. Disable Gemini AI service
6. Verify sensor gracefully handles unavailable service
7. Restart Home Assistant and verify no template errors during startup

#### Family Room Analysis Sensor (`sensor.family_room_analysis`)
```yaml
Test Cases:
- ✅ Tidy family room → "tidy" state
- ✅ Messy family room → "needs_tidying" state
- ✅ Service failures handled gracefully
- ✅ Confidence scoring within expected range (0-1)
```

#### Dog Walk Detection Sensor (`sensor.dog_walk_detection`)
```yaml
Test Cases:
- ✅ Person with dog detected on driveway → "walk_detected" state
- ✅ Person without dog → "no_walk" state
- ✅ Empty driveway → "no_activity" state
- ✅ Multiple people scenarios handled correctly
```

### 1.2 Status Sensor Tests

#### Kitchen Status Sensor (`sensor.kitchen_cleanliness_status`)
```yaml
Test Cases:
- ✅ Analysis "clean" + override "off" → "clean"
- ✅ Analysis "needs_cleaning" + override "off" → "needs_cleaning"  
- ✅ Analysis "needs_cleaning" + override "on" → "clean" (manual override)
- ✅ Analysis "unknown" → appropriate fallback behavior
```

### 1.3 Time Tracking Sensor Tests

#### Time Since Last Walk (`sensor.time_since_last_walk`)
```yaml
Test Cases:
- ✅ Recent walk (< 1 hour) → displays minutes correctly
- ✅ Moderate time (1-12 hours) → displays hours correctly
- ✅ Long time (> 12 hours) → displays with appropriate urgency
- ✅ No walk recorded → handles gracefully
- ✅ Timezone handling correct across DST changes
```

### 1.4 Message Template Tests

#### Kitchen Messages
```yaml
Test Cases:
- ✅ Positive reinforcement message variety (5+ different messages)
- ✅ Escalation messages based on time thresholds
- ✅ Template variables render correctly
- ✅ No template errors with missing data
- ✅ Appropriate emoji and formatting
```

## 2. Integration Tests - Component Interactions

### 2.1 Kitchen Monitoring Workflow
```yaml
Test Scenario: Complete kitchen cleaning detection cycle
Steps:
1. Kitchen starts clean → verify no notifications
2. Kitchen becomes messy → verify detection within 5 minutes
3. Notification cooldown respected → no duplicate notifications
4. Kitchen cleaned → verify positive reinforcement message
5. Status reset → ready for next cycle

Expected Results:
- ✅ Detection accuracy > 90%
- ✅ Notification timing within configured thresholds
- ✅ Message content appropriate for context
```

### 2.2 Family Room Monitoring Workflow  
```yaml
Test Scenario: Family room tidying workflow
Steps:
1. Room starts tidy → baseline established
2. Room becomes messy → detection triggered
3. Gentle reminder sent → verify tone and content
4. Room tidied → acknowledgment sent
5. Multiple mess/tidy cycles → verify system stability

Expected Results:
- ✅ Gentle, encouraging message tone
- ✅ No overwhelming frequency of notifications
- ✅ Accurate state transitions
```

### 2.3 Dog Walking Workflow
```yaml
Test Scenario: Complete dog walking cycle
Steps:
1. Morning routine → verify morning walk expectations
2. Walk detected on driveway → timestamp recorded
3. Evening routine → verify evening walk expectations  
4. Walk overdue → escalating reminders sent
5. Walk completed → confirmation and positive feedback

Expected Results:
- ✅ Accurate walk detection (minimize false positives)
- ✅ Appropriate timing for reminders
- ✅ Escalation logic functions correctly
```

## 3. System Tests - End-to-End Scenarios

### 3.1 Initial Setup and Configuration Test
```yaml
Test Scenario: New user setup experience
Steps:
1. Deploy package with default configuration
2. Verify all entities load successfully  
3. Follow Quick Setup Checklist to enable required switches
4. Test basic functionality with each monitoring area
5. Adjust optional settings based on preferences
6. Verify system operates as expected

Success Criteria:
- ✅ Zero configuration errors during deployment
- ✅ All essential switches identified and enabled easily
- ✅ System responds immediately after switch activation
- ✅ Clear feedback on what each switch controls
- ✅ Graceful handling of partial configuration
```

### 3.2 Daily Routine Simulation
```yaml
Test Scenario: Typical day with ADHD monitoring support
Timeline:
06:00 - System startup check
07:00 - Morning dog walk reminder
08:00 - Breakfast cleanup detection
12:00 - Lunch cleanup monitoring
17:00 - Evening preparation monitoring
18:00 - Evening dog walk reminder
20:00 - Daily summary report
22:00 - Quiet hours activation

Success Criteria:
- ✅ All events detected within 5-minute accuracy
- ✅ Notifications appropriate for time of day
- ✅ No false alarms or missed events
- ✅ Daily summary contains accurate data
```

### 3.2 Weekend Routine Simulation
```yaml
Test Scenario: Different weekend patterns
Variables:
- Later wake times
- Different meal schedules
- Extended family room activities
- Flexible dog walking times

Success Criteria:
- ✅ System adapts to different schedules
- ✅ Reminders remain helpful without being intrusive
- ✅ Manual overrides work correctly
```

### 3.3 Edge Case Handling
```yaml
Test Scenario: System resilience testing
Cases:
1. Internet connectivity loss
2. Camera offline scenarios  
3. AI service rate limiting
4. Home Assistant restart during monitoring
5. Clock changes (DST transitions)

Success Criteria:
- ✅ Graceful degradation without errors
- ✅ Recovery when services restored
- ✅ No data loss during interruptions
- ✅ Appropriate fallback messaging
```

## 4. Performance Tests

### 4.1 Response Time Tests
```yaml
Metrics:
- Image analysis completion: < 10 seconds
- Notification delivery: < 5 seconds  
- State change detection: < 2 seconds
- Template rendering: < 1 second
- Automation trigger response: < 3 seconds

Load Testing:
- Multiple simultaneous camera updates
- High-frequency motion detection
- Concurrent automation executions
```

### 4.2 Resource Usage Tests
```yaml
Monitoring:
- CPU usage during AI processing
- Memory consumption over 24-hour period
- Network bandwidth for image analysis
- Storage requirements for historical data

Thresholds:
- Peak CPU usage < 50% of available
- Memory growth < 100MB per day
- Network usage reasonable for image processing
```

## 5. Usability Tests

### 5.1 Configuration Interface Tests
```yaml
User Stories:
- Parent adjusts notification sensitivity
- Parent sets quiet hours
- Parent disables specific monitoring areas
- Parent reviews historical data
- Parent acknowledges false alarms

Success Criteria:
- ✅ Intuitive helper entity names and descriptions
- ✅ Clear feedback when settings changed
- ✅ Immediate effect of configuration changes
```

### 5.2 Notification Quality Tests
```yaml
Message Evaluation:
- Tone appropriateness for ADHD support
- Clear, actionable language
- Encouraging rather than nagging
- Varied messages prevent habituation
- Emergency vs. routine message distinction

Parent Feedback:
- Message helpfulness rating
- Frequency satisfaction
- False alarm rate acceptance
- System trust and reliability perception
```

## 6. Security Tests

### 6.1 Data Privacy Tests
```yaml
Verification:
- Camera images processed locally when possible
- API calls to Gemini use encrypted connections
- No sensitive data logged inappropriately
- Notification content doesn't expose private details
```

### 6.2 Access Control Tests
```yaml
Scenarios:
- Unauthorized Home Assistant access
- Network security during image processing
- API key protection and rotation
- Secure configuration storage
```

## 7. Regression Tests

### 7.1 Home Assistant Update Compatibility
```yaml
Test Matrix:
- Home Assistant core updates
- AI Tasks feature changes
- Template syntax evolution
- Integration API changes

Validation:
- All automations continue functioning
- Template sensors render correctly
- Configuration remains valid
- Performance characteristics maintained
```

### 7.2 Package Update Testing
```yaml
Scenarios:
- Clean installation on new system
- Upgrade from previous package version
- Configuration migration testing
- Backward compatibility verification
```

## 8. Acceptance Tests

### 8.1 ADHD Support Effectiveness
```yaml
Success Metrics:
- Reduction in forgotten tasks
- Improved routine compliance
- Positive behavioral reinforcement
- Reduced parental anxiety when away
- Child satisfaction with system

Measurement Period: 30 days minimum
```

### 8.2 Family Integration Success
```yaml
Criteria:
- System integrates naturally into daily routine
- Notifications are helpful, not disruptive
- Manual controls are used appropriately
- System reliability builds trust
- Maintenance requirements are minimal

User Acceptance: 
- Parent approval rating > 8/10
- Child comfort with system > 7/10
- Reduced need for manual check-ins
```

## 9. Test Automation Framework

### 9.1 Automated Test Suite
```yaml
Components:
- Template sensor validation scripts
- Mock AI service for reliable testing
- Automated notification verification
- Performance monitoring dashboards
- Daily smoke tests

CI/CD Integration:
- Pre-deployment validation
- Configuration syntax checking
- Template error detection
- Performance regression alerts
```

### 9.2 Monitoring and Alerting
```yaml
Continuous Monitoring:
- System health checks every 15 minutes
- AI service availability monitoring
- Notification delivery success rates
- Error rate thresholds and alerts

Dashboard Metrics:
- Daily detection accuracy
- Notification response times
- User interaction rates
- System uptime percentage
```

## Test Execution Schedule

### Phase 1: Component Testing (Week 1)
- Unit tests for all sensors and templates
- Individual automation verification
- Configuration validation

### Phase 2: Integration Testing (Week 2)  
- End-to-end workflow testing
- Multi-component interaction validation
- Edge case scenario testing

### Phase 3: System Testing (Week 3)
- Full daily routine simulations
- Performance and load testing
- Security and privacy verification

### Phase 4: User Acceptance (Week 4)
- Family integration testing
- Real-world scenario validation
- Feedback collection and refinement

## Configuration Quick Reference

### Troubleshooting Configuration Issues

#### System Not Detecting/Responding
1. **Check Master Switch**: Ensure `input_boolean.ai_detection_enabled` is ON
2. **Verify Monitoring Switches**: Enable specific area switches:
   - `input_boolean.kitchen_monitoring_enabled`
   - `input_boolean.family_room_monitoring_enabled` 
   - `input_boolean.dog_walk_monitoring_enabled`
3. **Enable Notifications**: Turn ON `input_boolean.notifications_enabled`
4. **Check Reminder Switches**: Enable individual reminder switches for alerts

#### No Notifications Received
1. Verify `input_boolean.notifications_enabled` is ON
2. Check specific reminder switches are enabled
3. Ensure `input_boolean.quiet_hours_active` is OFF (unless intentionally set)
4. Check that reminder switches are not snoozed

#### Override Not Working
1. Verify the correct override switch is enabled
2. Check that main monitoring is still enabled
3. Ensure override switches are used temporarily and turned off when done

#### Switch Configuration Reset
```yaml
# Copy this configuration to quickly restore recommended settings:
automation:
  - alias: "Quick Setup Configuration"
    trigger:
      - platform: homeassistant
        event: start
    action:
      - service: input_boolean.turn_on
        target:
          entity_id:
            - input_boolean.ai_detection_enabled
            - input_boolean.kitchen_monitoring_enabled
            - input_boolean.family_room_monitoring_enabled
            - input_boolean.dog_walk_monitoring_enabled
            - input_boolean.notifications_enabled
            - input_boolean.kitchen_reminders_enabled
            - input_boolean.family_room_reminders_enabled
            - input_boolean.dog_walk_reminders_enabled
```

## Success Criteria Summary

The AI Image Reminders system will be considered ready for production when:

- ✅ **Reliability**: 99%+ uptime with graceful error handling
- ✅ **Accuracy**: 90%+ correct detection across all monitoring areas  
- ✅ **Performance**: Sub-10-second response times for all operations
- ✅ **Usability**: Intuitive configuration with clear documentation
- ✅ **Integration**: Seamless Home Assistant package installation
- ✅ **Support**: Effective ADHD routine support with positive feedback
- ✅ **Maintenance**: Minimal ongoing configuration requirements

This comprehensive test plan ensures the AI Image Reminders system provides reliable, helpful, and non-intrusive support for ADHD monitoring while maintaining high technical standards and user satisfaction.
