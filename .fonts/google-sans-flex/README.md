# Google Sans Flex

Static instances generated from `GoogleSansFlex-Variable.ttf` with rounded
terminals (`ROND=100`) and optional italic slant (`slnt=-10`).

## Weights

| Weight | Normal     | Italic           |
| ------ | ---------- | ---------------- |
| 100    | Thin       | ThinItalic       |
| 200    | ExtraLight | ExtraLightItalic |
| 300    | Light      | LightItalic      |
| 400    | Regular    | Italic           |
| 500    | Medium     | MediumItalic     |
| 700    | Bold       | BoldItalic       |

## Generation

Requires [fonttools](https://github.com/fonttools/fonttools):

```sh
pip3 install fonttools
```

Place `GoogleSansFlex-Variable.ttf` in this directory and run:

```sh
python3 generate.py
```

<details>
<summary><code>generate.py</code></summary>

```py
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont

src = "GoogleSansFlex-Variable.ttf"

family = "Google Sans Flex"
weight_map = {
    100: "Thin",
    200: "ExtraLight",
    300: "Light",
    400: "Regular",
    500: "Medium",
    700: "Bold",
}

instances = []
for wght, wname in weight_map.items():
    instances.append((wname, {"ROND": 100.0, "wght": float(wght)}, False))
    italic_suffix = wname + "Italic" if wname != "Regular" else "Italic"
    instances.append(
        (italic_suffix, {"ROND": 100.0, "wght": float(wght), "slnt": -10.0}, True)
    )

for suffix, coords, is_italic in instances:
    print(f"GoogleSansFlex-{suffix}.ttf ...", flush=True)
    font = TTFont(src)
    instantiateVariableFont(font, coords, inplace=True, overlap=1)

    wght = int(coords["wght"])
    wname = weight_map[wght]
    parts = []
    if wname != "Regular":
        parts.append(wname)
    if is_italic:
        parts.append("Italic")
    style = " ".join(parts) if parts else "Regular"

    if wght == 700 and is_italic:
        ribbi = "Bold Italic"
    elif wght == 700:
        ribbi = "Bold"
    elif is_italic and wght == 400:
        ribbi = "Italic"
    elif wght == 400:
        ribbi = "Regular"
    else:
        ribbi = ""

    name1 = family if ribbi else f"{family} {wname}"
    name2 = ribbi if ribbi else ("Italic" if is_italic else "Regular")
    name4 = f"{family} {style}"
    name6 = f"GoogleSansFlex-{suffix}"

    name_table = font["name"]
    for pid, peid, lid in [(3, 1, 0x409), (1, 0, 0)]:
        name_table.setName(name1, 1, pid, peid, lid)
        name_table.setName(name2, 2, pid, peid, lid)
        name_table.setName(name4, 4, pid, peid, lid)
        name_table.setName(name6, 6, pid, peid, lid)
        name_table.setName(family, 16, pid, peid, lid)
        name_table.setName(style, 17, pid, peid, lid)

    mac_style = 0
    if wght >= 700:
        mac_style |= 1
    if is_italic:
        mac_style |= 2
    font["head"].macStyle = mac_style

    fs = font["OS/2"].fsSelection
    fs &= ~(1 | (1 << 5) | (1 << 6))
    if is_italic:
        fs |= 1
    if wght >= 700:
        fs |= 1 << 5
    if wght == 400 and not is_italic:
        fs |= 1 << 6
    font["OS/2"].fsSelection = fs

    font.save(f"./GoogleSansFlex-{suffix}.ttf")
```

</details>
