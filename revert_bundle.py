import os

def replace_in_file(filepath, old_text, new_text):
    if not os.path.exists(filepath):
        return
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    new_content = content.replace(old_text, new_text)
    if new_content != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Reverted bundle ID in {filepath}")

# iOS/macOS replacements
for pbx in [
    'ios/Runner.xcodeproj/project.pbxproj',
    'macos/Runner.xcodeproj/project.pbxproj',
    'macos/Runner/Configs/AppInfo.xcconfig'
]:
    replace_in_file(pbx, 'com.realenglish.crossword.adventure', 'com.aienglish.aienglishCengelBulmaca')

# Android replacements
replace_in_file('android/app/build.gradle.kts', 'com.realenglish.crossword.adventure', 'com.aienglish.aienglish_cengel_bulmaca')
replace_in_file('android/app/src/main/kotlin/com/realenglish/crossword/adventure/MainActivity.kt', 'com.realenglish.crossword.adventure', 'com.aienglish.aienglish_cengel_bulmaca')

# Linux replacement
replace_in_file('linux/CMakeLists.txt', 'com.realenglish.crossword.adventure', 'com.aienglish.aienglish_cengel_bulmaca')
