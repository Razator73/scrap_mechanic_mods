import json
from pathlib import Path


shape_sets_path = Path('new_install/Survival/Objects/Database/ShapeSets')
item_file = Path('item_names.json')
with open(item_file) as f:
    item_names = json.load(f)

non_stackables = {}
for file in shape_sets_path.glob('*.json'):
    try:
        with open(file) as f:
            shape_data = json.load(f)
        for item in shape_data.get('partList', []):
            if item.get('stackSize') is None and item.get('uuid'):
                item_name = item_names.get(item['uuid'], {'title': 'ITEM NOT FOUND'})['title']
                non_stackables[item['uuid']] = {'name': item_name, 'file': file.name}
                if input(f'Make {item_name} stackable? (y/n)').lower() == 'y':
                    item['stackSize'] = 10
        with open(file, 'w') as f:
            json.dump(shape_data, f, indent='\t')
    except json.decoder.JSONDecodeError:
        print(f'{file.name} - Probably includes comment lines')

for k, v in non_stackables.items():
    print(f'{k}: {v}')
