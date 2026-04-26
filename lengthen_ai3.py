from PIL import Image

orig_path = "/Users/michelle/.gemini/antigravity/brain/b1e86a69-4886-4265-b404-eafb3b55db00/phone_bouquet_vertical_new_1777206156495.png"
orig = Image.open(orig_path).convert("RGBA")

# We want to lower the man. The man is on the right side.
# Let's crop just the man.
# Bounding box for the man: (500, 300, 1024, 1024) approx.
# We will create a taller canvas.
canvas = Image.new("RGBA", (1024, 1524), (255, 255, 255, 255))

# Paste the original image at the top. This includes the man in his original position.
canvas.paste(orig, (0, 0))

# To "lower" him, we need to erase him from the top, and paste him at the bottom.
# Let's crop the man perfectly. Since background is pure white, we can crop a rectangle.
man_rect = (550, 300, 1024, 1024)
man_img = orig.crop(man_rect)

# Paste the man 500 pixels lower
canvas.paste(man_img, (550, 800))

# Erase the original man by pasting a white rectangle over his old position
from PIL import ImageDraw
draw = ImageDraw.Draw(canvas)
# But we only want to erase the man, not the flowers!
# Fortunately, the man is on the right, and the flowers/phone are mostly on the left.
# Wait, let's look at the AI image again. The man is on the right, the phone is in the middle.
# Let's just draw a white rectangle over (550, 300, 1024, 800)
draw.rectangle([550, 300, 1024, 800], fill=(255, 255, 255, 255))

out = "/Users/michelle/Vibe Projects/church of creationships/assets/phone_bouquet_vertical.png"
canvas.save(out)
print("Saved fixed AI image")
