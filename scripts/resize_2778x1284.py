import sys, os
from PIL import Image

SRC = r"C:\\Users\\Admin\\AndroidStudioProjects\\attachments"
DST = os.path.join(SRC, 'converted_2778x1284')
SIZE = (2778, 1284)
EXTS = {'.png','.jpg','.jpeg','.webp','.heic','.heif'}

os.makedirs(DST, exist_ok=True)

def convert(path):
    name, ext = os.path.splitext(os.path.basename(path))
    ext_lower = ext.lower()
    if ext_lower not in EXTS:
        return None
    try:
        with Image.open(path) as im:
            im = im.convert('RGBA') if im.mode in ('P','LA') else im.convert('RGB')
            src_w, src_h = im.size
            tgt_w, tgt_h = SIZE
            # center-crop to target aspect ratio, then resize
            src_ratio = src_w / src_h
            tgt_ratio = tgt_w / tgt_h
            if abs(src_ratio - tgt_ratio) > 1e-3:
                if src_ratio > tgt_ratio:
                    # source wider -> crop width
                    new_w = int(src_h * tgt_ratio)
                    left = (src_w - new_w) // 2
                    box = (left, 0, left + new_w, src_h)
                else:
                    # source taller -> crop height
                    new_h = int(src_w / tgt_ratio)
                    top = (src_h - new_h) // 2
                    box = (0, top, src_w, top + new_h)
                im = im.crop(box)
            out = im.resize(SIZE, Image.LANCZOS)
            out_path = os.path.join(DST, f"{name}_2778x1284.jpg")
            out.save(out_path, 'JPEG', quality=92, optimize=True, progressive=True)
            return out_path
    except Exception as e:
        print(f"[error] {path}: {e}")
        return None

if __name__ == '__main__':
    count = 0
    for entry in os.scandir(SRC):
        if not entry.is_file():
            continue
        p = entry.path
        outp = convert(p)
        if outp:
            print('[ok]', outp)
            count += 1
    print(f"[done] created {count} images in {DST}")
