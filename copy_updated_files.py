from pathlib import Path


def _copy(self, target):
    import shutil
    assert self.is_file()
    shutil.copy(self, target)


Path.copy = _copy

game_files_path = Path('game_files')
install_path = Path('Install')

modded_files = []
for path in install_path.glob('**/*.*'):
    modded_files.append(str(path)[8:])

for path in game_files_path.glob('**/*.*'):
    if str(path)[11:] in modded_files:
        copy_path = install_path / str(path)[11:]
        copy_dir = Path(*copy_path.parts[:-1])
        copy_dir.mkdir(parents=True, exist_ok=True)
        path.copy(copy_path)

for path in install_path.glob('**/*.*'):
    print(path)
