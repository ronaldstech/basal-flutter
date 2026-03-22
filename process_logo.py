from PIL import Image
import sys

def process(input_path):
    try:
        img = Image.open(input_path).convert("RGBA")
    except Exception as e:
        print(f"Failed to open image: {e}")
        return
        
    # Get bounding box of non-transparent pixels
    bbox = img.getbbox()
    if not bbox:
        print("Empty image")
        return
    
    # Crop to bounding box
    cropped = img.crop(bbox)
    
    # Determine the larger dimension to make a square
    width, height = cropped.size
    max_dim = max(width, height)
    
    # We want the logo to take up 85% of the square so it's nicely zoomed
    canvas_size = int(max_dim / 0.85)
    
    # Create iOS icon: Black background
    ios_canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 255))
    offset = ((canvas_size - width) // 2, (canvas_size - height) // 2)
    ios_canvas.paste(cropped, offset, cropped)
    ios_canvas.convert("RGB").save("logo_ios.png")
    
    # Create Android Foreground / Splash: Transparent background
    splash_canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    splash_canvas.paste(cropped, offset, cropped)
    splash_canvas.save("logo_android.png")
    print("SUCCESS")

process("logo.png")
