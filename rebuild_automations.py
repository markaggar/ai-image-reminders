#!/usr/bin/env python3
"""Completely rebuild automation files with correct structure."""

import os
import re

def completely_rebuild_automation_file(filepath):
    """Completely rebuild an automation file to fix all indentation issues."""
    
    # Read the file
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Split into lines and process
    lines = content.split('\n')
    
    # Filter out empty lines and rebuild structure
    output_lines = []
    current_automation = None
    current_section = None
    indent_stack = []
    
    i = 0
    while i < len(lines):
        line = lines[i].rstrip()
        
        if not line or line.startswith('#'):
            output_lines.append(line)
            i += 1
            continue
            
        # Detect automation start
        match = re.match(r'^-?\s*id:\s*(.+)', line)
        if match:
            # Start new automation
            output_lines.append(f"- id: {match.group(1)}")
            i += 1
            
            # Process the automation content
            while i < len(lines):
                line = lines[i].rstrip()
                
                # Skip empty lines
                if not line:
                    output_lines.append('')
                    i += 1
                    continue
                
                # Check if we hit the next automation
                next_match = re.match(r'^-?\s*id:\s*(.+)', line)
                if next_match:
                    break
                
                # Handle top-level automation keys (alias, description, trigger, condition, action)
                section_match = re.match(r'^\s*(alias|description|trigger|condition|action):\s*(.*)$', line)
                if section_match:
                    key = section_match.group(1)
                    value = section_match.group(2)
                    
                    if value:
                        output_lines.append(f"  {key}: {value}")
                    else:
                        output_lines.append(f"  {key}:")
                elif line.startswith('    -') or line.startswith('  -'):
                    # List items under trigger/condition/action
                    clean_line = line.strip()
                    output_lines.append(f"    {clean_line}")
                elif line.strip().startswith('-'):
                    # Top level list item
                    clean_line = line.strip()
                    output_lines.append(f"    {clean_line}")
                elif line.startswith('      ') or line.startswith('        '):
                    # Deep nested content
                    clean_line = line.strip()
                    if clean_line:
                        output_lines.append(f"      {clean_line}")
                elif line.startswith('    ') or line.startswith('  '):
                    # Second level content
                    clean_line = line.strip()
                    if clean_line:
                        output_lines.append(f"      {clean_line}")
                else:
                    # Default case
                    clean_line = line.strip()
                    if clean_line:
                        output_lines.append(f"    {clean_line}")
                
                i += 1
        else:
            # Regular content line
            output_lines.append(line)
            i += 1
    
    # Write the rebuilt content
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write('\n'.join(output_lines))
    
    print(f"Completely rebuilt {filepath}")

# List of automation files to fix
automation_files = [
    'automations/kitchen_monitoring.yaml',
    'automations/family_room_monitoring.yaml'
]

for filepath in automation_files:
    if os.path.exists(filepath):
        completely_rebuild_automation_file(filepath)
