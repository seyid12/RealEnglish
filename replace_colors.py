import os
import re

replacements = {
    # Replace constants definitions
    r'const _kBg = Color\(0xFF1A1A2E\);': "const _kBg = ColorPalette.background;",
    r'const _kCard = Color\(0xFF12122A\);': "const _kCard = ColorPalette.surface;",
    r'const _kAccent = Color\(0xFF4A7FD4\);': "const _kAccent = ColorPalette.primary;",
    r'const _kText = Color\(0xFFE0E0FF\);': "const _kText = ColorPalette.textPrimary;",
    r'const _kSubtext = Color\(0xFF8888AA\);': "const _kSubtext = ColorPalette.textSecondary;",
    
    r'const _kCellNormal = Color\(0xFF2D2D44\);': "const _kCellNormal = ColorPalette.cellNormal;",
    r'const _kCellSelected = Color\(0xFF3A4A6B\);': "const _kCellSelected = ColorPalette.cellSelected;",
    r'const _kCellCursor = Color\(0xFF4A7FD4\);': "const _kCellCursor = ColorPalette.cellCursor;",
    r'const _kCellCorrect = Color\(0xFF2D6A4F\);': "const _kCellCorrect = ColorPalette.cellCorrect;",
    r'const _kTextNormal = Color\(0xFFE0E0FF\);': "const _kTextNormal = ColorPalette.textPrimary;",
    r'const _kTextCorrect = Color\(0xFF74C69D\);': "const _kTextCorrect = ColorPalette.textDark;",
    r'const _kKeyBg = Color\(0xFF252540\);': "const _kKeyBg = ColorPalette.surface;",
    r'const _kKeyPressed = Color\(0xFF4A7FD4\);': "const _kKeyPressed = ColorPalette.primary;",
    
    r'const _kSuccess = Color\(0xFF2D6A4F\);': "const _kSuccess = ColorPalette.success;",
    r'const _kDanger = Color\(0xFFD44A4A\);': "const _kDanger = ColorPalette.error;",

    # Inline colors
    r'Color\(0xFF12122A\)': 'ColorPalette.surface',
    r'Color\(0xFF0F0F20\)': 'ColorPalette.background',
    r'Color\(0xFF3A2A2A\)': 'ColorPalette.surfaceLighter',
    r'Color\(0xFF2D6A4F\)': 'ColorPalette.success',
    r'Color\(0xFF7C3AED\)': 'ColorPalette.secondary',
    r'Color\(0xFF2D9E6A\)': 'ColorPalette.success',
    r'Color\(0xFFD4A017\)': 'ColorPalette.warning',
    r'Color\(0xFFD44A4A\)': 'ColorPalette.error',
    r'Color\(0xFFCCCCEE\)': 'ColorPalette.textSecondary',
}

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    new_content = content
    for old, new in replacements.items():
        new_content = re.sub(old, new, new_content)
        
    if new_content != content:
        # Add import if missing
        if "ColorPalette" in new_content and "color_palette.dart" not in new_content:
            # simple logic to find depth
            depth = filepath.count('/') - 1
            prefix = "../" * depth if depth > 0 else "./"
            if depth == 4: # e.g. lib/features/arena/view/view.dart
                prefix = "../../../"
            if depth == 5:
                prefix = "../../../../"
            
            import_statement = f"import '{prefix}core/theme/color_palette.dart';\n"
            
            # Add after first import
            lines = new_content.split('\n')
            for i, line in enumerate(lines):
                if line.startswith('import '):
                    lines.insert(i + 1, import_statement)
                    break
            new_content = '\n'.join(lines)

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Updated {filepath}")

for root, _, files in os.walk('lib/features'):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))
