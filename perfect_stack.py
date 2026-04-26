from PIL import Image

def remove_bg(img, threshold=245):
    img = img.convert("RGBA")
    data = img.getdata()
    new_data = []
    for item in data:
        # If the pixel is mostly white/light gray
        if item[0] > threshold and item[1] > threshold and item[2] > threshold:
            new_data.append((255, 255, 255, 0)) # transparent
        else:
            new_data.append(item)
    img.putdata(new_data)
    return img

# Original horizontal image
img_path = "/Users/michelle/Vibe Projects/church of creationships/assets/phone_bouquet.png"
orig = Image.open(img_path).convert("RGBA")
W, H = orig.size

# The flowers and phone are on the left
flowers_box = (0, 0, int(W * 0.65), H)
flowers = orig.crop(flowers_box)
flowers = remove_bg(flowers, 235)

# The man is on the right
man_box = (int(W * 0.6), 0, W, H)
man = orig.crop(man_box)
man = remove_bg(man, 235)

# Create a tall canvas to make the picture longer
new_w = int(W * 0.7)
new_h = H * 2
canvas = Image.new("RGBA", (new_w, new_h), (255, 255, 255, 255))

# Paste flowers near the top
canvas.paste(flowers, (0, 0), flowers)

# Paste man at the bottom, horizontally centered
paste_x = (new_w - man.width) // 2 + 30
paste_y = new_h - man.height - 50 # 50px from bottom
canvas.paste(man, (paste_x, paste_y), man)

output_path = "/Users/michelle/Vibe Projects/church of creationships/assets/phone_bouquet_vertical.png"
canvas.save(output_path)
print(f"Saved perfect vertical stack to {output_path}")
