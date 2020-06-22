from pathlib import Path


new_item_file = Path('game_files') / 'Survival' / 'CraftingRecipes' / 'item_names.json'

# remove comment lines
with open(new_item_file) as f:
    item_lines = f.readlines()

save_item_file = Path('item_names.json')
with open(save_item_file, 'w') as f:
    for line in [x for x in item_lines if not x.lstrip().startswith('//')]:
        f.write(line)
