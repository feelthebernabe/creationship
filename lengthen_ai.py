from PIL import Image

img_path = "/Users/michelle/.gemini/antigravity/brain/b1e86a69-4886-4265-b404-eafb3b55db00/phone_bouquet_vertical_new_1777206156495.png"
orig = Image.open(img_path).convert("RGBA")
W, H = orig.size

# The AI image is 1024x1024.
# Flowers and phone end around y=700
# Man is around y=300 to 1000 on the right side.
# Wait, they overlap horizontally!
# But the background is PURE WHITE.
# So we can just crop the flowers (top left) and man (bottom right).

flowers_crop = orig.crop((0, 0, W, 700))
# Let's clean up the right side of flowers_crop where the man's head might be.
# Actually, looking at the AI image, the man is on the right, looking up.
# His head is around y=350, x=750.
# The phone is at y=500, x=450.
# We can just use the original image's crops since `mix-blend-mode` is on.
