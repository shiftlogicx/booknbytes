import os
import math
from PIL import Image, ImageDraw, ImageFont, ImageFilter

def create_master_icon(size=2048):
    # Render at 2048x2048 then downsample with LANCZOS for super crisp quality
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    center = size / 2

    # 1. Background: Deep obsidian gradient with squircle mask or full bleed for iOS
    # iOS icons must have an opaque background (no transparency)
    bg = Image.new("RGB", (size, size), (11, 15, 25))
    bg_draw = ImageDraw.Draw(bg)

    # Radial ambient glow in center
    for r in range(int(size * 0.75), 0, -10):
        alpha = int(45 * (1.0 - (r / (size * 0.75))))
        # Amber / emerald glow
        glow_color = (16, 38, 32) if r > size * 0.4 else (28, 48, 40)
        bg_draw.ellipse(
            [center - r, center - r, center + r, center + r],
            fill=glow_color
        )

    # Convert bg to RGBA
    img = bg.convert("RGBA")
    draw = ImageDraw.Draw(img)

    # 2. Outer Luxury Hex / Circular Golden Sweep Border
    border_radius = size * 0.42
    # Double gold metallic ring
    for i in range(12):
        r = border_radius - i
        color = (245, 180, 50, 220) if i % 2 == 0 else (212, 175, 55, 255)
        draw.ellipse([center - r, center - r, center + r, center + r], outline=color, width=2)

    inner_glow_radius = border_radius - 16
    draw.ellipse(
        [center - inner_glow_radius, center - inner_glow_radius, center + inner_glow_radius, center + inner_glow_radius],
        outline=(0, 229, 153, 160),
        width=5
    )

    # 3. Crossed Silverware (Fork and Knife) in gold / silver behind the cloche
    # Let's draw crossed knife & fork handles
    silver_color = (226, 232, 240, 220)
    gold_accent = (245, 180, 50, 240)

    # Draw crossed lines / cutlery beneath platter
    cutlery_len = size * 0.28
    cutlery_y_center = size * 0.58

    # Left to right diagonal (Fork/Knife)
    draw.line(
        [(center - cutlery_len, cutlery_y_center - cutlery_len * 0.6),
         (center + cutlery_len, cutlery_y_center + cutlery_len * 0.6)],
        fill=silver_color,
        width=int(size * 0.02)
    )
    # Right to left diagonal
    draw.line(
        [(center + cutlery_len, cutlery_y_center - cutlery_len * 0.6),
         (center - cutlery_len, cutlery_y_center + cutlery_len * 0.6)],
        fill=silver_color,
        width=int(size * 0.02)
    )

    # Platter Rim (horizontal ellipse base)
    platter_width = size * 0.32
    platter_height = size * 0.08
    platter_y = size * 0.58

    # Platter shadow / glow
    draw.ellipse(
        [center - platter_width - 8, platter_y - platter_height - 6,
         center + platter_width + 8, platter_y + platter_height + 6],
        fill=(0, 229, 153, 90)
    )

    # Platter body
    draw.ellipse(
        [center - platter_width, platter_y - platter_height,
         center + platter_width, platter_y + platter_height],
        fill=(212, 175, 55, 255),
        outline=(255, 223, 100, 255),
        width=int(size * 0.015)
    )

    # 4. Cloche Dome (Half ellipse above platter)
    dome_width = size * 0.26
    dome_height = size * 0.24
    dome_bottom = platter_y

    # Dome shadow & body
    draw.pieslice(
        [center - dome_width, dome_bottom - dome_height * 2,
         center + dome_width, dome_bottom],
        start=180, end=360,
        fill=(245, 175, 45, 255),
        outline=(255, 225, 120, 255),
        width=int(size * 0.016)
    )

    # Inner Dome Luxury Highlight
    inner_dome_w = dome_width * 0.82
    inner_dome_h = dome_height * 0.82
    draw.arc(
        [center - inner_dome_w, dome_bottom - inner_dome_h * 2 - 4,
         center + inner_dome_w, dome_bottom - 4],
        start=195, end=275,
        fill=(255, 255, 255, 180),
        width=int(size * 0.016)
    )

    # Cloche Handle Knob (Top)
    knob_r = size * 0.038
    knob_y = dome_bottom - dome_height * 2 + 10
    draw.ellipse(
        [center - knob_r, knob_y - knob_r, center + knob_r, knob_y + knob_r],
        fill=(255, 220, 90, 255),
        outline=(255, 255, 255, 220),
        width=int(size * 0.008)
    )

    # Cloche Base Lip
    lip_w = dome_width * 1.05
    lip_h = size * 0.02
    draw.rounded_rectangle(
        [center - lip_w, dome_bottom - lip_h, center + lip_w, dome_bottom + lip_h],
        radius=int(size * 0.01),
        fill=(212, 160, 30, 255),
        outline=(255, 230, 110, 255),
        width=int(size * 0.006)
    )

    # 5. Rising Aroma / Flavor Steam Wisps
    steam_color = (0, 229, 153, 200)
    steam_w = int(size * 0.012)
    # Center steam wisp
    draw.arc([center - size*0.03, knob_y - size*0.12, center + size*0.03, knob_y - size*0.04], start=220, end=360, fill=steam_color, width=steam_w)
    draw.arc([center - size*0.03, knob_y - size*0.18, center + size*0.03, knob_y - size*0.10], start=160, end=290, fill=steam_color, width=steam_w)

    # Left steam wisp
    draw.arc([center - size*0.09, knob_y - size*0.10, center - size*0.04, knob_y - size*0.03], start=210, end=350, fill=steam_color, width=steam_w)

    # Right steam wisp
    draw.arc([center + size*0.04, knob_y - size*0.10, center + size*0.09, knob_y - size*0.03], start=170, end=310, fill=steam_color, width=steam_w)

    # 6. Top Text: "BookNBytes" in elegant bold sans/serif
    # Let's try to load a nice system font or default font
    font_top = None
    font_badge = None
    try:
        font_top = ImageFont.truetype("/System/Library/Fonts/SFNS.ttf", int(size * 0.065))
        font_badge = ImageFont.truetype("/System/Library/Fonts/SFNS.ttf", int(size * 0.045))
    except Exception:
        try:
            font_top = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", int(size * 0.065))
            font_badge = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", int(size * 0.045))
        except Exception:
            font_top = ImageFont.load_default()
            font_badge = ImageFont.load_default()

    brand_text = "BookNBytes"
    if font_top:
        bbox = draw.textbbox((0, 0), brand_text, font=font_top)
        text_w = bbox[2] - bbox[0]
        text_h = bbox[3] - bbox[1]
        text_x = center - text_w / 2
        text_y = size * 0.17
        # Shadow
        draw.text((text_x + 3, text_y + 3), brand_text, fill=(0, 0, 0, 180), font=font_top)
        # Gradient effect / Gold text
        draw.text((text_x, text_y), brand_text, fill=(255, 255, 255, 255), font=font_top)

    # 7. Bottom Badge: "RESTAURANT" in bold pill badge
    badge_text = "RESTAURANT"
    badge_w = size * 0.44
    badge_h = size * 0.095
    badge_x1 = center - badge_w / 2
    badge_y1 = size * 0.72
    badge_x2 = center + badge_w / 2
    badge_y2 = badge_y1 + badge_h

    # Badge glow
    draw.rounded_rectangle(
        [badge_x1 - 6, badge_y1 - 4, badge_x2 + 6, badge_y2 + 6],
        radius=int(badge_h / 2),
        fill=(0, 229, 153, 90)
    )

    # Badge body: Emerald gradient
    draw.rounded_rectangle(
        [badge_x1, badge_y1, badge_x2, badge_y2],
        radius=int(badge_h / 2),
        fill=(0, 200, 130, 255),
        outline=(255, 255, 255, 220),
        width=int(size * 0.008)
    )

    if font_badge:
        bbox_b = draw.textbbox((0, 0), badge_text, font=font_badge)
        bw = bbox_b[2] - bbox_b[0]
        bh = bbox_b[3] - bbox_b[1]
        bx = center - bw / 2
        by = badge_y1 + (badge_h - bh) / 2 - 4
        # Shadow
        draw.text((bx + 2, by + 2), badge_text, fill=(0, 50, 30, 200), font=font_badge)
        draw.text((bx, by), badge_text, fill=(255, 255, 255, 255), font=font_badge)

    # Convert to pure RGB as iOS App Icons cannot have alpha channels
    final_rgb = Image.new("RGB", (size, size), (11, 15, 25))
    final_rgb.paste(img, (0, 0), img)
    return final_rgb

def main():
    out_dir = "/Users/amitjaydeepsinghthakur/BookNBytes/hotel_app/ios/Runner/Assets.xcassets/AppIcon.appiconset"
    master = create_master_icon(2048)

    # Icon specifications from Contents.json
    icon_specs = [
        ("Icon-App-1024x1024@1x.png", 1024),
        ("Icon-App-20x20@1x.png", 20),
        ("Icon-App-20x20@2x.png", 40),
        ("Icon-App-20x20@3x.png", 60),
        ("Icon-App-29x29@1x.png", 29),
        ("Icon-App-29x29@2x.png", 58),
        ("Icon-App-29x29@3x.png", 87),
        ("Icon-App-40x40@1x.png", 40),
        ("Icon-App-40x40@2x.png", 80),
        ("Icon-App-40x40@3x.png", 120),
        ("Icon-App-60x60@2x.png", 120),
        ("Icon-App-60x60@3x.png", 180),
        ("Icon-App-76x76@1x.png", 76),
        ("Icon-App-76x76@2x.png", 152),
        ("Icon-App-83.5x83.5@2x.png", 167),
    ]

    for filename, px in icon_specs:
        resized = master.resize((px, px), Image.Resampling.LANCZOS)
        target_path = os.path.join(out_dir, filename)
        resized.save(target_path, "PNG", optimize=True)
        print(f"Generated {filename} ({px}x{px})")

if __name__ == "__main__":
    main()
