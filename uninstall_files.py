from pathlib import Path


def _copy(self, target):
    import shutil
    assert self.is_file()
    shutil.copy(self, target)


Path.copy = _copy

game_files_path = Path('game_files')
uninstall_path = Path('Uninstall')
install_path = Path('Install')

modded_files = []
for path in install_path.glob('**/*.*'):
    modded_files.append(str(path)[8:])

for path in game_files_path.glob('**/*.*'):
    if str(path)[11:] in modded_files:
        copy_path = uninstall_path / str(path)[11:]
        copy_path.mkdir(parents=True, exist_ok=True)
        path.copy(copy_path)

for path in uninstall_path.glob('**/*.*'):
    print(path)
