from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
import hashlib
import re

root=Path(__file__).resolve().parents[1]
version=re.search(r'^version: (.+)$',(root/'definition.yml').read_text(encoding='utf-8'),re.M)[1]
out=root/'dist'/f'ui-{version}.zip'
out.parent.mkdir(exist_ok=True)
files=[root/name for name in ('definition.yml','init.lua','README.md','LICENSE','CHANGELOG.md')]
for name in ('manager','patches','ui','locale'):
    files.extend(p for p in (root/name).rglob('*') if p.is_file())
with ZipFile(out,'w',ZIP_DEFLATED) as archive:
    for path in sorted(files): archive.write(path,path.relative_to(root).as_posix())
digest=hashlib.sha256(out.read_bytes()).hexdigest()
out.with_suffix('.zip.sha256').write_text(f'{digest}  {out.name}\n',encoding='utf-8')
print(out)
