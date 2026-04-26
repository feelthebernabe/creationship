from PIL import Image, ImageDraw, ImageFilter

img_path = "/Users/michelle/Vibe Projects/church of creationships/assets/phone_bouquet.png"
img = Image.open(img_path).convert("RGBA")
W, H = img.size

# The flowers and floating phone are on the left (~65%)
left_crop = img.crop((0, 0, int(W * 0.65), H))

# The man is on the right (~35%)
right_crop = img.crop((int(W * 0.65), 0, W, H))

# We want to stack them vertically.
new_w = int(W * 0.65)
new_h = H + int(H * 0.4)
new_img = Image.new("RGBA", (new_w, new_h), (255, 255, 255, 255))

# Create a gradient mask for the left crop to blend the bottom edge
left_mask = Image.new("L", left_crop.size, 255)
draw = ImageDraw.Draw(left_mask)
# fade out the bottom 100 pixels
for y in range(H - 100, H):
    alpha = int(255 * (H - y) / 100)
    draw.line([(0, y), (left_crop.width, y)], fill=alpha)

new_img.paste(left_crop, (0, 0), left_mask)

# Create a gradient mask for the right crop to blend the top edge
right_mask = Image.new("L", right_crop.size, 255)
draw = ImageDraw.Draw(right_mask)
# fade out the top 100 pixels
for y in range(0, 100):
    alpha = int(255 * (y) / 100)
    draw.line([(0, y), (right_crop.width, y)], fill=alpha)

# Paste man at bottom, horizontally centered
paste_x = (new_w - right_crop.width) // 2 + 50 # shift slightly to align
paste_y = new_h - right_crop.height
new_img.paste(right_crop, (paste_x, paste_y), right_mask)

output_path = "/Users/michelle/Vibe Projects/church of creationships/assets/phone_bouquet_vertical.png"
# we composite over a white background so it doesn't have transparency holes where we faded
bg = Image.new("RGBA", new_img.size, (252, 252, 252, 255))
final_img = Image.alpha_composite(bg, new_img)
final_img.save(output_path)
print(f"Saved edited image to {output_path}")
