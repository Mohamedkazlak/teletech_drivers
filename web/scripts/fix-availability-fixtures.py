from pathlib import Path

root = Path("web/src")
for path in root.rglob("*.tsx"):
    text = path.read_text(encoding="utf-8")
    original = text
    text = text.replace("availability_status: 'available'", "is_available: true")
    text = text.replace("availability_status: 'unavailable'", "is_available: false")
    text = text.replace(
        "availability_status: unavailable ? 'unavailable' : 'available'",
        "is_available: !unavailable",
    )
    text = text.replace("    availability_updated_at: '2026-11-01T08:00:00.000Z',\n", "")
    text = text.replace("    availability_updated_at: null,\n", "")
    if text != original:
        path.write_text(text, encoding="utf-8")
        print(path)
