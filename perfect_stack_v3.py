from PIL import Image

orig_path = "/Users/michelle/Vibe Projects/church of creationships/assets/phone_bouquet.png"
orig = Image.open(orig_path).convert("RGBA")
W, H = orig.size

# We will just split it down the middle since the phone is on the left and man is on the right.
left = orig.crop((0, 0, int(W * 0.62), H))
right = orig.crop((int(W * 0.62), 0, W, H))

# Create a tall canvas
new_w = int(W * 0.65)
new_h = int(H * 1.8)
canvas = Image.new("RGBA", (new_w, new_h), (255, 255, 255, 255))

# Paste left crop at top
canvas.paste(left, (0, 0), left)

# Paste right crop at bottom
px = (new_w - right.width) // 2 + 50
py = new_h - right.height
canvas.paste(right, (px, py), right)

out = "/Users/michelle/Vibe Projects/church of creationships/assets/phone_bouquet_vertical.png"
canvas.save(out)
print("Saved perfect clean stack")
