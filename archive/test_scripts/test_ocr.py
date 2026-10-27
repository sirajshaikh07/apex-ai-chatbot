import io
from PIL import Image, ImageDraw
import pytesseract

img = Image.new('RGB', (800, 200), color=(255, 255, 255))
d = ImageDraw.Draw(img)
d.text((20, 30), 'Candidate Bio-Data: Safa Himmatkha Pathan', fill=(0, 0, 0))
d.text((20, 80), 'Education: 12th Commerce | Contact: 9370285154', fill=(0, 0, 0))

buf = io.BytesIO()
img.save(buf, format='PNG')
buf.seek(0)

extracted = pytesseract.image_to_string(Image.open(buf))
print('=== OCR EXTRACTED TEXT ===')
print(extracted.strip())
