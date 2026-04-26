from PIL import Image

img_path = "/Users/michelle/Vibe Projects/church of creationships/assets/tech_birdhouse.png"
img = Image.open(img_path).convert("RGBA")
print(f"Original size: {img.size}")

# Let's crop to find the man. He is on the right side.
W, H = img.size

# Man is roughly in the right 25% of the image.
# We also want to capture the phone he is holding.
# Let's just manually composite: we'll move the left side (flowers + phone) up
# and the right side (man) down.

flowers_crop = img.crop((0, 0, int(W * 0.7), H))
man_crop = img.crop((int(W * 0.7), 0, W, H))

new_w = int(W * 0.8)
new_h = int(H * 1.3)
new_img = Image.new("RGBA", (new_w, new_h), (255, 255, 255, 255))

# Paste flowers at top left
new_img.paste(flowers_crop, (0, 0), flowers_crop)

# Paste man at bottom right, shifted down
paste_x = new_w - man_crop.width
paste_y = new_h - man_crop.height
new_img.paste(man_crop, (paste_x, paste_y), man_crop)

output_path = "/Users/michelle/Vibe Projects/church of creationships/assets/tech_birdhouse_edited.png"
new_img.save(output_path)
print(f"Saved edited image to {output_path}")
