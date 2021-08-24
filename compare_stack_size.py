import json
from pathlib import Path


def get_shape_data(shape_file):
    with open(shape_file) as f:
        shape_data = json.load(f)['partList']
    return {x['uuid']: x for x in shape_data}


if __name__ == '__main__':
    item_file = Path('item_names.json')
    with open(item_file) as f:
        item_names = json.load(f)

    mod_shape_sets_path = Path('new_install/Survival/Objects/Database/ShapeSets')
    game_shape_sets_path = Path('game_files/Survival/Objects/Database/ShapeSets')
    different_stack_sizes = []

    for file in [_ for _ in mod_shape_sets_path.glob('*.json') if _.name != 'blocks.json']:
        mod_shape_data = get_shape_data(file)
        game_shape_data = get_shape_data(game_shape_sets_path / file.name)

        for item_id, item_info in mod_shape_data.items():
            mod_size = item_info.get('stackSize', 1)
            game_size = game_shape_data[item_id].get('stackSize', 1)
            if mod_size != game_size:
                different_stack_sizes.append({
                    'uuid': item_id,
                    'name': item_names[item_id]['title'],
                    'mod_stack': mod_size,
                    'game_stack': game_size
                })

    print('### Items with stack size changes')
    for item in different_stack_sizes:
        print(f"* Changed {item['name']} from {item['game_stack']} to {item['mod_stack']} stack sizes")
