import json
from pathlib import Path


add_stack_size = True
shape_sets_paths = [Path('new_install/Survival/Objects/Database/ShapeSets'),
                    Path('new_install/Data/Objects/Database/ShapeSets')]
item_file = Path('item_names.json')
with open(item_file) as f:
    item_names = json.load(f)

non_stackables = {}
for file in [_ for path in shape_sets_paths for _ in path.glob('*.json')]:
    try:
        with open(file) as f:
            shape_data = json.load(f)
        for item in shape_data.get('partList', []):
            if item.get('stackSize') is None and item.get('uuid'):
                item_name = item_names.get(item['uuid'], {'title': 'ITEM NOT FOUND'})['title']
                non_stackables[item['uuid']] = {'name': item_name, 'file': file.name}
                size = input(f'Make {item_name} stackable? (y/n)')
                if add_stack_size and size.lower()[0] != 'n':
                    try:
                        size = int(size)
                        item['stackSize'] = size
                    except ValueError:
                        item['stackSize'] = 10
        with open(file, 'w') as f:
            json.dump(shape_data, f, indent='\t')
    except json.decoder.JSONDecodeError:
        print(f'{file.name} - Probably includes comment lines')

for k, v in non_stackables.items():
    print(f'{k}: {v}')
