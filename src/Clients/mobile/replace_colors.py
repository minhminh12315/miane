import os
import re

lib_dir = r"c:\Users\ADMIN\Desktop\miane\src\Clients\mobile\lib"

pattern = re.compile(r'\.withValues\(alpha:\s*([0-9a-zA-Z_\.\(\)\s\*\+\-\/]+)\)')

for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            if '.withValues' in content:
                new_content = pattern.sub(r'.withOpacity(\1)', content)
                with open(filepath, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                print(f"Updated {file}")
