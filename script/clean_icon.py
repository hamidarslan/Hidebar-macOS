"""Optional artwork maintenance: requires Pillow; not needed to build/run the app."""
from collections import deque
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
original = Image.open(root / "icons.png").convert("RGBA")
image = original.copy()
width, height = image.size
pixels = image.load()
outside = set()
queue = deque()

def visit(x, y):
    if 0 <= x < width and 0 <= y < height and (x, y) not in outside:
        r, g, b, _ = pixels[x, y]
        if min(r, g, b) >= 220 and max(r, g, b) - min(r, g, b) <= 35:
            outside.add((x, y))
            queue.append((x, y))

for x in range(width):
    visit(x, 0)
    visit(x, height - 1)
for y in range(height):
    visit(0, y)
    visit(width - 1, y)
while queue:
    x, y = queue.popleft()
    for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
        visit(x + dx, y + dy)

boundary = set()
for x, y in outside:
    for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
        nx, ny = x + dx, y + dy
        if 0 <= nx < width and 0 <= ny < height and (nx, ny) not in outside:
            boundary.add((nx, ny))
    pixels[x, y] = (0, 0, 0, 0)

source = original.load()
for x, y in boundary:
    neighbors = [source[nx, ny][:3]
                 for nx in range(max(0, x - 2), min(width, x + 3))
                 for ny in range(max(0, y - 2), min(height, y + 3))
                 if (nx, ny) not in outside and (nx, ny) not in boundary]
    if not neighbors:
        continue
    color = source[x, y][:3]
    inner = min(neighbors, key=min)
    alpha = min(1.0, (255 - min(color)) / max(1, 255 - min(inner)))
    if 0 < alpha < 0.995:
        unmatte = tuple(round(max(0, min(255, (c - 255 * (1 - alpha)) / alpha))) for c in color)
        pixels[x, y] = (*unmatte, round(255 * alpha))

destination = root / "Assets" / "AppIcon.png"
destination.parent.mkdir(exist_ok=True)
image.save(destination, optimize=True)
assert all(image.getpixel(p)[3] == 0 for p in [(0, 0), (width - 1, 0), (0, height - 1), (width - 1, height - 1)])
assert image.getpixel((width // 2, height // 2)) == original.getpixel((width // 2, height // 2))
print(f"Saved {destination.name}: {len(outside)} exterior pixels cleared; interior artwork preserved.")
