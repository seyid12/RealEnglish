import os
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # If it's already using animate_do, skip to prevent double imports
    if "import 'package:animate_do/animate_do.dart';" not in content:
        # Add imports
        import_str = "import 'package:animate_do/animate_do.dart';\nimport '../../../core/widgets/animated_background.dart';\nimport '../../../core/widgets/glassmorphic_card.dart';\n"
        # For top level core/theme imports usually at the top
        content = re.sub(r"(import 'package:flutter/material\.dart';\n)", r"\1" + import_str, content)

    # 1. Update Scaffolds to use AnimatedBackground
    # Match: body: SafeArea( child: ListView( ... ) )
    # Replace with: body: AnimatedBackground( child: SafeArea( child: FadeInUp( child: ListView( ... ) ) ) )
    
    if "AnimatedBackground(" not in content:
        # We need to wrap the body of Scaffold in AnimatedBackground
        # Just find `body: ` and replace it, but we can't easily parse AST in python. 
        # A simpler way for these specific views:
        content = re.sub(r"(body:\s*)(SafeArea\()", r"\1AnimatedBackground(child: \2", content)
        # And we need to add a closing parenthesis, but we can also just do this manually for the 4 views.

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

# We will just write specialized scripts or replace_file_content for the views since they vary slightly.
