#!/usr/bin/env python3
"""Fix all automation indentation issues."""

import os
import re

def fix_automation_file(filepath):
    """Fix indentation in a single automation file."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    lines = content.split('\n')
    fixed_lines = []
    in_automation = False
    
    i = 0
    while i < len(lines):
        line = lines[i]
        
        # Check if this is the start of an automation
        if re.match(r'^- id:', line):
            in_automation = True
            fixed_lines.append(line)
            i += 1
            
            # Fix the following lines (alias, description, trigger, etc.)
            while i < len(lines) and lines[i].startswith('    '):
                # Remove 2 extra spaces
                fixed_lines.append(lines[i][2:])
                i += 1
        else:
            fixed_lines.append(line)
            i += 1
    
    # Write back the fixed content
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write('\n'.join(fixed_lines))
    
    print(f"Fixed {filepath}")

# Fix all automation files
automation_dir = 'automations'
if os.path.exists(automation_dir):
    for filename in os.listdir(automation_dir):
        if filename.endswith('.yaml'):
            filepath = os.path.join(automation_dir, filename)
            fix_automation_file(filepath)
