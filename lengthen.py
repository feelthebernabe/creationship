from PIL import Image

img_path = "/Users/michelle/Vibe Projects/church of creationships/assets/phone_bouquet_vertical.png"
img = Image.open(img_path).convert("RGBA")
W, H = img.size

# We want to make the image longer by adding white space in the middle.
# Let's say we cut at y = int(H * 0.6)
split_y = int(H * 0.6)

top_crop = img.crop((0, 0, W, split_y))
bottom_crop = img.crop((0, split_y, W, H))

# Create a new taller canvas. Let's add 400 pixels of height.
added_height = 400
new_w = W
new_h = H + added_height
new_img = Image.new("RGBA", (new_w, new_h), (255, 255, 255, 255))

# Paste top part
new_img.paste(top_crop, (0, 0), top_crop)

# Paste bottom part shifted down
new_img.paste(bottom_crop, (0, split_y + added_height), bottom_crop)

output_path = "/Users/michelle/Vibe Projects/church of creationships/assets/phone_bouquet_vertical.png"
new_img.save(output_path)
print(f"Saved lengthened image to {output_path}")
