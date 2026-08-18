import os
from collections import defaultdict
from PIL import Image

folder = r"E:\DOCUMENTS\MELISSA\.DOLLZ STUFF\dollz assets\goth - punk\female\bodies"

def get_skin_color_key(image_path):
    """Extracts non-transparent pixel RGB values to group identical skin colors."""
    try:
        with Image.open(image_path) as img:
            img = img.convert("RGBA")
            # Using updated Pillow method to prevent deprecation warning
            pixels = list(img.get_flattened_data())
            # Convert flattened list into tuple RGBAs
            pixels_rgba = [pixels[i:i+4] for i in range(0, len(pixels), 4)]
            
            # Ignore fully transparent background pixels
            opaque = [p[:3] for p in pixels_rgba if p[3] > 0]
            if not opaque:
                return None
            
            # Find the most frequent color (primary skin tone)
            counts = defaultdict(int)
            for rgb in opaque:
                counts[tuple(rgb)] += 1
            primary_color = max(counts.items(), key=lambda x: x[1])[0]
            
            # Calculate brightness for sorting lightest to darkest
            r, g, b = primary_color
            brightness = (0.299 * r) + (0.587 * g) + (0.114 * b)
            return (primary_color, brightness)
    except Exception:
        return None

def get_letter_code(index):
    """Converts 0 -> A, 1 -> B, 25 -> Z, 26 -> AA, 27 -> AB..."""
    result = ""
    while index >= 0:
        result = chr(65 + (index % 26)) + result
        index = (index // 26) - 1
    return result

# 1. Collect and group all files by pixel skin color
color_groups = defaultdict(list)

for fname in os.listdir(folder):
    if fname.lower().endswith(('.gif', '.png')):
        full_path = os.path.join(folder, fname)
        color_data = get_skin_color_key(full_path)
        if color_data:
            primary_rgb, brightness = color_data
            color_groups[primary_rgb].append((fname, full_path, brightness))

# 2. Sort color groups from lightest to darkest skin tone
sorted_colors = sorted(color_groups.keys(), key=lambda rgb: color_groups[rgb][0][2], reverse=True)

# 3. Assign sequential letters (A, B, C...) and rename files
for color_idx, rgb_color in enumerate(sorted_colors):
    letter_code = get_letter_code(color_idx)
    files_in_group = color_groups[rgb_color]
    files_in_group.sort(key=lambda x: x[0])  # Sort filenames naturally

    for item_idx, (fname, old_path, _) in enumerate(files_in_group, start=1):
        ext = os.path.splitext(fname)[1]
        
        # New name format: body_A_01.gif, body_A_02.gif, body_B_01.gif, etc.
        new_name = f"body_{letter_code}_{item_idx:02d}{ext}"
        new_path = os.path.join(folder, new_name)

        if old_path != new_path:
            # Temporary rename stage to prevent file collisions
            temp_path = os.path.join(folder, f"temp_{fname}")
            os.rename(old_path, temp_path)
            os.rename(temp_path, new_path)
            print(f"Renamed: '{fname}' -> '{new_name}' (Tone Group {letter_code})")