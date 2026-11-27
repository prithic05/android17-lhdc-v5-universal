import os
import zipfile

root = os.path.dirname(os.path.abspath(__file__))
out_zip = os.path.join(root, 'android17-lhdc-v5-universal-v1.0.0-magisk.zip')

exclude = {'.git', '__pycache__', os.path.basename(__file__), os.path.basename(out_zip)}

with zipfile.ZipFile(out_zip, 'w', compression=zipfile.ZIP_DEFLATED) as z:
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in exclude]
        for fn in filenames:
            if fn in exclude or fn.endswith('.zip'):
                continue
            full = os.path.join(dirpath, fn)
            rel = os.path.relpath(full, root).replace('\\', '/')
            z.write(full, rel)

with zipfile.ZipFile(out_zip, 'r') as z:
    bad = z.testzip()
    assert bad is None, f'Bad zip entry: {bad}'
print('Built and verified:', out_zip, 'size=', os.path.getsize(out_zip))
