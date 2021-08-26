import json
from pathlib import Path


def get_shape_data(shape_file):
    with open(shape_file) as f:
        shape_data = json.load(f)['partList']
    return {x['uuid']: x for x in shape_data}


def read_json_with_comments(json_file):
    with open(json_file) as f:
        non_comment_lines = [line for line in f.readlines() if not line.strip().startswith('//')]
    return json.loads(''.join(non_comment_lines))


def get_stack_size_differences(mod_folder, game_folder, item_names):
    mod_shape_sets_path = mod_folder / 'Objects' / 'Database' / 'ShapeSets'
    game_shape_sets_path = game_folder / 'Objects' / 'Database' / 'ShapeSets'
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


def gather_item_recipes(data):
    recipes = {}
    for recipe in data:
        recipes.setdefault(recipe['itemId'], [])
        recipes[recipe['itemId']].append(recipe)
    return recipes


def compare_mats(mod_mats, game_mats):
    changes = []
    mod_mat_ids = [x['itemId'] for x in mod_mats]
    game_mat_ids = [x['itemId'] for x in game_mats]
    mod_only_mat_ids = [x for x in mod_mat_ids if x not in game_mat_ids]
    game_only_mat_ids = [x for x in game_mat_ids if x not in mod_mat_ids]
    both_mat_ids = [x for x in mod_mat_ids if x in game_mat_ids]
    for item_id in both_mat_ids:
        mod_quantity = [x['quantity'] for x in mod_mats if x['itemId'] == item_id][0]
        game_quantity = [x['quantity'] for x in game_mats if x['itemId'] == item_id][0]
        if mod_quantity != game_quantity:
            changes.append((item_id, f'changed amount from {game_quantity} to {mod_quantity}'))
    for item_id in mod_only_mat_ids:
        quantity = [x['quantity'] for x in mod_mats if x['itemId'] == item_id][0]
        changes.append((item_id, f'added taking {quantity} of the item'))
    for item_id in game_only_mat_ids:
        changes.append((item_id, 'remove this item requirement'))
    return changes


def compare_recipe(mod_recipe, game_recipe):
    changes = {}
    for k, v in mod_recipe.items():
        # print(k)
        if not isinstance(v, list) and game_recipe[k] != v:
            changes[k] = f'changed from {game_recipe[k]} to {v}'
        elif isinstance(v, list):
            # print(v)
            if mat_changes := compare_mats(v, game_recipe[k]):
                changes[k] = mat_changes
    return changes


def compare_item_recipes(mod_recipes, game_recipes):
    modded = []
    added = []
    removed = []
    for i in range(min(len(game_recipes), len(mod_recipes))):
        if changes := compare_recipe(mod_recipes[i], game_recipes[i]):
            modded.append(changes)
    if len(mod_recipes) > len(game_recipes):
        added += mod_recipes[len(game_recipes):]
    if len(mod_recipes) < len(game_recipes):
        removed += game_recipes[len(mod_recipes):]
    return modded, added, removed


def recipe_compare(mod_file, game_file):
    mod_data = read_json_with_comments(mod_file)
    game_data = read_json_with_comments(game_file)
    mod_item_recipes = gather_item_recipes(mod_data)
    game_item_recipes = gather_item_recipes(game_data)
    recipe_changes = {'added_recipes': [], 'modified_recipes': {}}
    for item_id, mod_recipes in mod_item_recipes.items():
        if game_recipes := game_item_recipes.get(item_id):
            # print(item_id)
            modded, added, removed = compare_item_recipes(mod_recipes, game_recipes)
            if modded or added or removed:
                recipe_changes['modified_recipes'][item_id] = {'modded': modded, 'added': added, 'removed': removed}
        else:
            recipe_changes['added_recipes'] += mod_recipes
    return recipe_changes


if __name__ == '__main__':
    mod_survival = Path('new_install') / 'Survival'
    game_survival = Path('game_files') / 'Survival'
    item_file = Path('item_names.json')
    with open(item_file) as item_file_obj:
        all_item_names = json.load(item_file_obj)

    get_stack_size_differences(mod_survival, game_survival, all_item_names)

    # compare craftbot and hideout additions
    # WIP as the recipes don't have unique identifiers
    # which makes it hard to compare when an item has multiple recipes
    recipe_files = ['craftbot.json', 'hideout.json']
    recipe_data = {}
    for recipe_file in recipe_files:
        recipe_data[recipe_file] = recipe_compare(mod_survival / 'CraftingRecipes' / recipe_file,
                                                  game_survival / 'CraftingRecipes' / recipe_file)
