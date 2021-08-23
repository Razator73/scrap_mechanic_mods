import json
from pathlib import Path


survival_item_file = Path('game_files') / 'Survival' / 'Gui' / 'Language' / 'English' / 'inventoryDescriptions.json'
data_item_file = Path('game_files') / 'Data' / 'Gui' / 'Language' / 'English' / 'InventoryItemDescriptions.json'

# remove comment lines
# item_lines = []
with open(survival_item_file) as f:
    item_names = json.load(f)
with open(data_item_file) as f:
    item_names = {**item_names, **json.load(f)}

save_item_file = Path('item_names.json')
with open(save_item_file, 'w') as f:
    json.dump(item_names, f, indent=2)
