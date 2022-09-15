import json
import re
from pathlib import Path


def add_item_names(file, names):
    with open(file) as f:
        recipe_lines = f.readlines()

    item_id_regex = re.compile(r'(\t*)"itemId": "([a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12})"')
    miss_ids = []
    # comment_line = False
    commented_lines = []
    for line in recipe_lines:
        comment_line = line.strip().startswith('//')
        if comment_line:
            continue
        if (line_search := item_id_regex.search(line)) and not comment_line:
            tabs, item_id = line_search.groups()
            if item_name := names.get(item_id):
                commented_lines.append(f'{tabs}// {item_name["title"]}\n')
            else:
                print(f'No item found for {item_id}')
                miss_ids.append(miss_ids)
        commented_lines.append(line)

    with open(file, 'w') as f:
        f.writelines(commented_lines)

    return miss_ids


if __name__ == '__main__':
    craftbot_path = Path('fant_mod/Survival/CraftingRecipes/craftbot.json')
    hideout_path = Path('fant_mod/Survival/CraftingRecipes/hideout.json')
    item_names_file = Path('item_names_fant.json')

    with open(item_names_file) as i:
        item_names = json.load(i)

    missing_ids = add_item_names(craftbot_path, item_names)
    missing_ids += add_item_names(hideout_path, item_names)
