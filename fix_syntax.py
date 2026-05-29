import os
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Remove 'const ' before ColorPalette
    new_content = re.sub(r'const\s+ColorPalette\.', 'ColorPalette.', content)
    
    # In vocabulary_studio_view.dart:307
    # const ColorPalette.secondary.withValues(alpha: 0.3) -> ColorPalette.secondary.withValues(alpha: 0.3)
    # The regex above already handles this.
    
    if new_content != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Fixed syntax in {filepath}")

for root, _, files in os.walk('lib/features'):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))
