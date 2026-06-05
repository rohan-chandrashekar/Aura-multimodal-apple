import json
import os
import subprocess

TEST_DIR = "test_images"
os.makedirs(TEST_DIR, exist_ok=True)

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print("Pillow required. Install: pip install pillow")
    raise

def create_text_image(filename, text_lines, size=(640, 480), bg="white", fg="black"):
    img = Image.new("RGB", size, bg)
    draw = ImageDraw.Draw(img)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 36)
    except Exception:
        font = ImageFont.load_default()
    y = 80
    for line in text_lines:
        draw.text((60, y), line, fill=fg, font=font)
        y += 60
    path = os.path.join(TEST_DIR, filename)
    img.save(path)
    return path

def create_object_scene(filename, objects_desc, size=(640, 480)):
    img = Image.new("RGB", size, (200, 200, 200))
    draw = ImageDraw.Draw(img)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 24)
    except Exception:
        font = ImageFont.load_default()

    colors = [(255, 0, 0), (0, 128, 0), (0, 0, 255), (255, 165, 0), (128, 0, 128)]
    positions = [(50, 50, 250, 200), (300, 50, 500, 200), (50, 250, 250, 400), (300, 250, 500, 400)]

    for i, (label, color_idx) in enumerate(objects_desc):
        if i >= len(positions):
            break
        x1, y1, x2, y2 = positions[i]
        color = colors[color_idx % len(colors)]
        draw.rectangle([x1, y1, x2, y2], fill=color, outline="black", width=2)
        draw.text((x1 + 10, y1 + 10), label, fill="white", font=font)

    path = os.path.join(TEST_DIR, filename)
    img.save(path)
    return path


print("Creating test images...")

create_text_image("text_sign.jpg", [
    "EMERGENCY EXIT",
    "Push Bar to Open",
    "Alarm Will Sound",
])

create_text_image("text_label.jpg", [
    "Ibuprofen 200mg",
    "Take 1-2 tablets",
    "every 4-6 hours",
])

create_text_image("text_meeting.jpg", [
    "Conference Room B",
    "Meeting at 3:00 PM",
    "Project Review",
])

create_object_scene("shapes_only.jpg", [
    ("Object A", 0),
    ("Object B", 1),
    ("Object C", 2),
])

img = Image.new("RGB", (640, 480), (240, 240, 240))
draw = ImageDraw.Draw(img)
try:
    font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 28)
    small_font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 20)
except Exception:
    font = ImageFont.load_default()
    small_font = font
draw.rectangle([50, 50, 300, 200], fill=(100, 100, 100), outline="black")
draw.text((80, 100), "LAPTOP", fill="white", font=font)
draw.rectangle([350, 80, 480, 220], fill=(139, 69, 19), outline="black")
draw.text((360, 130), "MUG", fill="white", font=font)
draw.text((50, 350), "WiFi: AuraNet", fill="black", font=small_font)
draw.text((50, 380), "Password: welcome123", fill="black", font=small_font)
img.save(os.path.join(TEST_DIR, "desk_scene.jpg"))

labels = [
    {
        "file": "text_sign.jpg",
        "objects": [],
        "text": ["EMERGENCY EXIT", "Push Bar to Open", "Alarm Will Sound"],
    },
    {
        "file": "text_label.jpg",
        "objects": [],
        "text": ["Ibuprofen 200mg", "Take 1-2 tablets", "every 4-6 hours"],
    },
    {
        "file": "text_meeting.jpg",
        "objects": [],
        "text": ["Conference Room B", "Meeting at 3:00 PM", "Project Review"],
    },
    {
        "file": "desk_scene.jpg",
        "objects": [],
        "text": ["WiFi: AuraNet", "Password: welcome123"],
    },
]

labels_path = os.path.join(TEST_DIR, "labels.json")
with open(labels_path, "w") as f:
    json.dump(labels, f, indent=2)

print(f"Created {len(labels)} test images + labels.json in {TEST_DIR}/")
print("Note: these are synthetic images for OCR evaluation.")
print("Object detection accuracy should be tested with real photos.")
