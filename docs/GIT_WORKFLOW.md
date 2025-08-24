# Version Control Workflow for AI Image Reminders

## Recommended Git Workflow

### 1. Always commit working versions
```bash
git add .
git commit -m "Working: Description of what's working"
git push
```

### 2. Use branches for experiments
```bash
# Create feature branch
git checkout -b feature/new-sensor-integration
# Make changes...
git add .
git commit -m "Experiment: Testing new sensors"

# If it works, merge back
git checkout master
git merge feature/new-sensor-integration

# If it breaks, just switch back
git checkout master
```

### 3. Tag stable releases
```bash
git tag -a v1.0 -m "Stable version with motion-triggered driveway"
git push --tags
```

### 4. Quick recovery commands
```bash
# See recent changes
git log --oneline -10

# Revert to previous commit
git reset --hard HEAD~1

# Revert specific file
git checkout HEAD~1 -- ai_image_reminders.yaml
```

## Backup Strategy
1. **Local Git**: Version history and branching
2. **Remote GitHub**: Backup and collaboration
3. **Deploy Script**: Quick testing iterations
4. **Tagged Releases**: Stable checkpoints

## Before Making Changes
```bash
git status                    # Check what's changed
git add .                     # Stage changes
git commit -m "Working: Description"  # Commit before experimenting
```
