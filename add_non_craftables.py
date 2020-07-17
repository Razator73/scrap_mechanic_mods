import json
from pathlib import Path


craftbot_file = Path('Install') / 'Survival' / 'CraftingRecipes' / 'craftbot.json'
non_craft_file = Path('non_craftable.json')

with open(non_craft_file) as f:
    non_craftables = json.load(f)

with open(craftbot_file) as f:
    craftbot_lines = f.readlines()

craftbot_lines = craftbot_lines[:-2]

template_list = [
    '\t}},\n\t{{', '\t\t// {item_name}', '\t\t"itemId": "{item_id}",',
    '\t\t"quantity": 1,', '\t\t"craftTime": 7,', '\t\t"ingredientList": [', '\t\t\t{{',
    '\t\t\t\t"quantity": 1,', '\t\t\t\t// blk_scrapstone',
    '\t\t\t\t"itemId": "30a2288b-e88e-4a92-a916-1edbfc2b2dac"', '\t\t\t}}', '\t\t]'
]
item_template = '\n'.join(template_list)

for item_id, item_info in non_craftables.items():
    if item_id != 'f08d772f-9851-47b4-83ef-6da7e7cba8cb':
        craftbot_lines.append(item_template.format(item_id=item_id, item_name=item_info['name']))

craftbot_lines.append('\n\t}\n]')

with open(craftbot_file, 'w') as f:
    f.writelines(craftbot_lines)
