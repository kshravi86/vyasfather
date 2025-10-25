import os
from PIL import Image, ImageOps

SRC = r"C:\\Users\\Admin\\AndroidStudioProjects\\attachments"
DST = os.path.join(SRC, 'converted_2778x1284_nocrop')
TARGET = (2778, 1284)
EXTS = {'.png', '.jpg', '.jpeg', '.webp', '.heic', '.heif'}
BG_COLOR = (0, 0, 0)  # black background padding

os.makedirs(DST, exist_ok=True)

for entry in os.scandir(SRC):
    if not entry.is_file():
        continue
    name, ext = os.path.splitext(entry.name)
    if ext.lower() not in EXTS:
        continue
    try:
        with Image.open(entry.path) as im:
            # Convert to RGB for JPEG
            if im.mode in ('P', 'LA'):
                im = im.convert('RGBA')
            if im.mode == 'RGBA':
                bg = Image.new('RGBA', im.size, (0, 0, 0, 0))
                im = Image.alpha_composite(bg, im).convert('RGB')
            else:
                im = im.convert('RGB')

            # Scale to fit (no crop), then pad to exact size
            resized = ImageOps.contain(im, TARGET, Image.LANCZOS)
            canvas = Image.new('RGB', TARGET, BG_COLOR)
            x = (TARGET[0] - resized.size[0]) // 2
            y = (TARGET[1] - resized.size[1]) // 2
            canvas.paste(resized, (x, y))
            out_path = os.path.join(DST, f"{name}_2778x1284.jpg")
            canvas.save(out_path, 'JPEG', quality=92, optimize=True, progressive=True)
            print('[ok]', out_path)
    except Exception as e:
        print(f"[error] {entry.path}: {e}")
print(f"[done] outputs in {DST}")
