from PIL import Image

orig_path = "/Users/michelle/.gemini/antigravity/brain/b1e86a69-4886-4265-b404-eafb3b55db00/phone_bouquet_vertical_new_1777206156495.png"
orig = Image.open(orig_path).convert("RGBA")
W, H = orig.size

# Generative AI image: 1024x1024, white bg
# Man is on the right. Flowers are on the left.
# We will just split it horizontally and add white space.
# The man goes up to around y=350, so if we cut at y=512 we cut his head.
# The flowers go down to around y=700, so they overlap vertically.
# But they don't overlap horizontally much! Man is on the right, flowers left.
# So we can cut them out precisely.

# Make a white canvas
new_w = W
new_h = H + 600
canvas = Image.new("RGBA", (new_w, new_h), (255, 255, 255, 255))

# We'll just take the whole image, paste it at the top.
# Then take the right side (where the man is), paste it at the bottom, and cover the original man with white.
canvas.paste(orig, (0, 0))

# The man is roughly in the bounding box (500, 300, 1024, 1024)
man_crop = orig.crop((500, 300, 1024, 1024))

# Paste man lower down
canvas.paste(man_crop, (500, 300 + 600))

# Now we need to erase the original man from the top part
# We just draw a white rectangle over his old position
from PIL import ImageDraw
draw = ImageDraw.Draw(canvas)
draw.rectangle([500, 300, 1024, 1024], fill=(255, 255, 255, 255))

# Save
out = "/Users/michelle/Vibe Projects/church of creationships/assets/phone_bouquet_vertical.png"
canvas.save(out)
print("Saved separated AI image")
