import re
from pathlib import Path
from PIL import Image


icon_map_folder = Path('Install') / 'Survival' / 'Gui'
icon_map_file = icon_map_folder / 'IconMapSurvival.png'
icon_map_img = Image.open(icon_map_file)
ren_container_img = Image.open('ren_container_icon.png')

while True:
    location_str = input('Input the location to input the icon:\n')
    if loc_search := re.search(r'\((\d+),\s?(\d+)\)', location_str):
        x, y = loc_search.groups()
        try:
            x = int(x)
            y = int(y)
        except ValueError:
            print('Please input the location in (x, y) format')
        try:
            assert x % 96 == 0 and y % 96 == 0, 'Must be multiple of 96'
            break
        except AssertionError:
            print('The x and y coordinates must both be a multiple of 96')
    else:
        print('Please input the location in (x, y) format')

icon_map_img.paste(ren_container_img, (x, y))
icon_map_img.save(icon_map_file)

icon_map_xml = icon_map_folder / 'IconMapSurvival.xml'
with open(icon_map_xml) as f:
    icon_map_lines = f.readlines()

ren_container_lines = ['            <Index name="d4e6c84c-a493-44b1-81aa-4f4741ea3ee0">\n',
                       f'                <Frame point="{x} {y}"/>\n',
                       '            </Index>\n']

with open(icon_map_xml, 'w') as f:
    for line in icon_map_lines[:-3] + ren_container_lines + icon_map_lines[-3:]:
        f.write(line)
