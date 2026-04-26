from PIL import Image, ImageDraw, ImageFilter

orig_path = "/Users/michelle/Vibe Projects/church of creationships/assets/phone_bouquet.png"
orig = Image.open(orig_path).convert("RGBA")
W, H = orig.size

# Flowers (left side)
f_box = (0, 0, int(W * 0.65), H)
flowers = orig.crop(f_box)

# Man (right side)
m_box = (int(W * 0.65), 0, W, H)
man = orig.crop(m_box)

# Canvas
new_w = int(W * 0.65)
new_h = H + 600
canvas = Image.new("RGBA", (new_w, new_h), (255, 255, 255, 255))

# Soft mask for flowers
f_mask = Image.new("L", flowers.size, 255)
d = ImageDraw.Draw(f_mask)
d.rectangle([0, H-150, flowers.width, H], fill=0) # black at bottom
f_mask = f_mask.filter(ImageFilter.GaussianBlur(50)) # feather

# Soft mask for man
m_mask = Image.new("L", man.size, 255)
d = ImageDraw.Draw(m_mask)
d.rectangle([0, 0, man.width, 150], fill=0) # black at top
d.rectangle([0, 0, 100, man.height], fill=0) # black at left
m_mask = m_mask.filter(ImageFilter.GaussianBlur(50)) # feather

canvas.paste(flowers, (0, 0), f_mask)

# Paste man lower down
px = (new_w - man.width) // 2 + 50
py = new_h - man.height
canvas.paste(man, (px, py), m_mask)

# Save
out = "/Users/michelle/Vibe Projects/church of creationships/assets/phone_bouquet_vertical.png"
canvas.save(out)
print("Saved seamlessly feathered image")
