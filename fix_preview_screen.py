#!/usr/bin/env python3
"""Script to fix invoice_preview_screen.dart by removing old PDF styles"""

import re

# Read the backup file
with open('lib/presentation/screens/invoice/invoice_preview_screen.dart.backup', 'r') as f:
    content = f.read()

# Fix line 44: Change DocumentStyle.minimal to DocumentStyle.minimalist
content = content.replace(
    'DocumentStyle _selectedStyle = DocumentStyle.minimal;',
    'DocumentStyle _selectedStyle = DocumentStyle.minimalist;'
)

# Remove all case statements for old styles in _buildDocumentContent
# Find the _buildDocumentContent method and replace it
old_build_content_pattern = r'Widget _buildDocumentContent\(\) \{.*?case DocumentStyle\.minimal:.*?return _buildMinimalDocument\(\);.*?case DocumentStyle\.bold:.*?return _buildBoldDocument\(\);.*?case DocumentStyle\.classic:.*?return _buildClassicDocument\(\);.*?case DocumentStyle\.modern:.*?return _buildCreativeDocument\(\);.*?case DocumentStyle\.elegant:.*?return _buildDarkDocument\(\);.*?case DocumentStyle\.corporate:.*?return _buildCorporateDocument\(\);'

new_build_content = '''Widget _buildDocumentContent() {
    switch (_selectedStyle) {
      case DocumentStyle.minimalist:
        return _buildMinimalistDocument();
      case DocumentStyle.modernCorporate:
        return _buildModernCorporateDocument();
      case DocumentStyle.elegantDark:
        return _buildElegantDarkDocument();
      case DocumentStyle.cleanBlue:
        return _buildCleanBlueDocument();
      case DocumentStyle.compact:
        return _buildCompactDocument();
      case DocumentStyle.modernStriped:
        return _buildModernStripedDocument();
    }
  }'''

# This is complex, so let's use a simpler approach - find and remove specific lines
lines = content.split('\n')
new_lines = []
skip_until = None

for i, line in enumerate(lines):
    # Skip old style cases
    if 'case DocumentStyle.minimal:' in line and 'minimalist' not in line:
        skip_until = 'return _buildMinimalDocument();'
        continue
    if 'case DocumentStyle.bold:' in line:
        skip_until = 'return _buildBoldDocument();'
        continue  
    if 'case DocumentStyle.classic:' in line:
        skip_until = 'return _buildClassicDocument();'
        continue
    if 'case DocumentStyle.modern:' in line and 'modernCorporate' not in line and 'modernStriped' not in line:
        skip_until = 'return _buildCreativeDocument();'
        continue
    if 'case DocumentStyle.elegant:' in line and 'elegantDark' not in line:
        skip_until = 'return _buildDarkDocument();'
        continue
    if 'case DocumentStyle.corporate:' in line and 'modernCorporate' not in line:
        skip_until = 'return _buildCorporateDocument();'
        continue
    
    if skip_until and skip_until in line:
        skip_until = None
        continue
        
    if not skip_until:
        new_lines.append(line)

content = '\n'.join(new_lines)

# Write the fixed file
with open('lib/presentation/screens/invoice/invoice_preview_screen.dart', 'w') as f:
    f.write(content)

print("File fixed successfully!")
