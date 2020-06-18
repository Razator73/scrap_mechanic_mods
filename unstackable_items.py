import json
from pathlib import Path


shape_sets_path = Path('game_files/Survival/Objects/Database/ShapeSets')


for file in shape_sets_path.glob('*.json'):
    print(file)
    try:
        with open(file) as f:
            data = json.load(f)
        print(data.keys())
    except json.decoder.JSONDecodeError:
        print('Probably includes comment lines')
