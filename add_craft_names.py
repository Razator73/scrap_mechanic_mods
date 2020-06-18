import json
import re
from pathlib import Path


def add_item_names(file, names):
    with open(file) as f:
        recipe_lines = f.readlines()

    item_id_regex = re.compile(r'(\t*)"itemId": "([a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12})"')
    comment_line = False
    commented_lines = []
    for line in recipe_lines:
        if (line_search := item_id_regex.search(line)) and not comment_line:
            tabs, item_id = line_search.groups()
            commented_lines.append(f'{tabs}// {names[item_id]}\n')
        comment_line = line.strip().startswith('//')
        commented_lines.append(line)

    with open(file, 'w') as f:
        f.writelines(commented_lines)


if __name__ == '__main__':
    craftbot_path = Path('Install/Survival/CraftingRecipes/craftbot.json')
    hideout_path = Path('Install/Survival/CraftingRecipes/hideout.json')
    item_names_file = Path('item_names.json')

    with open(item_names_file) as i:
        item_names = json.load(i)

    add_item_names(craftbot_path, item_names)
    add_item_names(hideout_path, item_names)
