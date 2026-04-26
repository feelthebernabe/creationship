from PIL import Image, ImageChops

def remove_white_bg(img, tolerance=240):
    img = img.convert("RGBA")
    data = img.getdata()
    newData = []
    for item in data:
        if item[0] > tolerance and item[1] > tolerance and item[2] > tolerance:
            newData.append((255, 255, 255, 0))
        else:
            newData.append(item)
    img.putdata(newData)
    return img

img_path = "/Users/michelle/Vibe Projects/church of creationships/assets/phone_bouquet.png"
img = Image.open(img_path).convert("RGBA")
W, H = img.size

# Extract man (right side)
man_crop = img.crop((int(W * 0.6), 0, W, H))
man_crop = remove_white_bg(man_crop, tolerance=230)

# Extract flowers (left side)
flowers_crop = img.crop((0, 0, int(W * 0.65), H))
flowers_crop = remove_white_bg(flowers_crop, tolerance=230)

# New canvas
new_w = int(W * 0.65)
new_h = int(H * 1.5)
new_img = Image.new("RGBA", (new_w, new_h), (255, 255, 255, 255))

# Paste flowers at the top
new_img.alpha_composite(flowers_crop, dest=(0, 0))

# Paste man at the bottom
paste_x = (new_w - man_crop.width) // 2 + 50
paste_y = new_h - man_crop.height
new_img.alpha_composite(man_crop, dest=(paste_x, paste_y))

output_path = "/Users/michelle/Vibe Projects/church of creationships/assets/phone_bouquet_vertical.png"
new_img.save(output_path)
print("Saved to", output_path)
