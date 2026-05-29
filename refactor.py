import os

replacements = {
    'VocabularyRepository': 'WordVaultManager',
    'vocabularyRepositoryProvider': 'wordVaultManagerProvider',
    'vocabulary_repository.dart': 'word_vault_manager.dart',
    'ControlPanelSettings': 'CommandCenterState',
    'ControlPanelNotifier': 'CommandCenterNotifier',
    'controlPanelProvider': 'commandCenterProvider',
    'control_panel_provider.dart': 'command_center_state.dart',
    'WordRecord': 'LexiconEntity',
    'word_record.dart': 'lexicon_entity.dart',
    'word_record.g.dart': 'lexicon_entity.g.dart',
    'WordRecordAdapter': 'LexiconEntityAdapter'
}

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    new_content = content
    for old, new in replacements.items():
        new_content = new_content.replace(old, new)
        
    if new_content != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Updated {filepath}")

for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))

if os.path.exists('test'):
    for root, _, files in os.walk('test'):
        for file in files:
            if file.endswith('.dart'):
                process_file(os.path.join(root, file))
