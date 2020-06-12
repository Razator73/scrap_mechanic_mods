import json
import re
from pathlib import Path


craftbot_path = Path('Install/Survival/CraftingRecipes/craftbot.json')
item_names_file = Path('item_names.json')

with open(item_names_file) as f:
    item_names = json.load(f)

with open(craftbot_path) as f:
    craftbot_lines = f.readlines()

item_id_regex = re.compile(r'(\t*)"itemId": "([a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12})"')
commented_lines = []
for line in craftbot_lines:
    if line_search := item_id_regex.search(line):
        tabs, item_id = line_search.groups()
        commented_lines.append(f'{tabs}// {item_names[item_id]}\n')
    commented_lines.append(line)

with open(craftbot_path, 'w') as f:
    f.writelines(commented_lines)
